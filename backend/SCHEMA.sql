-- ============================================================
-- Fundix — Supabase Schema
-- Run this in the Supabase SQL editor (Project → SQL Editor → New query)
-- Enable PostGIS first: Extensions → postgis → Enable
-- ============================================================

-- ── Extensions ────────────────────────────────────────────────────────────────
create extension if not exists postgis;

-- ── Profiles ──────────────────────────────────────────────────────────────────
-- Extends Supabase auth.users. Created automatically on signup via trigger.
create table public.profiles (
  id        uuid references auth.users(id) on delete cascade primary key,
  name      text        not null,
  phone     text,
  role      text        not null check (role in ('customer', 'mechanic')),
  created_at timestamptz default now()
);

-- ── Mechanics ─────────────────────────────────────────────────────────────────
-- One row per mechanic user. mechanic_type can only move garage; never back.
create table public.mechanics (
  id               uuid references public.profiles(id) on delete cascade primary key,
  mechanic_type    text        not null check (mechanic_type in ('garage', 'mobile')),
  is_online        boolean     not null default false,
  operating_status text        not null default 'open_now'
                              check (operating_status in ('open_now', 'busy', 'appointment_only')),
  -- Live GPS position — updated by the mechanic app while online
  current_lat      double precision,
  current_lng      double precision,
  -- PostGIS point built from current_lat/lng via trigger (see below)
  current_location geography(POINT, 4326),
  rating           numeric(3,2) not null default 0.00,
  review_count     integer      not null default 0,
  job_count        integer      not null default 0,
  verified         boolean      not null default false,
  updated_at       timestamptz  default now()
);

-- ── Zones ─────────────────────────────────────────────────────────────────────
-- Defines the geographic boundaries for each zone type.
-- Boundaries are stored as PostGIS polygons and seeded by the ops team.
-- Mobile sub-zones (commercial, residential, fuel) are rows with zone_type='controlled_mobile'.
create table public.zones (
  id                  uuid        default gen_random_uuid() primary key,
  name                text        not null,           -- e.g. 'Westlands Mall Zone'
  zone_type           text        not null
                      check (zone_type in ('garage_workshop', 'controlled_mobile', 'highway_emergency', 'restricted')),
  mobile_zone_subtype text
                      check (mobile_zone_subtype in ('commercial_area', 'residential_estate', 'fuel_station')),
  -- Geographic boundary — used for ST_Contains(boundary, customer_point) lookups
  boundary            geography(POLYGON, 4326),
  created_at          timestamptz default now()
);

-- Fast spatial index on zone boundaries
create index zones_boundary_idx on public.zones using gist(boundary);

-- ── Mechanic ↔ Zone coverage ──────────────────────────────────────────────────
-- Which zones a mobile mechanic accepts jobs in.
-- Garage mechanics don't need this — they are tied to their garage location.
create table public.mechanic_zones (
  mechanic_id uuid references public.mechanics(id) on delete cascade,
  zone_id     uuid references public.zones(id)     on delete cascade,
  primary key (mechanic_id, zone_id)
);

-- ── Requests ──────────────────────────────────────────────────────────────────
create table public.requests (
  id                  uuid        default gen_random_uuid() primary key,
  customer_id         uuid        not null references public.profiles(id),
  mechanic_id         uuid        references public.mechanics(id),
  vehicle_info        jsonb,      -- { make, model, year, plate }
  symptoms            text,
  -- Raw customer coordinates
  location_lat        double precision,
  location_lng        double precision,
  location_address    text,
  -- Server-classified zone — set on creation, never by the client
  zone_type           text        check (zone_type in ('garage_workshop', 'controlled_mobile', 'highway_emergency', 'restricted')),
  mobile_zone_subtype text        check (mobile_zone_subtype in ('commercial_area', 'residential_estate', 'fuel_station')),
  -- 8-stage Fundix job lifecycle
  status              text        not null default 'pending'
                      check (status in (
                        'pending',          -- request submitted, not yet dispatched
                        'dispatching',      -- finding mechanics
                        'offers_sent',      -- mechanics notified, awaiting selection
                        'mechanic_selected',-- customer picked a mechanic
                        'accepted',         -- mechanic confirmed the job
                        'in_progress',      -- job underway
                        'completed',        -- job done, payment triggered
                        'cancelled'
                      )),
  price_estimate      numeric(10,2),
  diagnosis_result    jsonb,      -- LLM diagnosis output
  created_at          timestamptz default now(),
  updated_at          timestamptz default now()
);

