-- تحديث: عمود الباركود + تصنيف البقوليات (شغّله مرة واحدة في SQL Editor، وآمن لإعادة التشغيل)
alter table products add column if not exists barcode text;
create unique index if not exists ux_products_barcode on products(barcode) where barcode is not null;
insert into categories(name_ar,slug,sort) select 'البقوليات','legumes',coalesce(max(sort),0)+1 from categories on conflict(slug) do nothing;
