# AstroNova iOS Frontend Agents & Architecture Documentation

## Overview
This document outlines the agent patterns, AI integrations, and intelligent systems within the AstroNova iOS frontend application.

## Agent Patterns & AI Integrations

### 1. AI Astrologer Chat Agent

**Location**: `RootView.swift` (Cosmic Nexus Tab)  
**Backend Integration**: `/api/v1/chat/send` endpoint  
**Purpose**: Conversational AI astrologer providing personalized astrological guidance

#### Agent Capabilities:
- **Context-Aware Conversations**: Uses user's birth chart data for personalized responses
- **Astrological Expertise**: Specialized AI trained on astrological knowledge
- **Historical Context**: Maintains conversation history for continuity
- **Intelligent Suggestions**: Provides follow-up questions and topic suggestions

#### Implementation Details:
```swift
// Chat service in APIServices.swift:541
func chatWithAstrologer(message: String, context: BirthData?) async throws -> ChatResponse
```

**Features**:
- Real-time chat interface with typing indicators
- Context injection with user's astrological profile
- Error handling with graceful fallbacks
- Offline mode support with cached responses

---

### 2. Intelligent Report Generation Agent

**Location**: `APIServices.swift:400-450`  
**Backend Integration**: AI-powered report services  
**Purpose**: Generates detailed, personalized astrological reports

#### Agent Types:
- **Love Forecast Agent**: Relationship and romantic compatibility analysis
- **Career Forecast Agent**: Professional and financial guidance
- **Year Ahead Agent**: Annual astrological predictions
- **Birth Chart Agent**: Detailed natal chart interpretations

#### Implementation:
```swift
// Report generation with AI enhancement
func generateDetailedReport(type: ReportType, birthData: BirthData) async throws -> ReportResponse
```

---

### 3. Compatibility Matching Agent

**Location**: `APIServices.swift:350-399` & Compatibility Tab  
**Backend Integration**: `/api/v1/match` endpoint  
**Purpose**: AI-enhanced relationship compatibility analysis

#### Agent Features:
- **Multi-System Analysis**: Western, Vedic, and Chinese astrology integration
- **Synastry Calculations**: Advanced astrological aspect analysis
- **Intelligent Scoring**: AI-weighted compatibility metrics
- **Personalized Insights**: Context-aware relationship advice

#### Implementation:
```swift
func calculateCompatibility(user: BirthData, partner: BirthData) async throws -> CompatibilityResponse
```

---

### 4. Predictive Horoscope Agent

**Location**: `APIServices.swift:200-300` & Horoscope Tab  
**Backend Integration**: AI-enhanced horoscope services  
**Purpose**: Generates personalized daily, weekly, and monthly horoscopes

#### Agent Capabilities:
- **Temporal Predictions**: Daily, weekly, monthly, and yearly forecasts
- **Personalization Engine**: Birth chart-specific content generation
- **Trend Analysis**: Identifies astrological patterns and cycles
- **Actionable Insights**: Provides practical guidance and recommendations

---

### 5. Planetary Intelligence Service

**Location**: `PlanetaryDataService.swift:41-204`  
**Purpose**: Real-time planetary position intelligence with caching

#### Agent Features:
- **Real-Time Data**: Current planetary positions and transits
- **Predictive Caching**: Intelligent pre-loading of upcoming planetary data
- **Event Detection**: Identifies significant astrological events
- **Custom Calculations**: User-specific planetary influences

#### Implementation:
```swift
class PlanetaryDataService: ObservableObject {
    func fetchCurrentPlanetaryPositions() async throws -> [Planet]
    func calculatePersonalizedTransits(birthData: BirthData) async throws -> [Transit]
}
```

---

### 6. Location Intelligence Agent

**Location**: `MapKitLocationService.swift:6-100`  
**Purpose**: Intelligent location search and timezone resolution

#### Agent Capabilities:
- **Smart Autocomplete**: MapKit-powered location suggestions
- **Timezone Intelligence**: Automatic timezone detection and historical resolution
- **Geocoding Accuracy**: Precise coordinate and location validation
- **Birth Location Optimization**: Historical timezone accuracy for birth chart calculations

---

### 7. Siri Integration Agent

**Location**: `AstronovaAppIntents.swift` & `SiriIntentHandler.swift`  
**Purpose**: Voice-activated astrological assistant

#### Agent Features:
- **App Shortcuts**: "Get Today's Horoscope", "Check Compatibility", "View Transit"
- **Entity Recognition**: Understands astrological terms and concepts
- **Context Preservation**: Maintains user profile context across Siri interactions
- **Natural Language Processing**: Interprets voice commands for astrological queries

