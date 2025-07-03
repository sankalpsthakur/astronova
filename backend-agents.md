# AstroNova Backend Agents & AI Architecture Documentation

## Overview
This document outlines the AI agents, intelligent services, and backend architecture powering the AstroNova astrological application. The backend provides sophisticated AI-driven astrological insights through multiple specialized agents.

## Core AI Agent Architecture

### 1. Conversational Astrologer Agent

**Location**: `services/claude_ai.py:17-66`  
**API Endpoint**: `POST /api/v1/chat/send`  
**AI Models**: Gemini 2.5 Flash (Primary), Claude 3 Sonnet (Fallback)

#### Agent Capabilities:
- **Contextual Conversations**: Integrates user's birth chart data for personalized responses
- **Astrological Expertise**: Specialized system prompts for accurate astrological guidance
- **Memory Management**: Maintains conversation history and context across sessions
- **Graceful Degradation**: Mock responses when AI services are unavailable

#### Implementation Details:
```python
class ClaudeAIService:
    def chat_with_context(self, message: str, birth_data: dict = None) -> dict:
        # Context-aware chat with astrological expertise
        # Lines 17-66 in claude_ai.py
```

**Features**:
- **System Prompt Engineering**: Custom prompts for astrological accuracy
- **Birth Chart Integration**: Uses natal chart data for personalized insights
- **Error Handling**: Comprehensive fallback strategies
- **Rate Limiting**: Intelligent request management

---

### 2. Report Generation Agent

**Location**: `services/reports_service.py:33-48`  
**AI Integration**: Claude 3 Sonnet for detailed content generation  
**Output Format**: PDF with AI-generated personalized content

#### Agent Types:
- **Love Forecast Agent**: Relationship analysis and romantic predictions
- **Career Forecast Agent**: Professional guidance and timing recommendations  
- **Year Ahead Agent**: Annual astrological overview and predictions
- **Birth Chart Agent**: Comprehensive natal chart interpretations

#### Implementation:
```python
class ReportsService:
    def generate_ai_content(self, report_type: str, birth_data: dict) -> str:
        # AI-powered content generation with astrological context
        # Lines 33-48 in reports_service.py
        
    def create_pdf_report(self, content: str, user_data: dict) -> bytes:
        # PDF generation with custom styling
        # Lines 50-68 in reports_service.py
```

**Features**:
- **Multi-Model Support**: Anthropic Claude for high-quality content
- **Template System**: Structured report formats with AI-generated insights
- **PDF Optimization**: Professional formatting with astrological symbols
- **Personalization Engine**: Birth data-driven content customization

---

### 3. Compatibility Analysis Agent

**Location**: `services/astro_calculator.py:75-88` & `routes/match.py:23-93`  
**Endpoint**: `POST /api/v1/match`  
**Calculation Engine**: Swiss Ephemeris + AI-enhanced interpretation

#### Agent Features:
- **Multi-System Analysis**: Western, Vedic, and Chinese astrological compatibility
- **Synastry Calculations**: Advanced aspect analysis between charts
- **AI-Enhanced Scoring**: Intelligent weighting of compatibility factors
- **Cultural Integration**: Chinese zodiac compatibility algorithms

#### Implementation:
```python
class AstroCalculator:
    def calculate_synastry_aspects(self, person1_data: dict, person2_data: dict) -> dict:
        # Advanced astrological compatibility analysis
        # Lines 75-78 in astro_calculator.py
        
    def chinese_zodiac_compatibility(self, year1: int, year2: int) -> dict:
        # Chinese astrology compatibility matrix
        # Lines 81-88 in astro_calculator.py
```

**Features**:
- **Aspect Analysis**: Planetary relationship calculations
- **Cultural Synthesis**: Combines Western and Eastern astrological systems  
- **Intelligent Scoring**: AI-weighted compatibility metrics
- **Caching Strategy**: Redis-based result caching for performance

---

### 4. Ephemeris Intelligence Service

**Location**: `services/ephemeris_service.py:58-106`  
**Endpoint**: `GET /api/v1/ephemeris/current`  
**Calculation Engine**: Swiss Ephemeris (Professional astronomical library)

#### Agent Capabilities:
- **Real-Time Planetary Data**: Current positions of all celestial bodies
- **Historical Accuracy**: Precise calculations for any date/time
- **Rising Sign Calculations**: Location-based ascendant determination
- **Transit Analysis**: Planetary movement predictions and timing

#### Implementation:
```python
class EphemerisService:
    def get_planetary_positions(self, date_time: datetime, location: dict = None) -> dict:
        # Swiss Ephemeris integration for accurate planetary data
        # Lines 58-106 in ephemeris_service.py
        
    def calculate_rising_sign(self, birth_data: dict) -> str:
        # Precise ascendant calculation with location data
        # Lines 40-55 in ephemeris_service.py
```

**Features**:
- **Swiss Ephemeris Integration**: Professional-grade astronomical calculations
- **Timezone Intelligence**: Accurate historical timezone handling
- **Multiple House Systems**: Support for various astrological house systems
- **Performance Optimization**: Efficient calculation caching

---

### 5. Chart Generation Agent

