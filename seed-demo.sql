-- بيانات أولية (شغّله بعد supabase-schema.sql). المنتجات التجريبية is_demo=true
-- آمن لإعادة التشغيل: لا يكرر الأقسام أو المنتجات أو الإعدادات الموجودة
insert into categories(name_ar,name_en,slug,sort) values
('مواد غذائية','Groceries','food',1),('مشروبات','Drinks','drinks',2),('ألبان','Dairy','dairy',3),('منظفات','Cleaning','cleaning',4),
('عناية شخصية','Personal Care','care',5),('مجمدات','Frozen','frozen',6),('معلبات','Canned','canned',7),('مخبوزات','Bakery','bakery',8),
('خضار وفواكه','Fruits & Vegetables','produce',9),('لحوم ودواجن','Meat & Poultry','meat',10),('حلويات وسناكس','Snacks & Sweets','snacks',11),
('مستلزمات الأطفال','Baby','baby',12),('بهارات وتوابل','Spices','spices',13)
on conflict(slug) do nothing;

insert into delivery_zones(name,fee) select v.n,v.f from (values('وسط المدينة',5),('المنطقة 2',8),('المنطقة 3',12)) v(n,f)
where not exists(select 1 from delivery_zones);

insert into store_settings(key,value) values('whatsapp_number','""'),('free_above','150'),('min_order','20'),('delivery_enabled','true'),('pickup_enabled','true'),('currency','"د.ل"')
on conflict(key) do nothing;

insert into products(sku,name_ar,price,old_price,stock,unit,is_new,featured,is_demo,category_id)
select v.a,v.b,v.c,v.d,v.e,v.f,v.g,v.h,true,c.id from (values
-- مشروبات
('D-1','كوكاكولا 1.25 لتر',8.5,10,40,'عبوة',false,true,'drinks'),('D-2','مياه معدنية 1.5 لتر',1.5,null,200,'عبوة',false,false,'drinks'),
('D-11','عصير برتقال 1 لتر',6,7.5,30,'عبوة',false,false,'drinks'),('D-12','شاي أحمر 100 كيس',9,null,45,'علبة',false,false,'drinks'),
('D-13','قهوة تركية 250 جرام',15,18,25,'عبوة',true,false,'drinks'),
-- مواد غذائية
('D-3','أرز بسمتي 5 كيلو',32,38,25,'كيس',false,true,'food'),('D-4','مكرونة سباغيتي 500 جرام',2.5,null,120,'عبوة',true,false,'food'),
('D-14','سكر أبيض 1 كيلو',3.5,null,80,'كيلو',false,false,'food'),('D-15','زيت دوار الشمس 1.8 لتر',18,21,35,'عبوة',false,true,'food'),
('D-16','دقيق أبيض 1 كيلو',3,null,60,'كيس',false,false,'food'),('D-17','عدس أحمر 1 كيلو',6,null,40,'كيس',false,false,'food'),
-- ألبان
('D-5','حليب طازج 1 لتر',4.5,null,60,'عبوة',true,false,'dairy'),('D-18','جبنة شرائح 200 جرام',7,8,20,'عبوة',false,false,'dairy'),
('D-19','زبادي طبيعي',1.2,null,100,'عبوة',false,false,'dairy'),('D-20','زبدة 200 جرام',6.5,null,25,'عبوة',false,false,'dairy'),
('D-21','بيض 30 حبة',18,20,30,'طبق',false,true,'dairy'),
-- منظفات
('D-6','سائل غسيل أطباق',6.5,8,30,'عبوة',false,false,'cleaning'),('D-22','مسحوق غسيل 3 كيلو',22,26,18,'كرتونة',false,true,'cleaning'),
('D-23','مناديل ورقية 10 رولات',12,null,40,'عبوة',false,false,'cleaning'),('D-24','منظف أرضيات 1 لتر',5.5,null,30,'عبوة',true,false,'cleaning'),
-- عناية شخصية
('D-7','شامبو 400 مل',14,17,22,'عبوة',false,false,'care'),('D-25','معجون أسنان',5,null,50,'قطعة',true,false,'care'),
('D-26','صابون 4 قطع',6,7,35,'عبوة',false,false,'care'),('D-27','مزيل عرق',11,null,20,'قطعة',false,false,'care'),
-- مجمدات
('D-8','بطاطس مجمدة 1 كيلو',9,11,15,'كيس',false,false,'frozen'),('D-28','خضار مشكلة مجمدة 1 كيلو',8,null,20,'كيس',false,false,'frozen'),
('D-29','بيتزا مجمدة',12,14,10,'قطعة',true,false,'frozen'),
-- معلبات
('D-9','تونة معلبة',4.5,5.5,70,'علبة',false,true,'canned'),('D-30','طماطم معجون 800 جرام',5,null,45,'علبة',false,false,'canned'),
('D-31','فول مدمس',2.5,null,60,'علبة',false,false,'canned'),('D-32','ذرة حلوة',3,null,40,'علبة',false,false,'canned'),
-- مخبوزات
('D-10','خبز تنور',1,null,90,'حبة',true,false,'bakery'),('D-33','كرواسون',1.5,2,30,'حبة',true,false,'bakery'),
('D-34','خبز توست',4,null,25,'عبوة',false,false,'bakery'),
-- خضار وفواكه
('D-35','طماطم',3,null,50,'كيلو',false,false,'produce'),('D-36','بطاطا',2.5,null,60,'كيلو',false,false,'produce'),
('D-37','موز',6,7,30,'كيلو',false,true,'produce'),('D-38','تفاح أحمر',7,null,30,'كيلو',true,false,'produce'),
('D-39','بصل',2,null,70,'كيلو',false,false,'produce'),
-- لحوم ودواجن
('D-40','دجاج كامل مجمد 1 كيلو',16,null,20,'كيلو',false,true,'meat'),('D-41','صدور دجاج 1 كيلو',22,25,15,'كيلو',false,false,'meat'),
('D-42','لحم مفروم 500 جرام',20,null,12,'عبوة',true,false,'meat'),
-- حلويات وسناكس
('D-43','شيبس 150 جرام',3,null,80,'كيس',false,false,'snacks'),('D-44','شوكولاتة بالحليب',2.5,3,90,'قطعة',false,false,'snacks'),
('D-45','بسكويت 12 قطعة',5,null,50,'علبة',true,false,'snacks'),
-- مستلزمات الأطفال
('D-46','حفاضات أطفال مقاس 4',45,52,15,'عبوة',false,true,'baby'),('D-47','مناديل مبللة للأطفال',6,null,40,'عبوة',false,false,'baby'),
-- بهارات وتوابل
('D-48','كمون مطحون 100 جرام',4,null,30,'عبوة',false,false,'spices'),('D-49','فلفل أسود 100 جرام',5,null,30,'عبوة',false,false,'spices'),
('D-50','كركم 100 جرام',3.5,null,25,'عبوة',true,false,'spices')
) v(a,b,c,d,e,f,g,h,cs) join categories c on c.slug=v.cs
on conflict(sku) do nothing;
-- لحذف التجريبي قبل الإطلاق: delete from products where is_demo;
