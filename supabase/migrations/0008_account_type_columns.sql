-- Registration captures which door an account came through.
-- auth.users.email is already globally unique, so one email can only ever own
-- one account. This column records whether that account is a family or a
-- purohit; 0011 then makes the answer permanent.
alter table public.profiles
  add column if not exists account_type text not null default 'family';

alter table public.profiles
  add column if not exists phone text;
