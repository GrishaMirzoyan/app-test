# Verification log

How the AAS Community build was checked. All steps were run against Node 22,
Postgres 16, and the patched `next@15.5.19`.

## Automated

| Check | Command | Result |
|---|---|---|
| Unit tests (label derivation + era-overlap) | `npm test` | ✅ 9/9 passing |
| Type-check + production build | `npm run build` | ✅ 31 routes compiled, type-check clean |
| Prisma schema valid + migrated | `npx prisma migrate dev` | ✅ `init` migration applied |
| Seed | `npm run db:seed` | ✅ 8 members + DM + archive items |

## Manual smoke test (against `next start`)

| Scenario | Expectation | Result |
|---|---|---|
| `GET /` | 200, `X-Robots-Tag: noindex` present | ✅ |
| `GET /dashboard` unauthenticated | 307 → `/` | ✅ |
| `GET /api/archive/image/...` unauthenticated | 403 | ✅ |
| Register + credentials sign-in | session shows member, `pending` | ✅ |
| Pending member → `GET /api/members/search` | 307 → `/verify` (gate) | ✅ |
| Verified member → member search | returns results (`Alum · Class of 2013`) | ✅ |
| Cohort chat for 2010 | group seeded with 6 era-overlapping members | ✅ |
| Vouch threshold (2) | 1 vouch → still pending; 2nd vouch → auto-verified | ✅ |

## Constraint spot-checks

- **City-level only** — onboarding/settings store `homeCity`/`homeCountry`; map
  pins resolve from `src/lib/cities.ts` centroids; no precise coordinates exist
  in the schema or UI.
- **Verification gate** — confirmed both at the page layer (`(app)/layout.tsx`)
  and the API layer (`requireVerified` redirects pending users).
- **Message-request gating** — `POST /api/chat/dm` returns `{requested:true}`
  for non-friends instead of delivering a message.
- **Tagging opt-out** — `POST /api/archive/[id]/tag` rejects tagging a member
  with `allowFaceTagging=false`; the item page filters such tags on read.
- **Export/delete** — `/api/account/export` returns JSON (password hash
  stripped); `/api/account/delete` cascades.

## Not covered here

- OAuth (Google/Apple) requires real provider credentials; the email/password
  path is exercised instead.
- Real-time chat uses polling in dev; the production transport (WebSocket /
  managed pub-sub) is a drop-in with the same message shape.
- Phase 2 features (gatherings, feed, store, mentorship) are schema-only by
  design until the verified-member count trigger is reached.
