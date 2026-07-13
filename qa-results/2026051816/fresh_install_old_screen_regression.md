# Fresh install old-screen regression

Date: 2026-05-23
Simulator: iPhone 17 Pro, iOS 26.4, UDID F2B5999E-043A-4B54-A751-D5491F7BF7A2
Bundle: com.astronova.app

## Why this was run

The app was still appearing with old screens in a live simulator/device context. Source and older XCTest captures were not enough proof, so the app was rebuilt, uninstalled from the booted simulator, freshly installed, launched, and screenshot from the running artifact.

## Fix applied

- Bumped `CURRENT_PROJECT_VERSION` from `2026052202` to `2026052301` in `client/astronova.xcodeproj/project.pbxproj` so the fresh checkpoint is distinguishable from the prior installed build.
- Rebuilt the app using `xcodebuild build`.
- Uninstalled and reinstalled `com.astronova.app` on the booted simulator.

## Verification

- Built artifact reports:
  - `CFBundleDisplayName`: `Astronova`
  - `CFBundleIdentifier`: `com.astronova.app`
  - `CFBundleVersion`: `2026052301`
- Fresh launch screenshot:
  - `qa-results/2026051816/fresh-install-launch-build-2026052301.png`
- First-run guest onboarding XCTest:
  - `AstronovaAppUITests/testFirstRunGuestOnboardingShowsCalibrationFlow`
  - Result: 1 UI test, 0 failures
  - Result bundle: `/tmp/AstronovaDerivedData/Logs/Test/Test-AstronovaApp-2026.05.23_12-08-35-+0200.xcresult`
- Captured live onboarding screens:
  - `qa-results/2026051816/17-onboarding-calibration-splash.png`
  - `qa-results/2026051816/17-onboarding-birth-coordinates.png`
  - `qa-results/2026051816/17-onboarding-phone-vector.png`

## Finding

The refreshed simulator app no longer shows the old signed-out or first-run onboarding surfaces. It shows the recalibrated Astronova landing and the new 4-step calibration flow while preserving birth date, birth time, and birth place collection.

One additional booted iOS 26.5 simulator had no default display and `simctl terminate` hung while another external `xcodebuild` process was active, so visible proof was taken from the active iOS 26.4 display simulator.
