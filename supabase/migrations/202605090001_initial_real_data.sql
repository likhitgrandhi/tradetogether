create extension if not exists pgcrypto;

create table if not exists public.app_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  handle text not null unique,
  display_name text not null,
  bio text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.snaptrade_users (
  seek_user_id uuid primary key references auth.users(id) on delete cascade,
  snaptrade_user_id text not null unique,
  encrypted_user_secret text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.brokerage_connections (
  id uuid primary key default gen_random_uuid(),
  seek_user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null default 'snaptrade',
  provider_connection_id text not null,
  brokerage_slug text,
  brokerage_name text,
  connection_type text not null default 'read',
  disabled boolean not null default false,
  disabled_at timestamptz,
  raw jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider, provider_connection_id)
);

create table if not exists public.brokerage_accounts (
  id uuid primary key default gen_random_uuid(),
  seek_user_id uuid not null references auth.users(id) on delete cascade,
  brokerage_connection_id uuid not null references public.brokerage_connections(id) on delete cascade,
  provider text not null default 'snaptrade',
  provider_account_id text not null,
  account_name text,
  account_number_mask text,
  account_type text,
  currency_code text,
  sync_status jsonb not null default '{}'::jsonb,
  raw jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider, provider_account_id)
);

create table if not exists public.instruments (
  id uuid primary key default gen_random_uuid(),
  provider text,
  provider_symbol_id text,
  symbol text not null,
  raw_symbol text,
  name text,
  asset_class text not null,
  exchange_code text,
  currency_code text,
  polygon_ticker text,
  option_type text,
  strike_price numeric,
  expiration_date date,
  underlying_instrument_id uuid references public.instruments(id),
  raw jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider, provider_symbol_id)
);

create table if not exists public.verified_trade_candidates (
  id uuid primary key default gen_random_uuid(),
  seek_user_id uuid not null references auth.users(id) on delete cascade,
  brokerage_account_id uuid not null references public.brokerage_accounts(id) on delete cascade,
  instrument_id uuid references public.instruments(id),
  provider text not null default 'snaptrade',
  provider_source_type text not null,
  provider_source_id text not null,
  side text not null,
  status text not null,
  quantity numeric,
  entry_price numeric,
  exit_price numeric,
  mark_price numeric,
  realized_pnl numeric,
  unrealized_pnl numeric,
  return_percent numeric,
  opened_at timestamptz,
  closed_at timestamptz,
  raw jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider, provider_source_type, provider_source_id)
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete cascade,
  verified_trade_candidate_id uuid references public.verified_trade_candidates(id),
  source text not null default 'manual',
  body text not null,
  visibility text not null default 'public',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint posts_verified_source_requires_candidate check (
    source <> 'verified_snaptrade' or verified_trade_candidate_id is not null
  )
);

create table if not exists public.snaptrade_webhook_events (
  id uuid primary key default gen_random_uuid(),
  event_type text,
  provider_event_id text,
  payload jsonb not null,
  processed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (provider_event_id)
);

create table if not exists public.sync_jobs (
  id uuid primary key default gen_random_uuid(),
  seek_user_id uuid references auth.users(id) on delete cascade,
  job_type text not null,
  status text not null default 'queued',
  payload jsonb not null default '{}'::jsonb,
  error_message text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.app_profiles enable row level security;
alter table public.snaptrade_users enable row level security;
alter table public.brokerage_connections enable row level security;
alter table public.brokerage_accounts enable row level security;
alter table public.instruments enable row level security;
alter table public.verified_trade_candidates enable row level security;
alter table public.posts enable row level security;
alter table public.snaptrade_webhook_events enable row level security;
alter table public.sync_jobs enable row level security;

create policy "profiles are readable" on public.app_profiles
  for select using (true);

create policy "users can update own profile" on public.app_profiles
  for update using (auth.uid() = id);

create policy "users can insert own profile" on public.app_profiles
  for insert with check (auth.uid() = id);

create policy "users can read own connections" on public.brokerage_connections
  for select using (auth.uid() = seek_user_id);

create policy "users can read own accounts" on public.brokerage_accounts
  for select using (auth.uid() = seek_user_id);

create policy "instruments are readable" on public.instruments
  for select using (true);

create policy "users can read own verified candidates" on public.verified_trade_candidates
  for select using (auth.uid() = seek_user_id);

create policy "public posts are readable" on public.posts
  for select using (visibility = 'public' or auth.uid() = author_id);

create policy "users can insert own posts" on public.posts
  for insert with check (auth.uid() = author_id);

create policy "users can read own sync jobs" on public.sync_jobs
  for select using (auth.uid() = seek_user_id);

create index if not exists brokerage_connections_seek_user_idx
  on public.brokerage_connections(seek_user_id);

create index if not exists brokerage_accounts_seek_user_idx
  on public.brokerage_accounts(seek_user_id);

create index if not exists verified_trade_candidates_seek_user_idx
  on public.verified_trade_candidates(seek_user_id, created_at desc);

create index if not exists posts_feed_idx
  on public.posts(visibility, created_at desc);

create index if not exists sync_jobs_user_status_idx
  on public.sync_jobs(seek_user_id, status, created_at desc);
