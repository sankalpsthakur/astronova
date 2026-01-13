# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Astronova is an iOS SwiftUI app with a Flask backend for Vedic astrology features: horoscopes, birth charts, compatibility analysis, Vimshottari dasha timelines, and a Time Travel visualization. Recent additions include a complete Temple/Pooja booking system with live video sessions.

**Structure:**
- `client/` — iOS SwiftUI app (Xcode project: `client/astronova.xcodeproj`)
  - 79 Swift files, MVVM architecture, iOS 17+ target
  - 5-tab navigation: Today, Connect, Time Travel, Ask (Oracle), Manage
- `server/` — Flask API (entry point: `server/app.py`)
  - 13 API blueprints, 19 test files (499+ tests), 80% test coverage
  - SQLite database with WAL mode and auto-migrations

**Tech Stack:**
- **Backend**: Python 3.11, Flask, SQLite, Swiss Ephemeris, OpenAI API
- **Frontend**: SwiftUI, iOS 17+, Combine, StoreKit 2, MapKit
- **Testing**: pytest (backend), XCTest (iOS), pre-commit hooks
- **Deployment**: Render (Flask), Xcode Cloud (iOS)

## Build & Run Commands

### Backend (Flask)
```bash
cd server
pip install -r requirements.txt
python app.py                    # Runs on 0.0.0.0:8080
```

**Environment Variables:**
| Variable | Required | Default | Purpose |
|----------|----------|---------|---------|
| `PORT` | No | `8080` | Server port |
| `FLASK_DEBUG` | No | `false` | Enable debug mode (auto-reload) |
| `DB_PATH` | No | `./astronova.db` | SQLite database file path |
| `GEMINI_API_KEY` | For chat | - | Google Gemini API key for Oracle chat (preferred) |
| `GEMINI_MODEL` | No | `gemini-1.5-flash` | Gemini model for chat |
| `OPENAI_API_KEY` | For chat | - | OpenAI API key (fallback if Gemini not available) |
| `OPENAI_MODEL` | No | `gpt-4o-mini` | OpenAI model for chat |
| `JWT_SECRET` | Recommended | Auto-generated | JWT signing secret (set in production) |
| `APPLE_BUNDLE_ID` | For iOS auth | - | Apple Sign-In bundle identifier |

### iOS Client
Open `client/astronova.xcodeproj` in Xcode 15+. Use scheme `AstronovaApp` targeting iOS 17+ simulator.

The app auto-connects to `http://127.0.0.1:8080` in Debug+Simulator mode.

### Local Development
```bash
# Terminal 1: Start Flask server
cd server
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py

# Terminal 2: Open Xcode
cd client
open astronova.xcodeproj
```

**Note**: No automated local development script exists. For production deployment, use `server/start.sh` (Render deployment script).

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

**Backend (Python):**
```bash
cd server
black . --check                    # Format checking
isort . --check                    # Import sorting
ruff check .                       # Fast linting
bandit -r . -x ./tests             # Security scanning
```

**Frontend (Swift):**
```bash
cd client
swiftlint lint                     # Swift linting and style checking

# Install SwiftLint:
brew install swiftlint
```

SwiftLint rules can be configured in `.swiftlint.yml` if present, otherwise uses default Swift style guidelines.

## Project Structure

### Directory Layout

```
astronova/
├── client/                          # iOS SwiftUI app
│   ├── astronova.xcodeproj/         # Xcode project
│   ├── AstronovaApp/                # Main app source
│   │   ├── Features/                # Feature modules (MVVM)
│   │   │   ├── Home/                # Today tab
│   │   │   ├── Discover/            # Domain insights
│   │   │   ├── TimeTravel/          # Dasha timeline
│   │   │   ├── Oracle/              # AI chat
│   │   │   ├── Self/                # Profile & settings
│   │   │   ├── Temple/              # Pooja booking
│   │   │   └── Paywall/             # Subscription
│   │   ├── Services/                # Business logic layer
│   │   ├── Config/                  # App configuration
│   │   ├── Cosmic*.swift            # Design system
│   │   ├── APIServices.swift        # API client facade
│   │   ├── APIModels.swift          # DTOs
│   │   ├── NetworkClient.swift      # HTTP client
│   │   ├── AuthState.swift          # Global auth state
│   │   └── UserProfile.swift        # User data model
│   ├── AstronovaAppTests/           # Unit tests
│   └── AstronovaAppUITests/         # UI tests
│
├── server/                          # Flask backend
│   ├── app.py                       # Flask app factory
│   ├── db.py                        # Database interface
│   ├── middleware.py                # Logging, request IDs
│   ├── routes/                      # API blueprints (13 files)
│   │   ├── astrology.py             # Dasha, positions
│   │   ├── auth.py                  # Apple Sign-In, JWT
│   │   ├── chart.py                 # Birth charts
│   │   ├── chat.py                  # AI chat
│   │   ├── compatibility.py         # Relationships
│   │   ├── content.py               # Quick questions
│   │   ├── discover.py              # Domain insights
│   │   ├── ephemeris.py             # Planetary positions
│   │   ├── horoscope.py             # Daily/weekly/monthly
│   │   ├── locations.py             # Geocoding
│   │   ├── misc.py                  # Health, subscription
│   │   ├── reports.py               # PDF reports
│   │   └── temple.py                # Pooja booking
│   ├── services/                    # Business logic
│   │   ├── dasha/                   # Vimshottari calculations
│   │   ├── pdf/                     # PDF rendering
│   │   ├── ephemeris_service.py     # Swiss Ephemeris
│   │   ├── planetary_strength_service.py
│   │   ├── dasha_interpretation_service.py
│   │   ├── transit_service.py
│   │   ├── chat_response_service.py
│   │   └── report_generation_service.py
│   ├── migrations/                  # Database migrations
│   │   ├── 001_initial_schema.py
│   │   └── 002_temple_pooja_booking.py
│   ├── tests/                       # Test suite (19 files)
│   │   ├── conftest.py              # Shared fixtures
│   │   ├── test_service_layer.py
│   │   ├── test_api_integration.py
│   │   ├── test_temple.py
│   │   └── ...
│   ├── requirements.txt             # Production deps
│   ├── astronova.db                 # SQLite database
│   └── openapi_spec.yaml            # API specification
│
├── tools/                           # Utility scripts
│   └── branding/                    # Logo generation
│
├── app-store-assets/                # App Store submission materials
│   ├── APP_STORE_SUBMISSION.md      # Submission guide & copy
│   └── COPY_PASTE_READY.txt         # Ready-to-paste text fields
│
├── CLAUDE.md                        # This file
├── .pre-commit-config.yaml          # Pre-commit hooks
└── README.md                        # Project README
```

