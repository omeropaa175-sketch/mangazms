# Mangazms — النسخة النهائية

نسخة Vercel + Supabase بدون build step، ومصممة لتجنب مشكلة `This page doesn't exist`:

- `index.html` في جذر المشروع مباشرة.
- `admin.html` في جذر المشروع مباشرة.
- `api/config.js` في جذر المشروع، ويقرأ مفاتيح Supabase من Vercel Environment Variables.
- لا يوجد `public/` مطلوب ولا `build.js`.
- تصميم متجاوب للجوال والكمبيوتر.
- مفضلة + آخر مشاهدة للمستخدمين.
- Google / Apple / Email عبر Supabase Auth.
- قارئ فصول مع تكبير وتصغير وتغيير لون الشاشة داخل القارئ فقط.
- لوحة إداريين مع حد أقصى إداريين اثنين.
- رفع أغلفة وفصول وصفحات إلى Supabase Storage.
- RLS وفهارس وقواعد بيانات منظمة.

## 1) رفع الملفات إلى GitHub

يجب أن يكون شكل الجذر هكذا بالضبط:

```text
Mangazms/
├─ index.html
├─ admin.html
├─ api/
│  └─ config.js
├─ assets/
│  └─ style.css
├─ supabase/
│  └─ schema.sql
└─ vercel.json
```

لا تضع مجلد `Mangazms` داخل مجلد `Mangazms` آخر.

## 2) إعداد Supabase

افتح Supabase > SQL Editor، والصق كامل الملف:

`supabase/schema.sql`

ثم نفّذه مرة واحدة.

القاعدة تنشئ:

- `profiles`
- `admin_users`
- `works`
- `genres`
- `work_genres`
- `chapters`
- `chapter_pages`
- `favorites`
- `reading_history`
- `site_settings`
- `audit_logs`
- Storage bucket باسم `mangazms`

## 3) إنشاء أول إداري

1. افتح Supabase > Authentication > Users.
2. أنشئ مستخدمًا بالبريد وكلمة المرور.
3. انسخ UUID الخاص بالمستخدم.
4. في SQL Editor نفّذ:

```sql
insert into public.admin_users(user_id, display_name)
values ('ضع-UUID-هنا', 'Main Admin');
```

مسموح بإداريين اثنين فقط. لا تضع كلمة المرور في GitHub أو في ملفات الموقع.

## 4) Vercel Environment Variables

في Vercel > Project > Settings > Environment Variables أضف:

```text
SUPABASE_URL=https://YOUR-PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_OR_PUBLISHABLE_KEY
```

فعّلها على **Production**، ويفضل أيضًا Preview وDevelopment إذا كنت تستخدمهما.

بعد الحفظ اعمل **Redeploy**.

> المفتاح المستخدم في الموقع هو المفتاح العام (anon/publishable)، وليس Service Role Key.

## 5) إعداد Google وApple

من Supabase > Authentication > Providers فعّل Google وApple إذا أردت تسجيل الدخول بهما.

أضف رابط الموقع المنشور في Redirect URLs، مثل:

```text
https://mangazms.vercel.app
```

وإذا أضفت دومينًا لاحقًا، أضف الدومين الجديد أيضًا.

## 6) فتح الموقع

الموقع:

`https://YOUR-VERCEL-DOMAIN/`

لوحة الإدارة:

`https://YOUR-VERCEL-DOMAIN/admin`

ويمكن أيضًا:

`https://YOUR-VERCEL-DOMAIN/admin.html`

## 7) إذا ظهر This page doesn't exist

تأكد أن **Root Directory** في Vercel هو مكان وجود `index.html` و`api/` و`vercel.json`.

إذا كانت الملفات في جذر GitHub، اجعل Root Directory:

```text
.
```

ثم Redeploy.

## 8) إذا ظهر خطأ Supabase

لا ترسل كلمات المرور أو Service Role Key.

افحص فقط:

- اسم المتغير `SUPABASE_URL`
- اسم المتغير `SUPABASE_ANON_KEY`
- Production مفعّل
- تم عمل Redeploy بعد تعديل المتغيرات
- افتح `https://YOUR-VERCEL-DOMAIN/api/config` للتأكد أن endpoint موجود. لا تشارك محتوى المفتاح في أي مكان عام.
