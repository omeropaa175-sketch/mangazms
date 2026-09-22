create extension if not exists pgcrypto;

create table if not exists public.admins(
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Admin',
  created_at timestamptz not null default now()
);
create or replace function public.admin_count_guard() returns trigger language plpgsql security definer set search_path=public as $$
begin if (select count(*) from public.admins)>=2 then raise exception 'Maximum of 2 admins reached'; end if; return new; end; $$;
drop trigger if exists admins_limit on public.admins;
create trigger admins_limit before insert on public.admins for each row execute function public.admin_count_guard();
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$
select exists(select 1 from public.admins where user_id=auth.uid()); $$;

create table if not exists public.mangas(
 id uuid primary key default gen_random_uuid(), title text not null, type text not null default 'manga' check(type in('manga','manhwa')),
 author text default '', genre text default '', description text default '', cover_url text default '', created_at timestamptz not null default now()
);
create table if not exists public.chapters(
 id uuid primary key default gen_random_uuid(), manga_id uuid not null references public.mangas(id) on delete cascade,
 number integer not null check(number>0), title text default '', created_at timestamptz not null default now(), unique(manga_id,number)
);
create table if not exists public.chapter_pages(
 id uuid primary key default gen_random_uuid(), chapter_id uuid not null references public.chapters(id) on delete cascade,
 page_number integer not null check(page_number>0), image_url text not null, created_at timestamptz not null default now(), unique(chapter_id,page_number)
);

create table if not exists public.user_favorites(
 user_id uuid not null references auth.users(id) on delete cascade,
 manga_id uuid not null references public.mangas(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key(user_id,manga_id)
);
create table if not exists public.user_history(
 user_id uuid not null references auth.users(id) on delete cascade,
 manga_id uuid not null references public.mangas(id) on delete cascade,
 last_viewed_at timestamptz not null default now(),
 primary key(user_id,manga_id)
);

alter table public.admins enable row level security;
alter table public.mangas enable row level security;
alter table public.chapters enable row level security;
alter table public.chapter_pages enable row level security;
alter table public.user_favorites enable row level security;
alter table public.user_history enable row level security;

drop policy if exists admins_self_read on public.admins;
create policy admins_self_read on public.admins for select using(auth.uid()=user_id or public.is_admin());
drop policy if exists mangas_public_read on public.mangas; create policy mangas_public_read on public.mangas for select using(true);
drop policy if exists mangas_admin_insert on public.mangas; create policy mangas_admin_insert on public.mangas for insert with check(public.is_admin());
drop policy if exists mangas_admin_update on public.mangas; create policy mangas_admin_update on public.mangas for update using(public.is_admin()) with check(public.is_admin());
drop policy if exists mangas_admin_delete on public.mangas; create policy mangas_admin_delete on public.mangas for delete using(public.is_admin());
drop policy if exists chapters_public_read on public.chapters; create policy chapters_public_read on public.chapters for select using(true);
drop policy if exists chapters_admin_insert on public.chapters; create policy chapters_admin_insert on public.chapters for insert with check(public.is_admin());
drop policy if exists chapters_admin_update on public.chapters; create policy chapters_admin_update on public.chapters for update using(public.is_admin()) with check(public.is_admin());
drop policy if exists chapters_admin_delete on public.chapters; create policy chapters_admin_delete on public.chapters for delete using(public.is_admin());
drop policy if exists pages_public_read on public.chapter_pages; create policy pages_public_read on public.chapter_pages for select using(true);
drop policy if exists pages_admin_insert on public.chapter_pages; create policy pages_admin_insert on public.chapter_pages for insert with check(public.is_admin());
drop policy if exists pages_admin_delete on public.chapter_pages; create policy pages_admin_delete on public.chapter_pages for delete using(public.is_admin());

drop policy if exists favorites_self_select on public.user_favorites; create policy favorites_self_select on public.user_favorites for select using(auth.uid()=user_id);
drop policy if exists favorites_self_insert on public.user_favorites; create policy favorites_self_insert on public.user_favorites for insert with check(auth.uid()=user_id and not public.is_admin());
drop policy if exists favorites_self_delete on public.user_favorites; create policy favorites_self_delete on public.user_favorites for delete using(auth.uid()=user_id and not public.is_admin());
drop policy if exists history_self_select on public.user_history; create policy history_self_select on public.user_history for select using(auth.uid()=user_id);
drop policy if exists history_self_insert on public.user_history; create policy history_self_insert on public.user_history for insert with check(auth.uid()=user_id and not public.is_admin());
drop policy if exists history_self_update on public.user_history; create policy history_self_update on public.user_history for update using(auth.uid()=user_id and not public.is_admin()) with check(auth.uid()=user_id and not public.is_admin());
drop policy if exists history_self_delete on public.user_history; create policy history_self_delete on public.user_history for delete using(auth.uid()=user_id and not public.is_admin());

insert into storage.buckets(id,name,public) values('mangazms','mangazms',true) on conflict(id) do nothing;
drop policy if exists storage_public_read on storage.objects; create policy storage_public_read on storage.objects for select using(bucket_id='mangazms');
drop policy if exists storage_admin_insert on storage.objects; create policy storage_admin_insert on storage.objects for insert with check(bucket_id='mangazms' and public.is_admin());
drop policy if exists storage_admin_update on storage.objects; create policy storage_admin_update on storage.objects for update using(bucket_id='mangazms' and public.is_admin()) with check(bucket_id='mangazms' and public.is_admin());
drop policy if exists storage_admin_delete on storage.objects; create policy storage_admin_delete on storage.objects for delete using(bucket_id='mangazms' and public.is_admin());
