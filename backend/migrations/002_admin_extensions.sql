-- Run in Supabase SQL Editor AFTER migration 001
-- Adds soft-delete for mechanics, ban support for customers,
-- zone deactivation, and two RPCs for GeoJSON boundary management.

-- ── Mechanics: soft-delete flag ──────────────────────────────────────────────
alter table public.mechanics
  add column if not exists is_active boolean not null default true;

-- ── Profiles: customer ban fields ────────────────────────────────────────────
alter table public.profiles
  add column if not exists is_banned     boolean     not null default false,
  add column if not exists banned_reason text,
  add column if not exists banned_at     timestamptz;

-- ── Zones: deactivation flag ─────────────────────────────────────────────────
alter table public.zones
  add column if not exists is_active boolean not null default true;

-- ── RPC: create a zone with a GeoJSON Polygon boundary ───────────────────────
-- p_boundary_geojson: a GeoJSON Geometry object, e.g.
--   { "type": "Polygon", "coordinates": [[[36.8, -1.3], ...]] }
create or replace function admin_create_zone(
  p_name                text,
  p_zone_type           text,
  p_mobile_zone_subtype text,
  p_boundary_geojson    jsonb
)
returns uuid language plpgsql security definer as $$
declare
  v_id uuid;
begin
  insert into public.zones(name, zone_type, mobile_zone_subtype, boundary)
  values (
    p_name,
    p_zone_type,
    p_mobile_zone_subtype,
    st_geomfromgeojson(p_boundary_geojson::text)::geography
  )
  returning id into v_id;
  return v_id;
end;
$$;

-- ── RPC: update a zone — all params are optional (null = keep existing) ───────
create or replace function admin_update_zone(
  p_id                  uuid,
  p_name                text,
  p_zone_type           text,
  p_mobile_zone_subtype text,
  p_boundary_geojson    jsonb,
  p_is_active           boolean
)
returns void language plpgsql security definer as $$
begin
  update public.zones
  set
    name                = coalesce(p_name,                name),
    zone_type           = coalesce(p_zone_type,           zone_type),
    mobile_zone_subtype = coalesce(p_mobile_zone_subtype, mobile_zone_subtype),
    boundary            = case
                            when p_boundary_geojson is not null
                            then st_geomfromgeojson(p_boundary_geojson::text)::geography
                            else boundary
                          end,
    is_active           = coalesce(p_is_active, is_active)
  where id = p_id;
end;
$$;
