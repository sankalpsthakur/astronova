# Astronova — Category #1 + Production Readiness Roadmap

**Date:** 2026-07-12
**Category:** Consumer Vedic/Western astrology habit apps
**Competitors:** Co–Star, The Pattern, CHANI, Sanctuary, Nebula, TimePassages, Astrotalk
**Git:** `https://github.com/sankalpsthakur/astronova.git`
**Branch truth:** `appstore/wave2-astronova` (+ untracked `tests/*` story packets)
**#1 thesis:** Authentic Vedic timing + calm daily decision UX + ethical AI/report monetization — not dark-pattern freemium.

## Local git state
- Branch: `appstore/wave2-astronova` (not `main`; local main behind origin)
- Untracked: `tests/ceetrix-astronova-app-store-story-packet.md`, release/payments e2e proof md
- Fold untracked packets into App Store ship + payments stories

## Dependency spine
1. **Ship truthfully** (ASC + IAP attach + reviewer journeys)
2. **Monetize cleanly** (server entitlements + chat credit ledger)
3. **Measure** (subscription lifecycle + request_id correlation)
4. **Habit** (personalized Today + chart-aware push)
5. **Growth** (compatibility front door + share)
6. **Oracle depth** (streaming, chart-context, rate limits)

## Production readiness pillars
| Pillar | Bar |
|--------|-----|
| Client journeys | Guest FTUE, SIWA, 5 Topo tabs, Settings Oracle/Reports/Paywall, Export/Delete |
| Simulator matrix | Cold launch → Today → paywall sandbox → restore → export/delete; no blank offline |
| Server/DB | JWT auth, chart/dasha/oracle/reports, entitlement ledger, credit ledger, backups |
| Logging | PortfolioAnalytics allow-list; server JSON + Sentry; `X-Request-ID` end-to-end; no PII/birth data |
| Launch | Public lookup only after live; IAP with version; support/privacy/terms 200 |

## Story map → Ceetrix
| Priority | Outcome story | Ceetrix (existing or new) |
|----------|---------------|---------------------------|
| P0 | App Store v1 reviewers can fully exercise guest + paid paths | #4, #17 |
| P0 | Paid products real end-to-end with server ledger | #1, new if needed |
| P0 | Subscription lifecycle observability | new + #11 |
| P0 | Top-tier request-correlated logging | implemented locally; production log-drain proof open |
| P1 | Daily habit beats generic horoscopes | #10, #15 |
| P1 | Compatibility first-class growth surface | #12, #13 |
| P1 | Oracle paid always-there astrologer | existing gates |
| P2 | Accessibility independent journeys | #9 |
| P2 | Multilingual Tier-1 | #8 |
| P2 | Temple ship or hide | #14 |
| P3 | Growth loop share/referral | #16, #15 |

## Simulator journey matrix (must stay green)
Today · Map · Timeline · Matrix · Journal · Settings(Oracle/Reports/Paywall/Restore/Export/Delete) · FTUE guest/SIWA

## Logging contract
- Client: `app_open`, `ftue_step`, `screen_view`, `paywall_*`, `subscription_*`, `network_request`+`request_id`
- Server: one JSON line/request; preserve/echo a safe client `X-Request-ID`;
  hash IP; classify (do not retain) user agent; never log JWT, query values,
  request bodies, birth payloads, or user text
- Partial: renew/cancel/grace/lapse events are locally deduplicated and status
  changes are observed while foregrounded with activation-time refresh;
  StoreKit sandbox proof and Smartlook linkage remain open (do not claim).
- Request correlation: `NetworkClient` generates one ID per typed/raw request,
  the server validates and echoes it, and both client allow-listed telemetry and
  server JSON request logs use that ID. Focused local tests cover propagation,
  invalid-ID replacement, route redaction, and forbidden-field absence.
  Production log-drain verification remains external, as does the active
  `SECURITY-CLOUDKIT-ROTATION.md` owner rotation gate.
