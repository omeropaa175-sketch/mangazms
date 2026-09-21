# Mangazms — نسخة قابلة للنشر

## التقنية
- Frontend: HTML/CSS/JavaScript
- Database + Auth + Storage: Supabase
- Hosting: Vercel
- لا يوجد حسابات للمستخدمين؛ الحسابات الإدارية فقط.

## 1) إنشاء مشروع Supabase
1. أنشئ مشروعًا جديدًا في Supabase.
2. افتح SQL Editor.
3. انسخ محتوى `supabase/schema.sql` وشغّله كاملًا.
4. من Authentication > Users أنشئ حساب البريد الإلكتروني/كلمة المرور للإداري الأول.
5. انسخ User ID الخاص بالحساب.
6. من SQL Editor نفّذ:
   `insert into public.admins (user_id, display_name) values ('USER_UUID_HERE', 'zaid momani');`
7. لإضافة الإداري الثاني، أنشئ User جديدًا في Authentication ثم أضفه إلى `public.admins`.
8. النظام يمنع أكثر من إداريين اثنين من جدول الإداريين.

> لا تضع كلمة مرور الإداري داخل GitHub أو داخل JavaScript.

## 2) ربط الموقع
افتح `public/index.html` واستبدل:
- `%%SUPABASE_URL%%`
- `%%SUPABASE_ANON_KEY%%`

بقيم مشروع Supabase من Settings > API.

مفتاح `anon/publishable` مناسب للواجهة مع RLS. لا تستخدم `service_role` في المتصفح.

## 3) النشر على Vercel
- ارفع المجلد إلى GitHub.
- في Vercel اختر Import Project.
- اجعل Root Directory هو المشروع.
- لأن الموقع static لا يحتاج Build Command.
- Publish Directory: `public`.
- Deploy.

## 4) ملاحظات الأمان
- الرفع محمي بـ Supabase Auth + RLS، وليس PIN داخل HTML.
- الصور تذهب إلى Storage bucket اسمه `mangazms`.
- القراءة عامة، أما الرفع والتعديل والحذف فتتطلب حسابًا موجودًا في `public.admins`.
- حد الإداريين اثنان enforced داخل قاعدة البيانات.
- لا تحفظ كلمة المرور في الكود أو GitHub.

## 5) المحتوى
استخدم فقط محتوى تملك حقوق نشره أو لديك ترخيص لنشره.
