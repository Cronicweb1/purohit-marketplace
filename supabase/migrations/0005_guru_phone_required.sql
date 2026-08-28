-- 0005_guru_phone_required.sql
-- A guru reference is only worth anything if an admin can actually ring the
-- guru. `guru_phone` was nullable and the UI labelled it "(optional)", so the
-- whole verification path could be satisfied with an unverifiable name.
--
-- Existing NULL rows are backfilled with a sentinel rather than deleted: the
-- rows belong to real purohits mid-verification, and deleting them would drop
-- their only proof of training. Admin sees the sentinel and asks for a number.

update public.guru_references
set guru_phone = 'not-provided'
where guru_phone is null or btrim(guru_phone) = '';

alter table public.guru_references
  alter column guru_phone set not null;

alter table public.guru_references
  drop constraint if exists guru_references_phone_len;
alter table public.guru_references
  add constraint guru_references_phone_len
  check (char_length(btrim(guru_phone)) between 8 and 20);
