drop trigger if exists profiles_guard_account_type on public.profiles;
create trigger profiles_guard_account_type
  before update on public.profiles
  for each row execute function public.guard_account_type();

drop trigger if exists pandit_profiles_require_purohit on public.pandit_profiles;
create trigger pandit_profiles_require_purohit
  before insert on public.pandit_profiles
  for each row execute function public.guard_pandit_account_type();
