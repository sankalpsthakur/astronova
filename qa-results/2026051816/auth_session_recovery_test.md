# Auth Session Recovery Evidence

Date: 2026-05-23

## Scope

- Invalid stored client session now resolves to a signed-out state with a visible recovery message instead of leaving a stale authenticated shell.
- Sign-out clears both `AuthState.jwtToken` and `APIServices.jwtToken`.
- Seeded UI-test profiles remain deterministic while real stored sessions still validate against the backend.
- Guest recovery path after sign-out is simulator-tested through the live app UI.

## Commands

```sh
pytest server/tests/test_auth_security.py -k 'validate_with_correct_token or validate_with_incorrect_token or validate_without_token or refresh_token_expiration or refresh_with_valid_token'
```

Result: 5 passed, 68 deselected.

```sh
QA_EVIDENCE_DIR=/Users/sankalp/Projects/iosapps/astronova/qa-results/2026051816 \
xcodebuild test \
  -project client/astronova.xcodeproj \
  -scheme AstronovaApp \
  -destination 'platform=iOS Simulator,id=F2B5999E-043A-4B54-A751-D5491F7BF7A2' \
  -derivedDataPath /tmp/AstronovaDerivedData \
  -only-testing:AstronovaAppTests/AstronovaAppTests/testInvalidSessionRecoveryReturnsToSignedOutWithMessage \
  -test-timeouts-enabled YES \
  -maximum-test-execution-time-allowance 120
```

Result: 1 passed, 0 failed.

Result bundle:

`/tmp/AstronovaDerivedData/Logs/Test/Test-AstronovaApp-2026.05.23_11-05-46-+0200.xcresult`
`/tmp/AstronovaDerivedData/Logs/Test/Test-AstronovaApp-2026.05.23_11-07-43-+0200.xcresult`

```sh
QA_EVIDENCE_DIR=/Users/sankalp/Projects/iosapps/astronova/qa-results/2026051816 \
xcodebuild test \
  -project client/astronova.xcodeproj \
  -scheme AstronovaApp \
  -destination 'platform=iOS Simulator,id=F2B5999E-043A-4B54-A751-D5491F7BF7A2' \
  -derivedDataPath /tmp/AstronovaDerivedData \
  -only-testing:AstronovaAppUITests/JourneyAcceptanceTests/test_J11_signOutRecoversThroughGuestPreview \
  -test-timeouts-enabled YES \
  -maximum-test-execution-time-allowance 180
```

Result: 1 passed, 0 failed.

Result bundle:

`/tmp/AstronovaDerivedData/Logs/Test/Test-AstronovaApp-2026.05.23_11-02-42-+0200.xcresult`
`/tmp/AstronovaDerivedData/Logs/Test/Test-AstronovaApp-2026.05.23_11-08-11-+0200.xcresult`

## Screenshots

- `qa-results/2026051816/11-settings-sign-out.png`
- `qa-results/2026051816/11-auth-landing-after-sign-out.png`
- `qa-results/2026051816/11-guest-restored-today.png`

## Notes

- A parallel rerun of the same client unit was killed before XCTest bootstrapped while the UI simulator test was also running. The standalone rerun passed and is the retained evidence.
