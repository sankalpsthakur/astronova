# J11 Auth Recovery Recalibrated Landing Evidence

Date: 2026-05-23

## Change

Updated the auth recovery UI test so it no longer asserts the stale signed-out landing phrase `today's move`. The test now verifies the recalibrated landing via:

- `auth.calibrationLanding`
- Value proposition copy containing `working model of your life`
- `continueWithoutSigningInButton`

## Simulator Journey

Command:

```sh
QA_EVIDENCE_DIR=/Users/sankalp/Projects/iosapps/astronova/qa-results/2026051816 \
xcodebuild test \
  -project client/astronova.xcodeproj \
  -scheme AstronovaApp \
  -destination 'platform=iOS Simulator,id=F2B5999E-043A-4B54-A751-D5491F7BF7A2' \
  -derivedDataPath /tmp/AstronovaDerivedData \
  -only-testing:AstronovaAppUITests/JourneyAcceptanceTests/test_J11_signOutRecoversThroughGuestPreview
```

Result:

```text
Executed 1 UI test, 0 failures
Test duration: 25.889s
Result bundle: /tmp/AstronovaDerivedData/Logs/Test/Test-AstronovaApp-2026.05.23_12-03-28-+0200.xcresult
```

## Clicked CTA Path

- Launched with seeded signed-in state.
- Opened Today settings from the gear icon.
- Tapped `settings.signOut.button`.
- Verified the recalibrated signed-out landing.
- Tapped `continueWithoutSigningInButton`.
- Verified recovery into restored Today value.

Screenshots:

- `qa-results/2026051816/11-settings-sign-out.png`
- `qa-results/2026051816/11-auth-landing-after-sign-out.png`
- `qa-results/2026051816/11-guest-restored-today.png`

## Product Meaning

This keeps the unhappy path aligned with the current onboarding/product direction: a user who signs out can recover through the calibration preview without Apple Sign-In and without seeing stale pre-recalibration messaging.
