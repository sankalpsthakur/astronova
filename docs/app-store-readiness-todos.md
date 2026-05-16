# App Store Readiness Todos (Completed)

This note tracks the items completed in the most recent App Store readiness pass.

## Completed
- Locked delete-account to JWT identity on the server and hid delete UI for guests.
- Refreshed StoreKit entitlements in Home/Root and improved restore messaging.
- Updated privacy copy and reviewer notes to mention Smartlook analytics/diagnostics.
- Removed unused location permission description from the app Info.plist.
- Updated auth security tests for real JWT validation and re-ran delete-account tests.

## Tests
- `pytest server/tests/test_auth_security.py -k delete_account`

## Release Pipeline Notes
- `client/ExportOptions.plist` is configured for App Store Connect upload with team ID `ZBSZPCY34Y`.
- Release build settings currently use bundle ID `com.astronova.app`, marketing version `1.0`, build number `2026051601`, automatic signing, and team ID `ZBSZPCY34Y` for the app target.
- `.github/workflows/ios-distribution.yml` is manual and preflight-only by default. A real TestFlight upload is gated behind `upload_to_testflight=true` plus App Store Connect API key secrets.
- Remaining external gates: App Store Connect API key, Apple Developer team access, signing/provisioning/certificate availability for automatic signing, bundle ID/App ID ownership, and an App Store Connect app record that accepts build `2026051601` or a later unique build number.

## Dependencies Installed
- `flask-babel`
- `flask-limiter`
- `PyJWT`
