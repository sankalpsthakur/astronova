# Astronova API Reference

Base URL: `/api/v1`

## Authentication

Most endpoints work without authentication. Relationship endpoints require `X-User-Id` header.
Protected endpoints require `Authorization: Bearer <JWT>` header.

---

## Ephemeris

### GET /ephemeris/current
Get current planetary positions.

**Query Parameters:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `lat` | float | No | Latitude for rising sign |
| `lon` | float | No | Longitude for rising sign |
| `system` | string | No | `western` (default) or `vedic` |

**Response:**
```json
{
  "planets": [
    {
      "id": "sun",
      "symbol": "☉",
      "name": "Sun",
      "sign": "Capricorn",
      "degree": 25.5,
      "longitude": 295.5,
      "retrograde": false,
      "house": null,
      "significance": "Core identity and vitality"
    }
  ],
  "timestamp": "2025-01-15T12:00:00Z",
  "has_rising_sign": false
}
```

### GET /ephemeris/at
Get planetary positions for a specific date.

**Query Parameters:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `date` | string | Yes | Date in YYYY-MM-DD format |
| `lat` | float | No | Latitude for rising sign |
| `lon` | float | No | Longitude for rising sign |
| `system` | string | No | `western` or `vedic` |

---

## Astrology

### GET /astrology/positions
Get simplified planetary positions.

**Response:**
```json
{
  "Sun": { "degree": 295.5, "sign": "Capricorn" },
  "Moon": { "degree": 142.3, "sign": "Leo" }
}
```

### POST /astrology/dashas/complete
Get complete Vimshottari dasha timeline with impact analysis.

**Request Body:**
```json
{
  "birthData": {
    "date": "1990-01-15",
    "time": "14:30",
    "timezone": "Asia/Kolkata",
    "latitude": 19.076,
    "longitude": 72.877
  },
  "targetDate": "2025-01-15",
  "includeTransitions": true,
  "includeEducation": true
}
```

**Response:**
```json
{
  "dasha": {
    "mahadasha": { "lord": "Jupiter", "start": "...", "end": "..." },
    "antardasha": { "lord": "Saturn", "start": "...", "end": "..." },
    "pratyantardasha": { "lord": "Mercury", "start": "...", "end": "..." }
  },
  "current_period": {
    "mahadasha": "Jupiter",
    "antardasha": "Saturn",
    "narrative": "A period of expansion meeting discipline..."
  },
  "impact_analysis": {
    "combined_scores": {
      "career": 7.5,
      "relationships": 6.2,
      "health": 8.0,
      "spiritual": 7.8
    }
  },
  "transitions": { ... },
  "education": { ... }
}
```

---

## Chart

### POST /chart/generate
Generate natal birth chart.

**Request Body:**
```json
{
  "birthData": {
    "date": "1990-01-15",
    "time": "14:30",
    "timezone": "Asia/Kolkata",
    "latitude": 19.076,
    "longitude": 72.877
  },
  "systems": ["western", "vedic"],
  "chartType": "natal"
}
```

**Response:**
```json
{
  "chartId": "uuid",
  "westernChart": {
    "positions": { "sun": { "sign": "Capricorn", "degree": 25.5, "house": 10 } },
    "houses": { "1": { "sign": "Aries", "degree": 0, "meaning": "Self, identity" } },
    "aspects": [{ "planet1": "Sun", "planet2": "Moon", "type": "trine", "orb": 2.5 }]
  },
  "vedicChart": {
    "lagna": { "sign": "Mesha", "degree": 5.2 },
    "positions": { ... },
    "dashas": [{ "planet": "Jupiter", "startDate": "...", "endDate": "..." }]
  }
}
```

### POST /chart/aspects
Calculate aspects between planets.

**Request Body:** Same as `/chart/generate`

**Response:**
```json
[
  { "planet1": "Sun", "planet2": "Moon", "type": "conjunction", "aspect": "conjunction", "orb": 2.5 }
]
```

---

## Horoscope