-- Fast lookups by customer and status
create index requests_customer_idx on public.requests(customer_id);
create index requests_status_idx   on public.requests(status);

-- Fast spatial lookup on mechanic positions (for nearby matching)
create index mechanics_location_idx on public.mechanics using gist(current_location);

-- ── Trigger: keep current_location in sync with lat/lng ───────────────────────
create or replace function sync_mechanic_location()
returns trigger language plpgsql as $$
begin
  if new.current_lat is not null and new.current_lng is not null then
    new.current_location := st_setsrid(st_makepoint(new.current_lng, new.current_lat), 4326)::geography;
  end if;
  new.updated_at := now();
  return new;
end;
$$;

create trigger mechanic_location_sync
  before insert or update on public.mechanics
  for each row execute function sync_mechanic_location();

-- ── Trigger: auto-create profile on signup ────────────────────────────────────
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles(id, name, phone, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', 'User'),
    new.raw_user_meta_data->>'phone',
    coalesce(new.raw_user_meta_data->>'role', 'customer')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ── nearby_mechanics RPC ─────────────────────────────────────────────────────
-- Called by matchingService.js. Returns online mechanics of the given type
-- within radius meters, ordered by distance. Uses the spatial index on
-- mechanics.current_location for fast results at scale.
create or replace function nearby_mechanics(
  p_lat          double precision,
  p_lng          double precision,
  p_radius_m     double precision,
  p_mechanic_type text
)
returns table (
  id            uuid,
  mechanic_type text,
  is_online     boolean,
  current_lat   double precision,
  current_lng   double precision,
  rating        numeric,
  review_count  integer,
  job_count     integer,
  distance_m    double precision,
  name          text
) language sql stable security definer as $$
  select
    m.id,
    m.mechanic_type,
    m.is_online,
    m.current_lat,
    m.current_lng,
    m.rating,
    m.review_count,
    m.job_count,
    st_distance(
      m.current_location,
      st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography
    ) as distance_m,
    p.name
  from public.mechanics m
  join public.profiles p on p.id = m.id
  where m.is_online = true
    and m.mechanic_type = p_mechanic_type
    and st_dwithin(
      m.current_location,
      st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
      p_radius_m
    )
  order by distance_m asc;
$$;

-- ── classify_point RPC ───────────────────────────────────────────────────────
-- Called by zoneService.js to classify a customer's GPS coordinates.
-- Returns the best matching zone (ordered: restricted zones last so positive
-- matches win). The backend service role bypasses RLS on this call.
create or replace function classify_point(p_lat double precision, p_lng double precision)
returns table (
  zone_type           text,
  mobile_zone_subtype text
) language sql stable security definer as $$
  select z.zone_type, z.mobile_zone_subtype
  from public.zones z
  where st_contains(
    z.boundary::geometry,
    st_setsrid(st_makepoint(p_lng, p_lat), 4326)
  )
  order by
    case z.zone_type
      when 'restricted'        then 4
      when 'highway_emergency' then 3
      when 'garage_workshop'   then 2
      when 'controlled_mobile' then 1
    end asc
  limit 1;
$$;

-- ── Row Level Security ────────────────────────────────────────────────────────
alter table public.profiles      enable row level security;
alter table public.mechanics     enable row level security;
alter table public.zones         enable row level security;
alter table public.mechanic_zones enable row level security;
alter table public.requests      enable row level security;

-- Profiles: users see and update only their own row
create policy "profiles: own read"   on public.profiles for select using (auth.uid() = id);
create policy "profiles: own update" on public.profiles for update using (auth.uid() = id);

-- Mechanics: own row full access; customers can read any mechanic (for offer cards)
create policy "mechanics: own write"     on public.mechanics for all    using (auth.uid() = id);
create policy "mechanics: customers read" on public.mechanics for select using (true);

-- Zones: read-only for all authenticated users; write via service role only
create policy "zones: authenticated read" on public.zones for select using (auth.role() = 'authenticated');

-- Mechanic zones: readable by all; writable by own mechanic
create policy "mechanic_zones: read"  on public.mechanic_zones for select using (true);
create policy "mechanic_zones: write" on public.mechanic_zones for all   using (auth.uid() = mechanic_id);

-- Requests: customer sees own; assigned mechanic sees theirs
create policy "requests: customer read"  on public.requests for select using (auth.uid() = customer_id);
create policy "requests: mechanic read"  on public.requests for select using (auth.uid() = mechanic_id);
create policy "requests: customer insert" on public.requests for insert with check (auth.uid() = customer_id);
