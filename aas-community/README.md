# AAS Community 🐧

A private, invite-and-verify community for everyone who attended the
Anglo-American School of Moscow — students, faculty, and staff. Members are
**Penguins**. *Once a Penguin, Always a Penguin.*

This app is built to the [Technical Build Brief](#). It is **not** a normal
social app: the school closed in 2023 and is listed as a "foreign agent" by the
Russian state, so **privacy and verification are load-bearing, not features.**

> Scope: parent profiles are out of scope. Roles are `student`, `faculty`, `staff`.

---

## What's built (Phase 1)

| Area | Brief | Status |
|---|---|---|
| Data model + label derivation | §3, §4.1 | ✅ `member` + `attendance_span` spine; Phase 2 schema scaffolded |
| Conventional auth | §1, §4.1 | ✅ Auth.js (email/password + Google/Apple), no custom crypto |
| Threshold (login + loading) | §4.1 | ✅ motto, intentional hold, "Welcome back" |
| Verification ("Confirmed as a Penguin") | §3.3, §4.2 | ✅ vouch threshold + era-corroboration → admin review, founder trust root |
| Verification gate | §1, §4.8 | ✅ single chokepoint; unverified see onboarding + request only |
| Profiles | §4.3 | ✅ role-aware, per-entry visibility, pseudonyms |
| Directory | §4.4 | ✅ name search + era-overlap / role / city / class filters |
| Hall of Flags (map) | §4.5 | ✅ city-level pins only, tap-a-city, stale-city nudge |
| Library (archive) | §4.6 | ✅ upload yearbooks/photos, browse by era, crowdsourced tagging w/ opt-out, verified-only image serving |
| Cafeteria (chat) | §4.7 | ✅ DMs + groups, message-request gating, cohort-seeded chats, friends graph |
| Privacy substrate | §1, §4.8 | ✅ city-level location, gate, per-item visibility, message requests, tagging opt-out, export/delete |

Phase 2 entities (gatherings, feed, store, mentorship — §3.7) have schema defined
now and are **gated behind a real verified-member count**, never a date (§5.1).

---

## Hard constraints honored (§1)

- **Data residency** — `.env.example` documents non-Russian regions for DB and
  object store; no infra choice in code ties it to Russian jurisdiction.
- **Location granularity** — only city + country are stored. The map uses a
  city-**centroid** lookup (`src/lib/cities.ts`); precise coordinates are never
  stored or exposed.
- **Verification gate** — `src/lib/gate.ts` (`requireVerified`) guards every
  sensitive page and API route. Unverified accounts get onboarding + `/verify`.
- **Default-private** — `noindex` headers on every response (`next.config.mjs`),
  whole app behind auth, archive images served only through an authenticated
  route that re-checks the gate.
- **Two privacy rings** — every shareable item carries `friends` /
  `verified_members` / `hidden` (`src/lib/visibility.ts`).
- **Message requests** — no unsolicited DM reaches the inbox; first contact from
  a non-friend raises a request (`/api/chat/dm`).
- **Pseudonymity** — `legalName` (private, for verification) is separate from
  `displayName` (shown).
- **Tagging opt-out** — honored both prospectively (tag creation checks the flag)
  and retroactively (existing tags hidden on read).
- **Auditable verification, ordinary auth** — Auth.js, bcrypt; no custom crypto.
- **Deletion & export** — `/api/account/export`, `/api/account/delete` (cascades).

---

## Stack

Next.js (App Router, TypeScript) · PostgreSQL via Prisma · Auth.js · Tailwind ·
S3-compatible object store (local filesystem fallback in dev) · polling-based
real-time chat (transport is swappable for WebSocket / managed pub-sub).

---

## Running locally

```bash
cd aas-community
cp .env.example .env            # set DATABASE_URL, AUTH_SECRET, etc.
npm install                     # see "Offline note" below if engine download fails
npx prisma migrate dev          # create the schema
npm run db:seed                 # seed the first cohort (dev data)
npm run dev                     # http://localhost:3000
```

**Seeded accounts** (password `penguin123`):
`founder@aas.example` is the admin / trust root. `alex@`, `nadia@`, `james@`,
`sara@`, `dmitry@` are verified; `lena@`, `tom@` are pending (seeking vouches).

### Offline / proxied environments

If `npm install` can't download Prisma engines, install with `--ignore-scripts`,
then provide the engines and run `prisma generate` pointing at them via
`PRISMA_QUERY_ENGINE_LIBRARY` / `PRISMA_SCHEMA_ENGINE_BINARY`.

---

## Project map

```
prisma/schema.prisma        # the spine + Phase 2 schema
src/lib/                     # gate, auth, labels, visibility, verification, cities, storage, chat
src/app/                     # threshold (/), onboarding, verify, admin, vouch
src/app/(app)/              # gated area: dashboard, directory, members, map, library, chat, settings
src/app/api/                # register, onboarding, verification, friends, chat, archive, settings, account
src/components/             # client components
```

See `VERIFY.md` for how this build was verified.
