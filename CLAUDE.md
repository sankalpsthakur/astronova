# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Astronova is an iOS SwiftUI app with a Flask backend for Vedic astrology features: horoscopes, birth charts, compatibility analysis, Vimshottari dasha timelines, and a Time Travel visualization.

**Structure:**
- `client/` — iOS SwiftUI app (Xcode project: `client/astronova.xcodeproj`)
- `server/` — Flask API (entry point: `server/app.py`)

## Build & Run Commands

### Backend (Flask)
```bash
cd server
pip install -r requirements.txt
python app.py                    # Runs on 0.0.0.0:8080
```

Environment variables:
- `FLASK_DEBUG=true` for debug mode
- `PORT=8080` (default)
- `DB_PATH=./astronova.db` (default)
- `OPENAI_API_KEY` for chat AI (optional)

### iOS Client
Open `client/astronova.xcodeproj` in Xcode 15+. Use scheme `AstronovaApp` targeting iOS 17+ simulator.

The app auto-connects to `http://127.0.0.1:8080` in Debug+Simulator mode.

### Quick Start Script
```bash
./scripts/run-local.sh           # Creates venv, installs deps, boots Flask, opens Xcode
OPEN_XCODE=0 ./scripts/run-local.sh  # Skip opening Xcode
```

## Testing

### Python Tests
```bash
cd server
pip install -r tests/requirements-test.txt
pytest tests/ -v                              # Run all tests (499+ tests)
pytest tests/test_api_integration.py -v       # Run specific file
pytest tests/ -v -m unit                      # Run only unit tests
pytest tests/ -v -m "not slow"                # Skip slow tests
pytest tests/ -v --cov=. --cov-report=html    # With coverage (80% minimum)
```

Test markers: `@pytest.mark.unit`, `@pytest.mark.integration`, `@pytest.mark.slow`, `@pytest.mark.ephemeris`, `@pytest.mark.api`, `@pytest.mark.service`, `@pytest.mark.performance`

