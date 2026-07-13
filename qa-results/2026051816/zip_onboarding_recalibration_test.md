# ZIP Onboarding Recalibration Evidence

Date: 2026-05-23

## Scope

- Replaced the visible first-run onboarding route with the ZIP-guided calibration journey:
  - calibration splash
  - combined birth coordinates with date, time, unknown-time, birthplace, coordinates, and timezone lookup
  - phone/Loshu vector
  - context priors
- Preserved the critical birth date, birth time, birthplace, MapKit search, coordinate, and timezone path.
- Persisted phone digits and context priors locally for the current onboarding slice.
- Reset paths now clear the new onboarding draft keys.

## Commands

```sh
xcodebuild build \
  -project client/astronova.xcodeproj \
  -scheme AstronovaApp \
  -destination 'platform=iOS Simulator,id=F2B5999E-043A-4B54-A751-D5491F7BF7A2' \
  -derivedDataPath /tmp/AstronovaDerivedData
```

Result: build succeeded.

```sh
QA_EVIDENCE_DIR=/Users/sankalp/Projects/iosapps/astronova/qa-results/2026051816 \
xcodebuild test \
  -project client/astronova.xcodeproj \
  -scheme AstronovaApp \
  -destination 'platform=iOS Simulator,id=F2B5999E-043A-4B54-A751-D5491F7BF7A2' \
  -derivedDataPath /tmp/AstronovaDerivedData \
  -only-testing:AstronovaAppUITests/AstronovaAppUITests/testFirstRunGuestOnboardingShowsCalibrationFlow \
  -only-testing:AstronovaAppUITests/AstronovaAppUITests/testOnboardingReachesContextPriorsAfterPhoneVector \
  -test-timeouts-enabled YES \
  -maximum-test-execution-time-allowance 180
```

Result: 2 UI tests passed, 0 failed.

Result bundle:

`/tmp/AstronovaDerivedData/Logs/Test/Test-AstronovaApp-2026.05.23_11-20-26-+0200.xcresult`

## Screenshot

- `qa-results/2026051816/17-onboarding-calibration-splash.png`
- `qa-results/2026051816/17-onboarding-birth-coordinates.png`
- `qa-results/2026051816/17-onboarding-phone-vector.png`
- `qa-results/2026051816/17-onboarding-context-priors.png`

## Follow-Up

The next slice should connect the new phone/context onboarding state to `UserPriorsRequest` / `phone_digit_sum` for server-backed synthesis instead of keeping it local-only.
