# Astronova – E2E Run Findings (Local)

Date: current local run (simulator iOS 18.6, backend localhost:8080, SQLite temp DB).

## Summary
- Backend endpoints are fully documented via OpenAPI (`server/openapi_spec.yaml`) and rendered in Swagger UI at `/docs` (spec served at `/api/v1/openapi.yaml`).
- Quantitative astronomy accuracy (Western + Kundali/Vedic) is validated against Swiss Ephemeris; results are consistent with rounding-only error (details in `docs/astrology-accuracy.md`).
- Full backend regression suite: `./.venv/bin/python -m pytest -q server/tests` → 499/499 pass.

## Backend
- Services: `chat_response_service.py`, `ephemeris_service.py`, `planetary_strength_service.py`, `dasha_service.py`, `dasha_interpretation_service.py`, `dasha/` subpackage, `report_generation_service.py`.
- Report flow: routes in `server/routes/reports.py`, persistence in `server/db.py`.
- Tests: `.venv/bin/python -m pytest server/tests -q` → 499/499 pass.
- Live HTTP smoke: `server/e2e_smoke.py --verbose` → 11/11 pass (auth, chat, locations, reports generate/pdf, subscription).
- App entry: `python server/app.py` (honors `PORT`, `DB_PATH`); `/api/v1/health` OK.
- API docs: Swagger UI at `/docs`, OpenAPI at `/api/v1/openapi.yaml`.
- Quantitative accuracy: `docs/astrology-accuracy.md` (Swiss Ephemeris reference; includes western vs kundali + dasha timing).

## Accuracy (Quantitative)
Ground truth: Swiss Ephemeris (`pyswisseph`) tropical + sidereal Lahiri.

- Western (tropical): MAE `0.002541°` (~9.15 arcsec), P95 `0.004755°`, Max `0.004999°`, sign match `100%`.
- Vedic/Kundali (sidereal Lahiri): MAE `0.002567°` (~9.24 arcsec), P95 `0.004738°`, Max `0.004987°`, sign match `100%`.
- Time Travel dashas: starting Mahadasha lord match `100%`; balance-years rounding error MAE `0.00002481y` (~13.05 min), Max `0.00004984y` (~26.21 min).
- Fallback mode (no Swiss): MAE ≈ `90°` (not accuracy-usable; should not be used for production astrology).

Repro: `./.venv/bin/python tools/generate_astrology_accuracy_report.py` (writes `docs/astrology-accuracy.md`).

## iOS Harness & Accessiblity
- Test harness runs before `AuthState` (`TestEnvironment.applyTestConfiguration()`); launch args: reset, seed profile full/minimal, set free-limit reached, set chat credits, set Pro, skip onboarding, mock purchases, enable logging.
- Key IDs: `getChatPackagesButton`, `goUnlimitedButton`, `startProButton`, `chatPackBuyButton_<sku>`, `reportBuyButton_<sku>`, `doneButton`, `paywallView`, `myReportsView`, `reportRow_<id>`, `chatCreditsLabel`.
- ATS updated to allow `http://127.0.0.1`/`localhost` for simulator.

## Monetization UI Tests (AstronovaAppUITests/MonetizationJourneyTests)
- Journey A (free → buy credits) ✅
- Journey B (free → paywall → Pro) ✅
- Journey C (report purchase → library) ❌
  - Fails because “View All” (library) never appears; likely no report persisted/loaded or the CTA is hidden when `userReports` is empty.

## Likely Fix for Journey C
1) After purchase in `InlineReportsStoreSheet`, trigger `loadUserReports()` or set a flag to reload and show a deterministic library CTA.
2) Ensure `APIServices.generateReport(...)` uses `userId` (it does) and backend associates it (DB insert already does).
3) Add a fallback “View All” button when zero reports exist in UI test mode, or wait after purchase for refresh.
4) Re-run with backend running on 8080:
   ```
   DB_PATH=$(mktemp -t astronova-uitest.XXXXXX).db PORT=8080 python server/app.py
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
     -project client/astronova.xcodeproj -scheme AstronovaApp \
     -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
     -configuration Debug \
     CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
     -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 \
     -only-testing:AstronovaAppUITests/MonetizationJourneyTests/testJourneyC_ReportPurchaseAndLibrary
   ```

## Manual Simulator Notes
- Available: iPhone 16 (iOS 18.6). Device types for iPhone 15 exist; can create via `xcrun simctl create "iPhone 15" …`.
- API base: `AppConfig` defaults to `http://127.0.0.1:8080` on Simulator (Debug).
