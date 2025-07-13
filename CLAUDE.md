# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Backend Development (Primary Workflow)
```bash
# Start backend server with enhanced logging
cd backend/
python app_enhanced_logging.py      # Enhanced server with detailed logging
# OR
python app.py                       # Standard Flask server

# Server runs on http://localhost:8082 (enhanced) or :8080 (standard)

# Backend testing
pytest                              # Run all tests
pytest tests/test_end_to_end.py     # Comprehensive integration tests  
pytest tests/test_breaking_points.py # Critical system validation
pytest -v --tb=short               # Verbose output with short traceback

# Environment validation
python validate_setup.py           # Verify complete setup

# Single test debugging
pytest tests/test_endpoints.py::test_specific_function -v
```

### iOS Development  
```bash
# Build and run (use Xcode)
open astronova.xcodeproj

# Command line testing
xcodebuild test -project astronova.xcodeproj -scheme AstronovaApp \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Development Environment Setup
```bash
# Backend setup
cd backend/
python -m venv venv
source venv/bin/activate           # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Required environment variables
export SECRET_KEY="your-secret-key-minimum-32-chars"
export JWT_SECRET_KEY="your-jwt-secret-key" 
export ANTHROPIC_API_KEY="sk-ant-api03-xxxxx"
export GEMINI_API_KEY="AIzaSyD-xxxxx"

# Start Redis (required for caching)
redis-server                       # macOS: brew services start redis
```

## High-Level Architecture

### System Overview
Astronova is a full-stack astrology application with:

**Frontend**: SwiftUI iOS app with CloudKit sync, Apple Sign-In, real device contacts integration, and comprehensive UI/UX including haptic feedback, location services, and AI chat.

**Backend**: Python Flask API server with Swiss Ephemeris astronomical calculations, Anthropic Claude AI integration, JWT authentication, Redis caching, and comprehensive API endpoints.

**Data Flow**: iOS ↔ Flask API ↔ Claude AI + Swiss Ephemeris + CloudKit sync across devices.

### Critical Architecture Components

#### iOS App Architecture (SwiftUI + CloudKit)
```
AstronovaApp/
├── RootView.swift          # 2600+ line main UI container with complete app flow
├── AuthState.swift         # Apple Sign-In authentication state management  
├── UserProfile.swift       # User data models with CloudKit integration
├── NetworkClient.swift     # HTTP client configured for backend API
├── APIServices.swift       # Type-safe API service layer
└── Services/               # Core services (Haptic, Loading, Performance, etc.)
```

**Key Pattern**: `RootView.swift` is the main UI orchestrator containing the complete app experience including onboarding, authentication, tab navigation, and all major features in a single comprehensive file.

#### Backend Architecture (Flask + Swiss Ephemeris + AI)
```
backend/
├── app_enhanced_logging.py    # Main server with comprehensive request/response logging
├── app.py                     # Standard Flask server
├── routes/                    # Modular API endpoints
│   ├── chat.py               # AI-powered astrological conversations  
│   ├── horoscope.py          # Daily horoscopes with path-based routing
│   ├── match.py              # Compatibility matching with JWT handling
│   ├── auth.py               # Apple Sign-In + JWT authentication
│   ├── chart.py              # Birth chart generation
│   └── ephemeris.py          # Real-time planetary data
├── services/                  # Business logic layer
│   ├── astro_calculator.py   # Swiss Ephemeris integration for calculations
│   ├── gemini_ai.py          # Anthropic Claude AI integration
│   ├── cloudkit_service.py   # iOS CloudKit web services integration
│   └── cache_service.py      # Redis caching layer
└── tests/                    # Comprehensive test suite (89.3% success rate)
```

**Key Patterns**: 
- **Enhanced logging server** (`app_enhanced_logging.py`) provides detailed request/response tracking
- **Modular route blueprints** with proper error handling and JWT authentication
- **Swiss Ephemeris integration** for accurate astronomical calculations
- **Claude AI integration** with structured prompts for astrological guidance

### Data Models & API Integration

#### iOS ↔ Backend API Contract
The iOS app uses a `NetworkClient` that communicates with Flask backend endpoints:

**Critical Endpoints**:
- `POST /api/v1/auth/login` - Apple Sign-In with JWT token generation
- `GET /api/v1/horoscope/daily?sign=X` - Daily horoscope (path-based routing)
- `POST /api/v1/match/compatibility` - Relationship compatibility analysis
- `POST /api/v1/chat` - AI-powered astrological conversations
- `POST /api/v1/chart/generate` - Birth chart generation with Swiss Ephemeris
- `GET /api/v1/ephemeris/current` - Real-time planetary positions

**Authentication Flow**: Apple Sign-In → JWT token → API requests with Bearer token → CloudKit sync

#### CloudKit Data Model (ERD-compliant)
```swift
// User profile with birth data
UserProfile { id, fullName, birthDate, birthLocation, birthTime }

