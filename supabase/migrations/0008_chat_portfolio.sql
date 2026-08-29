-- 0008_chat_portfolio.sql
--
-- Three things a two-sided marketplace cannot ship without:
--   1. portfolio_items  - work photos a purohit shows to families
--   2. conversations    - one thread per (job, purohit)
--   3. messages         - the thread contents
-- plus the public `profile-media` bucket that backs avatars and portfolio
-- photos.
--
-- Chat deliberately opens BEFORE the family finalises anyone. The commission
-- gate is not the chat layer: it is the `v_job_contacts` view, which only
-- returns phone/e-mail once an application reaches `status = 'selected'`.
-- Keep it that way.

-- ---------------------------------------------------------------- portfolio
create table if not exists public.portfolio_items (
  id          bigint generated always as identity primary key,
  pandit_id   uuid not null references public.pandit_profiles(id) on delete cascade,
  object_path text not null,
  caption     text,
  sort_order  int not null default 0,
  created_at  timestamptz not null default now()
);

create index if not exists portfolio_items_pandit_idx
  on public.portfolio_items (pandit_id, sort_order);

alter table public.portfolio_items enable row level security;

-- A portfolio is a shop window: anyone may look, only the owner may change it.
drop policy if exists portfolio_read on public.portfolio_items;
create policy portfolio_read on public.portfolio_items
  for select using (true);

drop policy if exists portfolio_write on public.portfolio_items;
create policy portfolio_write on public.portfolio_items
  for all using (pandit_id = auth.uid()) with check (pandit_id = auth.uid());

-- ------------------------------------------------------------ conversations
-- client_id / pandit_id reference public.profiles rather than auth.users so
-- PostgREST can embed the counterpart's name and avatar in one round trip.
create table if not exists public.conversations (
  id              bigint generated always as identity primary key,
  job_id          bigint not null references public.jobs(id) on delete cascade,
  client_id       uuid   not null references public.profiles(id) on delete cascade,
  pandit_id       uuid   not null references public.profiles(id) on delete cascade,
  created_at      timestamptz not null default now(),
  last_message_at timestamptz not null default now(),
  unique (job_id, pandit_id)
);

alter table public.conversations enable row level security;

drop policy if exists conv_read on public.conversations;
create policy conv_read on public.conversations
  for select using (
    client_id = auth.uid() or pandit_id = auth.uid() or public.is_admin()
  );

-- Only the family opens a thread, and only with someone who actually applied.
-- That single policy is what stops the app becoming a cold-outreach channel.
drop policy if exists conv_insert on public.conversations;
create policy conv_insert on public.conversations
  for insert with check (
    client_id = auth.uid()
    and exists (
      select 1 from public.jobs j
      where j.id = conversations.job_id and j.family_id = auth.uid()
    )
    and exists (
      select 1 from public.applications a
      where a.job_id = conversations.job_id
        and a.pandit_id = conversations.pandit_id
    )
  );

drop policy if exists conv_update on public.conversations;
create policy conv_update on public.conversations
  for update using (client_id = auth.uid() or pandit_id = auth.uid());

-- ----------------------------------------------------------------- messages
create table if not exists public.messages (
  id              bigint generated always as identity primary key,
  conversation_id bigint not null references public.conversations(id) on delete cascade,
  sender_id       uuid   not null references public.profiles(id) on delete cascade,
  body            text   not null check (length(btrim(body)) > 0),
  created_at      timestamptz not null default now(),
  read_at         timestamptz
);

create index if not exists messages_conv_idx
  on public.messages (conversation_id, created_at);

alter table public.messages enable row level security;

drop policy if exists msg_read on public.messages;
create policy msg_read on public.messages
  for select using (
    exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id
        and (c.client_id = auth.uid() or c.pandit_id = auth.uid() or public.is_admin())
    )
  );

drop policy if exists msg_insert on public.messages;
create policy msg_insert on public.messages
  for insert with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id
        and (c.client_id = auth.uid() or c.pandit_id = auth.uid())
    )
  );

-- Update exists so the *recipient* can stamp read_at.
drop policy if exists msg_update on public.messages;
create policy msg_update on public.messages
  for update using (
    exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id
        and (c.client_id = auth.uid() or c.pandit_id = auth.uid())
    )
  );

-- Sorting an inbox by "most recent activity" without this trigger means an
-- aggregate over every message on every list render.
create or replace function public.bump_conversation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.conversations
     set last_message_at = new.created_at
   where id = new.conversation_id;
  return new;
end;
$$;

drop trigger if exists messages_bump_conversation on public.messages;
create trigger messages_bump_conversation
  after insert on public.messages
  for each row execute function public.bump_conversation();

-- ------------------------------------------------------------------ storage
-- Public, unlike `verification-docs`: an avatar shown to strangers cannot sit
-- behind a 5-minute signed URL without re-signing on every list render.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('profile-media', 'profile-media', true, 5242880,
        array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
  set public = true,
      file_size_limit = 5242880,
      allowed_mime_types = array['image/jpeg','image/png','image/webp'];

drop policy if exists profile_media_read on storage.objects;
create policy profile_media_read on storage.objects
  for select using (bucket_id = 'profile-media');

drop policy if exists profile_media_insert on storage.objects;
create policy profile_media_insert on storage.objects
  for insert with check (
    bucket_id = 'profile-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists profile_media_update on storage.objects;
create policy profile_media_update on storage.objects
  for update using (
    bucket_id = 'profile-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists profile_media_delete on storage.objects;
create policy profile_media_delete on storage.objects
  for delete using (
    bucket_id = 'profile-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
