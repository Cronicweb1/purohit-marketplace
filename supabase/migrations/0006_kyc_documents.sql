-- KYC documents: a photo ID (compulsory) and an optional address proof.
--
-- Certificates and guru references already prove TRAINING. Nothing so far
-- proved IDENTITY, which is the thing a family actually needs before letting
-- someone into their home for a ceremony.

create table if not exists public.kyc_documents (
  id bigint generated always as identity primary key,

  -- NOTE: this references pandit_profiles, NOT profiles, even though
  -- pandit_profiles.id IS profiles.id. The admin queue selects FROM
  -- pandit_profiles and embeds kyc_documents(...); PostgREST can only resolve
  -- that embed through a direct foreign key to the table being selected from.
  -- Pointing this at profiles compiles fine and then fails at runtime with
  -- PGRST200, invisible to CI. certificates and guru_references both do the same.
  pandit_id uuid not null
    references public.pandit_profiles(id) on delete cascade,

  doc_role text not null
    constraint kyc_doc_role check (doc_role in ('identity', 'address')),

  doc_type text not null
    constraint kyc_doc_type check (doc_type in (
      'aadhaar', 'voter_id', 'pan', 'driving_licence', 'passport',
      'ration_card', 'electricity_bill', 'lpg_bill'
    )),

  -- The Azure Blob / S3 escape hatch. Rows carry where they live, so a future
  -- migration can move objects one at a time instead of in a big-bang cutover.
  storage_provider text not null default 'supabase',
  storage_path text not null,

  mime_type text,
  size_bytes integer,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- A bill is not an ID; a PAN card has no address on it and a passport or
  -- licence address is usually years stale.
  constraint kyc_type_matches_role check (
    (doc_role = 'identity' and doc_type in (
      'aadhaar', 'voter_id', 'pan', 'driving_licence', 'passport', 'ration_card'))
    or
    (doc_role = 'address' and doc_type in (
      'aadhaar', 'voter_id', 'ration_card', 'electricity_bill', 'lpg_bill'))
  )
);

-- One current document per role. Re-submitting replaces, so the client upserts
-- on (pandit_id, doc_role) rather than accumulating stale scans an admin would
-- have to guess between.
create unique index if not exists kyc_documents_one_per_role
  on public.kyc_documents (pandit_id, doc_role);

alter table public.kyc_documents enable row level security;

drop policy if exists kyc_owner on public.kyc_documents;
create policy kyc_owner on public.kyc_documents
  for all
  using (pandit_id = auth.uid() or public.is_admin())
  with check (pandit_id = auth.uid());

drop trigger if exists kyc_documents_touch on public.kyc_documents;
create trigger kyc_documents_touch
  before update on public.kyc_documents
  for each row execute function public.touch_updated_at();

-- Storage -------------------------------------------------------------------
-- Private bucket. Government ID scans must never be world-readable, so admins
-- view them through short-lived signed URLs rather than public links.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'verification-docs',
  'verification-docs',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Object keys are `<uid>/<slot>_<millis>.<ext>`; every policy below keys off
-- that first path segment.
drop policy if exists vdocs_owner_read on storage.objects;
create policy vdocs_owner_read on storage.objects
  for select
  using (
    bucket_id = 'verification-docs'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.is_admin()
    )
  );

drop policy if exists vdocs_owner_insert on storage.objects;
create policy vdocs_owner_insert on storage.objects
  for insert
  with check (
    bucket_id = 'verification-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists vdocs_owner_update on storage.objects;
create policy vdocs_owner_update on storage.objects
  for update
  using (
    bucket_id = 'verification-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists vdocs_owner_delete on storage.objects;
create policy vdocs_owner_delete on storage.objects
  for delete
  using (
    bucket_id = 'verification-docs'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.is_admin()
    )
  );