### iOS Tests
```bash
cd client
xcodebuild test -project astronova.xcodeproj -scheme AstronovaApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Code Quality

### Pre-commit Hooks
```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files   # Run manually
```

Checks: Black (line-length 127), isort, ruff, bandit, detect-secrets.

### Manual Linting
```bash
cd server
black . --check
isort . --check
ruff check .
bandit -r . -x ./tests
```

## Architecture

### Server (`server/`)

**Entry Point:** `app.py` — Flask app factory with blueprint registration

**Routes** (`routes/`) — 12 API blueprints:
| Blueprint | Purpose | Key Endpoints |
|-----------|---------|---------------|
| `astrology` | Dasha timelines, positions | `GET /positions`, `POST /dashas/complete` |
| `auth` | Apple Sign-In, JWT | `POST /apple`, `GET /validate`, `POST /refresh` |
| `chart` | Birth chart generation | `POST /generate`, `POST /aspects` |
| `chat` | AI chat, birth data sync | `POST /`, `POST /birth-data` |
| `compatibility` | Relationship analysis | `POST /`, `GET/POST /relationships`, `GET /{id}/snapshot` |
| `content` | Quick questions, insights | `GET /management` |
| `discover` | Daily domain insights | `GET /domains`, `POST /snapshot` |
| `ephemeris` | Planetary positions | `GET /current`, `GET /at?date=` |
| `horoscope` | Daily/weekly/monthly | `GET /?sign=&type=` |
| `locations` | Geocoding | `GET /search?q=` |
| `misc` | Health, config, subscription | `GET /health`, `GET /subscription/status` |
| `reports` | Report generation, PDF | `POST /`, `GET /{id}/pdf` |

**Services** (`services/`) — Business logic:
| Service | Purpose |
|---------|---------|
| `ephemeris_service.py` | Swiss Ephemeris wrapper (falls back to simplified math if pyswisseph unavailable) |
| `dasha/` | Vimshottari dasha calculators (timeline.py, assembler.py, constants.py) |
| `planetary_strength_service.py` | Shadbala-like calculations, impact scoring |
| `dasha_interpretation_service.py` | Narrative generation for dasha periods |
| `transit_service.py` | Synastry aspect activation, relationship pulse |
| `chat_response_service.py` | OpenAI integration for personalized chat |
| `report_generation_service.py` | Comprehensive report payload generation |
| `pdf/` | PDF rendering (report_renderer.py, themes.py, canvas.py) |

**Database** (`db.py`) — SQLite with WAL mode, auto-initialized on startup

**Middleware** (`middleware.py`) — Request ID generation, structured logging

### Client (`client/AstronovaApp/`)

**Core Infrastructure:**
| File | Purpose |
|------|---------|
| `AstronovaAppApp.swift` | @main app entry point |
| `RootView.swift` | Tab-based navigation shell (Today, Connect, Time Travel, Ask, Manage) |
| `AuthState.swift` | JWT lifecycle, Keychain storage, feature gates |
| `UserProfile.swift` | Profile model, UserDefaults persistence, chart caching |

**Network Layer:**
| File | Purpose |
|------|---------|
| `NetworkClient.swift` | Async HTTP client, JWT handling, error mapping |
| `APIServices.swift` | Typed API facade for all endpoints |
| `APIModels.swift` | Request/response DTOs (BirthData, ChartResponse, etc.) |

**Feature Views:**
| Feature | Key Files |
|---------|-----------|
| Home | `Features/Home/HomeView.swift`, `HomeViewModel.swift` |
| Discover | `Features/Discover/DiscoverView.swift`, `DomainGridView.swift` |
| Time Travel | `EnhancedTimeTravelView.swift`, `DashaChakraWheelView.swift` |
| Connect | `ConnectView.swift`, `RelationshipDetailView.swift`, `SynastryCompassView.swift` |
| Oracle (Chat) | `Features/Oracle/OracleView.swift`, `OracleViewModel.swift` |
| Self/Profile | `Features/Self/SelfTabView.swift`, `CosmicPulseView.swift` |

**Models:**
| File | Purpose |
|------|---------|
| `DashaModels.swift` | Vimshottari dasha timeline structures |
| `CompatibilityModels.swift` | Synastry, relationship snapshot DTOs |

**Services:**
| File | Purpose |
|------|---------|
| `Services/HapticFeedbackService.swift` | Tactile feedback patterns |
| `Services/BasicStoreManager.swift` | StoreKit 2 wrapper |
| `Config/AppConfig.swift` | Environment-based API URL resolution |

## Key API Endpoints

### Ephemeris & Positions
- `GET /api/v1/ephemeris/current` — Current planetary positions
- `GET /api/v1/ephemeris/at?date=YYYY-MM-DD&system=vedic` — Positions at date
- `GET /api/v1/astrology/positions` — Simplified positions dict

### Dasha (Vedic Timeline)
- `POST /api/v1/astrology/dashas/complete` — Complete dasha with impact analysis
  ```json
  {
    "birthData": { "date": "YYYY-MM-DD", "time": "HH:MM", "timezone": "IANA", "latitude": float, "longitude": float },
    "targetDate": "YYYY-MM-DD",
    "includeTransitions": true,
    "includeEducation": true
  }
  ```

### Chart
- `POST /api/v1/chart/generate` — Generate natal chart (western/vedic)
- `POST /api/v1/chart/aspects` — Calculate aspects from chart

### Horoscope
- `GET /api/v1/horoscope?sign=aries&type=daily` — Daily/weekly/monthly horoscopes

### Compatibility
- `POST /api/v1/compatibility` — Calculate compatibility between two people
- `GET /api/v1/compatibility/relationships` — List user's relationships (requires X-User-Id)
- `GET /api/v1/compatibility/relationships/{id}/snapshot` — Full compatibility snapshot

### Authentication
- `POST /api/v1/auth/apple` — Apple Sign-In
- `GET /api/v1/auth/validate` — Validate JWT (Bearer token required)
- `POST /api/v1/auth/refresh` — Refresh token

### Reports
- `POST /api/v1/reports` — Generate report (birth_chart, love_forecast, career_forecast, etc.)
- `GET /api/v1/reports/{id}/pdf` — Download report as PDF

### Other
- `GET /api/v1/health` — Health check
- `GET /api/v1/location/search?q=query` — Location search
- `POST /api/v1/chat` — Send chat message

## Database Schema

SQLite database at `server/astronova.db`. Schema managed via migrations in `server/migrations/`.

### Tables

```
┌─────────────────────────┐     ┌─────────────────────────┐
│         users           │     │    user_birth_data      │
├─────────────────────────┤     ├─────────────────────────┤
│ id TEXT PK              │────<│ user_id TEXT PK/FK      │
│ email TEXT              │     │ birth_date TEXT         │
│ first_name TEXT         │     │ birth_time TEXT         │
│ last_name TEXT          │     │ timezone TEXT           │
│ full_name TEXT          │     │ latitude REAL           │
│ created_at TEXT         │     │ longitude REAL          │
│ updated_at TEXT         │     │ location_name TEXT      │
└─────────────────────────┘     │ created_at TEXT         │
         │                      │ updated_at TEXT         │
         │                      └─────────────────────────┘
         │
         ├──────────────────────────────────────┐
         │                                      │
         ▼                                      ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│        reports          │     │   subscription_status   │
