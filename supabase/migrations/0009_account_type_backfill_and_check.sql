-- Existing accounts predate the column, so derive their type from the only
-- signal that existed at the time: whether they own a pandit_profiles row.
update public.profiles p
   set account_type = 'purohit'
 where exists (select 1 from public.pandit_profiles pp where pp.id = p.id)
   and p.account_type <> 'purohit';

alter table public.profiles
  drop constraint if exists profiles_account_type_check;

alter table public.profiles
  add constraint profiles_account_type_check
  check (account_type in ('family', 'purohit'));
