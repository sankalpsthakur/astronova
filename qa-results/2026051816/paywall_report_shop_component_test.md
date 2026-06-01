# Paywall And Report Shop Component Test

Command:

```sh
xcodebuild test -project client/astronova.xcodeproj -scheme AstronovaApp -destination 'platform=iOS Simulator,id=F2B5999E-043A-4B54-A751-D5491F7BF7A2' -derivedDataPath /tmp/AstronovaDerivedData -only-testing:AstronovaAppTests/AstronovaAppTests/testPaywallGateComponentContractKeepsProPrimaryAndReportsSecondary -only-testing:AstronovaAppTests/AstronovaAppTests/testReportsShopComponentContractSeparatesBuyAndIncludedStates -test-timeouts-enabled YES -maximum-test-execution-time-allowance 120
```

Result: passed, 2 ui-component contract tests, 0 failures.

Xcode result bundle:

```text
/tmp/AstronovaDerivedData/Logs/Test/Test-AstronovaApp-2026.05.23_10-50-47-+0200.xcresult
```
