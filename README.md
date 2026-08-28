# Purohit Marketplace

Two-sided marketplace connecting Indian families with verified Hindu priests
(Purohits / Pandits).

## Stack

| Layer | Choice | Why |
|---|---|---|
| App | **Flutter** (Riverpod + go_router) | One codebase → Android **and** iOS |
| Database + Auth + Storage | **Supabase** (managed, `ap-south-1` Mumbai) | Postgres with Row Level Security as the enforcement boundary |
| Cache / locks | **Upstash Redis** (REST over HTTPS) | Serverless, no port to expose |
| Backend (later) | Azure VM, Docker | Only for webhooks, FCM, cron, Antyeshti broadcast |
| CI — Android | GitHub-hosted Linux (free on public repos) | |
| CI — iOS | GitHub-hosted `macos-14` | iOS **cannot** build on Linux or an Azure VM |

## Security model — read this first

Authorization lives in **Postgres RLS policies**, not in app code.

- Flutter uses the **anon key** only. Every query is filtered by RLS.
- The **`service_role` key bypasses all RLS.** It must never appear in the
  Flutter bundle, in this repo, or in any client-visible env var. Backend only.
- User role is stored in `auth.users.raw_app_meta_data`, **never** as a
  `profiles.role` column — a column would let a user promote themselves to admin.
- Contact details live in `auth.users` and are exposed only through the
  `v_job_contacts` view, gated on `applications.status = 'selected'`. Leaking
  them earlier enables disintermediation, which kills the commission model.
- Certificates live in a **private** Storage bucket at `{pandit_id}/{uuid}`,
  served via short-lived signed URLs.

## Setup

1. Create the Supabase project in **Mumbai (`ap-south-1`)**.
2. Run `supabase/migrations/0001_init.sql`, then `0002_seed_rituals.sql`.
3. Copy `.env.example` → `.env` and fill in the URL + anon key.
4. `flutter create . --project-name purohit --platforms=android,ios && flutter run`

## Schema — 13 tables

`profiles` · `cities` · `pandit_profiles` · `certificates` · `guru_references` ·
`ritual_groups` · `rituals` · `pandit_rituals` · `jobs` · `applications` ·
`verification_events` · `device_tokens` · `reviews`

### Ritual taxonomy

`skills` and `services` in the original spec **overlapped** — Griha Pravesh,
Rudrabhishek, Vastu Puja, Ramayan Path, Sunderkand and the 16 Sanskars appeared
in both, with separate IDs and no join — so "given a job's ritual, find matching
purohits" was unanswerable. They are merged into one **`rituals`** table with
`bookable` / `claimable` flags and a soft `ritual_groups` FK.

- All **16 Sanskars are individual rows**; grouping is UI-only (two-level
  accordion). The set of 16 is *not* canonical — Wikipedia, Swaminarayan-Kalupur
  and VHP publish three different lists — so it is data, never a Dart enum.
- `rituals.aliases text[]` + GIN index is mandatory: families type "mundan",
  "janoi", "godh bharai", not the Sanskrit name.
- **Antyeshti** (funeral) breaks the post → bid → compare flow. A grieving family
  cannot run an auction. It ships with `bookable = false` until the
  `jobs.urgency = 'immediate'` broadcast path exists.
- **Vivaha** is multi-day → `jobs.end_date`.

## Roadmap

- [x] Repo + CI green on Android and iOS
- [x] Supabase project (Mumbai) + run migrations
- [ ] Auth (email OTP — see below)
- [ ] Purohit onboarding + certificate upload
- [ ] Verification queue (a small web page, **not** a 9-screen Flutter admin app)
- [ ] Job post → apply → select
- [ ] Azure VM + backend (webhooks, FCM, cron)

### ⚠️ Phone OTP is blocked

Indian SMS requires **DLT/TRAI PE registration**, which needs business KYC
(PAN / GST / incorporation) — realistically **6–12 weeks**, not 2. Launch with
**email OTP behind an `AuthChannel` abstraction** and start the paperwork in
parallel.