### GET /horoscope
Get horoscope for a zodiac sign.

**Query Parameters:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `sign` | string | Yes | Zodiac sign (aries, taurus, etc.) |
| `type` | string | No | `daily` (default), `weekly`, `monthly` |
| `date` | string | No | Date in YYYY-MM-DD (defaults to today) |

**Response:**
```json
{
  "id": "leo-20250115-daily",
  "sign": "leo",
  "date": "2025-01-15",
  "type": "daily",
  "content": "With the Sun illuminating your sign...",
  "luckyElements": {
    "color": "Gold",
    "number": 1,
    "day": "Sunday",
    "element": "fire",
    "ruler": "Sun"
  }
}
```

---

## Compatibility

### POST /compatibility
Calculate compatibility between two people.

**Request Body:**
```json
{
  "person1": {
    "date": "1990-01-15",
    "time": "14:30",
    "latitude": 19.076,
    "longitude": 72.877,
    "timezone": "Asia/Kolkata"
  },
  "person2": {
    "date": "1992-05-20",
    "time": "10:00",
    "latitude": 40.712,
    "longitude": -74.006,
    "timezone": "America/New_York"
  }
}
```

**Response:**
```json
{
  "overallIntensity": "intense",
  "vedicIntensity": "strong",
  "synastryAspects": ["Sun conjunction Moon", "Venus trine Mars"],
  "userChart": { ... },
  "partnerChart": { ... }
}
```

### GET /compatibility/relationships
List user's saved relationships.

**Headers:** `X-User-Id: <user-id>`

**Response:**
```json
{
  "relationships": [
    {
      "id": "rel-123",
      "name": "Partner Name",
      "sunSign": "Leo",
      "moonSign": "Pisces",
      "birthDate": "1992-05-20",
      "sharedSignature": "Warmth + honesty",
      "isFavorite": true
    }
  ]
}
```

### POST /compatibility/relationships
Create a new relationship.

**Headers:** `X-User-Id: <user-id>`

**Request Body:**
```json
{
  "partnerName": "Partner Name",
  "partnerBirthDate": "1992-05-20",
  "partnerBirthTime": "10:00",
  "partnerTimezone": "America/New_York",
  "partnerLatitude": 40.712,
  "partnerLongitude": -74.006,
  "partnerLocationName": "New York, NY"
}
```

### GET /compatibility/relationships/{id}/snapshot
Get full compatibility snapshot with transits.

**Headers:** `X-User-Id: <user-id>`

**Query Parameters:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `date` | string | No | Date for snapshot (defaults to today) |

**Response:**
```json
{
  "pair": { "nameA": "You", "nameB": "Partner", "sharedSignature": "..." },
  "natalA": { "sun": { ... }, "moon": { ... } },
  "natalB": { ... },
  "synastry": {
    "topAspects": [{ "planetA": "Sun", "planetB": "Moon", "aspectType": "conjunction" }],
    "domainBreakdown": [{ "domain": "Love", "intensity": "intense" }],
    "overallIntensity": "intense"
  },
  "now": {
    "pulse": { "state": "flowing", "score": 78, "label": "Flowing" },
    "sharedInsight": { "title": "...", "sentence": "...", "suggestedAction": "..." }
  },
  "next": { "date": "2025-01-22", "daysUntil": 7, "whatChanges": "..." },
  "journey": { "dailyMarkers": [...], "peakWindows": [...] }
}
```

### DELETE /compatibility/relationships/{id}
Delete a relationship.

**Headers:** `X-User-Id: <user-id>`

---

## Chat

### POST /chat
Send chat message and get AI response.

**Request Body:**
```json
{
  "message": "What does my birth chart say about my career?",
  "userId": "user-123",
  "conversationId": "conv-456",
  "birthData": { ... }
}
```

**Response:**
```json
{
  "reply": "Your birth chart shows strong career potential...",
  "messageId": "msg-789",
  "conversationId": "conv-456",
  "suggestedFollowUps": ["What about my love life?", "Tell me about transits"]
}
```

