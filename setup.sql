-- ALMADINA SUPERMARKET: ملف إعداد واحد، آمن لإعادة التشغيل
-- ALMADINA SUPERMARKET — Supabase schema (شغّله في SQL Editor)
create extension if not exists pg_trgm with schema extensions;
create table if not exists admins(user_id uuid primary key references auth.users on delete cascade, role text default 'admin');
create or replace function is_admin() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from admins where user_id=auth.uid()) $$;
create table if not exists categories(id serial primary key, name_ar text not null, name_en text, slug text unique not null, image_url text, sort int default 0, active bool default true);
create table if not exists subcategories(id serial primary key, category_id int references categories on delete cascade, name_ar text not null, sort int default 0);
create table if not exists products(id bigserial primary key, sku text unique, name_ar text not null, name_en text, description text,
 category_id int references categories, subcategory_id int references subcategories,
 price numeric(10,2) not null check(price>=0), old_price numeric(10,2), stock int not null default 0 check(stock>=0), min_stock int default 5, min_qty int default 1,
 unit text default 'قطعة', image_url text, featured bool default false, is_new bool default false, active bool default true, is_demo bool default false, created_at timestamptz default now());
create index if not exists ix_products_category_id on products(category_id) where active;
create index if not exists products_search on products using gin ((name_ar||' '||coalesce(name_en,'')||' '||coalesce(sku,'')) gin_trgm_ops);
create table if not exists offers(id serial primary key, product_id bigint references products on delete cascade, percent numeric, amount numeric, new_price numeric, starts_at timestamptz, ends_at timestamptz, active bool default true);
create table if not exists banners(id serial primary key, image_url text, title text, subtitle text, button_text text, link text, sort int default 0, active bool default true);
create table if not exists delivery_zones(id serial primary key, name text not null, fee numeric(10,2) not null default 0, active bool default true);
create table if not exists store_settings(key text primary key, value jsonb not null); -- whatsapp_number, delivery_enabled, free_above, min_order, currency, hours, social...
create table if not exists customers(id bigserial primary key, phone text unique not null, name text, created_at timestamptz default now());
create sequence if not exists order_seq;
create table if not exists orders(id bigserial primary key, order_no text unique not null, customer_id bigint references customers, name text not null, phone text not null,
 delivery bool not null, zone_id int references delivery_zones, address text, note text, subtotal numeric(10,2), delivery_fee numeric(10,2), total numeric(10,2),
 status text not null default 'جديد' check(status in ('جديد','تم التأكيد','قيد التجهيز','جاهز للاستلام','خرج للتوصيل','تم التسليم','ملغي')), created_at timestamptz default now());
create table if not exists order_items(id bigserial primary key, order_id bigint references orders on delete cascade, product_id bigint references products, name text, qty int check(qty>0), unit_price numeric(10,2));
create index if not exists ix_orders_created_at on orders(created_at desc); create index if not exists ix_orders_phone on orders(phone); create index if not exists ix_order_items_order_id on order_items(order_id);