├─────────────────────────┤     ├─────────────────────────┤
│ report_id TEXT PK       │     │ user_id TEXT PK/FK      │
│ user_id TEXT FK         │     │ is_active INTEGER       │
│ type TEXT               │     │ product_id TEXT         │
│ title TEXT              │     │ updated_at TEXT         │
│ content TEXT            │     └─────────────────────────┘
│ generated_at TEXT       │
│ status TEXT             │
└─────────────────────────┘

┌─────────────────────────┐     ┌─────────────────────────┐
│   chat_conversations    │     │     chat_messages       │
├─────────────────────────┤     ├─────────────────────────┤
│ id TEXT PK              │────<│ id TEXT PK              │
│ user_id TEXT FK         │     │ conversation_id TEXT FK │
│ created_at TEXT         │     │ user_id TEXT            │
│ updated_at TEXT         │     │ role TEXT               │
└─────────────────────────┘     │ content TEXT            │
                                │ created_at TEXT         │
                                └─────────────────────────┘

┌─────────────────────────┐     ┌─────────────────────────┐
│     relationships       │     │    content_insights     │
├─────────────────────────┤     ├─────────────────────────┤
│ id TEXT PK              │     │ id TEXT PK              │
│ user_id TEXT FK         │     │ title TEXT              │
│ partner_name TEXT       │     │ content TEXT            │
│ partner_birth_date TEXT │     │ category TEXT           │
│ partner_birth_time TEXT │     │ priority INTEGER        │
│ partner_timezone TEXT   │     │ is_active INTEGER       │
│ partner_latitude REAL   │     └─────────────────────────┘
│ partner_longitude REAL  │
│ is_favorite INTEGER     │
│ created_at TEXT         │
└─────────────────────────┘
```

### Database Migrations

Migrations are managed via Python files in `server/migrations/`. Migrations run automatically at app startup.

**Adding a new migration:**
1. Create `server/migrations/NNN_description.py` (e.g., `002_add_user_preferences.py`)
2. Define required constants and functions:
   ```python
   VERSION = 2
   NAME = "add_user_preferences"

   def up(conn: sqlite3.Connection) -> None:
       cur = conn.cursor()
       cur.execute("ALTER TABLE users ADD COLUMN preferences TEXT")
       conn.commit()

   def down(conn: sqlite3.Connection) -> None:  # Optional
       pass
   ```
3. Restart the server — migration runs automatically

**Check migration status:**
```bash
sqlite3 server/astronova.db "SELECT * FROM schema_migrations"
```

## Design System

Design tokens are in `client/AstronovaApp/`. New code should use these files directly.

### Files
| File | Purpose |
|------|---------|
| `CosmicColors.swift` | Colors, gradients, light/dark mode parity |
| `CosmicTypography.swift` | Type scale, tracking, line heights |
| `CosmicDesignSystem.swift` | Spacing, sizing, elevation, components |
| `CosmicDesignTokens.swift` | Legacy compatibility (shadows, starburst) |
| `CosmicMotion.swift` | Animations, transitions, haptic patterns |

### Color Palette
```
Backgrounds:  cosmicVoid → cosmicCosmos → cosmicNebula → cosmicStardust → cosmicTwilight
Accents:      cosmicGold (#D4A853), cosmicBrass (#B08D57), cosmicCopper (#C67D4D), cosmicAmethyst (#9B7ED9)
Text:         cosmicTextPrimary, cosmicTextSecondary, cosmicTextTertiary
Semantic:     cosmicSuccess, cosmicWarning, cosmicError, cosmicInfo
Planets:      planetSun, planetMoon, planetMercury, planetVenus, planetMars, planetJupiter, planetSaturn, etc.
```

### Typography Scale
```
hero:     44pt Bold      — Hero headlines
display:  32pt Bold      — Display headlines
title1:   26pt Semibold  — Primary titles
title2:   22pt Semibold  — Secondary titles
headline: 18pt Semibold  — Headlines
body:     16pt Regular   — Body text
callout:  14pt Regular   — Callout text
caption:  12pt Medium    — Caption text
micro:    10pt Medium    — Micro text
```

Usage: `Text("Hello").font(.cosmicTitle1)` or `CosmicText("Hello", style: .title1)`

### Gradients
- `LinearGradient.cosmicAntiqueGold` — Primary CTA gradient (brass → gold → copper)
- `LinearGradient.cosmicCelestialDawn` — Warm gradient (gold → copper → amethyst)
- `LinearGradient.cosmicDeepSpace` — Background gradient
- `RadialGradient.cosmicGoldGlow` — Focus state glow

### Button Styles
- `CosmicPrimaryButtonStyle` — Gradient (brass → gold → copper)
- `CosmicSecondaryButtonStyle` — Surface with gold border
- `CosmicGhostButtonStyle` — Text-only gold

### Animations
- `cosmicInstant` (100ms), `cosmicQuick` (200ms), `cosmicSmooth` (300ms), `cosmicReveal` (500ms)
- `cosmicSpring`, `cosmicBounce`, `cosmicSnappy`, `cosmicGentle`

## Services Documentation

### EphemerisService
Calculates planetary positions using Swiss Ephemeris (falls back to approximations if unavailable).
- **Western (tropical)**: Standard zodiac
- **Vedic (sidereal)**: Lahiri ayanamsha correction
- Supports: Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto, Rahu, Ketu
- Rising sign requires latitude/longitude

### DashaService (Vimshottari)
120-year cycle: Ketu (7y) → Venus (20y) → Sun (6y) → Moon (10y) → Mars (7y) → Rahu (18y) → Jupiter (16y) → Saturn (19y) → Mercury (17y)
- Moon's nakshatra determines starting period
- Hierarchical: Mahadasha → Antardasha → Pratyantardasha

### PlanetaryStrengthService
Calculates Shadbala-like strength scores:
- Positional strength (exaltation/debilitation)
- Directional strength (angular houses)
- Temporal strength (day/night, retrograde)
- Impact scoring across: career, relationships, health, spiritual

### TransitService
Calculates relationship pulse based on synastry aspect activation by transits.
- Aspect types: conjunction (0°), sextile (60°), square (90°), trine (120°), opposition (180°)
- Pulse states: flowing, electric, magnetic, grounded, friction

## Configuration & Deployment

### Environment-Aware API URL (iOS)
- Debug + Simulator: `http://127.0.0.1:8080`
- Device/Release: `https://astronova.onrender.com`
- Override: Set `API_BASE_URL` in Info.plist

### Render Deployment (server/render.yaml)
- Python 3.11.0
- Port 8080
- Health check: `/health`
- Auto-deploy on main branch

### Docker (server/Dockerfile)
- Base: python:3.11-slim
- Healthcheck: `/api/v1/health` every 30s

## Conventions

- **Python**: PEP 8, max line length 127, type hints encouraged
- **Swift**: iOS 17+ APIs, SwiftUI with MVVM patterns
- **Commit messages**: Conventional Commits (`feat:`, `fix:`, `refactor:`, etc.)
- **Coverage requirement**: 80% minimum for Python backend
- **Error handling**: NetworkError enum (iOS), JSON error responses (server)

## Common Development Tasks

### Adding a New API Endpoint
1. Create/update route in `server/routes/{blueprint}.py`
2. Add service method in `server/services/` if business logic needed
3. Update OpenAPI spec in `server/openapi_spec.yaml`
4. Add Swift method in `client/AstronovaApp/APIServices.swift`
5. Add response model in `client/AstronovaApp/APIModels.swift`
6. Add tests in `server/tests/test_{feature}.py`

### Adding a New SwiftUI View
1. Create view file in appropriate `Features/` subfolder
2. Create ViewModel if needed (MVVM pattern)
3. Use design tokens from `CosmicColors.swift`, `CosmicTypography.swift`
4. Wire to navigation in `RootView.swift` or parent view
5. Add accessibility identifiers for UI testing

### Running Specific Test Categories
```bash
pytest -m unit              # Fast unit tests only
pytest -m "not slow"        # Skip slow tests
pytest -m ephemeris         # Swiss Ephemeris tests
pytest -m api               # API endpoint tests
pytest --durations=10       # Show 10 slowest tests
```

## Logo & Branding

**Logo Elements:**
- **Nova Star** — 4-point star in center (white → cyan gradient)
- **Orbit Arc** — ~86% circular arc with rounded ends (cyan gradient)
- **Planet** — Golden orb on orbit path with glow

**Logo Colors:**
```
Star:       #FFFFFF → #9EEBFF (white to cyan)
Orbit:      #CCF2FF → #73D9FF (light cyan, 85%→60% opacity)
Planet:     #FABF26 (golden amber)
Background: #080817 → #0D3875 (deep space)
```

**Regenerate PNGs:**
```bash
mkdir -p tools/branding/output/module-cache
xcrun swiftc -O -parse-as-library \
  -module-cache-path tools/branding/output/module-cache \
  -o tools/branding/output/generate_astronova_assets \
  tools/branding/generate_astronova_assets.swift
tools/branding/output/generate_astronova_assets tools/branding/output
```

## Troubleshooting

- **Build errors about SwiftUI `.onChange`**: Ensure iOS 17+ SDK and Xcode 15+
- **"Cannot find type in scope"**: Confirm files are in AstronovaApp target (Xcode > Target Membership)
- **API decode errors**: NetworkClient logs raw response body; check `NetworkError.decodingError`
- **Time Travel shows no Dashas**: View displays toast explaining missing profile fields (birth time, location, timezone required)
- **Simulator to Flask connectivity**: Use `http://127.0.0.1:8080` (default in Debug/Simulator)
- **Swiss Ephemeris unavailable**: Backend falls back to approximations (less accurate); install `pyswisseph` for full precision
- **Coverage below 80%**: Run `pytest --cov=. --cov-report=html` and check `htmlcov/index.html` for uncovered code
