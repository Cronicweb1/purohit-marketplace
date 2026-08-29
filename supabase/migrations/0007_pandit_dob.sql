-- 0007_pandit_dob.sql
--
-- Date of birth for purohits.
--
-- Nullable on purpose: purohits registered before this migration have no DOB
-- and locking them out of their own profile would be worse than a gap in the
-- record. New registrations require it in the client.
--
-- The 18+ rule is enforced in the app (the date picker cannot offer a younger
-- date) rather than as a CHECK: a CHECK would have to call current_date, which
-- is only STABLE, and a hard-coded cut-off year silently starts rejecting valid
-- adults a few years from now. The only constraint here is a sanity floor.

alter table public.pandit_profiles
  add column if not exists dob date;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'pandit_dob_sane'
  ) then
    alter table public.pandit_profiles
      add constraint pandit_dob_sane
      check (dob is null or dob >= date '1900-01-01');
  end if;
end $$;

comment on column public.pandit_profiles.dob is
  'Date of birth. Nullable for rows created before 0007. The client enforces 18+.';
