-- Run in Supabase SQL Editor AFTER migration 003
-- Adds auto-release buffer, dispute support, and job completion tracking.

-- ── job_escrow extensions ─────────────────────────────────────────────────────
alter table public.job_escrow
  add column if not exists auto_release_at  timestamptz,
  add column if not exists disputed         boolean      not null default false,
  add column if not exists dispute_reason   text,
  add column if not exists released_at      timestamptz,
  add column if not exists released_via     text; -- 'auto', 'admin', 'customer_confirm'

-- Allow 'pending_release' as a valid status
alter table public.job_escrow
  drop constraint if exists job_escrow_status_check;
alter table public.job_escrow
  add constraint job_escrow_status_check
  check (status in (
    'awaiting_payment', 'funded', 'active',
    'pending_release',  -- buffer window: auto-release countdown active
    'partially_released', 'released', 'refunded', 'disputed'
  ));

-- ── requests: completion tracking ────────────────────────────────────────────
-- Add completed_at and allow 'completed' status if not already present
alter table public.requests
  add column if not exists completed_at  timestamptz,
  add column if not exists completed_by  text check (completed_by in ('customer', 'mechanic', 'admin'));

-- ── RPC: mark job complete and start auto-release countdown ──────────────────
-- p_release_after_minutes: buffer window (default 2 for dev, use 120 for prod)
create or replace function complete_job(
  p_request_id           uuid,
  p_completed_by         text,
  p_release_after_minutes integer default 2
)
returns void language plpgsql security definer as $$
begin
  -- Mark the request completed
  update public.requests
  set status       = 'completed',
      completed_at = now(),
      completed_by = p_completed_by
  where id = p_request_id;

  -- Start the auto-release countdown on the escrow
  update public.job_escrow
  set status          = 'pending_release',
      auto_release_at = now() + (p_release_after_minutes || ' minutes')::interval
  where request_id = p_request_id
    and status     in ('active', 'funded');
end;
$$;

-- ── RPC: dispute a completed job (pauses auto-release) ───────────────────────
create or replace function dispute_job(
  p_request_id  uuid,
  p_reason      text
)
returns void language plpgsql security definer as $$
begin
  update public.job_escrow
  set status         = 'disputed',
      disputed       = true,
      dispute_reason = p_reason
  where request_id = p_request_id
    and status     = 'pending_release';
end;
$$;

-- ── RPC: customer confirms job early (immediate release) ─────────────────────
create or replace function confirm_job_complete(p_request_id uuid)
returns void language plpgsql security definer as $$
declare v_escrow job_escrow%rowtype;
begin
  select * into v_escrow from public.job_escrow where request_id = p_request_id;
  if v_escrow.status not in ('pending_release', 'active', 'funded') then
    raise exception 'Escrow not in a releasable state';
  end if;
  -- Record the release entry
  insert into public.escrow_entries(escrow_id, entry_type, amount, description)
  values (v_escrow.id, 'release_to_mechanic', v_escrow.balance_held, 'Customer confirmed completion');
  -- Mark released
  update public.job_escrow
  set status       = 'released',
      released_at  = now(),
      released_via = 'customer_confirm'
  where id = v_escrow.id;
end;
$$;
