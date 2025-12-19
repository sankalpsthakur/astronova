# Astronova

[![Test Suite](https://github.com/yourusername/astronova/actions/workflows/test.yml/badge.svg)](https://github.com/yourusername/astronova/actions/workflows/test.yml)
[![iOS Build](https://github.com/yourusername/astronova/actions/workflows/ios.yml/badge.svg)](https://github.com/yourusername/astronova/actions/workflows/ios.yml)
[![codecov](https://codecov.io/gh/yourusername/astronova/branch/main/graph/badge.svg)](https://codecov.io/gh/yourusername/astronova)
[![Python 3.9+](https://img.shields.io/badge/python-3.9+-blue.svg)](https://www.python.org/downloads/)
[![Swift 5.9](https://img.shields.io/badge/swift-5.9-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

iOS SwiftUI app + Flask backend for horoscopes, charts, compatibility, and an animated Time Travel view. This README captures the current codebase accurately and concisely.

## What’s In This Repo

- client/ — SwiftUI app (Xcode project `client/astronova.xcodeproj`)
  - `AuthState.swift` — authentication, JWT lifecycle, feature gates
  - `UserProfile.swift` — profile model, persistence, chart caching
  - `NetworkClient.swift` — typed async HTTP client, error mapping
  - `APIServices.swift` — higher‑level API surface (charts, horoscope, ephemeris, dashas, chat)
  - `APIModels.swift` — request/response types shared across the app
  - `CosmicDesignTokens.swift` + `CosmicColors.swift` — shared spacing, typography, and color tokens used across views
  - `EnhancedTimeTravelView.swift` — primary Time Travel experience with chakra wheel, impact analysis, and live dasha API integration
  - `TimeTravelView.swift` — legacy local simulation kept for reference and prototyping
  - `RootView.swift` — app shell, tabs (Today, Connect, Time Travel, Ask, Manage)
  - `Config/AppConfig.swift` — API base URL resolution
- server/ — Flask API (entry `server/app.py`)
  - `routes/` — endpoints (horoscope, ephemeris, chart, astrology, compatibility, chat, content, auth, locations, reports)
  - `services/ephemeris_service.py` — Swiss Ephemeris if available; numeric fallbacks otherwise

## Requirements

- Xcode 15+ (iOS 17 SDK) — the app uses iOS 17’s `.onChange` two‑parameter closure
- Python 3.10+ for the backend

## Running Locally

Backend (Flask)
- `cd server && pip install -r requirements.txt`
- `python app.py` (defaults to 0.0.0.0:8080; health at `/api/v1/health`)
- Optional env: `FLASK_DEBUG=true` or `PORT=8080`

Helper script
- `./scripts/run-local.sh` will create the virtualenv if needed, install backend deps, boot the Flask server on port 8080, and (by default) open the Xcode project. Use `OPEN_XCODE=0 ./scripts/run-local.sh` to skip launching Xcode.

Client (iOS)
- Open `client/astronova.xcodeproj` in Xcode
- Scheme: AstronovaApp (iOS 17+ simulator or device)
- API base URL is resolved by `AppConfig`:
  - Debug + Simulator: `http://127.0.0.1:8080`
  - Otherwise: `https://astronova.onrender.com`
  - To override, set `API_BASE_URL` in the app’s Info.plist

## Architecture (Client)

- `NetworkClient` handles request execution, status mapping, decode strategy, and common errors (offline, timeout, token expired, server errors). JWT (if present) is attached as `Authorization: Bearer ...`.
- `APIServices` provides a typed facade over endpoints. Key flows:
  - Planetary positions (basic dict): tries `/api/v1/astrology/positions`, then maps from `/api/v1/ephemeris/current`; no device fallback.
  - Detailed positions: prefers `/api/v1/ephemeris/current` (array), else maps from basic dict.
  - Dashas: `/api/v1/astrology/dashas` (requires complete birth time + location + timezone).
  - Horoscopes: `/api/v1/horoscope` (daily/weekly/monthly).
  - Aspects (by date): `/api/v1/chart/aspects`.
  - Auth: `/api/v1/auth/*` (validate/refresh/logout).
- `AuthState` owns: API health check, token storage in Keychain, sign‑in flow stubs, feature gating (e.g., hasFullFunctionality depends on API connectivity + complete profile).
- `UserProfileManager` persists profile in UserDefaults, generates and caches charts via `APIServices`, and updates derived fields (e.g., sun sign) from responses.
- `EnhancedTimeTravelView` orchestration:
  - Loads `/api/v1/astrology/dashas/complete` via `TimeTravelViewModel` once the profile has birth date, time, latitude, longitude, and timezone.
  - Hydrates the chakra wheel, impact analysis, transition drawer, and educational sheets from the decoded `DashaCompleteResponse` models.
  - Surfaces actionable errors (e.g., missing birth time) instead of silently failing.
- `TimeTravelView` (legacy) still offers an on‑device mean‑motion simulation for experiments; it is no longer wired into the tab bar.

Notes
- A legacy `PlanetaryDataService.swift` exists but main flows now call `APIServices` directly. Keep it in the target only if you need custom static datasets.
- The local Time Travel simulation is intentionally approximate; it provides engaging motion, not scientific precision.

## Architecture (Server)

- Flask app in `server/app.py` mounts blueprints under `/api/v1/*`.
- `services/dasha/` contains the modular Vimshottari calculators (timeline + assembler) consumed by the Flask route.
- `services/ephemeris_service.py` uses Swiss Ephemeris if installed; otherwise falls back to simplified math.
- Endpoints used by the client: `ephemeris` (current/at), `astrology/dashas`, `chart/aspects`, `horoscope`, `auth/*`, `location/search`, `compatibility`, `content`.

## Configuration

- API base URL: set `API_BASE_URL` in the app’s Info.plist to override environment defaults.
- Auth: `AuthState` stores JWT in the Keychain (key `com.sankalp.AstronovaApp.jwtToken`). `APIServices.jwtToken` propagates to `NetworkClient`.
- CORS: Flask enables CORS by default in `create_app()`.

## Troubleshooting

- Build errors about SwiftUI `.onChange`: ensure iOS 17+ SDK and Xcode 15+.
- “Cannot find type in scope”: confirm files are in the AstronovaApp target (Xcode > Target Membership).
- API decode errors: `NetworkClient` logs the raw response body and throws `NetworkError.decodingError`.
- Time Travel shows no Dashas: the view now displays a toast explaining what profile fields are missing. Update birth time and location to refresh the API call.
- Simulator to Flask connectivity: use `http://127.0.0.1:8080` (already default in Debug/Simulator). On device, use a reachable host or set `API_BASE_URL`.

## Tests

- iOS unit tests in `client/AstronovaAppTests`.
- Backend integration coverage for dashas lives in `server/tests/test_dashas_complete.py` (pytest).

### Running Tests

Backend (Python):
```bash
cd server
pip install -r tests/requirements-test.txt
pytest tests/ -v --cov=. --cov-report=html
```

iOS (Swift):
```bash
cd client
xcodebuild test \
  -project astronova.xcodeproj \
  -scheme AstronovaApp \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Test Coverage

The project enforces a minimum test coverage of 80% for Python backend code. Coverage reports are automatically generated and uploaded to Codecov on every CI run.

## Security & Limits

- JWT is stored in the iOS Keychain; treat the token as sensitive.
- The backend may enforce rate limits; handle `429` upstream or adjust server configuration.

## Known Limitations

- Local Time Travel simulation is not ephemeris‑grade. Use API mode for accurate values.
- Some legacy or experimental files may exist; only the files listed in “What’s In This Repo” are considered core to current flows.

## CI/CD Pipeline

The project uses GitHub Actions for continuous integration and deployment.

### Workflows

1. **Test Suite** (`.github/workflows/test.yml`)
   - Runs on: Push to main/dev, Pull requests
   - Matrix testing across Python 3.9, 3.10, 3.11, 3.12
   - Code coverage with 80% minimum threshold
   - Security scanning (Bandit, Safety)
   - Performance benchmarks
   - Integration tests
   - Coverage reports uploaded to Codecov

2. **iOS Build** (`.github/workflows/ios.yml`)
   - Runs on: iOS client changes
   - Xcode build and test
   - Swift linting (SwiftLint)
   - Compiler warnings check
   - Test coverage collection

3. **Deployment** (`.github/workflows/deploy.yml`)
   - Staging: Automatic on main branch push
   - Production: Automatic on version tags (v*.*.*)
   - Pre-deployment checks (tests, code quality)
   - Health checks and smoke tests
   - Automatic rollback on failure

### Setting Up CI/CD

1. **Enable Codecov** (optional):
   - Sign up at https://codecov.io
   - Add `CODECOV_TOKEN` to GitHub repository secrets

2. **Enable Deployment** (optional):
   - Add `RENDER_API_KEY` to GitHub repository secrets
   - Update deployment URLs in `deploy.yml`

3. **Enable Pre-commit Hooks**:
   ```bash
   pip install pre-commit
   pre-commit install
   pre-commit run --all-files
   ```

### Pre-commit Hooks

The project includes pre-commit hooks for code quality:
- Code formatting (Black, isort)
- Linting (flake8)
- Security checks (Bandit, detect-secrets)
- File validation (trailing whitespace, YAML syntax)

Configure with `.pre-commit-config.yaml`. Enable optional hooks for:
- Type checking (mypy)
- Swift formatting (SwiftFormat)
- Swift linting (SwiftLint)
- Automatic test running

## Quick API Map (Client ↔ Server)

- GET `/api/v1/ephemeris/current` → `{ planets: [DetailedPlanetaryPosition] }`
- GET `/api/v1/ephemeris/at?date=YYYY-MM-DD[&system=vedic]` → `{ planets: [...] }`
- GET `/api/v1/astrology/positions` → `{ Sun: {degree, sign}, ... }`
- GET `/api/v1/chart/aspects?date=YYYY-MM-DD` → `[Aspect]`
- GET `/api/v1/horoscope?sign=aries&type=daily` → `HoroscopeResponse`
- GET `/api/v1/location/search?q=...&limit=10` → `LocationSearchResponse`
- POST `/api/v1/auth/apple` → `AuthResponse`; GET `/api/v1/auth/validate`; POST `/api/v1/auth/refresh`

This README is intentionally compact and strictly reflects the current implementation and flows.
