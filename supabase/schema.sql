-- Mangazms v2 database
-- Run this whole file once in Supabase SQL Editor.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Reader',
  avatar_url text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(id, display_name)
  values (new.id, coalesce(nullif(new.raw_user_meta_data->>'full_name',''), nullif(new.raw_user_meta_data->>'name',''), split_part(coalesce(new.email,''),'@',1), 'Reader'))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Admin',
  created_at timestamptz not null default now()
);

create or replace function public.admin_limit_guard()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform pg_advisory_xact_lock(hashtext('mangazms_admin_limit'));
  if (select count(*) from public.admin_users) >= 2 then
    raise exception 'Maximum of 2 administrators reached';
  end if;
  return new;
end;
$$;

drop trigger if exists admin_users_limit on public.admin_users;
create trigger admin_users_limit
before insert on public.admin_users
for each row execute function public.admin_limit_guard();

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(select 1 from public.admin_users where user_id = auth.uid());
$$;

create table if not exists public.works (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique default gen_random_uuid()::text,
  title text not null,
  type text not null default 'manga' check (type in ('manga','manhwa')),
  author text not null default '',
  genre text not null default '',
  description text not null default '',
  cover_url text not null default '',
  status text not null default 'published' check (status in ('draft','published')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists works_updated_at on public.works;
create trigger works_updated_at before update on public.works
for each row execute function public.set_updated_at();

create table if not exists public.genres (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.work_genres (
  work_id uuid not null references public.works(id) on delete cascade,
  genre_id uuid not null references public.genres(id) on delete cascade,
  primary key(work_id, genre_id)
);

create table if not exists public.chapters (
  id uuid primary key default gen_random_uuid(),
  work_id uuid not null references public.works(id) on delete cascade,
  number integer not null check (number > 0),
  title text not null default '',
  status text not null default 'published' check (status in ('draft','published')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(work_id, number)
);

drop trigger if exists chapters_updated_at on public.chapters;
create trigger chapters_updated_at before update on public.chapters
for each row execute function public.set_updated_at();

create table if not exists public.chapter_pages (
  id uuid primary key default gen_random_uuid(),
  chapter_id uuid not null references public.chapters(id) on delete cascade,
  page_number integer not null check (page_number > 0),
  image_url text not null,
  created_at timestamptz not null default now(),
  unique(chapter_id, page_number)
);

create table if not exists public.favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  work_id uuid not null references public.works(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(user_id, work_id)
);

create table if not exists public.reading_history (
  user_id uuid not null references auth.users(id) on delete cascade,
  work_id uuid not null references public.works(id) on delete cascade,
  chapter_id uuid references public.chapters(id) on delete set null,
  page_number integer not null default 1 check(page_number > 0),
  last_viewed_at timestamptz not null default now(),
  primary key(user_id, work_id)
);

create table if not exists public.site_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

drop trigger if exists site_settings_updated_at on public.site_settings;
create trigger site_settings_updated_at before update on public.site_settings
for each row execute function public.set_updated_at();

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  admin_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists works_status_created_idx on public.works(status, created_at desc);
create index if not exists works_type_created_idx on public.works(type, created_at desc);
create index if not exists chapters_work_number_idx on public.chapters(work_id, number desc);
create index if not exists pages_chapter_number_idx on public.chapter_pages(chapter_id, page_number);
create index if not exists history_user_date_idx on public.reading_history(user_id, last_viewed_at desc);
create index if not exists favorites_user_idx on public.favorites(user_id, created_at desc);
create index if not exists audit_created_idx on public.audit_logs(created_at desc);

alter table public.profiles enable row level security;
alter table public.admin_users enable row level security;
alter table public.works enable row level security;
alter table public.genres enable row level security;
alter table public.work_genres enable row level security;
alter table public.chapters enable row level security;
alter table public.chapter_pages enable row level security;
alter table public.favorites enable row level security;
alter table public.reading_history enable row level security;
alter table public.site_settings enable row level security;
alter table public.audit_logs enable row level security;

-- Profiles
 drop policy if exists profiles_self_select on public.profiles;
create policy profiles_self_select on public.profiles for select using (auth.uid() = id);
drop policy if exists profiles_self_update on public.profiles;
create policy profiles_self_update on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

-- Admins: users can only see their own membership; admins can see both memberships.
drop policy if exists admin_users_read on public.admin_users;
create policy admin_users_read on public.admin_users for select using (auth.uid() = user_id or public.is_admin());
drop policy if exists admin_users_insert on public.admin_users;
create policy admin_users_insert on public.admin_users for insert with check (public.is_admin());
drop policy if exists admin_users_delete on public.admin_users;
create policy admin_users_delete on public.admin_users for delete using (public.is_admin());

-- Works
drop policy if exists works_public_read on public.works;
create policy works_public_read on public.works for select using (status = 'published' or public.is_admin());
drop policy if exists works_admin_insert on public.works;
create policy works_admin_insert on public.works for insert with check (public.is_admin());
drop policy if exists works_admin_update on public.works;
create policy works_admin_update on public.works for update using (public.is_admin()) with check (public.is_admin());
drop policy if exists works_admin_delete on public.works;
create policy works_admin_delete on public.works for delete using (public.is_admin());

-- Genres
drop policy if exists genres_public_read on public.genres;
create policy genres_public_read on public.genres for select using (true);
drop policy if exists genres_admin_write on public.genres;
create policy genres_admin_write on public.genres for all using (public.is_admin()) with check (public.is_admin());

-- Work genres
drop policy if exists work_genres_public_read on public.work_genres;
create policy work_genres_public_read on public.work_genres for select using (true);
drop policy if exists work_genres_admin_write on public.work_genres;
create policy work_genres_admin_write on public.work_genres for all using (public.is_admin()) with check (public.is_admin());

-- Chapters: only published chapters of published works are public.
drop policy if exists chapters_public_read on public.chapters;
create policy chapters_public_read on public.chapters for select using (
  public.is_admin() or (status = 'published' and exists(select 1 from public.works w where w.id = work_id and w.status = 'published'))
);
drop policy if exists chapters_admin_insert on public.chapters;
create policy chapters_admin_insert on public.chapters for insert with check (public.is_admin());
drop policy if exists chapters_admin_update on public.chapters;
create policy chapters_admin_update on public.chapters for update using (public.is_admin()) with check (public.is_admin());
drop policy if exists chapters_admin_delete on public.chapters;
create policy chapters_admin_delete on public.chapters for delete using (public.is_admin());

-- Pages
drop policy if exists chapter_pages_public_read on public.chapter_pages;
create policy chapter_pages_public_read on public.chapter_pages for select using (
  public.is_admin() or exists(
    select 1 from public.chapters c join public.works w on w.id=c.work_id
    where c.id=chapter_id and c.status='published' and w.status='published'
  )
);
drop policy if exists chapter_pages_admin_insert on public.chapter_pages;
create policy chapter_pages_admin_insert on public.chapter_pages for insert with check (public.is_admin());
drop policy if exists chapter_pages_admin_update on public.chapter_pages;
create policy chapter_pages_admin_update on public.chapter_pages for update using (public.is_admin()) with check (public.is_admin());
drop policy if exists chapter_pages_admin_delete on public.chapter_pages;
create policy chapter_pages_admin_delete on public.chapter_pages for delete using (public.is_admin());

-- Favorites / history: private to each reader.
drop policy if exists favorites_self_select on public.favorites;
create policy favorites_self_select on public.favorites for select using (auth.uid()=user_id);
drop policy if exists favorites_self_insert on public.favorites;
create policy favorites_self_insert on public.favorites for insert with check (auth.uid()=user_id and not public.is_admin());
drop policy if exists favorites_self_delete on public.favorites;
create policy favorites_self_delete on public.favorites for delete using (auth.uid()=user_id and not public.is_admin());

drop policy if exists history_self_select on public.reading_history;
create policy history_self_select on public.reading_history for select using (auth.uid()=user_id);
drop policy if exists history_self_insert on public.reading_history;
create policy history_self_insert on public.reading_history for insert with check (auth.uid()=user_id and not public.is_admin());
drop policy if exists history_self_update on public.reading_history;
create policy history_self_update on public.reading_history for update using (auth.uid()=user_id and not public.is_admin()) with check (auth.uid()=user_id and not public.is_admin());
drop policy if exists history_self_delete on public.reading_history;
create policy history_self_delete on public.reading_history for delete using (auth.uid()=user_id and not public.is_admin());

-- Site settings are public-readable only if you later need them; admins write them.
drop policy if exists site_settings_public_read on public.site_settings;
create policy site_settings_public_read on public.site_settings for select using (true);
drop policy if exists site_settings_admin_write on public.site_settings;
create policy site_settings_admin_write on public.site_settings for all using (public.is_admin()) with check (public.is_admin());

-- Audit log is admin-only.
drop policy if exists audit_admin_read on public.audit_logs;
create policy audit_admin_read on public.audit_logs for select using (public.is_admin());
drop policy if exists audit_admin_insert on public.audit_logs;
create policy audit_admin_insert on public.audit_logs for insert with check (public.is_admin() and admin_user_id=auth.uid());

-- Storage bucket for covers and chapter pages.
insert into storage.buckets(id,name,public)
values('mangazms','mangazms',true)
on conflict(id) do update set public=true;

drop policy if exists mangazms_public_read on storage.objects;
create policy mangazms_public_read on storage.objects for select using (bucket_id='mangazms');
drop policy if exists mangazms_admin_insert on storage.objects;
create policy mangazms_admin_insert on storage.objects for insert with check (bucket_id='mangazms' and public.is_admin());
drop policy if exists mangazms_admin_update on storage.objects;
create policy mangazms_admin_update on storage.objects for update using (bucket_id='mangazms' and public.is_admin()) with check (bucket_id='mangazms' and public.is_admin());
drop policy if exists mangazms_admin_delete on storage.objects;
create policy mangazms_admin_delete on storage.objects for delete using (bucket_id='mangazms' and public.is_admin());

-- Helpful starter settings.
insert into public.site_settings(key,value) values
('site', '{"name":"Mangazms","language":"ar","readerBackgrounds":["dark","gray","sepia"]}'::jsonb)
on conflict(key) do nothing;

-- IMPORTANT: after creating the first user in Authentication > Users, replace the UUID below
-- and run the INSERT once. The trigger will prevent adding a third administrator.
-- insert into public.admin_users(user_id, display_name) values ('PASTE_AUTH_USER_UUID_HERE','Main Admin');
