# Astronova Nav Recomposition Test Evidence

This file pins the launch-gate simulator slice for Story 2 so the Ceetrix test
coverage gate can trace the iOS UI tests that live under `client/AstronovaAppUITests`.

Command:

```sh
xcodebuild test \
  -project client/astronova.xcodeproj \
  -scheme AstronovaApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:AstronovaAppUITests/JourneyAcceptanceTests/test_J1_allTabsRenderOffline \
  -only-testing:AstronovaAppUITests/JourneyAcceptanceTests/test_J7_timelineTabShowsSystemDashaAndForecast \
  -only-testing:AstronovaAppUITests/JourneyAcceptanceTests/test_J8_matrixTabShowsLoshuEigenvaluesAndTransformations \
  -only-testing:AstronovaAppUITests/JourneyAcceptanceTests/test_J12_journalShowsFreeWillDecisionLoopAndNoWhereElse \
  -only-testing:AstronovaAppUITests/JourneyAcceptanceTests/test_J13_astrocartographyUsesAppleMapsGlobe
```

Result:

- 5 selected JourneyAcceptanceTests passed.
- Timeline hit live `/api/v1/synthesis/mirror` and `/api/v1/predictions/timeline`.
- Matrix hit live `/api/v1/numerology/report`.
- Journal verified Free Will plus decision workflow and no Journal astrocartography CTA.
- Map verified `appleMapsGlobeView` ownership.

Capability/test mapping:

- `astronova.nav.shell`: UI-component and e2e coverage through tab label and
  accessibility identifier assertions for `Today`, `Map`, `Timeline`, `Matrix`,
  and `Journal`.
- `astronova.timeline.surface`: integration and e2e coverage through the live
  local backend calls to `/api/v1/synthesis/mirror` and
  `/api/v1/predictions/timeline`, plus assertions for `timeline.systemOverview`,
  `timeline.dashaPulse`, and `predictionTimelineView`.
- `astronova.matrix.surface`: integration and e2e coverage through the live
  local backend call to `/api/v1/numerology/report`, plus assertions for
  `loshuGridView`, `matrix.eigenvalues`, and `matrix.transformations`.
- `astronova.journal.agency`: UI-component and e2e coverage through
  `journal.freeWillHero`, `journal.decisionLoop`, Bayesian slider launch, and
  decision compose/result assertions.
- `astronova.map.globe_owner`: e2e coverage through `mapTabView`,
  `astrocartographyMapView`, and `appleMapsGlobeView`.

Server/service command:

```sh
server/.venv/bin/python -m pytest \
  server/tests/test_numerology_service.py \
  server/tests/test_prediction_service.py \
  server/tests/test_rajayoga_service.py \
  server/tests/test_monetization_entitlements.py -q
```

Server/service result:

- 50 server service and integration checks passed.
- Local simulator run logs showed 200 responses for synthesis mirror,
  prediction timeline, and numerology report endpoints.
