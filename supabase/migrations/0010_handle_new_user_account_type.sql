-- The signup trigger now reads the role and phone the client sent as signup
-- metadata, so the profile row is born with the correct account_type instead
-- of being patched afterwards.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  insert into public.profiles (id, full_name, account_type, phone)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'full_name', ''), 'New user'),
    case when new.raw_user_meta_data ->> 'account_type' = 'purohit'
         then 'purohit' else 'family' end,
    nullif(new.raw_user_meta_data ->> 'phone', '')
  )
  on conflict (id) do nothing;
  return new;
end; $function$;
