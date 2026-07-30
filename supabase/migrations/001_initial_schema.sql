-- WasteTrack V1 — initial schema
-- Run in Supabase SQL Editor. This file is a saved record of what's
-- been run — running this file itself doesn't do anything automatically.

create extension if not exists pgcrypto;  -- provides gen_random_uuid()

create table if not exists public.drivers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  base_location point,                 -- lat/lng, used for V2 Voronoi assignment
  tare_weight_kg float8,               -- empty vehicle weight, reference point for drop-off classification
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now()
);