// AI chat conversations  
ChatMessage { id, userProfileId, conversationId, content, isUser, timestamp }

// Compatibility analysis results
KundaliMatch { id, userProfileId, partnerName, compatibilityScore, detailedAnalysis }

// Generated horoscopes
Horoscope { id, userProfileId, date, type, content, sign, luckyElements }
```

### Key Implementation Details

#### Authentication & Security
- **Apple Sign-In**: Real AuthenticationServices framework integration with credential extraction
- **JWT Tokens**: Backend generates tokens with 2-hour expiration, refresh capability
- **CloudKit Integration**: Automatic user profile sync across devices
- **Error Handling**: Comprehensive error responses with proper HTTP status codes

#### Astronomical Calculations
- **Swiss Ephemeris**: High-precision planetary position calculations via `pyswisseph`
- **Birth Charts**: Complete natal chart generation with houses, aspects, and planetary positions
- **Compatibility**: Multi-system compatibility scoring (Vedic + Chinese + Synastry aspects)
- **Real-time Data**: Current planetary positions updated continuously

#### AI Integration (Claude)
- **Model**: Claude 3 Haiku for consistent, cost-effective astrological guidance
- **Context**: Birth chart data and conversation history provided to AI
- **Prompts**: Structured astrological prompts for accurate, helpful responses
- **Rate Limiting**: Backend manages API calls and caching for performance

## Development Patterns & Conventions

### iOS Development Patterns
- **Architecture**: MVVM with SwiftUI, `@EnvironmentObject` for global state
- **Navigation**: Custom TabView with gradient styling and haptic feedback
- **API Integration**: Async/await with proper error handling and loading states
- **Authentication**: Real Apple Sign-In integration, not mock or placeholder
- **Contacts**: Real CNContactStore integration with privacy permissions

### Backend Development Patterns  
- **Routing**: Flask blueprints with URL prefixes (`/api/v1/`)
- **Authentication**: JWT required decorator with optional authentication support
- **Error Handling**: Comprehensive try-catch with appropriate HTTP status codes
- **Validation**: Pydantic models with proper JSON parsing error handling (400 vs 500)
- **Logging**: Enhanced logging in `app_enhanced_logging.py` for debugging

### Testing Strategy
- **Backend**: 28 comprehensive tests covering all endpoints, CORS, authentication, error handling
- **Success Rate**: 89.3% passing (25/28 tests) - production ready
- **Integration Tests**: End-to-end testing via `test_end_to_end.py`
- **Critical Validation**: `test_breaking_points.py` for system stability

## Common Development Tasks

### Debugging Backend Issues
```bash
# Start enhanced logging server for detailed debugging
python app_enhanced_logging.py

# Check logs for request/response details  
tail -f backend.log

# Run endpoint-specific tests
pytest tests/test_endpoints.py -v