**Location**: `services/chart_service.py` & `routes/chart.py:116-186`  
**Endpoint**: `POST /api/v1/chart/generate`  
**Engine**: Multi-system astrological chart calculator

#### Agent Features:
- **Western Astrology**: Traditional tropical zodiac charts
- **Vedic Astrology**: Sidereal system with Lahiri Ayanamsa
- **Chinese Astrology**: Four Pillars of Destiny integration
- **House Systems**: Multiple house system support (Placidus, Whole Sign, etc.)

#### Implementation:
```python
def generate_comprehensive_chart(birth_data: dict) -> dict:
    # Multi-system chart generation with AI-enhanced interpretations
    # Lines 116-186 in chart.py
```

**Features**:
- **Multi-Cultural Support**: Western, Vedic, and Chinese systems
- **Aspect Calculations**: Complex planetary relationship analysis
- **House Interpretations**: AI-enhanced house meaning generation
- **Visual Data**: Chart coordinates for frontend visualization

---

### 6. User Intelligence Service

**Location**: `services/user_service.py:10-45`  
**Integration**: CloudKit Web Services for iOS synchronization

#### Agent Capabilities:
- **Profile Management**: Intelligent user data handling and validation
- **Cross-Platform Sync**: Seamless iOS app data synchronization
- **Authentication Intelligence**: JWT token management and validation
- **Data Privacy**: Secure user information handling

#### Implementation:
```python
@dataclass
class User:
    # Comprehensive user model with astrological context
    # Lines 10-45 in user_service.py
    
class UserService:
    def create_or_update_user(self, apple_user_data: dict) -> User:
        # Intelligent user profile management
```

---

### 7. CloudKit Integration Agent

**Location**: `services/cloudkit_service.py:60-597`  
**Purpose**: iOS ecosystem data synchronization and management

#### Agent Features:
- **Bidirectional Sync**: Real-time data synchronization with iOS app
- **Record Management**: CRUD operations for all astrological data types
- **Conflict Resolution**: Intelligent data conflict handling
- **Offline Support**: Graceful handling of connectivity issues

#### Supported Record Types:
```python
# CloudKit record types managed by the agent
RECORD_TYPES = [
    'UserProfile',      # User birth data and preferences
    'ChatMessage',      # AI conversation history
    'Horoscope',        # Personalized horoscope data
    'KundaliMatch',     # Compatibility analysis results
    'BirthChart',       # Generated astrological charts
    'BookmarkedReading' # Saved astrological insights
]
```

---

### 8. Cache Intelligence Service

**Location**: `services/cache_service.py` & `services/redis_cache.py`  
**Strategy**: Multi-tier caching with intelligent invalidation

#### Agent Features:
- **Intelligent Caching**: Context-aware cache key generation
- **TTL Management**: Dynamic cache expiration based on content type
- **Cache Warming**: Predictive cache population for common requests
- **Memory Optimization**: Efficient cache size management

#### Cache Strategies:
```python
CACHE_STRATEGIES = {
    'planetary_positions': 3600,    # 1 hour - astronomical data
    'birth_charts': 86400,          # 24 hours - personal charts
    'compatibility': 86400,         # 24 hours - relationship data
    'horoscopes': 3600,            # 1 hour - daily predictions
    'ai_responses': 1800           # 30 minutes - AI-generated content
}
```

---

## API Architecture & Intelligence

### Rate Limiting Agent

**Location**: `app.py:30-35`  
**Strategy**: Intelligent request throttling with user-based limits

#### Features:
- **Per-User Limits**: 200 requests/day, 50 requests/hour
- **Endpoint-Specific Rules**: Health checks exempted from limits
- **Adaptive Throttling**: Dynamic rate adjustment based on system load
- **Graceful Degradation**: Intelligent queuing during high traffic

### Authentication Agent

**Location**: `routes/auth.py:33-152` & `services/apple_auth_service.py`  
**Integration**: Apple ID authentication with JWT token management

#### Agent Capabilities:
- **Apple ID Verification**: Secure token validation with Apple's servers
- **JWT Intelligence**: Automatic token refresh and validation
- **Session Management**: Intelligent session lifecycle handling
- **Security Monitoring**: Anomaly detection in authentication patterns

---

## AI Model Integration

### Primary AI Stack
1. **Gemini 2.5 Flash** (Google) - Primary conversational agent
2. **Claude 3 Sonnet** (Anthropic) - Report generation and fallback
3. **Swiss Ephemeris** - Astronomical calculations (local processing)

### Model Selection Logic
```python
def select_ai_model(task_type: str, content_length: int) -> str:
    """
    Intelligent model selection based on task requirements
    """
    if task_type == "chat" and content_length < 1000:
        return "gemini-2.5-flash"  # Fast responses for chat
    elif task_type == "report" or content_length > 1000:
        return "claude-3-sonnet"   # High-quality long-form content
    else:
        return "gemini-2.5-flash"  # Default to fast model
```

---

## Data Validation & Security Agents

### Input Validation Agent

**Location**: `utils/validators.py`  
**Framework**: Pydantic-based schema validation

