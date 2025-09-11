# Astronova

iOS SwiftUI app + Flask backend for horoscopes, charts, compatibility, and an animated Time Travel view. This README captures the current codebase accurately and concisely.

## What’s In This Repo

- client/ — SwiftUI app (Xcode project `client/astronova.xcodeproj`)
  - `AuthState.swift` — authentication, JWT lifecycle, feature gates
  - `UserProfile.swift` — profile model, persistence, chart caching
  - `NetworkClient.swift` — typed async HTTP client, error mapping
  - `APIServices.swift` — higher‑level API surface (charts, horoscope, ephemeris, dashas, chat)
  - `APIModels.swift` — request/response types shared across the app
  - `TimeTravelView.swift` — animated planetary view (Local simulation or API data)
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
- `TimeTravelView` has a Source toggle:
  - Local: runs an on‑device mean‑motion simulation (approximate, for visualization). It animates ephemerides continuously (no network).
  - API: fetches ephemeris for a given date; optionally fetches dashas (if profile has required fields) and aspects.

Notes
- A legacy `PlanetaryDataService.swift` exists but main flows now call `APIServices` directly. Keep it in the target only if you need custom static datasets.
- The local Time Travel simulation is intentionally approximate; it provides engaging motion, not scientific precision.

## Architecture (Server)

- Flask app in `server/app.py` mounts blueprints under `/api/v1/*`.
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
- Time Travel shows no Dashas: verify profile has birth time, place, latitude, longitude, and timezone; otherwise switch Source to Local.
- Simulator to Flask connectivity: use `http://127.0.0.1:8080` (already default in Debug/Simulator). On device, use a reachable host or set `API_BASE_URL`.

## Tests

- iOS unit tests in `client/AstronovaAppTests`.
- Backend lightweight tests in `server/tests` (extend as needed).

## Security & Limits

- JWT is stored in the iOS Keychain; treat the token as sensitive.
- The backend may enforce rate limits; handle `429` upstream or adjust server configuration.

## Known Limitations

- Local Time Travel simulation is not ephemeris‑grade. Use API mode for accurate values.
- Some legacy or experimental files may exist; only the files listed in “What’s In This Repo” are considered core to current flows.

## Quick API Map (Client ↔ Server)

- GET `/api/v1/ephemeris/current` → `{ planets: [DetailedPlanetaryPosition] }`
- GET `/api/v1/ephemeris/at?date=YYYY-MM-DD[&system=vedic]` → `{ planets: [...] }`
- GET `/api/v1/astrology/positions` → `{ Sun: {degree, sign}, ... }`
- GET `/api/v1/chart/aspects?date=YYYY-MM-DD` → `[Aspect]`
- GET `/api/v1/horoscope?sign=aries&type=daily` → `HoroscopeResponse`
- GET `/api/v1/location/search?q=...&limit=10` → `LocationSearchResponse`
- POST `/api/v1/auth/apple` → `AuthResponse`; GET `/api/v1/auth/validate`; POST `/api/v1/auth/refresh`

This README is intentionally compact and strictly reflects the current implementation and flows.

