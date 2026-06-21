-- ============================================================
-- Flowstate — Supabase Schema
-- Paste this entire file into Supabase > SQL Editor > Run
-- ============================================================

-- 1. PROFILES TABLE
--    Auto-created for every new user that signs up.
create table if not exists public.profiles (
  id                  uuid references auth.users on delete cascade primary key,
  email               text,
  full_name           text,
  plan                text default 'free',           -- 'free' | 'signals' | 'auto_pro' | 'elite'
  subscription_status text default 'inactive',       -- 'active' | 'inactive' | 'trialing'
  subscription_end    timestamptz,
  created_at          timestamptz default now()
);

-- 2. TRADES TABLE
--    One row per trade taken. lockout_until enforces the daily lock.
create table if not exists public.trades (
  id             uuid default gen_random_uuid() primary key,
  user_id        uuid references public.profiles(id) on delete cascade not null,
  instrument     text not null,                      -- 'NQ' | 'ES' | 'GOLD'
  direction      text not null,                      -- 'LONG' | 'SHORT'
  model_name     text,
  entry          text,
  sl             text,
  tp             text,
  result         text default 'pending',             -- 'pending' | 'win' | 'loss'
  pnl_gbp        numeric,
  r_multiple     numeric,
  lockout_until  timestamptz not null,
  taken_at       timestamptz default now(),
  closed_at      timestamptz
);

-- 3. ROW LEVEL SECURITY
--    Users can only see and write their own data. You (admin) can see all.
alter table public.profiles enable row level security;
alter table public.trades   enable row level security;

create policy "Users can read own profile"
  on public.profiles for select using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id);

create policy "Users can read own trades"
  on public.trades for select using (auth.uid() = user_id);

create policy "Users can insert own trades"
  on public.trades for insert with check (auth.uid() = user_id);

-- 4. AUTO-CREATE PROFILE ON SIGNUP
--    Whenever a new user signs up, this trigger creates their profile row.
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================================
-- DONE. You can now view users in: Table Editor > profiles
-- View trades in:                  Table Editor > trades
-- Manage users in:                 Authentication > Users
-- ============================================================