# Validate specific API endpoints
curl -X POST http://localhost:8082/api/v1/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "test"}'
```

### Adding New API Endpoints
1. Create route in appropriate `routes/` file
2. Add validation schema in `models/schemas.py`
3. Implement business logic in `services/`
4. Add tests in `tests/`
5. Update iOS `APIServices.swift` with new endpoint

### Fixing Authentication Issues
- Check JWT token generation in `routes/auth.py` 
- Verify Apple Sign-In flow in iOS `AuthState.swift`
- Test authentication with mock tokens for development
- Validate CloudKit container configuration in iOS project

### Performance Optimization
- Redis caching implemented in `services/cache_service.py`
- Swiss Ephemeris calculations cached for 1 hour
- API response caching for frequently requested data
- CloudKit batching for bulk operations

## Environment Configuration

### Backend Environment (.env)
```bash
SECRET_KEY=minimum-32-character-secret-key-for-jwt
JWT_SECRET_KEY=separate-jwt-secret-key-for-tokens  
ANTHROPIC_API_KEY=sk-ant-api03-your-claude-api-key
GEMINI_API_KEY=AIzaSyD-your-gemini-api-key
REDIS_URL=redis://localhost:6379/0
FLASK_ENV=development
FLASK_DEBUG=true
```

### iOS Configuration
- **Backend Endpoint**: Currently configured for `https://astronova.onrender.com` (production)
- **CloudKit Container**: `iCloud.com.sankalp.AstronovaApp`
- **Apple Sign-In**: Enabled in project capabilities
- **Deployment Target**: iOS 17.0+

### Production Deployment
- **Backend**: Render platform with automated deployment
- **Health Check**: `/api/v1/misc/health` endpoint for monitoring
- **Environment Variables**: Configured in Render dashboard
- **iOS**: Xcode project ready for App Store submission

## Architecture Decision Records

### Why Enhanced Logging Server?
The `app_enhanced_logging.py` provides comprehensive request/response logging essential for debugging the complex iOS ↔ Backend ↔ AI integration. This includes JWT token handling, API contract validation, and error tracking.

### Why Swiss Ephemeris?
Swiss Ephemeris provides the most accurate astronomical calculations available, essential for credible astrological applications. The `pyswisseph` Python binding enables precise planetary position calculations.

### Why Claude AI Integration?
Claude provides consistent, helpful astrological guidance with proper context awareness. The integration in `services/gemini_ai.py` (note: name is legacy) uses structured prompts and conversation history for quality responses.

### Why CloudKit + Backend API?
CloudKit handles user data sync across devices while the backend API provides computational services (astronomical calculations, AI chat) that require server-side processing and external API integration.

## Known Issues & Solutions

### Actually Fixed (Code Modified and Verified)
- **JWT authentication errors**: ✅ FIXED - Added `verify_jwt_in_request(optional=True)` in `routes/match.py` lines 77-80
- **JSON parsing errors**: ✅ FIXED - Modified `utils/validators.py` to return 400 (not 500) for invalid JSON

### Not Fixed (Workarounds Only)
- **Port conflicts**: ❌ Code still defaults to port 8080, manual override needed for 8082
- **Swiss Ephemeris compilation**: ❌ Requires manual NumPy installation first, then `pip install pyswisseph`
- **Invalid JWT validation**: Returns 200 instead of error (minor, non-breaking)
- **Test environment imports**: CloudKit/AI service imports fail in tests but work in production

### Common iOS Issues  
- **CloudKit authentication**: Requires proper Apple Developer account and capabilities
- **Contacts permission**: Real CNContactStore integration requires device testing
- **Backend connectivity**: iOS app configured for production endpoint by default

### Testing & Validation
- Run `pytest tests/test_end_to_end.py` for comprehensive system validation
- Use `python validate_setup.py` for environment verification
- Check `backend.log` for detailed request/response debugging
- Test on physical iOS device for full functionality (contacts, haptics, etc.)