### File Naming Conventions

**Python (Backend):**
- `snake_case.py` for all files
- `test_*.py` for test files
- `*_service.py` for service layer
- `*_bp` variable suffix for Flask blueprints

**Swift (iOS):**
- `PascalCase.swift` for all files
- `*View.swift` for SwiftUI views
- `*ViewModel.swift` for view models
- `*Models.swift` for data models
- `*Service.swift` for service layer
- `Cosmic*.swift` for design system
- `*Tests.swift` for test files

### Code Organization Principles

1. **Separation of Concerns**: Routes → Services → Database
2. **MVVM on iOS**: View → ViewModel → Services → API
3. **Feature Modules**: Group related files by feature (iOS Features/)
4. **Shared Components**: Design system, utilities extracted
5. **Test Colocation**: Tests mirror source structure

## Architecture

### Server (`server/`)

**Entry Point:** `app.py` — Flask app factory with blueprint registration

**Routes** (`routes/`) — 13 API blueprints:
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
| `temple` | Pooja booking, pandits, video sessions | `GET /poojas`, `POST /bookings`, `POST /session/{id}/token` |

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
| Temple | `Features/Temple/TempleView.swift`, `TempleModels.swift` (Astrologers, Pooja, Oracle) |
| Paywall | `Features/Paywall/PaywallView.swift` |

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

### Temple (Pooja Booking & Video Sessions)
- `GET /api/v1/temple/poojas` — List available pooja types
- `GET /api/v1/temple/poojas/{id}` — Get pooja details
- `GET /api/v1/temple/pandits` — List available pandits (query: specialization, language, available)
- `GET /api/v1/temple/pandits/{id}` — Get pandit details
- `GET /api/v1/temple/pandits/{id}/availability` — Get available time slots
- `POST /api/v1/temple/bookings` — Create pooja booking
- `GET /api/v1/temple/bookings` — List user bookings (query: status)
- `GET /api/v1/temple/bookings/{id}` — Get booking details
- `POST /api/v1/temple/bookings/{id}/cancel` — Cancel booking
- `POST /api/v1/temple/bookings/{id}/session` — Generate video session link
- `POST /api/v1/temple/pandits/enroll` — Enroll new pandit
- `GET /api/v1/temple/pandit/bookings` — List pandit's bookings (requires X-Pandit-Id header)
- `POST /api/v1/temple/filter-message` — Filter contact details from messages

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

# Temple / Pooja Booking Tables

┌─────────────────────────┐     ┌─────────────────────────┐
│      pooja_types        │     │    pooja_bookings       │
├─────────────────────────┤     ├─────────────────────────┤
│ id TEXT PK              │────<│ id TEXT PK              │
│ name TEXT               │     │ user_id TEXT FK         │
│ description TEXT        │     │ pooja_type_id TEXT FK   │
│ deity TEXT              │     │ pandit_id TEXT FK       │
│ duration_minutes INT    │     │ scheduled_date TEXT     │
│ base_price INT          │     │ scheduled_time TEXT     │
│ icon_name TEXT          │     │ timezone TEXT           │
│ benefits TEXT (JSON)    │     │ status TEXT             │
│ ingredients TEXT (JSON) │     │ sankalp_name TEXT       │
│ mantras TEXT (JSON)     │     │ sankalp_gotra TEXT      │
│ is_active INTEGER       │     │ sankalp_nakshatra TEXT  │
└─────────────────────────┘     │ special_requests TEXT   │
                                │ amount_paid INTEGER     │
┌─────────────────────────┐     │ payment_status TEXT     │
│        pandits          │     │ session_link TEXT       │
├─────────────────────────┤     │ session_id TEXT         │
│ id TEXT PK              │────<│ created_at TEXT         │
│ name TEXT               │     │ updated_at TEXT         │
│ email TEXT              │     └─────────────────────────┘
│ phone TEXT              │              │
│ specializations TEXT    │              │
│ languages TEXT (JSON)   │              ▼
│ experience_years INT    │     ┌─────────────────────────┐
│ rating REAL             │     │    pooja_sessions       │
│ review_count INTEGER    │     ├─────────────────────────┤
│ price_per_session INT   │     │ id TEXT PK              │
│ avatar_url TEXT         │     │ booking_id TEXT FK      │
│ bio TEXT                │     │ provider TEXT           │
│ is_verified INTEGER     │     │ user_link TEXT          │
│ is_available INTEGER    │     │ pandit_link TEXT        │
│ created_at TEXT         │     │ started_at TEXT         │
└─────────────────────────┘     │ ended_at TEXT           │
         │                      │ status TEXT             │
         ▼                      │ created_at TEXT         │
