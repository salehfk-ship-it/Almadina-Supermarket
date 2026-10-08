-- ALMADINA SUPERMARKET — Supabase schema (شغّله في SQL Editor)
create extension if not exists pg_trgm;
create table admins(user_id uuid primary key references auth.users on delete cascade, role text default 'admin');
create function is_admin() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from admins where user_id=auth.uid()) $$;
create table categories(id serial primary key, name_ar text not null, name_en text, slug text unique not null, image_url text, sort int default 0, active bool default true);
create table subcategories(id serial primary key, category_id int references categories on delete cascade, name_ar text not null, sort int default 0);
create table products(id bigserial primary key, sku text unique, name_ar text not null, name_en text, description text,
 category_id int references categories, subcategory_id int references subcategories,
 price numeric(10,2) not null check(price>=0), old_price numeric(10,2), stock int not null default 0 check(stock>=0), min_stock int default 5, min_qty int default 1,
 unit text default 'قطعة', image_url text, featured bool default false, is_new bool default false, active bool default true, is_demo bool default false, created_at timestamptz default now());
create index on products(category_id) where active;
create index products_search on products using gin ((name_ar||' '||coalesce(name_en,'')||' '||coalesce(sku,'')) gin_trgm_ops);
create table offers(id serial primary key, product_id bigint references products on delete cascade, percent numeric, amount numeric, new_price numeric, starts_at timestamptz, ends_at timestamptz, active bool default true);
create table banners(id serial primary key, image_url text, title text, subtitle text, button_text text, link text, sort int default 0, active bool default true);
create table delivery_zones(id serial primary key, name text not null, fee numeric(10,2) not null default 0, active bool default true);
create table store_settings(key text primary key, value jsonb not null); -- whatsapp_number, delivery_enabled, free_above, min_order, currency, hours, social...
create table customers(id bigserial primary key, phone text unique not null, name text, created_at timestamptz default now());
create sequence order_seq;
create table orders(id bigserial primary key, order_no text unique not null, customer_id bigint references customers, name text not null, phone text not null,
 delivery bool not null, zone_id int references delivery_zones, address text, note text, subtotal numeric(10,2), delivery_fee numeric(10,2), total numeric(10,2),
 status text not null default 'جديد' check(status in ('جديد','تم التأكيد','قيد التجهيز','جاهز للاستلام','خرج للتوصيل','تم التسليم','ملغي')), created_at timestamptz default now());
create table order_items(id bigserial primary key, order_id bigint references orders on delete cascade, product_id bigint references products, name text, qty int check(qty>0), unit_price numeric(10,2));
create index on orders(created_at desc); create index on orders(phone); create index on order_items(order_id);

-- إنشاء الطلب بشكل ذري مع قفل المخزون (يمنع تجاوز الكمية والمخزون السالب)
create function place_order(p jsonb) returns text language plpgsql security definer set search_path=public as $$
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
create policy pub_cat on categories for select using(active); create policy pub_sub on subcategories for select using(true);
create policy pub_prod on products for select using(active); create policy pub_off on offers for select using(active and (ends_at is null or ends_at>now()));
create policy pub_ban on banners for select using(active); create policy pub_zone on delivery_zones for select using(active); create policy pub_set on store_settings for select using(true);
do $$ declare t text; begin foreach t in array array['admins','categories','subcategories','products','offers','banners','delivery_zones','store_settings','customers','orders','order_items'] loop
 execute format('create policy adm_%1$s on %1$s for all using(is_admin()) with check(is_admin())',t); end loop; end $$;
-- التخزين: bucket عام للقراءة، والرفع للإدارة فقط
insert into storage.buckets(id,name,public) values('product-images','product-images',true) on conflict do nothing;
create policy img_admin on storage.objects for all using(bucket_id='product-images' and is_admin()) with check(bucket_id='product-images' and is_admin());
-- بعد إنشاء حسابك في Supabase Auth: insert into admins(user_id) values('<UUID>');
