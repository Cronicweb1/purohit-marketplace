-- user_metadata is client-writable, so account_type would be trivially
-- forgeable if the profiles row could be edited after signup. This closes
-- that hole: the value is permanent for everyone except an admin.
create or replace function public.guard_account_type()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if new.account_type is distinct from old.account_type and not public.is_admin() then
    raise exception 'account_type is permanent: this email is already registered as a % account', old.account_type;
  end if;
  return new;
end; $function$;
