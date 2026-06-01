# J12 Analysis CTA Live Simulator Evidence

Date: 2026-05-23

## Runtime Setup

Started a live local Flask backend for the simulator journey:

```sh
DB_PATH=/tmp/astronova-j12.db PORT=18093 ASTRONOVA_DISABLE_RATE_LIMITS=1 PYTHONPATH=server server/.venv/bin/python server/app.py
```

Confirmed health before the simulator run:

```text
GET http://127.0.0.1:18093/api/v1/health -> 200
```

## Simulator Journey

Command:

```sh
QA_EVIDENCE_DIR=/Users/sankalp/Projects/iosapps/astronova/qa-results/2026051816 \
ASTRONOVA_LOCAL_BACKEND=http://127.0.0.1:18093 \
xcodebuild test \
  -project client/astronova.xcodeproj \
  -scheme AstronovaApp \
  -destination 'platform=iOS Simulator,id=F2B5999E-043A-4B54-A751-D5491F7BF7A2' \
  -derivedDataPath /tmp/AstronovaDerivedData \
  -only-testing:AstronovaAppUITests/JourneyAcceptanceTests/test_J12_analysisModulesReachLiveScreens
```

Result:

```text
Executed 1 UI test, 0 failures
Test duration: 36.303s
Result bundle: /tmp/AstronovaDerivedData/Logs/Test/Test-AstronovaApp-2026.05.23_12-00-45-+0200.xcresult
```

## Clicked CTA Path

The simulator clicked through the imported analysis module CTAs from Journal:

- `analysis.cosmicMirror.button` -> `cosmicMirrorView`
- `analysis.predictionTimeline.button` -> `predictionTimelineView`
- `analysis.astrocartography.button` -> `astrocartographyMapView` with `appleMapsGlobeView`
- `analysis.freeWill.button` -> `bayesianSliderView`

Screenshots:

- `qa-results/2026051816/12-analysis-modules.png`
- `qa-results/2026051816/12-cosmic-mirror.png`
- `qa-results/2026051816/12-action-forecast.png`
- `qa-results/2026051816/12-astrocartography.png`
- `qa-results/2026051816/12-free-will.png`

## Server Log Evidence

Persisted log:

```text
qa-results/2026051816/j12-live-server.log
```

Observed app-originated requests:

```text
GET /health -> 200 request_id=c2c4eac2 user=7BA2932A-2618-45A1-9FDB-16C410EA0859
GET /api/v1/ephemeris/topo-substitutions -> 200 request_id=2b0a3c2c
POST /api/v1/synthesis/mirror -> 200 request_id=5246ad8a
POST /api/v1/predictions/timeline -> 200 request_id=720d5c29
```

The backend logged real synthesis/prediction service work:

```text
Full prediction report: 8 triggers, 7 months, 3 peak windows
Full prediction report: 12 triggers, 13 months, 4 peak windows
```

## Residual Risk

Cosmic Mirror and Action Forecast were live-server backed in this simulator run. Astrocartography and Free Will are local interactive screens; their proof here is reachability, visual rendering, and Apple Maps globe presence, not a server-backed computation.
