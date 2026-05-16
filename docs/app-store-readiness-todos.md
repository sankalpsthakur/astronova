# App Store Readiness Notes and External Gates

This note tracks the source/readiness work from the most recent App Store pass
without claiming a completed TestFlight upload or live App Store listing.

## Completed
- Locked delete-account to JWT identity on the server and hid delete UI for guests.
- Refreshed StoreKit entitlements in Home/Root and improved restore messaging.
- Updated privacy copy and reviewer notes to include the Smartlook package-reference caveat.
- Removed unused location permission description from the app Info.plist.
- Updated auth security tests for real JWT validation and re-ran delete-account tests.

## Tests
- `pytest server/tests/test_auth_security.py -k delete_account`

## Release Pipeline Notes
- `client/ExportOptions.plist` is configured for App Store Connect upload with team ID `ZBSZPCY34Y`.
- Release build settings currently use bundle ID `com.astronova.app`, marketing version `1.0`, build number `2026051601`, automatic signing, and team ID `ZBSZPCY34Y` for the app target.
- `.github/workflows/ios-distribution.yml` is manual and preflight-only by default. A real TestFlight upload is gated behind `upload_to_testflight=true` plus App Store Connect API key secrets.
- No uploaded TestFlight build is confirmed here. Verify upload/build presence in App Store Connect before marking release status as complete.
- No public App Store URL is confirmed here. Keep any store link hidden or marked pending until the Astronova listing is approved/live.
- Remaining external gates: App Store Connect API key, Apple Developer team access, signing/provisioning/certificate availability for automatic signing, bundle ID/App ID ownership, App Store Connect app record availability, sandbox IAP records, reviewer/test account creation, support/privacy/terms URL verification, and acceptance of build `2026051601` or a later unique build number.

## IAP Product Truth
- Current expected product count: 12 App Store products.
- Pro subscriptions: `astronova_pro_12_month_commitment` (current default Pro plan) and `astronova_pro_monthly`.
- Non-consumable reports: `report_general`, `report_love`, `report_career`, `report_money`, `report_health`, `report_family`, `report_spiritual`.
- Consumable chat credits: `chat_credits_5`, `chat_credits_15`, `chat_credits_50`.

## Smartlook Gate
- Current repo state has a Smartlook Swift package reference, but `SmartlookAnalytics` is not linked to the `AstronovaApp` target.
- Do not claim Smartlook recording/events are live unless a source worker links the SDK and verifies a fresh build/session.

## Dependencies Installed
- `flask-babel`
- `flask-limiter`
- `PyJWT`
