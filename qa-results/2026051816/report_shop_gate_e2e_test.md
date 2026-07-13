# Report Shop Gate E2E Test

Command:

```sh
QA_EVIDENCE_DIR=/Users/sankalp/Projects/iosapps/astronova/qa-results/2026051816 xcodebuild test -project client/astronova.xcodeproj -scheme AstronovaApp -destination 'platform=iOS Simulator,id=F2B5999E-043A-4B54-A751-D5491F7BF7A2' -derivedDataPath /tmp/AstronovaDerivedData -only-testing:AstronovaAppUITests/JourneyAcceptanceTests/test_J16_reportShopGatePurchasesFromPaywallAlternative -test-timeouts-enabled YES -maximum-test-execution-time-allowance 180
```

Result: passed, 1 e2e simulator test, 0 failures.

Xcode result bundle:

```text
/tmp/AstronovaDerivedData/Logs/Test/Test-AstronovaApp-2026.05.23_10-45-20-+0200.xcresult
```

Captured evidence:

- `16-paywall-primary-pro-cta.png`
- `16-reports-shop-open.png`
- `16-reports-shop-restore-none.png`
- `16-report-purchase-success.png`
- `16-report-purchased-badge.png`
