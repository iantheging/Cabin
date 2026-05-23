-- ============================================================
--  MACKINAW COTTAGE — Supabase Database Setup
--  Run this entire file in: Supabase Dashboard → SQL Editor
-- ============================================================

-- 1. USERS TABLE
create table if not exists users (
  id          bigint primary key generated always as identity,
  username    text not null unique,
  password    text not null,
  is_admin    boolean not null default false,
  created_at  timestamptz default now()
);

-- 2. BOOKINGS TABLE
create table if not exists bookings (
  id          bigint primary key generated always as identity,
  username    text not null,
  start_date  date not null,
  end_date    date not null,
  created_at  timestamptz default now()
);

-- 3. REQUESTS TABLE (date-change requests)
create table if not exists requests (
  id              bigint primary key generated always as identity,
  booking_id      bigint references bookings(id) on delete cascade,
  from_user       text not null,
  to_user         text not null,
  proposed_start  date not null,
  proposed_end    date not null,
  message         text not null,
  reply_message   text,
  status          text not null default 'pending', -- pending | accepted | declined
  created_at      timestamptz default now()
);

-- 4. DISABLE Row Level Security (simple family app — all users share access)
--    If you want stricter security later, enable RLS and add policies.
alter table users    disable row level security;
alter table bookings disable row level security;
alter table requests disable row level security;

-- 5. ALLOW public (anon key) access via Supabase API
grant select, insert, update, delete on users    to anon;
grant select, insert, update, delete on bookings to anon;
grant select, insert, update, delete on requests to anon;

-- Grant sequence usage so inserts with generated IDs work
grant usage, select on all sequences in schema public to anon;

-- 6. CREATE DEFAULT ADMIN ACCOUNT
--    Username: Admin   Password: cottage2024
--    ⚠️  Change this password immediately after first login!
insert into users (username, password, is_admin)
values ('Admin', 'cottage2024', true)
on conflict (username) do nothing;

-- ============================================================
--  DONE! You can now open the app and sign in as:
--  Username: Admin    Password: cottage2024
-- ============================================================
