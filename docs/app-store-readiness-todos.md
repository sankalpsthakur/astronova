# App Store Readiness Notes and External Gates

This note tracks the source/readiness work from the most recent App Store pass
without claiming a completed TestFlight upload or live App Store listing.

## Completed
- Locked delete-account to JWT identity on the server and hid delete UI for guests.
- Refreshed StoreKit entitlements in Home/Root and improved restore messaging.
- Updated privacy copy and reviewer notes to include the Smartlook package-reference caveat.
- Removed unused location permission description from the app Info.plist.
- Updated auth security tests for real JWT validation and re-ran delete-account tests.
- Added end-to-end `X-Request-ID` propagation for typed/raw client API calls,
  response echoing, and structured server request logs. Request telemetry now
  retains only normalized route/status/method/correlation fields and excludes
  JWTs, query values, server error text, birth payloads, and user text.
- Added a durable server StoreKit transaction ledger and Oracle credit balance.
  Verified Pro, report, and credit transactions are claimed idempotently; a
  conflicting replay is rejected. Client Pro/report/credit state, completion
  events, and transaction finishing now occur only after server delivery.
- StoreKit transaction JWS values are never logged. Consumable credit retries
  return the existing absolute balance without adding credits twice.
- Account deletion clears paid balances/entitlements and direct ledger owner
  IDs, while retaining anonymized transaction tombstones so deleted or
  re-registered accounts cannot reclaim the same signed purchase.

## Tests
- `pytest server/tests/test_auth_security.py -k delete_account`
- `pytest server/tests/test_request_correlation.py server/tests/test_portfolio_analytics_scrub.py`
- `xcodebuild ... -sdk iphoneos CODE_SIGNING_ALLOWED=NO build-for-testing`
  compiled the app and focused request-correlation XCTest bundle successfully;
  tests were not executed because this bounded pass prohibited simulator use.

## Release Pipeline Notes
- `client/ExportOptions.plist` is configured for App Store Connect upload with team ID `ZBSZPCY34Y`.
- Release build settings currently use bundle ID `com.astronova.app`, marketing version `1.0`, build number `2026051601`, automatic signing, and team ID `ZBSZPCY34Y` for the app target.
- `.github/workflows/ios-distribution.yml` is manual and preflight-only by default. A real TestFlight upload is gated behind `upload_to_testflight=true` plus App Store Connect API key secrets.
- No uploaded TestFlight build is confirmed here. Verify upload/build presence in App Store Connect before marking release status as complete.
- No public App Store URL is confirmed here. Keep any store link hidden or marked pending until the Astronova listing is approved/live.
- Remaining external gates: App Store Connect API key, Apple Developer team access, signing/provisioning/certificate availability for automatic signing, bundle ID/App ID ownership, App Store Connect app record availability, sandbox IAP records, reviewer/test account creation, support/privacy/terms URL verification, and acceptance of build `2026051601` or a later unique build number.
- Request-correlation production proof remains open until a deployed request ID
  is verified in the configured log drain. `SECURITY-CLOUDKIT-ROTATION.md`
  remains an active owner-only secret-rotation gate; this pass did not inspect,
  modify, or expose its contents.

## IAP Product Truth
- Current expected product count: 12 App Store products.
- Pro subscriptions: `astronova_pro_12_month_commitment` (current default Pro plan) and `astronova_pro_monthly`.
- Non-consumable reports: `report_general`, `report_love`, `report_career`, `report_money`, `report_health`, `report_family`, `report_spiritual`.
- Consumable chat credits: `chat_credits_5`, `chat_credits_15`, `chat_credits_50`.
- These 12 IDs match `Info.plist`, `ShopCatalog`, and the local
  `AstronovaProducts.storekit` file. This is repository/local StoreKit truth
  only; live/sandbox App Store Connect product availability is still open.

## Remaining Apple Payment Gates
- Confirm all 12 products, prices, tax/category metadata, subscription group,
  introductory offers, and the 12-month billing terms in App Store Connect.
- Run authenticated sandbox purchase, cancellation, Ask to Buy/pending,
  restore, renewal, expiry, refund/revocation, and interrupted-delivery tests
  against the deployed server.
- Configure and verify App Store Server Notifications/webhooks for renewals,
  expiry, billing retry, refunds, and revocations; client transaction/status
  listeners do not replace server notification coverage.
- Configure Apple StoreKit root trust and bundle ID on the deployed server, and
  verify ledger persistence across deploy/restart. No live ASC, sandbox, or
  webhook proof was produced in this local pass.

## Smartlook Gate
- Current repo state has a Smartlook Swift package reference, but `SmartlookAnalytics` is not linked to the `AstronovaApp` target.
- Do not claim Smartlook recording/events are live unless a source worker links the SDK and verifies a fresh build/session.

## Dependencies Installed
- `flask-babel`
- `flask-limiter`
- `PyJWT`