-- إنشاء الطلب بشكل ذري مع قفل المخزون (يمنع تجاوز الكمية والمخزون السالب)
create or replace function place_order(p jsonb) returns text language plpgsql security definer set search_path=public as $$
declare it jsonb; pr products%rowtype; oid bigint; cid bigint; sub numeric:=0; fee numeric:=0; no text; z delivery_zones%rowtype; free numeric;
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
  update products set stock=stock-(it->>'qty')::int where id=pr.id;
  insert into order_items(order_id,product_id,name,qty,unit_price) values(oid,pr.id,pr.name_ar,(it->>'qty')::int,pr.price);
  sub:=sub+pr.price*(it->>'qty')::int;
 end loop;
 if (p->>'delivery')::bool then
  select * into z from delivery_zones where id=(p->>'zone_id')::int and active; fee:=coalesce(z.fee,0);
  select (value#>>'{}')::numeric into free from store_settings where key='free_above'; if free is not null and sub>=free then fee:=0; end if;
 end if;
 update orders set subtotal=sub,delivery_fee=fee,total=sub+fee where id=oid;
 return no;
end $$;
revoke all on function place_order(jsonb) from public; grant execute on function place_order(jsonb) to anon,authenticated;

-- الأمان (RLS)
alter table admins enable row level security; alter table categories enable row level security; alter table subcategories enable row level security; alter table products enable row level security;
alter table offers enable row level security; alter table banners enable row level security; alter table delivery_zones enable row level security; alter table store_settings enable row level security;
alter table customers enable row level security; alter table orders enable row level security; alter table order_items enable row level security;
drop policy if exists pub_cat on categories; create policy pub_cat on categories for select using(active); drop policy if exists pub_sub on subcategories; create policy pub_sub on subcategories for select using(true);
drop policy if exists pub_prod on products; create policy pub_prod on products for select using(active); drop policy if exists pub_off on offers; create policy pub_off on offers for select using(active and (ends_at is null or ends_at>now()));
drop policy if exists pub_ban on banners; create policy pub_ban on banners for select using(active); drop policy if exists pub_zone on delivery_zones; create policy pub_zone on delivery_zones for select using(active); drop policy if exists pub_set on store_settings; create policy pub_set on store_settings for select using(true);
do $$ declare t text; begin foreach t in array array['admins','categories','subcategories','products','offers','banners','delivery_zones','store_settings','customers','orders','order_items'] loop
 execute format('drop policy if exists adm_%1$s on %1$s; create policy adm_%1$s on %1$s for all using(is_admin()) with check(is_admin())',t); end loop; end $$;
-- التخزين: bucket عام للقراءة، والرفع للإدارة فقط
insert into storage.buckets(id,name,public) values('product-images','product-images',true) on conflict do nothing;
drop policy if exists img_admin on storage.objects; create policy img_admin on storage.objects for all using(bucket_id='product-images' and is_admin()) with check(bucket_id='product-images' and is_admin());
-- بعد إنشاء حسابك في Supabase Auth: insert into admins(user_id) values('<UUID>');

grant execute on function is_admin() to anon,authenticated;

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

-- بيانات أولية (شغّله بعد supabase-schema.sql). المنتجات التجريبية is_demo=true
insert into categories(name_ar,slug,sort) values('مواد غذائية','food',1),('مشروبات','drinks',2),('ألبان','dairy',3),('منظفات','cleaning',4),('عناية شخصية','care',5),('مجمدات','frozen',6),('معلبات','canned',7),('مخبوزات','bakery',8) on conflict(slug) do nothing;
insert into delivery_zones(name,fee) select * from (values('وسط المدينة',5),('المنطقة 2',8),('المنطقة 3',12)) v(n,f) where not exists(select 1 from delivery_zones);
insert into store_settings(key,value) values('whatsapp_number','""'),('free_above','150'),('min_order','20'),('delivery_enabled','true'),('pickup_enabled','true'),('currency','"د.ل"') on conflict(key) do nothing;
insert into products(sku,name_ar,price,old_price,stock,unit,is_new,is_demo,category_id)
select v.a,v.b,v.c,v.d,v.e,v.f,v.g,true,c.id from (values
('D-1','كوكاكولا 1.25 لتر',8.5,10,40,'عبوة',false,'drinks'),('D-2','مياه معدنية 1.5 لتر',1.5,null,200,'عبوة',false,'drinks'),
('D-3','أرز بسمتي 5 كيلو',32,38,25,'كيس',false,'food'),('D-4','مكرونة سباغيتي 500 جرام',2.5,null,120,'عبوة',true,'food'),
('D-5','حليب طازج 1 لتر',4.5,null,60,'عبوة',true,'dairy'),('D-6','سائل غسيل أطباق',6.5,8,30,'عبوة',false,'cleaning'),
('D-7','شامبو 400 مل',14,17,22,'عبوة',false,'care'),('D-8','بطاطس مجمدة 1 كيلو',9,11,15,'كيس',false,'frozen'),
('D-9','تونة معلبة',4.5,5.5,70,'علبة',false,'canned'),('D-10','خبز تنور',1,null,90,'حبة',true,'bakery')
) v(a,b,c,d,e,f,g,cs) join categories c on c.slug=v.cs on conflict(sku) do nothing;
-- لحذف التجريبي قبل الإطلاق: delete from products where is_demo;

-- ⚠️ ضع بريد المدير بدل البريد التالي (نفس بريد المستخدم في Authentication) ثم شغّل الملف
insert into admins(user_id) select id from auth.users where lower(email)=lower('salehfk@gmail.com') on conflict do nothing;
select count(*) as عدد_المديرين from admins; -- يجب أن تكون النتيجة 1 على الأقل
