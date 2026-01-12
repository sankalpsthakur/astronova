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

## Dependencies Installed
- `flask-babel`
- `flask-limiter`
- `PyJWT`