┌─────────────────────────┐     └─────────────────────────┘
│  pandit_availability    │
├─────────────────────────┤     ┌─────────────────────────┐
│ id TEXT PK              │     │  contact_filter_logs    │
│ pandit_id TEXT FK       │     ├─────────────────────────┤
│ day_of_week INTEGER     │     │ id TEXT PK              │
│ start_time TEXT         │     │ context_type TEXT       │
│ end_time TEXT           │     │ context_id TEXT         │
│ is_active INTEGER       │     │ sender_type TEXT        │
└─────────────────────────┘     │ sender_id TEXT          │
                                │ original_message TEXT   │
                                │ filtered_message TEXT   │
                                │ patterns_matched TEXT   │
                                │ action_taken TEXT       │
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

### Temple/Pooja Booking System
Complete pooja booking workflow with video session integration:
- **Pooja Types**: Pre-configured poojas with deity, duration, benefits, ingredients, mantras
- **Pandit Management**: Enrollment, availability scheduling, rating system
- **Booking Flow**:
  1. User selects pooja type and time slot
  2. System auto-assigns pandit or user selects preferred pandit
  3. Payment confirmation triggers session link generation
  4. Both parties receive unique video session links
- **Video Sessions**: WebRTC integration for live pooja streaming
  - Token-based authentication for secure access
  - Mock tokens provided for development when video service not configured
  - Session recording support
- **Contact Filtering**: Automatic removal of phone/email/social handles from chat messages
  - Regex-based pattern matching for Indian/international numbers
  - Logs all filter actions for monitoring
  - Prevents direct contact exchange during sessions

## iOS App Architecture & Patterns

### Navigation Structure
- **Tab-Based Navigation**: RootView.swift contains 5 main tabs:
  1. **Today** (Home) — Daily insights, cosmic pulse, domain cards
  2. **Connect** — Relationships, compatibility, synastry compass
  3. **Time Travel** — Dasha timeline visualization, chakra wheel
  4. **Ask** (Oracle) — AI chat with astrological context
  5. **Manage** (Self) — Profile, reports, settings

### MVVM Pattern
- **ViewModels**: Observe `@Published` properties for state changes
- **Services**: Injected via initializer or singleton (e.g., `NetworkClient.shared`)
- **Data Flow**: View → ViewModel → Service → API → Database

### State Management
- **AuthState**: Global authentication state (`@EnvironmentObject`)
- **UserProfile**: Persistent user data in UserDefaults with Codable
- **Feature Gates**: Subscription-based feature access via `AuthState.hasActiveSubscription`

### Design System Usage
Always use design tokens from `CosmicColors.swift`, `CosmicTypography.swift`, `CosmicMotion.swift`:
```swift
// Colors
.foregroundColor(.cosmicGold)
.background(Color.cosmicVoid)

// Typography
Text("Title").font(.cosmicTitle1)
CosmicText("Body", style: .body)

// Spacing
.padding(.horizontal, Cosmic.Spacing.screen)  // 20pt
.padding(.vertical, Cosmic.Spacing.md)        // 12pt

// Animations
.animation(.cosmicSmooth, value: state)
withAnimation(.cosmicSpring) { ... }
```

### Error Handling
- **NetworkError**: Centralized error enum in NetworkClient.swift
  - `.unauthorized`, `.notFound`, `.serverError`, `.decodingError`, etc.
- **User-Facing Messages**: Convert NetworkError to localized strings
- **Retry Logic**: Built into NetworkClient for transient failures

### Accessibility
- Add `.accessibilityIdentifier()` for UI test automation
- Use `.accessibilityLabel()` for VoiceOver support
- Maintain 44pt minimum tap targets (Cosmic.Size.touchTarget)

## Security & Rate Limiting

### Authentication
- **JWT-based**: Token issued after Apple Sign-In
- **Headers**:
  - `Authorization: Bearer <token>` — Standard JWT auth
  - `X-User-Id: <user_id>` — Alternative for user identification
  - `X-Pandit-Id: <pandit_id>` — Pandit-specific endpoints
- **Token Expiration**: 30 days (configurable in `routes/auth.py`)
- **Refresh Tokens**: Use `POST /api/v1/auth/refresh` with valid token

### Rate Limiting
Rate limits prevent API abuse using flask-limiter with in-memory storage.

**Default Limits** (per IP or X-User-Id):
- 200 requests per day
- 60 requests per hour

**Expensive Endpoints** (stricter limits):
- `/api/v1/reports/*` — 20 per minute
- `/api/v1/chart/generate` — 20 per minute
- `/api/v1/compatibility/*` — 20 per minute
- `/api/v1/astrology/dashas/*` — 20 per minute

**Exemptions**:
- `/api/v1/health` — No rate limit (health checks)
- `/docs` — No rate limit (API documentation)

**Rate Limit Response**:
```json
{
  "error": "Rate limit exceeded",
  "message": "60 per hour",
  "code": "RATE_LIMIT_EXCEEDED"
}
```
HTTP Status: `429 Too Many Requests`

### CORS Configuration
Allowed origins (configured in `app.py`):
- `https://astronova.onrender.com`
- `https://astronova.app`
- `http://localhost:8080`
- `http://127.0.0.1:8080`

**Note**: iOS native apps don't send Origin headers, so CORS primarily protects against browser-based attacks.

### Contact Filtering (Temple Feature)
Automatic removal of contact information from chat/video messages:
- Phone numbers (Indian/international, spaced digits)
- Email addresses
- Social media handles (WhatsApp, Telegram, Instagram)
- URLs
- Pattern: Replaced with `[contact removed]`
- Logged in `contact_filter_logs` table for monitoring

