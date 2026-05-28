-- ============================================================
-- Fundix — Supabase Schema (refined)
-- Run this in the Supabase SQL editor: Project → SQL Editor → New query
-- PostGIS must be enabled first: Database → Extensions → postgis → Enable
-- ============================================================

-- Supabase installs PostGIS in the tiger schema on some plans;
-- this ensures geography types and ST_* functions are found.
set search_path to "$user", public, extensions, tiger, topology;

-- ── Extensions ────────────────────────────────────────────────────────────────
create extension if not exists postgis;

-- ── Profiles ──────────────────────────────────────────────────────────────────
create table public.profiles (
  id         uuid references auth.users(id) on delete cascade primary key,
  name       text        not null,
  phone      text,
  role       text        not null check (role in ('customer', 'mechanic')),
  avatar_url text,
  created_at timestamptz default now()
);

-- ── Vehicles ──────────────────────────────────────────────────────────────────
create table public.vehicles (
  id           uuid        default gen_random_uuid() primary key,
  owner_id     uuid        references public.profiles(id) on delete cascade not null,
  brand        text        not null,
  model        text        not null,
  year         int         not null,
  engine       text,
  fuel_type    text        not null default 'Petrol',
  transmission text        not null default 'Auto',
  body_type    text        not null default 'Sedan',
  plate_number text,
  nickname     text,
  created_at   timestamptz default now()
);

alter table public.vehicles enable row level security;

create policy "vehicles: own all"
  on public.vehicles for all
  using  (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

-- ── Mechanics ─────────────────────────────────────────────────────────────────
create table public.mechanics (
  id               uuid references public.profiles(id) on delete cascade primary key,
  mechanic_type    text         not null check (mechanic_type in ('garage', 'mobile')),
  is_online        boolean      not null default false,
  operating_status text         not null default 'open_now'
                               check (operating_status in ('open_now', 'busy', 'appointment_only')),
  current_lat      double precision,
  current_lng      double precision,
  current_location geography(POINT, 4326),
  rating           numeric(3,2) not null default 0.00,
  review_count     integer      not null default 0,
  job_count        integer      not null default 0,
  verified         boolean      not null default false,
  updated_at       timestamptz  default now()
);

-- ── Zones ─────────────────────────────────────────────────────────────────────
create table public.zones (
  id                  uuid        default gen_random_uuid() primary key,
  name                text        not null,
  zone_type           text        not null
                      check (zone_type in ('garage_workshop', 'controlled_mobile', 'highway_emergency', 'restricted')),
  mobile_zone_subtype text
                      check (mobile_zone_subtype in ('commercial_area', 'residential_estate', 'fuel_station')),
  boundary            geography(POLYGON, 4326),
  created_at          timestamptz default now()
);

create index zones_boundary_idx on public.zones using gist(boundary);

-- ── Mechanic ↔ Zone coverage ──────────────────────────────────────────────────
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
  vehicle_info        jsonb,
  symptoms            text,
  location_lat        double precision,
  location_lng        double precision,
  location_address    text,
  zone_type           text        check (zone_type in ('garage_workshop', 'controlled_mobile', 'highway_emergency', 'restricted')),
  mobile_zone_subtype text        check (mobile_zone_subtype in ('commercial_area', 'residential_estate', 'fuel_station')),
  status              text        not null default 'pending'
                      check (status in (
                        'pending',
                        'dispatching',
                        'offers_sent',
                        'mechanic_selected',
                        'accepted',
                        'in_progress',
                        'completed',
                        'cancelled'
                      )),
  price_estimate      numeric(10,2),
  diagnosis_result    jsonb,
  created_at          timestamptz default now(),
  updated_at          timestamptz default now()
);

create index requests_customer_idx  on public.requests(customer_id);
create index requests_status_idx    on public.requests(status);
create index mechanics_location_idx on public.mechanics using gist(current_location);

-- ── Mechanic offers ───────────────────────────────────────────────────────────
-- One row per mechanic per request during the offers_sent stage.
-- Customer selects one → request moves to mechanic_selected.
create table public.mechanic_offers (
  id           uuid        default gen_random_uuid() primary key,
  request_id   uuid        not null references public.requests(id)  on delete cascade,
  mechanic_id  uuid        not null references public.mechanics(id) on delete cascade,
  price_quote  numeric(10,2),
  eta_minutes  int,
  status       text        not null default 'pending'
               check (status in ('pending', 'accepted', 'declined', 'expired')),
  sent_at      timestamptz default now(),
  responded_at timestamptz,
  unique (request_id, mechanic_id)
);