#### Features:
- **Coordinate Validation**: Latitude/longitude bounds checking
- **Date Validation**: Historical and future date range validation
- **Birth Data Integrity**: Comprehensive astrological data validation
- **Sanitization**: Input cleaning and normalization

### Security Intelligence

**Location**: Throughout application with centralized config  
**Features**:
- **JWT Security**: Token-based authentication with configurable expiration
- **CORS Intelligence**: Dynamic CORS configuration for iOS app
- **Input Sanitization**: Comprehensive request validation
- **Error Intelligence**: Secure error handling without information leakage

---

## Performance Intelligence

### Database Optimization Agent

**Strategy**: Intelligent query optimization and connection management

#### Features:
- **Connection Pooling**: Efficient database connection management
- **Query Optimization**: Intelligent query caching and batching
- **Index Management**: Automatic index optimization for frequent queries
- **Performance Monitoring**: Real-time performance metrics collection

### System Health Agent

**Location**: `routes/misc.py:163-200`  
**Endpoint**: `GET /api/v1/misc/system-status`

#### Monitoring Capabilities:
- **Service Health**: Real-time monitoring of all AI services
- **Resource Usage**: Memory, CPU, and disk utilization tracking
- **API Performance**: Response time and error rate monitoring
- **Dependency Health**: External service availability checking

---

## Deployment & DevOps Intelligence

### Container Intelligence

**Location**: `Dockerfile` & deployment configuration  
**Platform**: Render.com with auto-scaling

#### Features:
- **Auto-Scaling**: Intelligent scaling based on demand
- **Health Monitoring**: Automatic health checks and restart policies
- **Environment Intelligence**: Dynamic configuration based on deployment environment
- **Log Intelligence**: Structured logging with performance metrics

### Configuration Intelligence

**Location**: `config.py`  
**Strategy**: Environment-based configuration with intelligent defaults

```python
class Config:
    # Intelligent configuration management
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY')
    GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY')
    CLAUDE_API_KEY = os.environ.get('CLAUDE_API_KEY')
    
    # Environment-specific intelligence
    @staticmethod
    def get_ai_model_config():
        return {
            'development': 'gemini-2.5-flash',
            'production': 'claude-3-sonnet',
            'testing': 'mock-responses'
        }
```

---

## Testing Intelligence

### Test Agent Framework

**Location**: `tests/` directory  
**Strategy**: Comprehensive testing with AI service mocking

#### Features:
- **AI Service Mocking**: Deterministic responses for testing
- **Load Testing**: Performance testing for AI endpoints
- **Integration Testing**: End-to-end testing with iOS app simulation
- **Error Scenario Testing**: Comprehensive failure mode testing

---

## Future Agent Enhancements

### Planned Intelligence Features

1. **Predictive Analytics Agent**: Machine learning for astrological trend prediction
2. **Personalization Engine**: Advanced user preference learning
3. **Content Optimization Agent**: A/B testing for AI-generated content
4. **Multi-Language Agent**: Internationalization with cultural astrological variations
5. **Real-Time Notification Agent**: Intelligent timing for astrological alerts
6. **Dream Analysis Agent**: AI-powered dream interpretation with astrological context
7. **Health Insights Agent**: Wellness recommendations based on astrological cycles

---

## Integration Guidelines

### Adding New AI Agents

1. **Service Creation**: Create dedicated service file in `services/` directory
2. **Route Integration**: Add corresponding routes in `routes/` directory
3. **Schema Definition**: Define Pydantic models in `models/schemas.py`
4. **Cache Strategy**: Implement appropriate caching in cache service
5. **Testing**: Create comprehensive tests in `tests/` directory
6. **Documentation**: Update this agents.md file

### Best Practices

- **Error Handling**: Always provide graceful fallbacks for AI failures
- **Rate Limiting**: Implement appropriate rate limiting for AI endpoints
- **Caching**: Cache AI responses when appropriate to reduce costs
- **Monitoring**: Add health checks and performance monitoring
- **Security**: Validate all inputs and sanitize AI outputs
- **Privacy**: Minimize data sent to external AI services
- **Scalability**: Design agents to handle increasing load gracefully

---

## Monitoring & Analytics

### AI Performance Metrics

**Tracked Metrics**:
- Response time per AI model
- Success/failure rates for AI requests
- Token usage and cost optimization
- User satisfaction with AI responses
- Cache hit rates for AI-generated content

### Business Intelligence

**Analytics Tracked**:
- Most popular AI features
- User engagement with different agents
- Conversion rates for premium AI features
- Geographic usage patterns
- Seasonal trends in astrological queries

---

## API Documentation & Integration

### OpenAPI Specification

**Location**: `openapi_spec.yaml`  
**Purpose**: Complete API documentation for iOS app integration

#### Features:
- **Comprehensive Schemas**: All request/response models documented
- **Authentication Flows**: JWT and Apple ID authentication patterns
- **Error Responses**: Standardized error handling documentation
- **Code Examples**: Integration examples for iOS Swift code

The backend agent architecture provides a robust, scalable, and intelligent foundation for the AstroNova astrological application, combining traditional astrological calculations with modern AI capabilities to deliver personalized, accurate, and engaging astrological insights.