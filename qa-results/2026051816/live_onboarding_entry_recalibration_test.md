# Astronova live onboarding entry recalibration

Date: 2026-05-23

## Correction addressed

The installed app still showed the stale unauthenticated entry screen ("Get today's move in under a minute") even though the profile setup flow had been recalibrated. The active `CompellingLandingView` was still old, so a normal first launch did not look like the ZIP-guided Astronova direction.

## Changes verified

- Replaced the unauthenticated entry screen with a calibration-oriented Astronova landing.
- Preserved Sign in with Apple.
- Preserved guest preview and routed it into the recalibrated onboarding sequence.
- Preserved birth date, birth time, birth-place search, phone vector, and context priors journey coverage.
- Fixed the landing accessibility identifier so it no longer masks the guest CTA identifier in UI automation.

## Manual simulator evidence

Simulator:
`iPhone 17 Pro (F2B5999E-043A-4B54-A751-D5491F7BF7A2), iOS 26.4`

Commands:

```sh
xcodebuild build -project client/astronova.xcodeproj -scheme AstronovaApp -destination 'platform=iOS Simulator,id=F2B5999E-043A-4B54-A751-D5491F7BF7A2' -derivedDataPath /tmp/AstronovaDerivedData
xcrun simctl install F2B5999E-043A-4B54-A751-D5491F7BF7A2 /tmp/AstronovaDerivedData/Build/Products/Debug-iphonesimulator/AstronovaApp.app
xcrun simctl launch F2B5999E-043A-4B54-A751-D5491F7BF7A2 com.astronova.app UITEST_RESET UITEST_ENABLE_LOGGING
xcrun simctl io F2B5999E-043A-4B54-A751-D5491F7BF7A2 screenshot qa-results/2026051816/18-live-installed-auth-calibration.png
```

Result:

- Build succeeded.
- Fresh installed app shows the new Astronova calibration landing.
- Screenshot: `qa-results/2026051816/18-live-installed-auth-calibration.png`

## UI automation evidence

Command:

```sh
QA_EVIDENCE_DIR=/Users/sankalp/Projects/iosapps/astronova/qa-results/2026051816 xcodebuild test -project client/astronova.xcodeproj -scheme AstronovaApp -destination 'platform=iOS Simulator,id=F2B5999E-043A-4B54-A751-D5491F7BF7A2' -derivedDataPath /tmp/AstronovaDerivedData -only-testing:AstronovaAppUITests/AstronovaAppUITests/testFirstRunGuestOnboardingShowsCalibrationFlow -only-testing:AstronovaAppUITests/AstronovaAppUITests/testOnboardingReachesContextPriorsAfterPhoneVector -test-timeouts-enabled YES -maximum-test-execution-time-allowance 180
```

Result:

- 2 UI tests passed, 0 failures.
- Result bundle: `/tmp/AstronovaDerivedData/Logs/Test/Test-AstronovaApp-2026.05.23_11-36-34-+0200.xcresult`

Screenshots:

- `qa-results/2026051816/17-onboarding-calibration-splash.png`
- `qa-results/2026051816/17-onboarding-birth-coordinates.png`
- `qa-results/2026051816/17-onboarding-phone-vector.png`
- `qa-results/2026051816/17-onboarding-context-priors.png`

## Note

An earlier UI test attempt failed because the new `auth.calibrationLanding` accessibility identifier was attached to the screen container and masked child identifiers. That was corrected before the passing test run above.
