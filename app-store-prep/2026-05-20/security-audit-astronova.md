# Astronova Security Audit — 2026-05-20

Read-only audit. Scope: git history, hardcoded secrets, dependency CVEs, network egress.

## 1. Git history — secret-leak commits

**CRITICAL — historical EC private key.** Commit `1f6048b` (2025-06-18) added `cloudkit_private_key.pem` (real `BEGIN EC PRIVATE KEY` P-256 block, 227 bytes). Deleted in `fb75892`, still reachable via `git cat-file -p 1f6048b:cloudkit_private_key.pem` on any clone. Same commit's `backend/.env.example` only has placeholders.

**Action:** rotate the CloudKit S2S key in Apple Developer (assume compromised); optionally `git filter-repo`/BFG + force-push.

No other PEM blocks, JWTs, or key prefixes (`AIza*`, `sk-*`, `ghp_*`, `AKIA*`, `xoxb-*`) found.

## 2. Hardcoded secrets in source

- `client/AstronovaApp/Info.plist:50` ships `SMARTLOOK_PROJECT_KEY` plaintext. Smartlook project keys are client-side IDs; SDK currently unlinked (`ANALYTICS_INTEGRATION.md`). Low risk; move to xcconfig.
- `server/routes/auth.py:131` falls back to `"astronova-dev-secret-change-in-production"` if both `JWT_SECRET` and `JWT_SECRET_KEY` are unset. Render auto-generates `JWT_SECRET_KEY`, but the fallback should `raise` when `FLASK_ENV=production`.
- `server/.env*` files exist locally (`0600`), correctly gitignored, never tracked.
- Apple Sign-In validation (`auth.py:103-109`) properly verifies RS256, `aud`, `iss`. No `verify=False`.

## 3. Backend dependency CVEs

`pip-audit` ran against `server/.venv` (Python 3.14) — `pip-audit` was not pre-installed; pulled via `pip install --user pip-audit 2.10.0`. **8 known vulns in 4 packages:**

| Package | Installed | IDs | Fix |
|---|---|---|---|
| cryptography | 42.0.8 | GHSA-h4gh-qq45-vh27, CVE-2024-12797, CVE-2026-26007, CVE-2026-34073 | 46.0.6 |
| pyopenssl | 25.1.0 | CVE-2026-27448, CVE-2026-27459 | 26.0.0 |
| idna | 3.13 | CVE-2026-45409 | 3.15 |
| pytest | 7.4.4 | CVE-2025-71176 | 9.0.3 (dev-only) |

`requirements.txt` pins `cryptography>=41.0.0,<43.0.0` — upper bound blocks the fixes. Bump to `>=46.0.6,<47.0.0`. `runtime.txt` pins `python-3.11.0`; bump to latest 3.11.x patch.

## 4. Network egress audit

iOS client talks to exactly four hosts:

1. **`astronova-ghcr.onrender.com`** — sole API base URL across DEBUG, simulator, Release (`Config/AppConfig.swift:27/30/34`), plus `/privacy` and `/terms` WKWebView loads. Confirmed only production backend.
2. **`apps.apple.com/account/subscriptions`** — paywall deep-link (Apple-managed).
3. **`astronova.app/help`** — marketing-site help link, not API.
4. **`meet.jit.si`** — referenced only in a doc-comment; actual URL is server-constructed and opened via UniversalLink.

Server egress: `appleid.apple.com` (JWKS), `unpkg.com` (Swagger UI assets at `/docs`, browser-only). The retired Render host references previously noted in the default CORS allowlist and session URL migration were updated to `astronova-ghcr.onrender.com` on 2026-05-27 for consistency with the current production backend.

`Info.plist` has no `NSAppTransportSecurity` exceptions — all egress HTTPS.

## Priority

1. Rotate CloudKit S2S key (historical PEM exposure).
2. Bump `cryptography` and `pyopenssl` in `requirements.txt`.
3. Make `get_jwt_secret()` fail closed in production.
4. Patch Python to latest 3.11.x.
