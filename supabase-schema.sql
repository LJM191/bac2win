-- Bac2Win / Back2Win - Supabase schema
-- À exécuter dans Supabase SQL Editor si la base doit être reconstruite.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  pseudo text default 'Utilisateur',
  avatar text default '🎓',
  school_level text default 'premiere' check (school_level in ('premiere','terminale')),
  profile_photo text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.user_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz default now()
);

create table if not exists public.leaderboard (
  user_id uuid primary key references auth.users(id) on delete cascade,
  pseudo text default 'Élève',
  avatar text default '🎓',
  profile_photo text,
  school_level text default 'premiere' check (school_level in ('premiere','terminale')),
  points integer not null default 0,
  answered integer not null default 0,
  correct integer not null default 0,
  pct integer not null default 0,
  sessions integer not null default 0,
  streak integer not null default 0,
  updated_at timestamptz default now()
);

create table if not exists public.legacy_netlify_data (
  email text primary key,
  legacy_user_id text,
  pseudo text,
  avatar text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz,
  updated_at timestamptz,
  imported_at timestamptz default now()
);

create index if not exists leaderboard_points_idx on public.leaderboard(points desc, pct desc, answered desc);

alter table public.profiles enable row level security;
alter table public.user_data enable row level security;
alter table public.leaderboard enable row level security;
alter table public.legacy_netlify_data enable row level security;

drop policy if exists "profiles own select" on public.profiles;
drop policy if exists "profiles own insert" on public.profiles;
drop policy if exists "profiles own update" on public.profiles;
drop policy if exists "user_data own select" on public.user_data;
drop policy if exists "user_data own insert" on public.user_data;
drop policy if exists "user_data own update" on public.user_data;
drop policy if exists "leaderboard public read" on public.leaderboard;
drop policy if exists "leaderboard own insert" on public.leaderboard;
drop policy if exists "leaderboard own update" on public.leaderboard;
drop policy if exists "legacy own email select" on public.legacy_netlify_data;

create policy "profiles own select" on public.profiles for select to authenticated using (auth.uid() = user_id);
create policy "profiles own insert" on public.profiles for insert to authenticated with check (auth.uid() = user_id);
create policy "profiles own update" on public.profiles for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "user_data own select" on public.user_data for select to authenticated using (auth.uid() = user_id);
create policy "user_data own insert" on public.user_data for insert to authenticated with check (auth.uid() = user_id);
create policy "user_data own update" on public.user_data for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "leaderboard public read" on public.leaderboard for select to anon, authenticated using (true);
create policy "leaderboard own insert" on public.leaderboard for insert to authenticated with check (auth.uid() = user_id);
create policy "leaderboard own update" on public.leaderboard for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "legacy own email select" on public.legacy_netlify_data
for select to authenticated
using (lower(email) = lower(coalesce(auth.jwt()->>'email','')));

grant usage on schema public to anon, authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update on public.user_data to authenticated;
grant select on public.leaderboard to anon;
grant select, insert, update on public.leaderboard to authenticated;
grant select on public.legacy_netlify_data to authenticated;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at before update on public.profiles for each row execute function public.touch_updated_at();

drop trigger if exists trg_user_data_updated_at on public.user_data;
create trigger trg_user_data_updated_at before update on public.user_data for each row execute function public.touch_updated_at();

drop trigger if exists trg_leaderboard_updated_at on public.leaderboard;
create trigger trg_leaderboard_updated_at before update on public.leaderboard for each row execute function public.touch_updated_at();
