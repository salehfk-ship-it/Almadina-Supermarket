-- شغّله بعد supabase-schema.sql: يفعّل العروض تلقائياً في الأسعار ويتوقف العرض عند انتهاء تاريخه
create or replace function offer_price(pid bigint) returns numeric language sql stable as $$
select coalesce((select min(greatest(0, case when o.new_price is not null then o.new_price when o.percent is not null then p.price*(1-o.percent/100) else p.price-coalesce(o.amount,0) end))
 from offers o join products p on p.id=o.product_id where o.product_id=pid and o.active and (o.starts_at is null or o.starts_at<=now()) and (o.ends_at is null or o.ends_at>now())),(select price from products where id=pid)) $$;
create or replace function place_order(p jsonb) returns text language plpgsql security definer set search_path=public as $$
declare it jsonb; pr products%rowtype; oid bigint; cid bigint; sub numeric:=0; fee numeric:=0; no text; z delivery_zones%rowtype; free numeric; ep numeric;
begin
 if length(trim(coalesce(p->>'name','')))<3 or (p->>'phone') !~ '^(\+?218|0)?9[1-6][0-9]{7}$' then raise exception 'بيانات العميل غير صحيحة'; end if;
 if jsonb_array_length(p->'items')=0 then raise exception 'السلة فارغة'; end if;
 no:='MD-'||lpad(nextval('order_seq')::text,6,'0');
 insert into customers(phone,name) values(p->>'phone',p->>'name') on conflict(phone) do update set name=excluded.name returning id into cid;
 insert into orders(order_no,customer_id,name,phone,delivery,zone_id,address,note) values(no,cid,p->>'name',p->>'phone',(p->>'delivery')::bool,nullif(p->>'zone_id','')::int,p->>'address',p->>'note') returning id into oid;
 for it in select * from jsonb_array_elements(p->'items') loop
  select * into pr from products where id=(it->>'id')::bigint and active for update;
  if not found then raise exception 'المنتج غير متوفر'; end if;
  if pr.stock<(it->>'qty')::int then raise exception 'الكمية المطلوبة غير متوفرة حالياً. الكمية المتوفرة: %',pr.stock; end if;
  ep:=round(offer_price(pr.id),2);
  update products set stock=stock-(it->>'qty')::int where id=pr.id;
  insert into order_items(order_id,product_id,name,qty,unit_price) values(oid,pr.id,pr.name_ar,(it->>'qty')::int,ep);
  sub:=sub+ep*(it->>'qty')::int;
 end loop;
 if (p->>'delivery')::bool then
  select * into z from delivery_zones where id=(p->>'zone_id')::int and active; fee:=coalesce(z.fee,0);
  select (value#>>'{}')::numeric into free from store_settings where key='free_above'; if free is not null and sub>=free then fee:=0; end if;
 end if;
 update orders set subtotal=sub,delivery_fee=fee,total=sub+fee where id=oid;
 return no;
end $$;
revoke all on function place_order(jsonb) from public; grant execute on function place_order(jsonb) to anon,authenticated;
