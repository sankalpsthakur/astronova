# Astronova Refreshed Client Screen Evidence

Date: 2026-05-23

## What regressed

The ZIP-guided onboarding and Today surfaces were partially wired while stale
client/test contracts remained alive. The highest-risk gaps were:

- Recalibrated onboarding dropped explicit name capture from the live path.
- Paywall tests and tiered variants still accepted or exposed the old
  `paywallCloseButton` identifier.
- Today dashboard tests scrolled through deeper cards before tapping the daily
  habit CTA, making the first value loop brittle.
- Empty placeholder UI/unit tests still existed and did not prove product
  behavior.

## Client fixes covered by this evidence

- First-run onboarding now keeps the important capture fields in the refreshed
  flow: name, birth date, birth time, birth place, phone vector, and context
  priors.
- Tiered paywalls now use the canonical close identifier `paywall.close`.
- The Today screen leads with ZIP-style synthesis and reaches the daily signal
  habit loop before deeper action-queue diagnostics.
- Stale no-op UI/unit tests were removed or rewritten around current product
  identifiers.
- The unused legacy `TodayTab` block that still rendered `Today's Horoscope`
  was deleted from `RootView.swift`; the only remaining `Today's Horoscope`
  hit is the negative UI assertion guarding against its return.

## Verification

Build:

```text
xcodebuild build -project client/astronova.xcodeproj -scheme AstronovaApp -destination 'platform=iOS Simulator,id=F2B5999E-043A-4B54-A751-D5491F7BF7A2' -derivedDataPath /tmp/AstronovaDerivedData
** BUILD SUCCEEDED **
```

Stale-screen search after pruning:

```text
rg -n "Today's Horoscope|struct TodayTab|PlanetaryEnergiesView|WelcomeToTodayCard|PrimaryCTASection|DiscoveryCTASection|paywallCloseButton" client/AstronovaApp client/AstronovaAppUITests
client/AstronovaAppUITests/JourneyAcceptanceTests.swift:1089: XCTAssertFalse(app.staticTexts["Today's Horoscope"].exists, ...)
```

Server entitlement tests:

```text
server/.venv/bin/python -m pytest server/tests/test_monetization_entitlements.py -q
11 passed, 198 warnings in 0.44s
```

Targeted simulator UI journeys:

```text
QA_EVIDENCE_DIR=/Users/sankalp/Projects/iosapps/astronova/qa-results/2026051816 \
xcodebuild test -project client/astronova.xcodeproj -scheme AstronovaApp \
  -destination 'platform=iOS Simulator,id=F2B5999E-043A-4B54-A751-D5491F7BF7A2' \
  -derivedDataPath /tmp/AstronovaDerivedData \
  -only-testing:AstronovaAppUITests/AstronovaAppUITests/testFirstRunGuestOnboardingShowsCalibrationFlow \
  -only-testing:AstronovaAppUITests/AstronovaAppUITests/testOnboardingReachesContextPriorsAfterPhoneVector \
  -only-testing:AstronovaAppUITests/JourneyAcceptanceTests/test_J14_todayDailySignalOpensHabitLoop

Executed 3 tests, with 0 failures (0 unexpected)
** TEST SUCCEEDED **
```

TTV:

```json
{
  "time_to_daily_signal_seconds" : 6.9772670269012451
}
```

Evidence artifacts:

- `17-onboarding-calibration-splash.png`
- `17-onboarding-birth-coordinates.png`
- `17-onboarding-phone-vector.png`
- `17-onboarding-context-priors.png`
- `14-today-refreshed-dashboard.png`
- `14-today-daily-signal.png`
- `14-daily-signal-log-sheet.png`
- `14-today-ttv.json`

## Remaining thermo-nuclear review findings

- `RootView.swift` is still structurally too large. The next cleanup should
  extract onboarding/report store code and continue deleting unreachable legacy
  screen structs after reference search plus simulator smoke proof.
- `JourneyAcceptanceTests.swift` is over 1k lines. The next test cleanup should
  split shared helpers or journey domains into focused files without weakening
  coverage.
- Report entitlement client sync exists at the API layer, but the report-shop
  purchase path still needs a live client integration test proving the server
  entitlement is consumed exactly once.
