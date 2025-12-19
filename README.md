# Astronova

[![Test Suite](https://github.com/yourusername/astronova/actions/workflows/test.yml/badge.svg)](https://github.com/yourusername/astronova/actions/workflows/test.yml)
[![iOS Build](https://github.com/yourusername/astronova/actions/workflows/ios.yml/badge.svg)](https://github.com/yourusername/astronova/actions/workflows/ios.yml)
[![codecov](https://codecov.io/gh/yourusername/astronova/branch/main/graph/badge.svg)](https://codecov.io/gh/yourusername/astronova)
[![Python 3.9+](https://img.shields.io/badge/python-3.9+-blue.svg)](https://www.python.org/downloads/)
[![Swift 5.9](https://img.shields.io/badge/swift-5.9-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

iOS SwiftUI app + Flask backend for Vedic and Western astrology: horoscopes, birth charts, compatibility analysis, Vimshottari dasha timelines, and an animated Time Travel visualization.

## Features

- **Daily Horoscopes** — Personalized daily, weekly, and monthly horoscopes for all 12 zodiac signs
- **Birth Charts** — Generate Western (tropical) and Vedic (sidereal) natal charts with house placements
- **Vimshottari Dasha** — Complete 120-year Vedic timeline with Mahadasha, Antardasha, and Pratyantardasha
- **Time Travel** — Interactive visualization of planetary positions and dasha periods across time
- **Compatibility** — Synastry analysis with relationship pulse, aspect activation, and journey forecasts
- **AI Chat** — Personalized astrological guidance powered by OpenAI
- **Reports** — Comprehensive PDF reports for birth charts, love, career, and more

## Quick Start

### Backend
```bash
cd server
pip install -r requirements.txt
python app.py                    # Runs on http://0.0.0.0:8080
```

### iOS Client
1. Open `client/astronova.xcodeproj` in Xcode 15+
2. Select scheme `AstronovaApp` targeting iOS 17+ simulator
3. Build and run (the app connects to `http://127.0.0.1:8080` automatically)

### One-Command Setup
```bash
./scripts/run-local.sh           # Creates venv, installs deps, boots Flask, opens Xcode
```

## Project Structure

```
astronova/
├── client/                      # iOS SwiftUI app
│   ├── AstronovaApp/           # Main app source
│   │   ├── Features/           # Feature modules (Home, Discover, TimeTravel, etc.)
│   │   ├── Services/           # iOS services (Haptics, Store, etc.)
│   │   ├── CosmicColors.swift  # Design system colors
│   │   ├── NetworkClient.swift # HTTP client
│   │   └── APIServices.swift   # API facade
│   └── astronova.xcodeproj     # Xcode project
├── server/                      # Flask API
│   ├── routes/                 # API blueprints (12 modules)
│   ├── services/               # Business logic
│   │   ├── ephemeris_service.py
│   │   ├── dasha/              # Vimshottari calculations
│   │   └── pdf/                # Report rendering
│   ├── tests/                  # Pytest test suite (499+ tests)
│   ├── app.py                  # Flask app factory
│   └── db.py                   # SQLite schema
├── docs/                        # Documentation
└── tools/                       # Utilities (branding, scripts)
```

## API Overview

All endpoints use the `/api/v1/` prefix.

| Category | Key Endpoints |
|----------|---------------|
| **Ephemeris** | `GET /ephemeris/current`, `GET /ephemeris/at?date=YYYY-MM-DD` |
| **Dasha** | `POST /astrology/dashas/complete` |
| **Charts** | `POST /chart/generate`, `POST /chart/aspects` |
| **Horoscopes** | `GET /horoscope?sign=aries&type=daily` |
| **Compatibility** | `POST /compatibility`, `GET /compatibility/relationships/{id}/snapshot` |
| **Reports** | `POST /reports`, `GET /reports/{id}/pdf` |
| **Chat** | `POST /chat` |
| **Auth** | `POST /auth/apple`, `GET /auth/validate` |

See [CLAUDE.md](./CLAUDE.md) for complete API documentation.

## Testing

### Backend (Python)
```bash
cd server
pip install -r tests/requirements-test.txt
pytest tests/ -v                              # Run all tests
pytest tests/ -v --cov=. --cov-report=html    # With coverage (80% minimum)
```

### iOS (Swift)
```bash
cd client
xcodebuild test -project astronova.xcodeproj -scheme AstronovaApp \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Configuration

### Environment Variables (Backend)
| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Server port |
| `FLASK_DEBUG` | `false` | Enable debug mode |
| `DB_PATH` | `./astronova.db` | SQLite database path |
| `OPENAI_API_KEY` | — | Required for AI chat |

### iOS API URL
- **Debug + Simulator**: `http://127.0.0.1:8080`
- **Production**: `https://astronova.onrender.com`
- Override via `API_BASE_URL` in Info.plist

## Technology Stack

**Backend:**
- Python 3.9+ with Flask
- Swiss Ephemeris (pyswisseph) for planetary calculations
- SQLite database
- OpenAI GPT-4o-mini for chat

**iOS:**
- SwiftUI (iOS 17+)
- Async/await networking
- Keychain for JWT storage
- StoreKit 2 for in-app purchases

## Documentation

- [CLAUDE.md](./CLAUDE.md) — Development guide for AI assistants and contributors
- [docs/](./docs/) — Feature specifications and technical documentation

## CI/CD

GitHub Actions workflows:
- **test.yml** — Python tests across 3.9-3.12, coverage enforcement (80%)
- **ios.yml** — Xcode build and tests
- **deploy.yml** — Staging/production deployment to Render

## Contributing

1. Install pre-commit hooks: `pip install pre-commit && pre-commit install`
2. Run tests before committing: `pytest tests/ -v`
3. Follow [Conventional Commits](https://www.conventionalcommits.org/)

## License

MIT License — see [LICENSE](LICENSE) for details.