create index offers_request_idx  on public.mechanic_offers(request_id);
create index offers_mechanic_idx on public.mechanic_offers(mechanic_id);

-- ── Reviews ───────────────────────────────────────────────────────────────────
-- One review per completed request. A trigger keeps mechanics.rating in sync.
create table public.reviews (
  id          uuid        default gen_random_uuid() primary key,
  request_id  uuid        not null references public.requests(id)  on delete cascade unique,
  mechanic_id uuid        not null references public.mechanics(id),
  customer_id uuid        not null references public.profiles(id),
  rating      int         not null check (rating between 1 and 5),
  comment     text,
  created_at  timestamptz default now()
);

create index reviews_mechanic_idx on public.reviews(mechanic_id);

-- ── FCM tokens ────────────────────────────────────────────────────────────────
-- Push notification tokens per device. One user may have multiple devices.
create table public.fcm_tokens (
  id         uuid        default gen_random_uuid() primary key,
  user_id    uuid        not null references public.profiles(id) on delete cascade,
  token      text        not null unique,
  platform   text        check (platform in ('android', 'ios')),
  updated_at timestamptz default now()
);

create index fcm_tokens_user_idx on public.fcm_tokens(user_id);

-- ── Triggers ──────────────────────────────────────────────────────────────────

-- Keeps mechanics.current_location in sync with lat/lng on every write.
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

-- Auto-stamps updated_at on every request mutation.
create or replace function touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger requests_updated_at
  before update on public.requests
  for each row execute function touch_updated_at();

-- Auto-creates a profile row when a user signs up.
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

-- Recalculates mechanics.rating and review_count after each new review.
create or replace function update_mechanic_rating()
returns trigger language plpgsql as $$
begin
  update public.mechanics
  set
    rating       = (select round(avg(rating)::numeric, 2) from public.reviews where mechanic_id = new.mechanic_id),
    review_count = (select count(*) from public.reviews where mechanic_id = new.mechanic_id)
  where id = new.mechanic_id;
  return new;
end;
$$;

create trigger reviews_update_rating
  after insert on public.reviews
  for each row execute function update_mechanic_rating();

-- ── RPCs ──────────────────────────────────────────────────────────────────────

