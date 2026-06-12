# Production Readiness — Status & Remaining Tasks

Living checklist from the deep production-readiness scans (server, client,
API contracts, services layer, DB connection handling, client state/storage).
Server claims below are verified by the test suite (638 passing); client
changes follow existing patterns but **need an Xcode build to verify**.

## Fixed and verified (server)

- **Auth**: `/auth/validate` returns 401 + error codes on missing/invalid
  tokens (was 200). JWT secret/config fail-fast, receipt verification, WAL,
  rate-limiter JWT keying all in via the payments-hardening line.
- **DB integrity**: `upsert_user` and admin `grant-pro` are atomic
  `ON CONFLICT` upserts (no check-then-insert races). All identified
  connection-leak sites wrapped in `try/finally` (admin grant-pro/list-users,
  temple contact-filter log, pooja list, pandit list, user/pandit bookings,
  vedic library, booking create). Hot paths (auth/chat/horoscope/discover and
  all `db.py` helpers) audited clean.
- **Payload safety**: `MAX_CONTENT_LENGTH` (1 MB, `MAX_CONTENT_LENGTH_BYTES`
  env) → 413 on oversized bodies. Admin `limit`/`offset` validated → 400.
- **Services**: LLM calls (Gemini/OpenAI) have a 30 s timeout
  (`LLM_REQUEST_TIMEOUT_SECONDS`) so a hung provider can't pin workers.
  Missing moon longitude now raises instead of silently computing dashas
  from 0° Aries.
- **Logging**: curated-content loaders use `logger.warning` (not `print`);
  admin log no longer contains email PII; `LOG_LEVEL` env respected.

## Written, needs Xcode build to verify (client)

- 402 → `NetworkError.paymentRequired` and paywall routing (see
  `CLIENT_PAYMENT_VERIFICATION.md`).
- `validateStoredToken` now acts on the server's verdict: explicit rejection
  goes through `handleTokenExpiry()` (refresh with backoff) instead of being
  ignored; `validateToken()` only maps auth rejections to `false` and lets
  transient errors propagate (no sign-out while offline).
- Keychain JWT store: duplicate-item retry + production analytics event on
  failure (was DEBUG-only logging).
- Decoding failures report the failing coding path (never values) to
  analytics, making schema drift diagnosable in production.
- StoreKit empty-product result tracked in analytics.

## Remaining backlog (triaged, not yet done)

### Client — needs deliberate design, not mechanical fixes
1. **Sensitive data in UserDefaults** (HIGH): `user_email`, `user_full_name`,
   `apple_user_id` (RootView), birth data drafts (@AppStorage), and the full
   profile JSON (`user_profile`) are unencrypted. Decide: Keychain migration
   for identity fields; birth data is app-functional and lower risk but
   GDPR-relevant.
2. **No schema version on persisted models** (HIGH): `UserProfile`,
   `GamificationManager.PersistedState`, journal/decision stores decode with
   `try?` — a future field change silently wipes user data. Add
   `schemaVersion` + migration decode before the next model change ships.
3. **`OracleQuotaManager` is `nonisolated(unsafe)`** (HIGH): quota/credit
   mutations are not synchronized. Annotate `@MainActor` (requires fixing
   call sites — compile needed).
4. **Silent `try?` decodes** (MEDIUM): journal drafts, gamification state,
   home-guidance cache — add logging/analytics on decode failure.
5. **Task lifecycle** (MEDIUM): fire-and-forget `Task {}` in `AuthState`,
   un-stored URLSession tasks in `AstronovaFlags`, analytics flush
   serialization.
6. **UX error states** (MEDIUM): Discover snapshot error/retry state, chat
   error specificity, location search can't distinguish "no results" from
   "network error" (5 call sites), purchase-failure reasons.

### Server — accepted/deferred
- `get_pooja_type`/`get_pandit`/`get_booking` parse stored JSON after the
  connection closes — a corrupt row 500s but doesn't leak; acceptable.
- Error-response envelope is not fully uniform across blueprints (most use
  `{"error","code"}`); standardize opportunistically.
- Transit-strength clamp & nakshatra boundary use defensive `min()` — audited,
  correct as written.

### Needs human / external resources
- Xcode build + TestFlight verification of all client changes.
- Apple sandbox E2E: purchase → entitlement → refund.
- Render env values: `APPLE_ROOT_CA_PEM`, webhook registration (templated in
  `render.yaml`).
- hi/ta/te/bn paywall translations.

## False positives from agent scans (do not re-flag)
- `/health` exists (`app.py:519`, plus `/api/v1/health`).
- Ephemeris cache is bounded (evicts per insert under `_CACHE_LOCK`) and its
  datetimes are uniformly naive-UTC.
- `db.py` `delete_user_data` f-string interpolates a hardcoded table list —
  not injectable.
- Report PDF failures ARE surfaced (`pdfError` rendered in
  `ReportDetailView`).
- No unguarded `print()` in client release code (swept mechanically).
