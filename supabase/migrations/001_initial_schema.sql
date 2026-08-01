-- WasteTrack V1 — initial schema
-- Run in Supabase SQL Editor. This file is a saved record of what's
-- been run — running this file itself doesn't do anything automatically.


-- Create drivers table
create extension if not exists pgcrypto;  -- provides gen_random_uuid()

create table if not exists public.drivers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  base_location point,                 -- lat/lng, used for V2 Voronoi assignment
  tare_weight_kg float8,               -- empty vehicle weight, reference point for drop-off classification
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now()
);

-- Create authorized zones table
create table if not exists public.authorized_zones (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,           -- e.g. "Achimota Transfer Station"
  polygon jsonb not null,              -- GeoJSON polygon, [lng, lat] coordinate order
  source text,                         -- citation, e.g. "AMA notice, 2026-03-01"
  created_at timestamptz not null default now()
);

-- Create shifts table
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

-- Create gps_pings table