#### Supported Intents:
```swift
// Example Siri shortcuts
- "Hey Siri, what's my horoscope today?"
- "Hey Siri, check my planetary transits"
- "Hey Siri, calculate compatibility with [partner]"
```

---

### 8. Haptic Intelligence Service

**Location**: `HapticFeedbackService.swift:5-215`  
**Purpose**: Context-aware haptic feedback system

#### Agent Features:
- **Cosmic Patterns**: Custom haptic patterns for astrological events
- **Contextual Feedback**: Different patterns for insights, celebrations, and warnings
- **Adaptive Intensity**: Adjusts based on content significance
- **Accessibility Integration**: Enhanced UX for visually impaired users

#### Haptic Patterns:
```swift
enum CosmicHapticPattern {
    case cosmicInsight    // Discovery of astrological insights
    case celebration      // Positive astrological events
    case starburst       // Major astrological alignments
    case subtle          // Background planetary movements
}
```

---

## Service Architecture

### Dependency Injection Container

**Location**: `DependencyContainer.swift`  
**Purpose**: Centralized agent and service management

```swift
class DependencyContainer {
    @Published var apiServices: APIServicesProtocol
    @Published var storeManager: StoreManagerProtocol
    @Published var locationService: LocationServiceProtocol
    
    // Agent instances
    private let chatAgent: ChatAgent
    private let reportAgent: ReportGenerationAgent
    private let compatibilityAgent: CompatibilityAgent
}
```

### Authentication & Personalization

**Location**: `AuthState.swift` & `UserProfile.swift`  
**Purpose**: User context management for AI personalization

#### Features:
- **Profile-Based AI**: All agents use user's birth data for personalization
- **Anonymous Mode**: Limited agent functionality for unauthenticated users
- **Cross-Session Context**: Persistent user preferences and chat history

---

## AI Model Integration

### Primary AI Backend
- **Service**: Gemini AI (Google)
- **Fallback**: Claude AI (Anthropic)
- **Local Processing**: Core Chart calculations (Swiss Ephemeris)

### Data Flow
1. **User Input** → iOS App
2. **Context Enrichment** → Birth Data + Historical Context
3. **AI Processing** → Backend AI Services
4. **Response Enhancement** → Astrological validation
5. **UI Presentation** → SwiftUI with animations

---

## Performance & Caching

### Intelligent Caching Strategy

**Location**: Throughout service layer  
**Purpose**: Optimized AI response times and offline functionality

#### Cache Layers:
- **Planetary Data**: 1-hour cache with predictive refresh
- **Chat History**: Persistent local storage with CloudKit sync
- **Reports**: 24-hour cache with versioning
- **Compatibility**: Relationship-specific caching

---

## Security & Privacy

### AI Data Protection
- **Local Processing**: Birth calculations performed locally when possible
- **Encrypted Transmission**: All AI communications use HTTPS with certificate pinning
- **Data Minimization**: Only necessary context sent to AI services
- **User Consent**: Explicit permissions for AI feature usage

---

## Testing & Quality Assurance

### Mock Agent Services

**Location**: `MockServices.swift`  
**Purpose**: Testing infrastructure for AI agents

#### Features:
- **Deterministic Responses**: Consistent AI responses for testing
- **Edge Case Simulation**: Error conditions and fallback scenarios
- **Performance Testing**: Load testing for AI service endpoints
- **Offline Mode Testing**: Validates graceful degradation

---

## Future Agent Enhancements

### Planned Intelligent Features
1. **Dream Analysis Agent**: AI-powered dream interpretation with astrological context
2. **Daily Ritual Agent**: Personalized daily practices based on planetary energies
3. **Career Guidance Agent**: Professional advice using astrological timing
4. **Health Insights Agent**: Wellness recommendations based on astrological cycles
5. **Learning Agent**: Adaptive AI that learns user preferences over time

---

## Integration Guidelines

### Adding New AI Agents

1. **Protocol Definition**: Create service protocol in `ServiceProtocols.swift`
2. **Implementation**: Implement in dedicated service file
3. **Dependency Injection**: Register in `DependencyContainer.swift`
4. **UI Integration**: Connect via environment objects in SwiftUI
5. **Testing**: Create mock implementation in `MockServices.swift`
6. **Documentation**: Update this agents.md file

### Best Practices
- Always provide offline fallbacks for AI features
- Implement proper error handling and user feedback
- Cache AI responses when appropriate
- Respect user privacy and data minimization principles
- Ensure accessibility in AI-driven UI components