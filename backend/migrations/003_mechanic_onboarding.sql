-- Run in Supabase SQL Editor AFTER migration 002
-- Adds mechanic application submission fields and rejection support.

-- Application-specific fields on mechanics table
alter table public.mechanics
  add column if not exists rejection_reason    text,
  add column if not exists service_zones       text[]  default '{}',
  add column if not exists work_radius_km      integer,
  add column if not exists garage_name         text,
  add column if not exists garage_address      text,
  add column if not exists google_maps_link    text,
  add column if not exists application_metadata jsonb   default '{}';

-- Escrow and M-Pesa tables (if not already created by escrow migration)
create table if not exists public.job_escrow (
  id                uuid         default gen_random_uuid() primary key,
  request_id        uuid         not null references public.requests(id) on delete cascade,
  customer_id       uuid         not null references public.profiles(id),
  mechanic_id       uuid         references public.mechanics(id),
  travel_fee        numeric(12,2) not null default 0,
  inspection_fee    numeric(12,2) not null default 0,
  balance_held      numeric(12,2) not null default 0,
  status            text         not null default 'awaiting_payment'
                    check (status in ('awaiting_payment','funded','active','partially_released','released','refunded','disputed')),
  mpesa_reference   text,
  mechanic_phone    text,
  created_at        timestamptz  default now(),
  updated_at        timestamptz  default now(),
  unique(request_id)
);

create table if not exists public.escrow_entries (
  id            uuid         default gen_random_uuid() primary key,
  escrow_id     uuid         not null references public.job_escrow(id) on delete cascade,
  entry_type    text         not null
                check (entry_type in ('deposit','release_to_mechanic','refund_to_customer','platform_fee')),
  amount        numeric(12,2) not null,
  description   text,
  payment_ref   text,
  created_at    timestamptz  default now()
);

-- Trigger to sync escrow balance after each ledger entry
create or replace function sync_escrow_balance()
returns trigger language plpgsql security definer as $$
begin
  update public.job_escrow
  set balance_held = (
    select coalesce(sum(
      case entry_type
        when 'deposit'             then amount
        when 'release_to_mechanic' then -amount
        when 'refund_to_customer'  then -amount
        when 'platform_fee'        then -amount
        else 0
      end
    ), 0)
    from public.escrow_entries
    where escrow_id = new.escrow_id
  ),
  updated_at = now()
  where id = new.escrow_id;
  return new;
end;
$$;

drop trigger if exists trg_sync_escrow_balance on public.escrow_entries;
create trigger trg_sync_escrow_balance
  after insert on public.escrow_entries
  for each row execute function sync_escrow_balance();

-- RPC: initialise escrow when request is accepted
create or replace function initialise_escrow(
  p_request_id     uuid,
  p_customer_id    uuid,
  p_travel_fee     numeric,
  p_inspection_fee numeric
)
returns uuid language plpgsql security definer as $$
declare v_id uuid;
begin
  insert into public.job_escrow(request_id, customer_id, travel_fee, inspection_fee)
  values (p_request_id, p_customer_id, p_travel_fee, p_inspection_fee)
  returning id into v_id;
  return v_id;
end;
$$;

-- RPC: fund escrow after M-Pesa payment received
create or replace function fund_escrow(
  p_request_id   uuid,
  p_amount       numeric,
  p_mpesa_ref    text
)
returns void language plpgsql security definer as $$
declare v_escrow_id uuid;
begin
  select id into v_escrow_id from public.job_escrow where request_id = p_request_id;
  if v_escrow_id is null then
    raise exception 'Escrow not found for request %', p_request_id;
  end if;
  insert into public.escrow_entries(escrow_id, entry_type, amount, description, payment_ref)
  values (v_escrow_id, 'deposit', p_amount, 'M-Pesa payment', p_mpesa_ref);
  update public.job_escrow set status = 'funded', mpesa_reference = p_mpesa_ref
  where id = v_escrow_id;
end;
$$;

-- RPC: activate escrow when mechanic is assigned
create or replace function activate_escrow(p_request_id uuid, p_mechanic_id uuid, p_mechanic_phone text)
returns void language plpgsql security definer as $$
begin
  update public.job_escrow
  set status = 'active', mechanic_id = p_mechanic_id, mechanic_phone = p_mechanic_phone
  where request_id = p_request_id and status = 'funded';
end;
$$;

-- RPC: release escrow to mechanic
create or replace function release_to_mechanic(
  p_escrow_id  uuid,
  p_amount     numeric,
  p_description text
)
returns void language plpgsql security definer as $$
begin
  insert into public.escrow_entries(escrow_id, entry_type, amount, description)
  values (p_escrow_id, 'release_to_mechanic', p_amount, p_description);
  update public.job_escrow set status = 'released' where id = p_escrow_id;
end;
$$;

-- RPC: refund escrow to customer
create or replace function refund_to_customer(
  p_escrow_id  uuid,
  p_amount     numeric,
  p_description text
)
returns void language plpgsql security definer as $$
begin
  insert into public.escrow_entries(escrow_id, entry_type, amount, description)
  values (p_escrow_id, 'refund_to_customer', p_amount, p_description);
  update public.job_escrow set status = 'refunded' where id = p_escrow_id;
end;
$$;

-- RPC: full ledger for admin view
create or replace function get_job_ledger(p_request_id uuid)
returns jsonb language plpgsql security definer as $$
declare
  v_escrow job_escrow%rowtype;
  v_entries jsonb;
begin
  select * into v_escrow from public.job_escrow where request_id = p_request_id;
  select jsonb_agg(e order by e.created_at) into v_entries
  from public.escrow_entries e where e.escrow_id = v_escrow.id;
  return jsonb_build_object(
    'escrow', row_to_json(v_escrow),
    'entries', coalesce(v_entries, '[]'::jsonb)
  );
end;
$$;