### Security Best Practices
1. **JWT Secret**: Always set `JWT_SECRET` in production (don't rely on auto-generated)
2. **HTTPS Only**: Production should enforce HTTPS (handled by Render)
3. **Database**: SQLite with WAL mode for concurrent access
4. **Input Validation**: All endpoints validate input types and required fields
5. **SQL Injection**: Use parameterized queries (no string interpolation)
6. **Secrets Detection**: Pre-commit hook (`detect-secrets`) scans for leaked credentials

## API Documentation

### Interactive Docs (Swagger UI)
Access at: `http://localhost:8080/docs` (or `/api/v1/docs`)

Features:
- Try-it-out functionality for all endpoints
- Request/response schemas
- Authentication testing
- Example payloads

### OpenAPI Spec
Available at: `/api/v1/openapi.yaml`

Use with tools like:
- Postman (import OpenAPI spec)
- Insomnia
- HTTPie Desktop
- Swagger Editor

## Performance Optimization

### Backend Performance

**Database Optimization:**
- **WAL Mode**: Write-Ahead Logging enabled for concurrent reads
- **Connection Pooling**: Single connection per request (SQLite limitation)
- **Indexes**: Key indexes on `user_id`, `created_at`, `updated_at` columns
- **Query Optimization**: Use parameterized queries, avoid N+1 queries

**Caching Strategies:**
- **Swiss Ephemeris**: Planetary calculations cached per date/location
- **Chart Generation**: User charts cached in `UserProfile` (iOS)
- **Static Content**: OpenAPI spec, Swagger UI loaded once

**Rate Limiting Performance:**
- In-memory storage (fast but resets on restart)
- For production: Consider Redis for distributed rate limiting

**Expensive Operations:**
- **Dasha Timeline**: Full calculation ~100-200ms (includes 3 hierarchy levels)
- **Chart Generation**: Western/Vedic chart ~50-100ms
- **Compatibility Analysis**: Full synastry ~150-300ms
- **PDF Generation**: Report rendering ~500ms-2s (depends on content)

**Optimization Tips:**
1. Use `includeTransitions=false` if transitions not needed (faster dasha calc)
2. Cache frequently accessed user data (birth data, preferences)
3. Batch API calls where possible (iOS: combine multiple requests)
4. Use `pytest -n auto` for parallel test execution

### iOS Performance

**Network Optimization:**
- **Concurrent Requests**: NetworkClient supports parallel API calls
- **Request Debouncing**: Search inputs debounced (500ms default)
- **Image Loading**: Lazy loading for avatars/icons
- **Response Caching**: UserDefaults for profile, Keychain for tokens

**UI Performance:**
- **SwiftUI Previews**: Use lightweight data for previews
- **List Performance**: Use `LazyVStack` for long scrollable lists
- **Animation Performance**: Prefer `.cosmicSmooth` (300ms) for most animations
- **Memory Management**: Avoid retain cycles with `[weak self]` in closures

**Build Performance:**
- **Incremental Builds**: Xcode caches Swift modules
- **Clean Build**: Only when necessary (Cmd+Shift+K)
- **Parallel Build**: Enabled by default in Xcode 15+

**Profiling Tools:**
- **Backend**: Use `pytest --durations=10` to find slow tests
- **iOS**: Xcode Instruments (Time Profiler, Allocations, Network)

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

## Code Examples & Common Patterns

### Backend API Endpoint Pattern

**Standard route structure:**
```python
from flask import Blueprint, jsonify, request
from middleware import require_auth
from db import get_connection

my_bp = Blueprint("my_feature", __name__)

@my_bp.route("/items", methods=["GET"])
@require_auth  # Adds authentication requirement
def list_items():
    """GET /api/v1/my_feature/items - List all items"""
    user_id = request.headers.get("X-User-Id")

    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT id, name, created_at
        FROM items
        WHERE user_id = ?
        ORDER BY created_at DESC
    """, (user_id,))

    items = [
        {"id": row["id"], "name": row["name"], "createdAt": row["created_at"]}
        for row in cur.fetchall()
    ]

    conn.close()
    return jsonify({"items": items})

@my_bp.route("/items", methods=["POST"])
@require_auth
def create_item():
    """POST /api/v1/my_feature/items - Create new item"""
    data = request.get_json() or {}
    user_id = request.headers.get("X-User-Id")

    # Validate required fields
    if not data.get("name"):
        return jsonify({"error": "name is required"}), 400

    conn = get_connection()
    cur = conn.cursor()

    item_id = str(uuid.uuid4())
    now = datetime.utcnow().isoformat()

    cur.execute("""
        INSERT INTO items (id, user_id, name, created_at)
        VALUES (?, ?, ?, ?)
    """, (item_id, user_id, data["name"], now))

    conn.commit()
    conn.close()

    return jsonify({"id": item_id, "name": data["name"]}), 201
```

### iOS API Service Pattern

**Adding a new API method:**
```swift
// In APIServices.swift
extension APIServices {
    func fetchItems() async throws -> [Item] {
        let response: ItemsResponse = try await client.request(
            endpoint: "/my_feature/items",
            responseType: ItemsResponse.self
        )
        return response.items
    }

    func createItem(name: String) async throws -> Item {
        let payload = CreateItemRequest(name: name)
        let response: Item = try await client.request(
            endpoint: "/my_feature/items",
            method: .POST,
            body: payload,
            responseType: Item.self
        )
        return response
    }
}

// In APIModels.swift
struct ItemsResponse: Codable {
    let items: [Item]
}

struct Item: Codable, Identifiable {
    let id: String
    let name: String
    let createdAt: String
}

struct CreateItemRequest: Codable {
    let name: String
}
```

### iOS ViewModel Pattern

**MVVM with async/await:**
```swift
@MainActor
class ItemsViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService: APIServices

    init(apiService: APIServices = .shared) {
        self.apiService = apiService
    }

    func loadItems() async {
        isLoading = true
        errorMessage = nil

        do {
            items = try await apiService.fetchItems()
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
            print("Failed to load items: \(error)")
        } catch {
            errorMessage = "An unexpected error occurred"
            print("Unexpected error: \(error)")
        }

        isLoading = false
    }

    func createItem(name: String) async {
        do {
            let newItem = try await apiService.createItem(name: name)
            items.insert(newItem, at: 0)
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        }
    }
}
```

### iOS View with ViewModel

```swift
struct ItemsView: View {
    @StateObject private var viewModel = ItemsViewModel()
    @State private var showingAddSheet = false
    @State private var newItemName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cosmicVoid.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage) {
                        Task { await viewModel.loadItems() }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: Cosmic.Spacing.md) {
                            ForEach(viewModel.items) { item in
                                ItemCard(item: item)
                            }
                        }
                        .padding(.horizontal, Cosmic.Spacing.screen)
                    }
                }
            }
            .navigationTitle("Items")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.cosmicGold)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddItemSheet(
                    itemName: $newItemName,
                    onCreate: {
                        Task {
                            await viewModel.createItem(name: newItemName)
                            showingAddSheet = false
                            newItemName = ""
                        }
                    }
                )
            }
        }
        .task {
            await viewModel.loadItems()
        }
    }
}
```

### Database Migration Example

```python
# server/migrations/003_add_items_table.py
import sqlite3

VERSION = 3
NAME = "add_items_table"

def up(conn: sqlite3.Connection) -> None:
    """Apply migration"""
    cur = conn.cursor()

    # Create table
    cur.execute("""
        CREATE TABLE IF NOT EXISTS items (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
    """)

    # Add indexes
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_items_user_id
        ON items(user_id)
    """)

    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_items_created_at
        ON items(created_at DESC)
    """)

    conn.commit()

def down(conn: sqlite3.Connection) -> None:
    """Rollback migration (optional)"""
    cur = conn.cursor()
    cur.execute("DROP TABLE IF EXISTS items")
    conn.commit()
```

### Error Handling Patterns

**Backend error responses:**
```python
# Standard error format
return jsonify({"error": "User not found"}), 404
return jsonify({"error": "Invalid input", "details": {"field": "email"}}), 400

# With error codes
return jsonify({
    "error": "Rate limit exceeded",
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests"
}), 429
```

**iOS error handling:**
```swift
do {
    let data = try await apiService.fetchData()
    // Success path
} catch let error as NetworkError {
    switch error {
    case .authenticationFailed, .tokenExpired:
        // Trigger re-authentication
        authState.signOut()
    case .offline:
        // Show offline banner
        showOfflineBanner = true
    case .serverError(let code, _) where code >= 500:
        // Retry with exponential backoff
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        // Retry logic
    default:
        // Show error to user
        errorMessage = error.errorDescription
    }
} catch {
    // Handle unexpected errors
    print("Unexpected error: \(error)")
}
```

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

### Adding Temple/Pooja Features
1. **New Pooja Type**:
   - Add entry to `pooja_types` table (via SQL or migration)
   - Include: name, description, deity, duration, price, icon, benefits, ingredients, mantras
   - Update iOS `TempleModels.swift` if needed
2. **Pandit Management**:
   - Pandits enroll via `/api/v1/temple/pandits/enroll`
   - Set availability via `pandit_availability` table
   - Admin must verify (set `is_verified = 1`)
3. **Video Session Integration**:
   - Configure video service credentials in environment
   - Session links auto-generate on booking confirmation
   - Frontend loads video SDK for live streaming

### Database Changes & Migrations
When adding new tables or columns:
1. Create migration file: `server/migrations/00X_description.py`
2. Define `VERSION`, `NAME`, `up(conn)`, optionally `down(conn)`
3. Migration runs automatically on server start
4. Check status: `sqlite3 server/astronova.db "SELECT * FROM schema_migrations"`

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

## Test Infrastructure & Best Practices

### Backend Test Suite (499+ tests, 80% coverage minimum)
Located in `server/tests/` with 19 test files covering unit, integration, and E2E scenarios.

**Test Categories:**
| Category | Marker | Purpose | Files |
|----------|--------|---------|-------|
| Unit | `@pytest.mark.unit` | Fast service-layer tests | `test_service_layer.py` |
| Integration | `@pytest.mark.integration` | API endpoint tests | `test_api_integration.py` |
| Ephemeris | `@pytest.mark.ephemeris` | Swiss Ephemeris calculations | `test_ephemeris.py` |
| API | `@pytest.mark.api` | HTTP endpoint validation | `test_api_*.py` |
| Slow | `@pytest.mark.slow` | Time-intensive tests | Various |
| Performance | `@pytest.mark.performance` | Performance benchmarks | `test_performance.py` |

**Running Tests:**
```bash
# All tests with coverage
pytest tests/ -v --cov=. --cov-report=html

# Fast tests only (skip slow)
pytest -m "not slow"

# Specific category
pytest -m unit              # Unit tests
pytest -m api               # API tests
pytest -m ephemeris         # Ephemeris tests

# Parallel execution (faster)
pytest tests/ -n auto

# Specific test file
pytest tests/test_temple.py -v

# Show slowest tests
pytest --durations=10
```

**Key Test Files:**
- `test_service_layer.py` — Core service unit tests (DashaService, EphemerisService, etc.)
- `test_dasha_transitions.py` — P1 bug validation for days_remaining calculations
- `test_horoscope_service.py` — Horoscope generation and lucky elements
- `test_dasha_timezone_accuracy.py` — Timezone handling validation
- `test_api_integration.py` — Complete API endpoint coverage
- `test_auth_integration.py` — Authentication flow tests
- `test_temple.py` — Pooja booking system tests
- `conftest.py` — Shared fixtures (test_client, sample_birth_data, etc.)

**Test Fixtures (`conftest.py`):**
```python
@pytest.fixture
def test_client():
    """Flask test client with auto-initialized database"""

@pytest.fixture
def sample_birth_data():
    """Standard birth data for consistent testing"""

@pytest.fixture
def auth_headers(test_client):
    """Authenticated request headers with JWT"""

@pytest.fixture
def sample_user_id():
    """Test user ID for database operations"""
```

**Coverage Requirements:**
- Minimum 80% overall coverage
- Check with: `pytest --cov=. --cov-report=term-missing`
- HTML report: `pytest --cov=. --cov-report=html` → `htmlcov/index.html`

### iOS Test Suite
Located in `client/AstronovaAppTests/` and `client/AstronovaAppUITests/`

**Test Types:**
- **Unit Tests** (`AstronovaAppTests/`): Model logic, utilities, data transformations
- **UI Tests** (`AstronovaAppUITests/`): User flow validation, UI component testing
  - `MonetizationJourneyTests.swift` — Paywall and subscription flows
  - `AstronovaAppUITests.swift` — Core navigation and feature tests

**Running iOS Tests:**
```bash
# Command line
cd client
xcodebuild test \
  -project astronova.xcodeproj \
  -scheme AstronovaApp \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Or use Xcode: Cmd+U to run all tests
```

### Test Database Management
- Tests use in-memory SQLite database (`:memory:`)
- Fresh database for each test via `test_client` fixture
- Migrations auto-apply during test setup
- No cleanup needed (memory database discarded after test)

### Writing New Tests

**Backend Test Template:**
```python
@pytest.mark.unit
def test_new_feature(test_client, sample_birth_data):
    """Test description"""
    # Arrange
    payload = {"birthData": sample_birth_data}

    # Act
    response = test_client.post('/api/v1/endpoint', json=payload)

    # Assert
    assert response.status_code == 200
    data = response.get_json()
    assert 'expectedField' in data
```

**iOS Test Template:**
```swift
func testFeature() throws {
    // Arrange
    let app = XCUIApplication()
    app.launch()

    // Act
    app.buttons["featureButton"].tap()

    // Assert
    XCTAssertTrue(app.staticTexts["expectedText"].exists)
}
```

### Continuous Integration
- Pre-commit hooks run Black, isort, ruff, bandit, detect-secrets
- Install: `pip install pre-commit && pre-commit install`
- Manual: `pre-commit run --all-files`

## Development Workflow Tips

### Local Development Setup
```bash
# Terminal 1: Start Flask server
cd server
python app.py

# Terminal 2: Open Xcode
open client/astronova.xcodeproj
```

### Hot Reload & Debugging
- **Flask**: Set `FLASK_DEBUG=true` for auto-reload on file changes
- **iOS**: Xcode hot reload via SwiftUI previews (Cmd+Option+P)
- **Breakpoints**: Use `import pdb; pdb.set_trace()` (Python) or Xcode breakpoints (Swift)

### API Testing
```bash
# Using curl
curl http://127.0.0.1:8080/api/v1/health

# With authentication
curl -H "Authorization: Bearer <JWT_TOKEN>" \
     http://127.0.0.1:8080/api/v1/astrology/positions

# POST with JSON
curl -X POST http://127.0.0.1:8080/api/v1/temple/bookings \
     -H "Content-Type: application/json" \
     -H "X-User-Id: test-user-123" \
     -d '{"poojaTypeId": "pooja_ganesh", "scheduledDate": "2025-01-20", "scheduledTime": "10:00"}'
```

### Database Inspection
```bash
# Open database
sqlite3 server/astronova.db

# Common queries
SELECT * FROM users LIMIT 5;
SELECT * FROM pooja_bookings WHERE status = 'pending';
SELECT * FROM schema_migrations;

# Export schema
sqlite3 server/astronova.db .schema > schema.sql
```

### Git Workflow
```bash
# Feature branch
git checkout -b feat/new-feature

# Commit with conventional commits
git commit -m "feat(temple): add booking cancellation flow"
git commit -m "fix(api): resolve JWT expiration handling"
git commit -m "refactor(ios): extract common chart components"

# Before pushing, ensure tests pass
pytest tests/ -v
pre-commit run --all-files
```

## Common Pitfalls & Anti-Patterns

### Backend Anti-Patterns

❌ **Don't: String concatenation in SQL queries**
```python
# BAD - SQL injection vulnerability!
query = f"SELECT * FROM users WHERE id = '{user_id}'"
cur.execute(query)
```

✅ **Do: Use parameterized queries**
```python
# GOOD - Safe from SQL injection
cur.execute("SELECT * FROM users WHERE id = ?", (user_id,))
```

❌ **Don't: Forget to close database connections**
```python
# BAD - Connection leak
conn = get_connection()
cur = conn.cursor()
# ... queries ...
return jsonify(data)  # Connection never closed!
```

✅ **Do: Always close connections**
```python
# GOOD
conn = get_connection()
cur = conn.cursor()
# ... queries ...
conn.close()  # Always close
return jsonify(data)
```

❌ **Don't: Return sensitive data**
```python
# BAD - Exposes sensitive fields
return jsonify(user)  # Might include password_hash, tokens, etc.
```

✅ **Do: Explicitly select returned fields**
```python
# GOOD - Only return safe fields
return jsonify({
    "id": user["id"],
    "name": user["name"],
    "email": user["email"]
})
```

❌ **Don't: Use `print()` for logging**
```python
# BAD - Lost in production
print(f"User logged in: {user_id}")
```

✅ **Do: Use structured logging**
```python
# GOOD - Captured in logs
logger.info("User logged in", extra={"user_id": user_id})
```

### iOS Anti-Patterns

❌ **Don't: Force unwrap optionals**
```swift
// BAD - Crashes if nil!
let data = response.data!
```

✅ **Do: Safely unwrap with guard or if-let**
```swift
// GOOD
guard let data = response.data else {
    print("No data received")
    return
}
```

❌ **Don't: Block main thread with synchronous code**
```swift
// BAD - UI freezes!
@MainActor
func loadData() {
    let data = apiService.fetchDataSync()  // Blocks UI
    self.items = data
}
```

✅ **Do: Use async/await**
```swift
// GOOD - Non-blocking
@MainActor
func loadData() async {
    do {
        let data = try await apiService.fetchData()
        self.items = data
    } catch {
        print("Error: \(error)")
    }
}
```

❌ **Don't: Create retain cycles**
```swift
// BAD - Memory leak!
apiService.fetchData { data in
    self.items = data  // Retains self
}
```

✅ **Do: Use weak self in closures**
```swift
// GOOD - Prevents retain cycle
apiService.fetchData { [weak self] data in
    self?.items = data
}

// Or with async/await (no closure needed):
Task {
    let data = try await apiService.fetchData()
    self.items = data  // Safe with async/await
}
```

❌ **Don't: Hardcode colors or spacing**
```swift
// BAD - Inconsistent design
Text("Hello").foregroundColor(Color(hex: "#D4A853"))
    .padding(.horizontal, 20)
```

✅ **Do: Use design tokens**
```swift
// GOOD - Consistent with design system
Text("Hello").foregroundColor(.cosmicGold)
    .padding(.horizontal, Cosmic.Spacing.screen)
```

❌ **Don't: Nest too many views in body**
```swift
// BAD - Hard to read, slow to compile
var body: some View {
    VStack {
        HStack {
            VStack {
                // ... 50+ lines of nested views
            }
        }
    }
}
```

✅ **Do: Extract subviews**
```swift
// GOOD - Modular and readable
var body: some View {
    VStack {
        HeaderView()
        ContentView()
        FooterView()
    }
}
```

### Testing Anti-Patterns

❌ **Don't: Write tests that depend on each other**
```python
# BAD - Test order matters
def test_create_user():
    user_id = create_user()
    global last_user_id
    last_user_id = user_id

def test_delete_user():
    delete_user(last_user_id)  # Depends on previous test!
```

✅ **Do: Make tests independent**
```python
# GOOD - Each test is self-contained
def test_create_user(test_client):
    response = test_client.post('/users', json={"name": "Test"})
    assert response.status_code == 201

def test_delete_user(test_client, sample_user_id):
    response = test_client.delete(f'/users/{sample_user_id}')
    assert response.status_code == 200
```

## Related Documentation

### Additional Resources

Beyond this CLAUDE.md file, the project contains additional documentation:

**In `/docs/` directory:**
- `architecture.md` — Detailed system architecture and data flow diagrams
- `api-reference.md` — Complete REST API endpoint documentation with examples
- `development.md` — Comprehensive development guide and setup instructions
- `compatibility-design-spec.md` — Relationship compatibility feature design specification
- `astrology-accuracy.md` — Quantitative accuracy benchmarks against Swiss Ephemeris

**Root directory files:**
- `CONTRIBUTING.md` — Contribution guidelines, PR process, CI/CD pipeline
- `README.md` — Project overview and quick start guide
- `E2E_TEST_REPORT.md` — End-to-end testing results and findings
- `TEST_REPORT.md` — Comprehensive test results and coverage reports
- `FRESH_BUILD_TEST_REPORT.md` — Fresh build testing verification (latest)
- `UX_GAP_ANALYSIS.md` — User experience analysis and improvement recommendations
- `TEMPLE_FEATURE_STATUS.md` — Temple/Pooja booking feature implementation status

**App Store:**
- `app-store-assets/APP_STORE_SUBMISSION.md` — Complete App Store submission guide
- `app-store-assets/COPY_PASTE_READY.txt` — Ready-to-paste App Store Connect fields

**For Comprehensive Understanding:**
1. Start with `CLAUDE.md` (this file) for codebase overview and patterns
2. Check `docs/architecture.md` for system design deep-dive
3. Refer to `CONTRIBUTING.md` for contribution workflow
4. Use `docs/api-reference.md` when working with specific endpoints

## Quick Reference

### Essential Commands

**Backend:**
```bash
# Start server
cd server && python app.py

# Run tests
pytest tests/ -v
pytest -m unit                    # Unit tests only
pytest -m "not slow"              # Skip slow tests

# Check coverage
pytest --cov=. --cov-report=html

# Lint & format
black . && isort . && ruff check .

# Database
sqlite3 server/astronova.db       # Open DB
.schema                           # Show schema
SELECT * FROM users LIMIT 5;      # Query
```

**iOS:**
```bash
# Build & run
open client/astronova.xcodeproj   # Xcode
# Then: Cmd+R to build & run

# Tests
# Xcode: Cmd+U
xcodebuild test -project client/astronova.xcodeproj \
  -scheme AstronovaApp \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Clean build
# Xcode: Cmd+Shift+K
```

### Key File Locations

| File | Purpose |
|------|---------|
| `server/app.py` | Flask app entry point |
| `server/db.py` | Database initialization |
| `server/routes/` | API endpoints (13 blueprints) |
| `server/services/` | Business logic |
| `server/tests/conftest.py` | Test fixtures |
| `client/AstronovaApp/RootView.swift` | iOS main navigation |
| `client/AstronovaApp/AuthState.swift` | Global auth state |
| `client/AstronovaApp/NetworkClient.swift` | HTTP client |
| `client/AstronovaApp/APIServices.swift` | API methods |
| `client/AstronovaApp/Cosmic*.swift` | Design system |
| `CLAUDE.md` | This documentation |

### API Response Formats

**Success:**
```json
{
  "data": {...},
  "message": "Optional success message"
}
```

**Error:**
```json
{
  "error": "Human-readable error",
  "code": "ERROR_CODE",
  "details": {"field": "value"}
}
```

**List Response:**
```json
{
  "items": [...],
  "total": 42,
  "page": 1
}
```

### Environment Variables Quick Reference

```bash
# Backend (.env or export)
export PORT=8080
export FLASK_DEBUG=true
export DB_PATH=./astronova.db
export OPENAI_API_KEY=sk-...
export JWT_SECRET=your-secret-key
```

### Design System Quick Reference

**Colors:**
- Background layers: `cosmicVoid` → `cosmicCosmos` → `cosmicNebula` → `cosmicStardust`
- Accent: `cosmicGold`, `cosmicBrass`, `cosmicCopper`, `cosmicAmethyst`
- Text: `cosmicTextPrimary`, `cosmicTextSecondary`, `cosmicTextTertiary`

**Typography:**
- Hero: 44pt Bold → `.cosmicHero`
- Display: 32pt Bold → `.cosmicDisplay`
- Title1: 26pt Semibold → `.cosmicTitle1`
- Body: 16pt Regular → `.cosmicBody`
- Caption: 12pt Medium → `.cosmicCaption`

**Spacing:**
- `Cosmic.Spacing.xs` = 4pt
- `Cosmic.Spacing.sm` = 8pt
- `Cosmic.Spacing.md` = 12pt
- `Cosmic.Spacing.lg` = 16pt
- `Cosmic.Spacing.xl` = 24pt
- `Cosmic.Spacing.screen` = 20pt (standard horizontal padding)

**Animations:**
- `.cosmicInstant` = 100ms
- `.cosmicQuick` = 200ms
- `.cosmicSmooth` = 300ms
- `.cosmicReveal` = 500ms
- Springs: `.cosmicSpring`, `.cosmicBounce`, `.cosmicSnappy`

### Test Markers Reference

```python
@pytest.mark.unit          # Fast unit tests
@pytest.mark.integration   # API integration tests
@pytest.mark.slow          # Time-consuming tests
@pytest.mark.ephemeris     # Swiss Ephemeris tests
@pytest.mark.api           # HTTP endpoint tests
@pytest.mark.service       # Service layer tests
@pytest.mark.performance   # Performance benchmarks
```

### Common HTTP Status Codes

| Code | Meaning | When to Use |
|------|---------|-------------|
| 200 | OK | Successful GET/PUT/DELETE |
| 201 | Created | Successful POST (new resource) |
| 400 | Bad Request | Invalid input/validation error |
| 401 | Unauthorized | Missing or invalid auth token |
| 403 | Forbidden | Valid token but insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Unexpected server error |

## App Store Submission

### Submission Materials
Located in `app-store-assets/` directory:
- **APP_STORE_SUBMISSION.md** — Complete submission guide with copy for all text fields, screenshot recommendations, and reviewer notes
- **COPY_PASTE_READY.txt** — Ready-to-paste content for App Store Connect fields

### Key Information
- **Bundle ID**: `com.astronova.app`
- **Version**: 1.0
- **Category**: Lifestyle (primary), Entertainment (secondary)
- **Age Rating**: 4+
- **Screenshots Required**: iPhone 6.5" Display (1242 × 2688px or 1284 × 2778px)
  - Minimum 3 screenshots, maximum 10
  - Recommended: Daily insights, Temple services, Expert astrologers

### App Review Notes
- Test account setup instructions provided in submission materials
- Sample birth data for testing: 1990-01-15, 14:30, New York, NY
- Backend API: `https://astronova.onrender.com`
- Features require network connectivity
- StoreKit testing enabled for subscription flow

### Privacy Declarations
Required data disclosures:
- Name, Email (Apple Sign-In)
- User birth data (date, time, location)
- Usage data for analytics
- Purchase history for subscriptions

## Troubleshooting

### Backend Issues
- **Module import errors**: Ensure virtual environment active (`source venv/bin/activate`)
- **Port 8080 already in use**: Find process `lsof -i :8080` and kill it, or change PORT env var
- **Database locked**: SQLite WAL mode enabled; check for zombie connections
- **Swiss Ephemeris unavailable**: Backend falls back to approximations (less accurate); install `pyswisseph` for full precision
- **Coverage below 80%**: Run `pytest --cov=. --cov-report=html` and check `htmlcov/index.html` for uncovered code

### iOS Issues
- **Build errors about SwiftUI `.onChange`**: Ensure iOS 17+ SDK and Xcode 15+
- **"Cannot find type in scope"**: Confirm files are in AstronovaApp target (Xcode > Target Membership)
- **API decode errors**: NetworkClient logs raw response body; check `NetworkError.decodingError`
- **Time Travel shows no Dashas**: View displays toast explaining missing profile fields (birth time, location, timezone required)
- **Simulator to Flask connectivity**: Use `http://127.0.0.1:8080` (default in Debug/Simulator)
- **Xcode preview crashes**: Clean build folder (Cmd+Shift+K), restart Xcode, delete DerivedData

### Database Issues
- **Migration fails**: Check `server/migrations/` for syntax errors; migrations must define `VERSION` and `up(conn)`
- **Missing tables**: Migrations auto-run on startup; check logs for errors
- **Test database pollution**: Tests use in-memory DB (`:memory:`); no cleanup needed
