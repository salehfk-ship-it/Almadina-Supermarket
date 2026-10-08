-- بيانات أولية (شغّله بعد supabase-schema.sql). المنتجات التجريبية is_demo=true
insert into categories(name_ar,slug,sort) values('مواد غذائية','food',1),('مشروبات','drinks',2),('ألبان','dairy',3),('منظفات','cleaning',4),('عناية شخصية','care',5),('مجمدات','frozen',6),('معلبات','canned',7),('مخبوزات','bakery',8);
insert into delivery_zones(name,fee) values('وسط المدينة',5),('المنطقة 2',8),('المنطقة 3',12);
insert into store_settings(key,value) values('whatsapp_number','""'),('free_above','150'),('min_order','20'),('delivery_enabled','true'),('pickup_enabled','true'),('currency','"د.ل"');
insert into products(sku,name_ar,price,old_price,stock,unit,is_new,is_demo,category_id)
select v.a,v.b,v.c,v.d,v.e,v.f,v.g,true,c.id from (values
('D-1','كوكاكولا 1.25 لتر',8.5,10,40,'عبوة',false,'drinks'),('D-2','مياه معدنية 1.5 لتر',1.5,null,200,'عبوة',false,'drinks'),
('D-3','أرز بسمتي 5 كيلو',32,38,25,'كيس',false,'food'),('D-4','مكرونة سباغيتي 500 جرام',2.5,null,120,'عبوة',true,'food'),
('D-5','حليب طازج 1 لتر',4.5,null,60,'عبوة',true,'dairy'),('D-6','سائل غسيل أطباق',6.5,8,30,'عبوة',false,'cleaning'),
('D-7','شامبو 400 مل',14,17,22,'عبوة',false,'care'),('D-8','بطاطس مجمدة 1 كيلو',9,11,15,'كيس',false,'frozen'),
('D-9','تونة معلبة',4.5,5.5,70,'علبة',false,'canned'),('D-10','خبز تنور',1,null,90,'حبة',true,'bakery')
) v(a,b,c,d,e,f,g,cs) join categories c on c.slug=v.cs;
-- لحذف التجريبي قبل الإطلاق: delete from products where is_demo;