### POST /chat/birth-data
Save birth data for personalized chat.

**Request Body:**
```json
{
  "userId": "user-123",
  "birthData": {
    "date": "1990-01-15",
    "time": "14:30",
    "timezone": "Asia/Kolkata",
    "latitude": 19.076,
    "longitude": 72.877,
    "locationName": "Mumbai, India"
  }
}
```

### GET /chat/birth-data
Retrieve saved birth data.

**Query Parameters:** `userId=user-123`

---

## Reports

### POST /reports
Generate an astrology report.

**Request Body:**
```json
{
  "birthData": { ... },
  "reportType": "birth_chart",
  "userId": "user-123"
}
```

**Report Types:** `birth_chart`, `love_forecast`, `career_forecast`, `wealth_forecast`, `health_forecast`, `family_forecast`, `spiritual_forecast`, `year_ahead`

**Response:**
```json
{
  "reportId": "rpt-123",
  "type": "birth_chart",
  "title": "Your Birth Chart Analysis",
  "summary": "...",
  "keyInsights": ["..."],
  "downloadUrl": "/api/v1/reports/rpt-123/pdf",
  "status": "completed"
}
```

### GET /reports/user/{userId}
Get all reports for a user.

### GET /reports/{id}/pdf
Download report as PDF.

---

## Discover

### GET /discover/domains
Get life domain insights.

**Query Parameters:** `date=2025-01-15`

**Response:**
```json
{
  "date": "2025-01-15",
  "domains": [
    {
      "domain": "love",
      "shortInsight": "Hearts connect easily today",
      "fullInsight": "...",
      "drivers": [{ "planet": "Venus", "aspect": "trine Sun" }],
      "intensity": 0.85
    }
  ],
  "cosmicWeather": { "mood": "harmonious", "dominantPlanet": "Sun" }
}
```

### POST /discover/snapshot
Get personalized discover snapshot.

**Request Body:**
```json
{
  "birthData": { ... },
  "targetDate": "2025-01-15"
}
```

---

## Locations

### GET /location/search
Search for locations.

**Query Parameters:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `q` | string | No | Search query |
| `limit` | int | No | Max results (default 10, max 50) |

**Response:**
```json
{
  "locations": [
    {
      "name": "New York",
      "displayName": "New York, NY, USA",
      "latitude": 40.7128,
      "longitude": -74.006,
      "timezone": "America/New_York"
    }
  ]
}
```

---

## Auth

### POST /auth/apple
Authenticate with Apple Sign-In.

**Request Body:**
```json
{
  "idToken": "apple-id-token",
  "userIdentifier": "user-id-from-apple",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe"
}
```

**Response:**
```json
{
  "jwtToken": "eyJ...",
  "user": { "id": "...", "email": "...", "fullName": "..." },
  "expiresAt": "2025-02-15T..."
}
```

### GET /auth/validate
Validate current JWT token.

**Headers:** `Authorization: Bearer <token>`

### POST /auth/refresh
Refresh JWT token.

**Headers:** `Authorization: Bearer <token>`

### POST /auth/logout
Logout user.

### DELETE /auth/delete-account
Delete user account.

---

## Health & Config

### GET /health
Basic health check.

**Response:**
```json
{
  "status": "healthy",
  "service": "astronova-api",
  "timestamp": "2025-01-15T12:00:00Z"
}
```

### GET /subscription/status
Check subscription status.

**Query Parameters:** `userId=user-123`

**Response:**
```json
{
  "isActive": true
}
```

---

## Error Responses

All errors return JSON with consistent format:

```json
{
  "error": "Error message",
  "code": "ERROR_CODE",
  "detail": "Additional context"
}
```

**Common Error Codes:**
- `INVALID_JSON` — Request body not valid JSON
- `VALIDATION_ERROR` — Missing or invalid fields
- `UNAUTHORIZED` — Missing authentication
- `NOT_FOUND` — Resource not found
- `CALCULATION_ERROR` — Astrology calculation failed
