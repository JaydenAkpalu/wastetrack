-- WasteTrack V1 — initial schema
-- Run in Supabase SQL Editor. This file is a saved record of what's
-- been run — running this file itself doesn't do anything automatically.

-- =============
-- Drivers table
-- =============
create extension if not exists pgcrypto;  -- provides gen_random_uuid()

create table if not exists public.drivers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  base_location point,                 -- lat/lng, used for V2 Voronoi assignment
  tare_weight_kg float8,               -- empty vehicle weight, reference point for drop-off classification
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now()
);

-- =============================
-- Authorized zones table
-- =============================
create table if not exists public.authorized_zones (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,           -- e.g. "Achimota Transfer Station"
  polygon jsonb not null,              -- GeoJSON polygon, [lng, lat] coordinate order
  source text,                         -- citation, e.g. "AMA notice, 2026-03-01"
  created_at timestamptz not null default now()
);

-- ===================
-- Shifts table
-- ===================
create table if not exists public.shifts (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(id) on delete restrict,
  started_at timestamptz not null,
  ended_at timestamptz,
  status text not null default 'in_progress'
    check (status in ('compliant', 'partial', 'flagged', 'in_progress')),
  flag_reason text,
  created_at timestamptz not null default now()
);

-- ===============
-- Gps_pings table
-- ===============
create table if not exists public.gps_pings (
  id uuid primary key default gen_random_uuid(),
  shift_id uuid not null references public.shifts(id) on delete cascade,
  driver_id uuid not null references public.drivers(id),  -- denormalized for faster reads, always derived from shift_id
  lat float8 not null,
  lng float8 not null,
  load_kg float8,                      -- simulated cargo weight at this ping, nullable for future real-sensor dropouts
  pinged_at timestamptz not null,      -- renamed from "timestamp" — reserved word, avoids quoting it everywhere
  zone_touched boolean,                -- nullable until the geofence check runs
  created_at timestamptz not null default now()
);

-- =========================
-- Zone_touches table
-- =========================
create table if not exists public.zone_touches (
  id uuid primary key default gen_random_uuid(),
  shift_id uuid not null references public.shifts(id) on delete cascade,      -- meaningless without its shift, so it goes when the shift does
  zone_id uuid not null references public.authorized_zones(id) on delete restrict,  -- zones are reference data — don't let deleting one erase compliance history
  entered_at timestamptz not null,
  exited_at timestamptz,                -- nullable — empty while the driver's still inside the zone
  dwell_seconds int,                    -- computed once exited_at is known
  weight_at_entry float8 not null,      -- known at the moment of entry
  weight_at_exit float8,                -- nullable — not known until exit
  weight_delta float8,                  -- weight_at_entry - weight_at_exit, computed on exit
  drop_off_classification text check (drop_off_classification in ('full', 'partial', 'none')),
  created_at timestamptz not null default now()
);

-- ============
-- RLS POLICIES
-- ============
create policy "public read drivers" on public.drivers
    for select using(true);

create policy "public read authorized_zones" on public.authorized_zones
    for select using(true);

create policy "public read shifts" on public.shifts
    for select using(true);

create policy "public read gps_pings" on public.gps_pings
    for select using(true);

create policy "public read zone_touches" on public.zone_touches
    for select using(true);


