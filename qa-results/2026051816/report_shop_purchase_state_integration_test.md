# Report Shop Purchase State Integration Test

Command:

```sh
xcodebuild test -project client/astronova.xcodeproj -scheme AstronovaApp -destination 'platform=iOS Simulator,id=F2B5999E-043A-4B54-A751-D5491F7BF7A2' -derivedDataPath /tmp/AstronovaDerivedData -only-testing:AstronovaAppTests/AstronovaAppTests/testReportShopMockPurchasePersistsReportStateForCurrentSession -test-timeouts-enabled YES -maximum-test-execution-time-allowance 120
```

Result: passed, 1 integration test, 0 failures.

Xcode result bundle:

```text
/tmp/AstronovaDerivedData/Logs/Test/Test-AstronovaApp-2026.05.23_10-54-33-+0200.xcresult
```

Refactor guard:

```text
J16 report-shop simulator journey re-run passed after moving mock report persistence into APIServices.
/tmp/AstronovaDerivedData/Logs/Test/Test-AstronovaApp-2026.05.23_10-55-33-+0200.xcresult
```
