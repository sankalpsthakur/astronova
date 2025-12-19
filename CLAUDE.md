# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Astronova is an iOS SwiftUI app with a Flask backend for Vedic astrology features: horoscopes, birth charts, compatibility analysis, dasha timelines, and a Time Travel visualization.

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

### iOS Client
Open `client/astronova.xcodeproj` in Xcode 15+. Use scheme `AstronovaApp` targeting iOS 17+ simulator.

The app auto-connects to `http://127.0.0.1:8080` in Debug+Simulator mode.

## Testing

### Python Tests
```bash
cd server
pip install -r tests/requirements-test.txt
pytest tests/ -v                              # Run all tests
pytest tests/test_api_integration.py -v       # Run specific file
pytest tests/test_api_integration.py::TestHoroscopeEndpoints::test_horoscope_all_signs -v  # Run specific test
pytest tests/ -v --cov=. --cov-report=html    # With coverage
```

Test markers: `@pytest.mark.unit`, `@pytest.mark.integration`, `@pytest.mark.slow`, `@pytest.mark.ephemeris`, `@pytest.mark.api`

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
- `app.py` — Flask app factory, blueprint registration, health endpoints, Swagger UI at `/docs`
- `routes/` — API blueprints: astrology, auth, chart, chat, compatibility, content, discover, ephemeris, horoscope, locations, reports
- `services/` — Business logic:
  - `ephemeris_service.py` — Swiss Ephemeris wrapper (falls back to simplified math if pyswisseph unavailable)
  - `dasha/` — Vimshottari dasha calculators (timeline + assembler)
  - `planetary_strength_service.py` — Shadbala calculations
  - `report_generation_service.py` — Report generation

API base path: `/api/v1/*`

### Client (`client/AstronovaApp/`)
- `NetworkClient.swift` — Async HTTP client, JWT handling, error mapping
- `APIServices.swift` — Typed API facade for endpoints
- `AuthState.swift` — JWT lifecycle, Keychain storage, feature gates
- `EnhancedTimeTravelView.swift` — Primary Time Travel experience with dasha API integration
- `RootView.swift` — Tab shell (Today, Connect, Time Travel, Ask, Manage)

## Key API Endpoints

- `GET /api/v1/ephemeris/current` — Current planetary positions
- `GET /api/v1/ephemeris/at?date=YYYY-MM-DD` — Positions at date
- `GET /api/v1/astrology/dashas/complete` — Complete dasha timeline (requires birth data)
- `GET /api/v1/horoscope?sign=aries&type=daily` — Daily/weekly/monthly horoscopes
- `POST /api/v1/compatibility` — Compatibility calculation
- `GET /api/v1/chart/aspects?date=YYYY-MM-DD` — Aspects for date
- `GET /health` or `GET /api/v1/health` — Health check

## Database Schema

SQLite database at `server/astronova.db`. Schema defined in `server/db.py`.

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
│ content_quick_questions │     │    content_insights     │
├─────────────────────────┤     ├─────────────────────────┤
│ id TEXT PK              │     │ id TEXT PK              │
│ text TEXT               │     │ title TEXT              │
│ category TEXT           │     │ content TEXT            │
│ order_index INTEGER     │     │ category TEXT           │
│ is_active INTEGER       │     │ priority INTEGER        │
└─────────────────────────┘     │ is_active INTEGER       │
                                └─────────────────────────┘
```

### Key Relationships
- `user_birth_data.user_id` → `users.id` (1:1, birth chart data)
- `subscription_status.user_id` → `users.id` (1:1, subscription state)
- `reports.user_id` → `users.id` (1:N, generated reports)
- `chat_conversations.user_id` → `users.id` (1:N, chat sessions)
- `chat_messages.conversation_id` → `chat_conversations.id` (1:N, messages in conversation)

## Design System

Design tokens are in `client/AstronovaApp/`. New code should use these files directly.

### Files
| File | Purpose |
|------|---------|
| `CosmicColors.swift` | Colors, gradients, light/dark mode parity |
| `CosmicTypography.swift` | Type scale, tracking, line heights |
| `CosmicDesignSystem.swift` | Spacing, sizing, elevation, components |
| `CosmicDesignTokens.swift` | Legacy compatibility (shadows, starburst) |
| `CosmicMotion.swift` | Animations, transitions |

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

### Logo & Branding

**Logo Elements:**
- **Nova Star** — 4-point star in center (white → cyan gradient)
- **Orbit Arc** — ~86% circular arc with rounded ends (cyan gradient)
- **Planet** — Golden orb on orbit path with glow
- **Background** (icon only) — Deep space gradient with purple glow

**Logo Colors:**
```
Star:       #FFFFFF → #9EEBFF (white to cyan)
Orbit:      #CCF2FF → #73D9FF (light cyan, 85%→60% opacity)
Planet:     #FABF26 (golden amber)
Background: #080817 → #0D3875 (deep space)
Glow:       #7566FA (purple, 50% opacity)
```

**Logo Files:**
| File | Purpose |
|------|---------|
| `tools/branding/astronova-icon.svg` | App icon with dark background |
| `tools/branding/astronova-mark.svg` | Transparent mark (no background) |
| `tools/branding/output/astronova-icon-1024.png` | Generated PNG |
| `client/.../Assets.xcassets/BrandLogo.imageset/` | Asset catalog |
| `client/.../Components/BrandLogoView.swift` | SwiftUI component |

**Usage in App:**
```swift
BrandLogoView(size: 56)  // Uses PNG asset, falls back to programmatic rendering
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

## Conventions

- Python: PEP 8, max line length 127, type hints encouraged
- Swift: iOS 17+ APIs, SwiftUI with MVVM patterns
- Commit messages: Conventional Commits (`feat:`, `fix:`, `refactor:`, etc.)
- Coverage requirement: 80% minimum for Python backend
