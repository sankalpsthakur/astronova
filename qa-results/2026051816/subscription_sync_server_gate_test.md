# Astronova subscription sync and server premium gate evidence

Date: 2026-05-23

## Risk addressed

Native StoreKit purchase/restore state could mark Pro locally while the backend still rejected premium server routes such as report generation. This created a split-brain paid state: client unlocked, server still `402 PAYMENT_REQUIRED`.

## Changes verified

- Added authenticated `POST /api/v1/subscription/sync`.
- The endpoint only activates known Astronova Pro product IDs.
- The endpoint requires a transaction identifier or original transaction identifier.
- The endpoint writes `subscription_status`, which is the same server-side entitlement source used by report and deep chat premium gates.
- StoreKit purchase, transaction updates, and current-entitlement restore refresh now call the sync endpoint for Pro transactions.
- Added OpenAPI coverage for subscription sync plus the live synthesis/numerology/prediction/rajayoga routes that power showcased client screens.

## Commands

```sh
server/.venv/bin/python -m pytest server/tests/test_monetization_entitlements.py -q
server/.venv/bin/python -m pytest server/tests/test_monetization_entitlements.py server/tests/test_openapi_contract.py -q
xcodebuild build -project client/astronova.xcodeproj -scheme AstronovaApp -destination 'platform=iOS Simulator,id=F2B5999E-043A-4B54-A751-D5491F7BF7A2' -derivedDataPath /tmp/AstronovaDerivedData
```

## Results

- Monetization entitlement tests: 10 passed.
- Monetization + OpenAPI contract tests: 13 passed.
- iOS simulator build: succeeded.

## Residual risk

This closes the app/server state handoff for authenticated native purchases, but full production-grade payment integrity still needs App Store Server API / signed transaction JWS verification on the backend. The new endpoint rejects non-Pro products and requires transaction identity, but it does not yet cryptographically verify the transaction server-side.
