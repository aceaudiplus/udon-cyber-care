-- Udon Cyber Care Professional V2
-- Run this entire script in Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role text not null default 'technician' check (role in ('owner','technician')),
  created_at timestamptz not null default now()
);
create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text not null,
  email text,
  address text,
  customer_type text not null default 'บุคคลทั่วไป',
  note text,
  created_by uuid default auth.uid() references auth.users(id),
  created_at timestamptz not null default now()
);
create table if not exists public.repairs (
  id uuid primary key default gen_random_uuid(),
  ticket_no text not null unique,
  customer_id uuid not null references public.customers(id),
  received_at date not null default current_date,
  brand text, model text, serial_no text, accessories text,
  issue text not null, condition_note text,
  status text not null default 'รับเครื่องแล้ว' check(status in ('รับเครื่องแล้ว','กำลังตรวจสอบ','รออนุมัติราคา','รออะไหล่','กำลังซ่อม','รอรับเครื่อง','ส่งมอบแล้ว','ยกเลิก')),
  estimate numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0,
  paid numeric(12,2) not null default 0,
  technician_id uuid references auth.users(id),
  work_note text,
  created_by uuid default auth.uid() references auth.users(id),
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
create table if not exists public.parts (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  compatible_models text,
  qty integer not null default 0 check(qty >= 0),
  min_qty integer not null default 1 check(min_qty >= 0),
  cost numeric(12,2) not null default 0,
  sale_price numeric(12,2) not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists public.repair_parts (
  id uuid primary key default gen_random_uuid(),
  repair_id uuid not null references public.repairs(id) on delete cascade,
  part_id uuid not null references public.parts(id),
  qty integer not null check(qty > 0),
  unit_price numeric(12,2) not null default 0
);
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  repair_id uuid not null references public.repairs(id) on delete cascade,
  amount numeric(12,2) not null check(amount > 0),
  method text not null default 'เงินสด',
  reference text,
  paid_at timestamptz not null default now(),
  received_by uuid default auth.uid() references auth.users(id)
);

create or replace function public.current_user_role()
returns text language sql stable security definer set search_path = public
as $$ select role from public.profiles where id = auth.uid() $$;
create or replace function public.is_owner()
returns boolean language sql stable security definer set search_path = public
as $$ select coalesce(public.current_user_role() = 'owner', false) $$;

-- New signups are technicians by default. Promote the shop owner manually below.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$ begin
  insert into public.profiles(id,full_name,role)
  values(new.id, coalesce(new.raw_user_meta_data->>'full_name',''), 'technician')
  on conflict (id) do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.customers enable row level security;
alter table public.repairs enable row level security;
alter table public.parts enable row level security;
alter table public.repair_parts enable row level security;
alter table public.payments enable row level security;

-- Profiles: users can read own profile; owner can manage all profile rows.
drop policy if exists "profile self read" on public.profiles;
create policy "profile self read" on public.profiles for select to authenticated using(id=auth.uid() or public.is_owner());
drop policy if exists "owner update profiles" on public.profiles;
create policy "owner update profiles" on public.profiles for update to authenticated using(public.is_owner()) with check(public.is_owner());

-- Authenticated staff can read/write customer and repair records.
do $$ declare t text; begin
 foreach t in array array['customers','repairs'] loop
  execute format('drop policy if exists %I on public.%I','staff select',t);
  execute format('create policy %I on public.%I for select to authenticated using (true)','staff select',t);
  execute format('drop policy if exists %I on public.%I','staff insert',t);
  execute format('create policy %I on public.%I for insert to authenticated with check (true)','staff insert',t);
  execute format('drop policy if exists %I on public.%I','staff update',t);
  execute format('create policy %I on public.%I for update to authenticated using (true) with check (true)','staff update',t);
 end loop;
end $$;
-- Delete is owner-only.
drop policy if exists "owner delete customers" on public.customers;
create policy "owner delete customers" on public.customers for delete to authenticated using(public.is_owner());
drop policy if exists "owner delete repairs" on public.repairs;
create policy "owner delete repairs" on public.repairs for delete to authenticated using(public.is_owner());

-- Inventory, payments and part consumption are owner-controlled in this initial release.
drop policy if exists "owner all parts" on public.parts;
create policy "owner all parts" on public.parts for all to authenticated using(public.is_owner()) with check(public.is_owner());
drop policy if exists "staff read parts" on public.parts;
create policy "staff read parts" on public.parts for select to authenticated using(true);
drop policy if exists "owner all repair_parts" on public.repair_parts;
create policy "owner all repair_parts" on public.repair_parts for all to authenticated using(public.is_owner()) with check(public.is_owner());
drop policy if exists "owner all payments" on public.payments;
create policy "owner all payments" on public.payments for all to authenticated using(public.is_owner()) with check(public.is_owner());
drop policy if exists "staff read payments" on public.payments;
create policy "staff read payments" on public.payments for select to authenticated using(true);

-- Create the first user in Authentication > Users, then promote their UUID:
-- update public.profiles set role='owner', full_name='ชื่อเจ้าของร้าน' where id='AUTH-USER-UUID';
-- Add staff from Authentication > Users; their role defaults to technician.
