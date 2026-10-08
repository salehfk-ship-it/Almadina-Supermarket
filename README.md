# سوبر ماركت المدينة — دليل التشغيل الكامل

مجلد جاهز للرفع على GitHub ثم النشر التلقائي على Netlify (أو Vercel). لا يحتاج بناء ولا أوامر.

## الترتيب الصحيح (مهم)
1. **أنشئ مشروع Supabase** من supabase.com (اختر منطقة قريبة).
2. **أنشئ حساب المدير أولاً:** Authentication ← Users ← Add user ← Create new user. اكتب البريد وكلمة مرور قوية، وفعّل **Auto Confirm User**.
3. **شغّل قاعدة البيانات:** افتح SQL Editor، وافتح ملف `setup.sql`، وتأكد أن البريد في آخر سطرين هو بريد المدير نفسه، والصق الملف كاملاً واضغط Run. النتيجة الأخيرة يجب أن تظهر `عدد_المديرين = 1`. الملف آمن لإعادة التشغيل متى شئت.
4. **انسخ مفاتيح الربط:** Project Settings ← API. انسخ Project URL ومفتاح `anon public` (وليس `service_role` أبداً).
5. **عدّل `config.js`** وضع القيمتين بين علامتي الاقتباس (يمكنك تعديله من موقع GitHub مباشرة).
6. **GitHub:** أنشئ Repository جديداً وارفع كل ملفات هذا المجلد (Add file ← Upload files).
7. **Netlify:** Add new site ← Import from Git ← اختر المستودع. اترك Build command فاضياً وPublish directory = `.` ثم Deploy. أي تعديل لاحق على GitHub ينشر نفسه.
   (إن استخدمت Vercel: أطفئ Deployment Protection من Settings، وإلا سيرى الزبائن صفحة دخول Vercel.)

## الفحص
افتح `رابط-موقعك/check.html` وسجّل بريد المدير وكلمة المرور واضغط ابدأ. تظهر لك ✅ أو ❌ مع سبب كل مشكلة. بعد النجاح يمكنك حذف الملف.

## بعد التشغيل
- من "دخول الإدارة" أسفل الصفحة: الإعدادات ← ضع رقم واتساب بصيغة 218912345678، ورسوم التوصيل، وبيانات التواصل.
- أدخل منتجاتك (إضافة سريعة أو استيراد CSV) ثم احذف التجريبية من SQL Editor: `delete from products where is_demo;`
- الصور: من لوحة المنتجات اختر صورة لكل منتج (تُرفع إلى Storage).
- الأمان: من Authentication ← Sign In / Providers ← Email أطفئ التسجيل العام (Allow new users to sign up) إن لم تحتجه.
- الدومين: من إعدادات الموقع في Netlify ← Domain management.

## إضافة مدير آخر
أنشئ مستخدماً من Authentication ثم شغّل: `insert into admins(user_id) select id from auth.users where email='البريد';`
