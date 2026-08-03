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


-- =====================
-- Realtime on gps_pings
-- =====================
alter publication supabase_realtime add table gps_pings;

-- ===========================
-- Seed authorized_zones table
-- ===========================
insert into public.authorized_zones (name, polygon, source) values

(
  'Achimota Transfer Station (ZoomPak)',
  '{
    "type": "Polygon",
    "coordinates": [[
      [-0.2292027, 5.6217017],
      [-0.2273973, 5.6217017],
      [-0.2273973, 5.6234983],
      [-0.2292027, 5.6234983],
      [-0.2292027, 5.6217017]
    ]]
  }'::jsonb,
  'Zoomlion "ZoomPak" transfer station behind the New Achimota Lorry Station, opened 2017 (MyJoyOnline). Reconfirmed as one of six transfer stations reopened for tricycle drop-off under Presidential directive, 11 Jul 2026 (GBC Ghana Online). Coordinates from mapped facility location.'
),

(
  'Teshie Transfer Station',
  '{
    "type": "Polygon",
    "coordinates": [[
      [-0.1055026, 5.5823017],
      [-0.1036974, 5.5823017],
      [-0.1036974, 5.5840983],
      [-0.1055026, 5.5840983],
      [-0.1055026, 5.5823017]
    ]]
  }'::jsonb,
  'Zoomlion''s first waste transfer station, opened ~2015 (MyJoyOnline). One of six transfer stations reopened for tricycle drop-off under Presidential directive, 11 Jul 2026 (GBC Ghana Online). Coordinates are a neighborhood-level approximation (Teshie centroid) — exact facility footprint not independently verifiable via mapping search.'
),

(
  'Kpone Transfer Station',
  '{
    "type": "Polygon",
    "coordinates": [[
      [0.0277972, 5.7022017],
      [0.0296028, 5.7022017],
      [0.0296028, 5.7039983],
      [0.0277972, 5.7039983],
      [0.0277972, 5.7022017]
    ]]
  }'::jsonb,
  'Named as one of six transfer stations reopened for tricycle drop-off under Presidential directive, 11 Jul 2026 (GBC Ghana Online). Coordinates approximate the Kpone-Katamanso waste-facility locality. Note: the original Kpone engineered landfill operated 2013-2019 and was decommissioned 2019-2023 — the 2026-reopened facility is a separate Zoomlion transfer station in the same locality.'
),

(
  'Ashaiman Transfer Station',
  '{
    "type": "Polygon",
    "coordinates": [[
      [-0.0497027, 5.6821017],
      [-0.0478973, 5.6821017],
      [-0.0478973, 5.6838983],
      [-0.0497027, 5.6838983],
      [-0.0497027, 5.6821017]
    ]]
  }'::jsonb,
  'One of six transfer stations reopened for tricycle drop-off under Presidential directive, 11 Jul 2026 (GBC Ghana Online). Facility name/location confirmed via Google Places ("Zoomlion Transfer Station Ashaiman").'
),

(
  'Pantang Transfer Station',
  '{
    "type": "Polygon",
    "coordinates": [[
      [-0.1965028, 5.7078017],
      [-0.1946972, 5.7078017],
      [-0.1946972, 5.7095983],
      [-0.1965028, 5.7095983],
      [-0.1965028, 5.7078017]
    ]]
  }'::jsonb,
  'One of six transfer stations reopened for tricycle drop-off under Presidential directive, 11 Jul 2026 (GBC Ghana Online). Facility name/location confirmed via Google Places ("Zoomlion Transfer Station Pantang").'
);