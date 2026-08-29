-- The other half of one-email-one-role: a family account can never grow a
-- purohit listing, no matter which client calls the insert.
create or replace function public.guard_pandit_account_type()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if not exists (
    select 1 from public.profiles p
     where p.id = new.id and p.account_type = 'purohit'
  ) then
    raise exception 'this email is registered as a family account and cannot also be a purohit';
  end if;
  return new;
end; $function$;
