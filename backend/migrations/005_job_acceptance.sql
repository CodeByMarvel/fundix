-- Run in Supabase SQL Editor AFTER migration 004
-- Adds mechanic job acceptance and post-inspection escrow release.

-- ── requests: inspection tracking ────────────────────────────────────────────
-- 'inspection_complete' status: Stage 1 done, callout fee releasing, awaiting Stage 2 decision
alter table public.requests
  add column if not exists inspection_completed_at timestamptz;

-- ── RPC: mechanic marks inspection done — releases callout fee to themselves ──
-- Separate from complete_job (Stage 2). Moves request to 'inspection_complete'
-- and starts the auto-release buffer on the Stage 1 escrow.
create or replace function complete_inspection(
  p_request_id            uuid,
  p_release_after_minutes integer default 2
)
returns void language plpgsql security definer as $$
begin
  update public.requests
  set status                   = 'inspection_complete',
      inspection_completed_at  = now()
  where id     = p_request_id
    and status = 'accepted';

  if not found then
    raise exception 'Request % is not in accepted status', p_request_id;
  end if;

  update public.job_escrow
  set status          = 'pending_release',
      auto_release_at = now() + (p_release_after_minutes || ' minutes')::interval
  where request_id = p_request_id
    and status     = 'active';
end;
$$;
