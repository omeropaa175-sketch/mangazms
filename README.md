# Mangazms — Final

نسخة static جاهزة لـ GitHub + Vercel مع Supabase.

## المزايا
- الرئيسية، كل الأعمال، المانجا، المانهوا، الأحدث، آخر مشاهدة، المفضلة، البحث.
- حسابات زوار عبر Google أو البريد الإلكتروني/كلمة المرور أو Apple.
- حساب الزائر مخصص للمفضلة وآخر المشاهدات فقط.
- لوحة إدارة منفصلة للإداريين فقط.
- Supabase Database + Auth + Storage + RLS.
- حد أقصى إداريان.
- قارئ فصول بإعدادات داخل القارئ فقط: تكبير، تصغير، وتغيير الخلفية.

## Supabase
1. أنشئ مشروع Supabase.
2. افتح SQL Editor وشغّل `supabase/schema.sql` بالكامل.
3. من Authentication > Users أنشئ حساب الإداري الأول بالبريد وكلمة المرور.
4. انسخ UUID للمستخدم ثم نفّذ:
   `insert into public.admins (user_id, display_name) values ('UUID_HERE','Admin 1');`
5. يمكن إضافة إداري ثانٍ بالطريقة نفسها. القاعدة تمنع الإداري الثالث.
6. في Authentication > Providers فعّل Google وApple إذا أردت تسجيل الدخول بهما، وأدخل بيانات OAuth التي يطلبها Supabase.
7. في `public/index.html` و`public/admin.html` استبدل `%%SUPABASE_URL%%` و`%%SUPABASE_ANON_KEY%%` بقيم المشروع.
8. ارفع المشروع إلى GitHub ثم استورده في Vercel. اجعل Publish Directory هو `public` إذا طلبه Vercel.
9. لوحة الإدارة: `/admin.html`.

## دخول الإدارة
الإدارة لا تستخدم Google/Apple. أنشئ حساب الإدارة من Supabase Authentication > Users، ثم أضف UUID إلى جدول `public.admins`. بعدها افتح `/admin.html` وسجّل بالبريد وكلمة المرور.

لا تضع `service_role` أو كلمات المرور داخل GitHub.

استخدم فقط محتوى لديك حق نشره أو ترخيص لنشره.
