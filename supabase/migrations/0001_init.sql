-- Purohit Marketplace — hardened schema (13 tables)
-- Run in the Supabase SQL Editor, or via `supabase db push`.
--
-- DESIGN RULES
--  1. NO `profiles.role` column. Role lives in auth.users.raw_app_meta_data and
--     is read via the JWT. A column would let a user promote themselves.
--  2. NO verified_by / verified_at columns. Verification is an append-only log
--     (`verification_events`) because purohits get rejected and resubmit.
--  3. Contact details stay in auth.users, exposed only via `v_job_contacts`,
--     gated on applications.status = 'selected'.
--  4. `skills` + `services` are merged into `rituals` — they overlapped and
--     nothing joined them.

create extension if not exists "pgcrypto";
create extension if not exists "pg_trgm";

-- ---------------------------------------------------------------- enums
create type verification_status as enum ('pending','under_review','approved','rejected');
create type application_status  as enum ('applied','shortlisted','selected','rejected','withdrawn');
create type job_status          as enum ('open','assigned','completed','cancelled');
create type job_urgency         as enum ('flexible','scheduled','immediate');
create type certificate_kind    as enum ('gurukul','degree','other');
create type device_platform     as enum ('android','ios','web');

-- ------------------------------------------------------------ role helpers
-- SECURITY DEFINER + fixed search_path: cannot be shadowed by the caller.
create or replace function public.auth_role()
returns text language sql stable security definer set search_path = public, auth as $$
  select coalesce(
    nullif(current_setting('request.jwt.claims', true)::jsonb #>> '{app_metadata,role}', ''),
    'user'
  );
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select public.auth_role() = 'admin';
$$;

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

-- ---------------------------------------------------------------- 1. cities
-- Replaces the free-text `location` field. Radius search IS the product.
create table cities (
  id          bigserial primary key,
  name        text not null,
  state       text not null,
  country     text not null default 'IN',
  lat         double precision not null,
  lng         double precision not null,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  unique (name, state, country)
);
create index cities_latlng_idx on cities (lat, lng);

-- -------------------------------------------------------------- 2. profiles
-- Replaces `users`. PK references auth.users; contact details stay in auth.
create table profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  full_name    text not null,
  avatar_url   text,
  city_id      bigint references cities(id),
  locale       text not null default 'en',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create trigger profiles_touch before update on profiles
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------- 3. pandit_profiles
create table pandit_profiles (
  id                  uuid primary key references profiles(id) on delete cascade,
  bio                 text,
  experience_years    int check (experience_years between 0 and 90),
  city_id             bigint references cities(id),
  service_radius_km   int not null default 25 check (service_radius_km between 1 and 500),
  languages           text[] not null default '{}',
  base_fee            numeric(10,2) check (base_fee >= 0),
  currency            char(3) not null default 'INR',
  status              verification_status not null default 'pending',
  is_available        boolean not null default true,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);
create index pandit_profiles_status_idx on pandit_profiles(status);
create index pandit_profiles_city_idx   on pandit_profiles(city_id);
create trigger pandit_profiles_touch before update on pandit_profiles
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------- 4. certificates
-- Files live in a PRIVATE Storage bucket at {pandit_id}/{uuid}. Only the path.
create table certificates (
  id                bigserial primary key,
  pandit_id         uuid not null references pandit_profiles(id) on delete cascade,
  kind              certificate_kind not null default 'gurukul',
  institution       text not null,
  issued_on         date,
  storage_provider  text not null default 'supabase',
  storage_path      text not null,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index certificates_pandit_idx on certificates(pandit_id);
create trigger certificates_touch before update on certificates
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------- 5. guru_references
-- Second verification path, for purohits with no formal Gurukul certificate.
create table guru_references (
  id            bigserial primary key,
  pandit_id     uuid not null references pandit_profiles(id) on delete cascade,
  guru_name     text not null,
  guru_phone    text,
  gurukul_name  text,
  years_studied int check (years_studied between 0 and 90),
  notes         text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index guru_references_pandit_idx on guru_references(pandit_id);
create trigger guru_references_touch before update on guru_references
  for each row execute function public.touch_updated_at();

-- --------------------------------------------------------- 6. ritual_groups
-- SOFT grouping only (e.g. "16 Sanskars"). The UI expands it; a booking is
-- never stored against a group. The set of 16 is not canonical, so it is data.
create table ritual_groups (
  id          bigserial primary key,
  slug        text not null unique,
  name        text not null,
  description text,
  sort_order  int not null default 0
);

-- --------------------------------------------------------------- 7. rituals
-- MERGE of the old `skills` + `services`, which overlapped.
--   bookable  = a family can post a job for it
--   claimable = a purohit can list it as a specialisation
-- Vedic Knowledge / Jyotishacharya / Kathavachak / Karmakandi are
-- specialisations: claimable = true, bookable = false.
create table rituals (
  id            bigserial primary key,
  slug          text not null unique,
  name          text not null,
  name_hi       text,
  aliases       text[] not null default '{}',
  group_id      bigint references ritual_groups(id) on delete set null,
  bookable      boolean not null default true,
  claimable     boolean not null default true,
  typical_duration_minutes int,
  is_multi_day  boolean not null default false,
  is_active     boolean not null default true,
  sort_order    int not null default 0,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
-- Families search "mundan" / "janoi" / "godh bharai", never the Sanskrit name.
create index rituals_aliases_gin on rituals using gin (aliases);
create index rituals_name_trgm   on rituals using gin (name gin_trgm_ops);
create trigger rituals_touch before update on rituals
  for each row execute function public.touch_updated_at();

-- -------------------------------------------------------- 8. pandit_rituals
create table pandit_rituals (
  id         bigserial primary key,
  pandit_id  uuid   not null references pandit_profiles(id) on delete cascade,
  ritual_id  bigint not null references rituals(id) on delete cascade,
  fee        numeric(10,2) check (fee >= 0),
  currency   char(3) not null default 'INR',
  created_at timestamptz not null default now(),
  unique (pandit_id, ritual_id)
);

-- ------------------------------------------------------------------ 9. jobs
create table jobs (
  id                      bigserial primary key,
  family_id               uuid not null references profiles(id) on delete cascade,
  ritual_id               bigint references rituals(id) on delete set null,
  city_id                 bigint references cities(id),
  title                   text not null,
  description             text,
  address_line            text,
  lat                     double precision,
  lng                     double precision,
  start_date              date not null,
  end_date                date,                 -- Vivaha is multi-day
  urgency                 job_urgency not null default 'scheduled',
  budget                  numeric(10,2) check (budget >= 0),
  currency                char(3) not null default 'INR',
  status                  job_status not null default 'open',
  selected_application_id bigint,               -- FK added after applications
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),
  constraint jobs_dates_ck check (end_date is null or end_date >= start_date)
);
create index jobs_status_idx  on jobs(status);
create index jobs_ritual_idx  on jobs(ritual_id);
create index jobs_city_idx    on jobs(city_id);
create index jobs_urgency_idx on jobs(urgency) where urgency = 'immediate';
create trigger jobs_touch before update on jobs
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------- 10. applications
create table applications (
  id          bigserial primary key,
  job_id      bigint not null references jobs(id) on delete cascade,
  pandit_id   uuid   not null references pandit_profiles(id) on delete cascade,
  message     text,
  quoted_fee  numeric(10,2) check (quoted_fee >= 0),
  currency    char(3) not null default 'INR',
  status      application_status not null default 'applied',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (job_id, pandit_id)          -- one application per purohit per job
);
create index applications_job_idx    on applications(job_id);
create index applications_pandit_idx on applications(pandit_id);
create trigger applications_touch before update on applications
  for each row execute function public.touch_updated_at();

alter table jobs
  add constraint jobs_selected_application_fk
  foreign key (selected_application_id) references applications(id) on delete set null;

-- --------------------------------------------------- 11. verification_events
-- APPEND-ONLY. No updates, no deletes — purohits resubmit after rejection and
-- the full history must survive.
create table verification_events (
  id          bigserial primary key,
  pandit_id   uuid not null references pandit_profiles(id) on delete cascade,
  from_status verification_status,
  to_status   verification_status not null,
  actor_id    uuid references auth.users(id),
  reason      text,
  created_at  timestamptz not null default now()
);
create index verification_events_pandit_idx on verification_events(pandit_id, created_at desc);

-- ---------------------------------------------------------- 12. device_tokens
create table device_tokens (
  id           bigserial primary key,
  user_id      uuid not null references profiles(id) on delete cascade,
  token        text not null unique,
  platform     device_platform not null,
  last_seen_at timestamptz not null default now(),
  created_at   timestamptz not null default now()
);
create index device_tokens_user_idx on device_tokens(user_id);

-- ---------------------------------------------------------------- 13. reviews
create table reviews (
  id          bigserial primary key,
  job_id      bigint not null references jobs(id) on delete cascade,
  family_id   uuid not null references profiles(id) on delete cascade,
  pandit_id   uuid not null references pandit_profiles(id) on delete cascade,
  rating      int not null check (rating between 1 and 5),
  comment     text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (job_id, family_id)
);
create index reviews_pandit_idx on reviews(pandit_id);
create trigger reviews_touch before update on reviews
  for each row execute function public.touch_updated_at();

-- ============================================================ RLS
alter table profiles            enable row level security;
alter table pandit_profiles     enable row level security;
alter table certificates        enable row level security;
alter table guru_references     enable row level security;
alter table cities              enable row level security;
alter table ritual_groups       enable row level security;
alter table rituals             enable row level security;
alter table pandit_rituals      enable row level security;
alter table jobs                enable row level security;
alter table applications        enable row level security;
alter table verification_events enable row level security;
alter table device_tokens       enable row level security;
alter table reviews             enable row level security;

-- Public reference data: readable by anyone, writable only by admins.
create policy cities_read   on cities        for select using (true);
create policy groups_read   on ritual_groups for select using (true);
create policy rituals_read  on rituals       for select using (is_active or public.is_admin());
create policy cities_admin  on cities        for all using (public.is_admin()) with check (public.is_admin());
create policy groups_admin  on ritual_groups for all using (public.is_admin()) with check (public.is_admin());
create policy rituals_admin on rituals       for all using (public.is_admin()) with check (public.is_admin());

-- profiles: everyone reads (names/avatars are public); you edit only your own.
create policy profiles_read   on profiles for select using (true);
create policy profiles_insert on profiles for insert with check (id = auth.uid());
create policy profiles_update on profiles for update
  using (id = auth.uid()) with check (id = auth.uid());

-- pandit_profiles: only APPROVED purohits are publicly visible.
create policy pandit_public_read on pandit_profiles for select
  using (status = 'approved' or id = auth.uid() or public.is_admin());
create policy pandit_self_insert on pandit_profiles for insert with check (id = auth.uid());
create policy pandit_self_update on pandit_profiles for update
  using (id = auth.uid() or public.is_admin());

-- `status` must not be self-editable, even though the row is self-updatable.
create or replace function public.guard_pandit_status()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status is distinct from old.status and not public.is_admin() then
    raise exception 'status is changed only by an admin, via verification_events';
  end if;
  return new;
end; $$;
create trigger pandit_status_guard before update on pandit_profiles
  for each row execute function public.guard_pandit_status();

-- certificates / guru_references: strictly owner + admin. Never public.
create policy certs_owner on certificates for all
  using (pandit_id = auth.uid() or public.is_admin())
  with check (pandit_id = auth.uid());
create policy guru_owner on guru_references for all
  using (pandit_id = auth.uid() or public.is_admin())
  with check (pandit_id = auth.uid());

-- pandit_rituals: publicly readable, owner-writable.
create policy pr_read  on pandit_rituals for select using (true);
create policy pr_write on pandit_rituals for all
  using (pandit_id = auth.uid() or public.is_admin())
  with check (pandit_id = auth.uid());

-- jobs: open jobs visible to approved purohits; families always see their own.
create policy jobs_read on jobs for select using (
  family_id = auth.uid()
  or public.is_admin()
  or (status = 'open' and exists (
        select 1 from pandit_profiles p
        where p.id = auth.uid() and p.status = 'approved'))
);
create policy jobs_insert on jobs for insert with check (family_id = auth.uid());
create policy jobs_update on jobs for update
  using (family_id = auth.uid() or public.is_admin());

-- applications: visible to the applying purohit and the job's family only.
create policy apps_read on applications for select using (
  pandit_id = auth.uid()
  or public.is_admin()
  or exists (select 1 from jobs j where j.id = job_id and j.family_id = auth.uid())
);
create policy apps_insert on applications for insert with check (
  pandit_id = auth.uid()
  and exists (select 1 from pandit_profiles p
              where p.id = auth.uid() and p.status = 'approved')
);
create policy apps_update on applications for update using (
  pandit_id = auth.uid()
  or public.is_admin()
  or exists (select 1 from jobs j where j.id = job_id and j.family_id = auth.uid())
);

-- verification_events: readable by the purohit and admins. Writes are admin
-- only (in practice the backend, using service_role). Append-only.
create policy ve_read   on verification_events for select
  using (pandit_id = auth.uid() or public.is_admin());
create policy ve_insert on verification_events for insert
  with check (public.is_admin());

-- device_tokens: strictly private to the user.
create policy dt_owner on device_tokens for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- reviews: public read; the family writes for its own job.
create policy reviews_read  on reviews for select using (true);
create policy reviews_write on reviews for all
  using (family_id = auth.uid() or public.is_admin())
  with check (family_id = auth.uid());

-- ================================================== contact disclosure gate
-- THE COMMISSION MODEL DEPENDS ON THIS. Contact details are released only
-- once an application reaches 'selected'.
create or replace view v_job_contacts
with (security_invoker = true) as
select
  a.job_id,
  a.pandit_id,
  j.family_id,
  fu.phone as family_phone,
  fu.email as family_email,
  pu.phone as pandit_phone,
  pu.email as pandit_email
from applications a
join jobs j        on j.id = a.job_id
join auth.users fu on fu.id = j.family_id
join auth.users pu on pu.id = a.pandit_id
where a.status = 'selected'
  and (a.pandit_id = auth.uid() or j.family_id = auth.uid());

-- ================================================== new-user bootstrap
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', 'New user'))
  on conflict (id) do nothing;
  return new;
end; $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
