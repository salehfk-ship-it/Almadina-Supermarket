# نشر موقع سوبر ماركت المدينة

## 1) قاعدة البيانات (Supabase، مجاني)
1. أنشئ حساباً وأنشئ Project جديداً على supabase.com.
2. من SQL Editor شغّل بالترتيب: `supabase-schema.sql` ثم `upgrade.sql` ثم `seed-demo.sql`.
3. من Authentication > Users أضف مستخدماً (بريد وكلمة مرور قوية) وانسخ UUID الخاص به.
4. شغّل في SQL Editor: `insert into admins(user_id) values('UUID هنا');`
5. من Settings > API انسخ Project URL ومفتاح anon public.
6. افتح `config.js` وضعهما في SUPABASE_URL و SUPABASE_ANON_KEY.

## 2) النشر
- أسهل طريقة: ادخل app.netlify.com/drop واسحب هذا المجلد كاملاً، فتحصل على رابط عام.
- لربط دومين: من إعدادات الموقع في Netlify اختر Domain management.

## 3) قبل الإطلاق
- ادخل من رابط "دخول الإدارة" أسفل الصفحة بالبريد وكلمة المرور، ثم ضع رقم واتساب (بصيغة 218912345678) من الإعدادات.
- احذف المنتجات التجريبية: `delete from products where is_demo;` وأدخل المنتجات الحقيقية أو استورد CSV.
- صور المنتجات: ارفعها في Storage > product-images وضع رابط الصورة في عمود image_url في جدول products.
- اطلب طلباً تجريبياً كاملاً وتأكد أنه يظهر في الإدارة وأن المخزون ينقص.
