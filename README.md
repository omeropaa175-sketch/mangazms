# Mangazms

## Vercel setup
Add these Environment Variables to Vercel for Production, Preview and Development:
- `SUPABASE_URL` = your Supabase Project URL
- `SUPABASE_ANON_KEY` = your Supabase Publishable/anon key

The Vercel build generates `public/config.js` from these variables, so the Supabase URL/key do not need to be committed to GitHub. Never use `service_role` in the browser.

## Supabase
Run `supabase/schema.sql` in SQL Editor. Create the admin user in Authentication, then insert its UUID into `public.admins`.

## Deploy
Push to GitHub and let Vercel redeploy. The build command is `npm run build` and output directory is `public`.