create or replace function nearby_mechanics(
  p_lat           double precision,
  p_lng           double precision,
  p_radius_m      double precision,
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

alter table public.profiles        enable row level security;
alter table public.mechanics       enable row level security;
alter table public.zones           enable row level security;
alter table public.mechanic_zones  enable row level security;
alter table public.requests        enable row level security;
alter table public.mechanic_offers enable row level security;
alter table public.reviews         enable row level security;
alter table public.fcm_tokens      enable row level security;

-- Profiles: own row only
create policy "profiles: own read"   on public.profiles for select using (auth.uid() = id);
create policy "profiles: own update" on public.profiles for update using (auth.uid() = id);

-- Mechanics: own row full access; any authenticated user can read (for offer cards)
create policy "mechanics: own write"      on public.mechanics for all    using (auth.uid() = id);
create policy "mechanics: customers read" on public.mechanics for select using (true);

-- Zones: read-only for authenticated users; written via service role only
create policy "zones: authenticated read" on public.zones for select using (auth.role() = 'authenticated');

-- Mechanic zones
create policy "mechanic_zones: read"  on public.mechanic_zones for select using (true);
create policy "mechanic_zones: write" on public.mechanic_zones for all   using (auth.uid() = mechanic_id);

-- Requests
create policy "requests: customer read"   on public.requests for select using (auth.uid() = customer_id);
create policy "requests: mechanic read"   on public.requests for select using (auth.uid() = mechanic_id);
create policy "requests: customer insert" on public.requests for insert with check (auth.uid() = customer_id);
create policy "requests: customer cancel" on public.requests for update
  using (auth.uid() = customer_id and status = 'pending');
create policy "requests: mechanic update" on public.requests for update
  using (auth.uid() = mechanic_id);

-- Mechanic offers: mechanics see their own; customers see offers on their requests
create policy "offers: mechanic read" on public.mechanic_offers for select
  using (auth.uid() = mechanic_id);
create policy "offers: customer read" on public.mechanic_offers for select
  using (exists (
    select 1 from public.requests r
    where r.id = request_id and r.customer_id = auth.uid()
  ));
create policy "offers: mechanic respond" on public.mechanic_offers for update
  using (auth.uid() = mechanic_id);

-- Reviews: public read; customer can insert only for their completed requests
create policy "reviews: public read"     on public.reviews for select using (true);
create policy "reviews: customer insert" on public.reviews for insert
  with check (
    auth.uid() = customer_id and
    exists (
      select 1 from public.requests r
      where r.id = request_id
        and r.status = 'completed'
        and r.customer_id = auth.uid()
    )
  );

-- FCM tokens: own device tokens only
create policy "fcm_tokens: own all" on public.fcm_tokens for all using (auth.uid() = user_id);

-- ── Job Escrow Account ────────────────────────────────────────────────────────
-- One row per job. Holds the call-out deposit (travel fee + inspection fee)
-- between customer payment and job resolution.
create table public.job_escrow (
  id              uuid          default gen_random_uuid() primary key,
  request_id      uuid          not null references public.requests(id) on delete cascade unique,
  customer_id     uuid          not null references public.profiles(id),
  mechanic_id     uuid          references public.mechanics(id),
  travel_fee      numeric(10,2) not null check (travel_fee >= 0),
  inspection_fee  numeric(10,2) not null check (inspection_fee >= 0),
  balance_held    numeric(10,2) not null default 0 check (balance_held >= 0),
  status          text          not null default 'awaiting_payment'
                  check (status in (
                    'awaiting_payment',   -- STK push sent, deposit not yet confirmed
                    'funded',             -- deposit confirmed, mechanic not yet dispatched
                    'active',             -- mechanic en route, funds held
                    'partially_released', -- some funds paid out, remainder still held
                    'released',           -- all funds paid out to mechanic
                    'refunded',           -- full deposit returned to customer
                    'disputed'            -- admin hold pending manual review
                  )),
  mpesa_reference text,
  created_at      timestamptz   default now(),
  updated_at      timestamptz   default now()
);

create index escrow_request_idx  on public.job_escrow(request_id);
create index escrow_customer_idx on public.job_escrow(customer_id);
create index escrow_mechanic_idx on public.job_escrow(mechanic_id);

-- ── Escrow Ledger ─────────────────────────────────────────────────────────────
-- Every money event for a job. A trigger keeps job_escrow.balance_held in sync.
create table public.escrow_entries (
  id          uuid          default gen_random_uuid() primary key,
  escrow_id   uuid          not null references public.job_escrow(id) on delete cascade,
  entry_type  text          not null check (entry_type in (
                'deposit',              -- customer pays call-out fee in
                'release_to_mechanic',  -- escrow pays out to mechanic
                'refund_to_customer',   -- escrow refunds customer
                'platform_fee'          -- Fundix platform cut before payout
              )),
  amount      numeric(10,2) not null check (amount > 0),
  description text,
  payment_ref text,
  created_at  timestamptz   default now()
);

create index entries_escrow_idx on public.escrow_entries(escrow_id);

-- Trigger: keeps job_escrow.balance_held and status in sync after every entry.
create or replace function sync_escrow_balance()
returns trigger language plpgsql as $$
declare
  v_escrow      public.job_escrow%rowtype;
  v_new_balance numeric(10,2);
  v_new_status  text;
begin
  select * into v_escrow from public.job_escrow where id = new.escrow_id for update;

  if new.entry_type = 'deposit' then
    v_new_balance := v_escrow.balance_held + new.amount;
    v_new_status  := case
                       when v_escrow.status = 'awaiting_payment' then 'funded'
                       else v_escrow.status
                     end;
  else
    -- Debit: release, refund, or platform fee
    v_new_balance := greatest(v_escrow.balance_held - new.amount, 0);

    if v_new_balance = 0 then
      v_new_status := case
                        when new.entry_type = 'refund_to_customer' then 'refunded'
                        else 'released'
                      end;
    elsif v_escrow.status not in ('released', 'refunded', 'disputed') then
      v_new_status := 'partially_released';
    else
      v_new_status := v_escrow.status;
    end if;
  end if;

  update public.job_escrow
  set balance_held = v_new_balance,
      status       = v_new_status
  where id = new.escrow_id;

  return new;
end;
$$;

create trigger escrow_balance_sync
  after insert on public.escrow_entries
  for each row execute function sync_escrow_balance();

create trigger job_escrow_updated_at
  before update on public.job_escrow
  for each row execute function touch_updated_at();

-- ── Escrow RPCs ───────────────────────────────────────────────────────────────

-- Creates the escrow account when the customer confirms the call-out fee.
-- Returns the new escrow id so the client can reference it.
create or replace function initialise_escrow(
  p_request_id     uuid,
  p_customer_id    uuid,
  p_travel_fee     numeric,
  p_inspection_fee numeric
)
returns uuid language plpgsql security definer as $$
declare
  v_id uuid;
begin
  insert into public.job_escrow(request_id, customer_id, travel_fee, inspection_fee)
  values (p_request_id, p_customer_id, p_travel_fee, p_inspection_fee)
  returning id into v_id;
  return v_id;
end;
$$;

-- Records the M-Pesa deposit after STK push confirmation.
create or replace function fund_escrow(
  p_escrow_id uuid,
  p_amount    numeric,
  p_mpesa_ref text
)
returns void language plpgsql security definer as $$
begin
  update public.job_escrow
  set mpesa_reference = p_mpesa_ref
  where id = p_escrow_id;

  insert into public.escrow_entries(escrow_id, entry_type, amount, description, payment_ref)
  values (p_escrow_id, 'deposit', p_amount, 'Call-out deposit', p_mpesa_ref);
end;
$$;

-- Assigns the mechanic and marks the escrow active once dispatch is confirmed.
create or replace function activate_escrow(
  p_escrow_id   uuid,
  p_mechanic_id uuid
)
returns void language plpgsql security definer as $$
begin
  update public.job_escrow
  set mechanic_id = p_mechanic_id,
      status      = 'active'
  where id = p_escrow_id
    and status = 'funded';
end;
$$;

-- Releases an amount from escrow to the mechanic.
-- Call twice for partial payouts (e.g. inspection fee only on rejected quote).
create or replace function release_to_mechanic(
  p_escrow_id   uuid,
  p_amount      numeric,
  p_description text default 'Released to mechanic'
)
returns void language plpgsql security definer as $$
begin
  insert into public.escrow_entries(escrow_id, entry_type, amount, description)
  values (p_escrow_id, 'release_to_mechanic', p_amount, p_description);
end;
$$;

-- Refunds an amount from escrow back to the customer.
-- Use when customer cancels before dispatch or mechanic fails to arrive.
create or replace function refund_to_customer(
  p_escrow_id   uuid,
  p_amount      numeric,
  p_description text default 'Refunded to customer'
)
returns void language plpgsql security definer as $$
begin
  insert into public.escrow_entries(escrow_id, entry_type, amount, description)
  values (p_escrow_id, 'refund_to_customer', p_amount, p_description);
end;
$$;

-- Returns the full ledger for a request — used by customer, mechanic, and admin views.
create or replace function get_job_ledger(p_request_id uuid)
returns table (
  escrow_id       uuid,
  status          text,
  travel_fee      numeric,
  inspection_fee  numeric,
  balance_held    numeric,
  mpesa_reference text,
  entry_type      text,
  amount          numeric,
  description     text,
  payment_ref     text,
  entry_time      timestamptz
) language sql stable security definer as $$
  select
    e.id              as escrow_id,
    e.status,
    e.travel_fee,
    e.inspection_fee,
    e.balance_held,
    e.mpesa_reference,
    ee.entry_type,
    ee.amount,
    ee.description,
    ee.payment_ref,
    ee.created_at     as entry_time
  from public.job_escrow e
  left join public.escrow_entries ee on ee.escrow_id = e.id
  where e.request_id = p_request_id
  order by ee.created_at asc;
$$;

-- ── Escrow RLS ────────────────────────────────────────────────────────────────

alter table public.job_escrow    enable row level security;
alter table public.escrow_entries enable row level security;

-- Customer sees their own escrow; mechanic sees escrow tied to their job.
create policy "escrow: customer read"
  on public.job_escrow for select
  using (auth.uid() = customer_id);

create policy "escrow: mechanic read"
  on public.job_escrow for select
  using (auth.uid() = mechanic_id);

-- Ledger entries inherit visibility from the parent escrow row.
create policy "entries: customer read"
  on public.escrow_entries for select
  using (exists (
    select 1 from public.job_escrow e
    where e.id = escrow_id and e.customer_id = auth.uid()
  ));

create policy "entries: mechanic read"
  on public.escrow_entries for select
  using (exists (
    select 1 from public.job_escrow e
    where e.id = escrow_id and e.mechanic_id = auth.uid()
  ));
