# Astronova Architecture

## System Overview

Astronova is a full-stack astrology platform consisting of:
- **iOS Client** — SwiftUI app for end users
- **Flask Backend** — REST API for astrology calculations and data persistence

```
┌─────────────────────────────────────────────────────────────────┐
│                        iOS Client                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   Views     │  │  ViewModels │  │  Services   │              │
│  │  (SwiftUI)  │──│   (State)   │──│ (API/Store) │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│                          │                                       │
│                   ┌──────┴──────┐                                │
│                   │ NetworkClient│                                │
│                   └──────┬──────┘                                │
└──────────────────────────┼──────────────────────────────────────┘
                           │ HTTPS
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Flask Backend                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   Routes    │──│  Services   │──│  Database   │              │
│  │ (Blueprints)│  │  (Logic)    │  │  (SQLite)   │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│         │                │                                       │
│         │         ┌──────┴──────┐                                │
│         │         │Swiss Ephemeris│                              │
│         │         └─────────────┘                                │
└─────────────────────────────────────────────────────────────────┘
```

## Backend Architecture

### Layer Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    API Routes Layer                      │
│  astrology │ auth │ chart │ chat │ compatibility │ etc. │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    Services Layer                        │
│  EphemerisService │ DashaService │ TransitService │ etc.│
└─────────────────────────────────────────────────────────┘
                            │
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
┌──────────────────┐ ┌────────────┐ ┌───────────┐
│ Swiss Ephemeris  │ │  OpenAI    │ │  SQLite   │
│  (pyswisseph)    │ │   API      │ │  Database │
└──────────────────┘ └────────────┘ └───────────┘
```

### Routes (12 Blueprints)

| Blueprint | Base Path | Responsibility |
|-----------|-----------|----------------|
| `astrology` | `/api/v1/astrology` | Dasha calculations, planetary positions |
| `auth` | `/api/v1/auth` | Authentication (Apple Sign-In, JWT) |
| `chart` | `/api/v1/chart` | Birth chart generation and aspects |
| `chat` | `/api/v1/chat` | AI chat conversations |
| `compatibility` | `/api/v1/compatibility` | Relationship analysis, synastry |
| `content` | `/api/v1/content` | Content management |
| `discover` | `/api/v1/discover` | Daily domain insights |
| `ephemeris` | `/api/v1/ephemeris` | Planetary positions |
| `horoscope` | `/api/v1/horoscope` | Daily/weekly/monthly horoscopes |
| `locations` | `/api/v1/location` | Geocoding and timezone lookup |
| `misc` | `/api/v1` | Health, config, subscription status |
| `reports` | `/api/v1/reports` | Report generation and PDF download |

### Core Services

#### EphemerisService
Calculates planetary positions using Swiss Ephemeris library.
- **Western (Tropical)**: Standard zodiac (Aries 0° at vernal equinox)
- **Vedic (Sidereal)**: Lahiri ayanamsha correction (~24°)
- **Fallback**: Simplified approximations if pyswisseph unavailable

#### DashaService
Implements Vimshottari dasha system (120-year cycle):
```
Ketu (7y) → Venus (20y) → Sun (6y) → Moon (10y) → Mars (7y)
→ Rahu (18y) → Jupiter (16y) → Saturn (19y) → Mercury (17y)
```

Components:
- `TimelineCalculator`: Generates period sequences
- `DashaAssembler`: Formats response payloads
- `DashaInterpretationService`: Provides narrative content

#### TransitService
Calculates aspect activations for relationship compatibility:
- Detects when transiting planets activate synastry aspects
- Determines relationship "pulse" state (flowing, electric, friction, etc.)
- Generates daily journey forecasts

#### PlanetaryStrengthService
Implements Shadbala-like strength calculations:
- Positional strength (exaltation/debilitation)
- Directional strength (angular houses)
- Temporal strength (day/night, retrograde)
- Impact scoring across life areas

### Database Schema

SQLite database with WAL mode for concurrent reads.

**Core Tables:**
- `users` — User accounts
- `user_birth_data` — Birth chart information (1:1 with users)
- `relationships` — Saved relationships for compatibility
- `reports` — Generated astrology reports
- `chat_conversations` / `chat_messages` — Chat history
- `subscription_status` — In-app purchase state

## iOS Client Architecture

### MVVM Pattern

```
┌─────────────────────────────────────────────────────────┐
│                        View Layer                        │
│  RootView │ HomeView │ ConnectView │ TimeTravelView    │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    ViewModel Layer                       │
│  HomeViewModel │ OracleViewModel │ TimeTravelViewModel │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                     Service Layer                        │
│  APIServices │ AuthState │ UserProfileManager           │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    Network Layer                         │
│               NetworkClient (async/await)                │
└─────────────────────────────────────────────────────────┘
```

### Key Components

#### AuthState
- JWT lifecycle management
- Keychain storage for tokens
- Feature gates based on auth status

#### NetworkClient
- Async/await HTTP client
- Automatic JWT injection
- Error mapping to `NetworkError` enum
- 10s timeout, ISO8601 date decoding

#### APIServices
- Typed facade over all API endpoints
- Methods for charts, horoscopes, dashas, compatibility, etc.

### Navigation Structure

```
RootView (TabBar)
├── Tab 1: Home (Today's guidance)
├── Tab 2: Connect (Relationships/Compatibility)
├── Tab 3: Time Travel (Dasha visualization)
├── Tab 4: Ask (Oracle/Chat)
└── Tab 5: Manage (Profile/Self)
```

### Design System

Cosmic design tokens defined in:
- `CosmicColors.swift` — Color palette with light/dark mode
- `CosmicTypography.swift` — Type scale (hero → micro)
- `CosmicDesignSystem.swift` — Spacing, sizing, elevation
- `CosmicMotion.swift` — Animations and haptic patterns

## Data Flow Examples

### Dasha Timeline Request

```
1. User opens Time Travel view
2. TimeTravelViewModel.loadDashas() called
3. APIServices.fetchCompleteDasha(request) invoked
4. NetworkClient.post("/api/v1/astrology/dashas/complete", body)
5. Flask routes/astrology.py handles request
6. DashaService.calculate_complete_dasha() called
7. TimelineCalculator generates periods
8. DashaAssembler formats response
9. JSON returned to client
10. View renders dasha chakra wheel
```

### Compatibility Snapshot

```
1. User selects relationship in ConnectView
2. Navigate to RelationshipDetailView
3. APIServices.getCompatibilitySnapshot(id) called
4. Flask routes/compatibility.py handles request
5. TransitService calculates current activations
6. Synastry aspects evaluated
7. Pulse state determined
8. CompatibilitySnapshot returned
9. View displays synastry compass and pulse
```

## Deployment Architecture

```
┌─────────────────┐     ┌─────────────────┐
│   iOS Client    │────▶│  Render.com     │
│   (App Store)   │     │  (Flask API)    │
└─────────────────┘     └─────────────────┘
                               │
                        ┌──────┴──────┐
                        │   SQLite    │
                        │  Database   │
                        └─────────────┘
```

**Production URL**: `https://astronova.onrender.com`
**Staging URL**: `https://astronova-staging.onrender.com`

## Security Considerations

- JWT tokens stored in iOS Keychain
- Demo auth mode for development (token: "demo-token")
- CORS enabled for cross-origin requests
- Rate limiting available via Flask middleware
- Input validation on all endpoints
- No sensitive data in logs (middleware filters)
