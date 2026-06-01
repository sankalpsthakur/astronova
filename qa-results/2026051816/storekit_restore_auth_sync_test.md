# StoreKit Restore + Auth Sync Evidence

Date: 2026-05-23

## Change

- StoreKit restore now reports success from current StoreKit entitlements, not from stale local `hasAstronovaPro` state.
- Current report/non-consumable entitlements are treated as restored purchases for the restore CTA.
- Successful Pro purchase, transaction updates, current entitlement refresh, valid stored JWT sessions, Apple sign-in, and token refresh now all retry server subscription sync after the API JWT is available.
- Mock `BasicStoreManager` restore was aligned with this behavior for UI test/report-shop flows.

## Verification

### iOS unit / integration slice

Command:

```sh
xcodebuild test -project client/astronova.xcodeproj -scheme AstronovaApp -destination 'platform=iOS Simulator,id=F2B5999E-043A-4B54-A751-D5491F7BF7A2' -derivedDataPath /tmp/AstronovaDerivedData -only-testing:AstronovaAppTests/AstronovaAppTests/testReportShopMockPurchasePersistsReportStateForCurrentSession -only-testing:AstronovaAppTests/SubscriptionLifecycleAnalyticsTests
```

Result: passed, 6 tests, 0 failures.

Result bundle:

```text
/tmp/AstronovaDerivedData/Logs/Test/Test-AstronovaApp-2026.05.23_11-54-11-+0200.xcresult
```

### Server entitlement gates

Command:

```sh
server/.venv/bin/python -m pytest server/tests/test_monetization_entitlements.py server/tests/test_openapi_contract.py -q
```

Result: passed, 13 tests, 0 failures.

### Simulator build

Command:

```sh
xcodebuild build -project client/astronova.xcodeproj -scheme AstronovaApp -destination 'platform=iOS Simulator,id=F2B5999E-043A-4B54-A751-D5491F7BF7A2' -derivedDataPath /tmp/AstronovaDerivedData
```

Result: build succeeded.

## Residual Risk

This proves the client/server state recovery path and gate contract in local simulator/test conditions. Production-grade subscription trust still needs App Store signed transaction verification or App Store Server API validation before `/api/v1/subscription/sync` should be treated as cryptographically authoritative.
