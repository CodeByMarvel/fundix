-- Run this in Supabase SQL Editor: Project → SQL Editor → New query

alter table public.mechanics
  add column level integer not null default 1
    check (level between 1 and 3),
  add column application_status text not null default 'pending'
    check (application_status in ('pending', 'approved', 'rejected'));

-- Mechanics that already exist in the DB (created before this migration)
-- are set to approved so they keep working.
update public.mechanics set application_status = 'approved' where true;
