# Compatibility Feature Implementation Backlog

> Maps the [Design Spec](./compatibility-design-spec.md) to actual repo files with build checkpoints.

## Current State Summary

| Layer | File | Status |
|-------|------|--------|
| Tab Shell | `client/.../RootView.swift` | Tab 2 "Connect" exists |
| List View | `client/.../ConnectView.swift` | 100% mock data (`RelationshipProfile.mockList`) |
| Detail View | `client/.../RelationshipDetailView.swift` | Uses `CompatibilitySnapshot.mock` |
| Models | `client/.../CompatibilityModels.swift` | Rich models, all `.mock` extensions |
| Synastry Map | `client/.../SynastryCompassView.swift` | Exists (needs wiring) |
| Pulse | `client/.../RelationshipPulseView.swift` | Exists (needs wiring) |
| Journey | `client/.../CompatibilityJourneyView.swift` | Exists (mock data) |
| Meaning Stack | `client/.../CompatibilityMeaningStack.swift` | Exists (mock data) |
| API Client | `client/.../APIServices.swift` | `calculateCompatibility()` exists, never called |
| Backend Route | `server/routes/compatibility.py` | Basic scores only, no snapshot schema |
| Database | `server/db.py` | **NO `relationships` table** |

---

## Phase 0: Audit + Baseline (0.5 day)

### Tasks

- [ ] **0.1** Screenshot current Connect tab flow (list → detail → each pillar)
- [ ] **0.2** Document which mock data extensions are used where
- [ ] **0.3** Verify `POST /api/v1/compatibility` returns 200 with test data

### Files to Read
- `client/AstronovaApp/ConnectView.swift`
- `client/AstronovaApp/RelationshipDetailView.swift`
- `server/routes/compatibility.py`

### Checkpoint
- [ ] Screenshots saved to `docs/screenshots/connect-baseline/`

---

## Phase 1: Data Contract (1 day)

### 1.1 Database Schema

**File:** `server/db.py`

Add `relationships` table:

```sql
CREATE TABLE IF NOT EXISTS relationships (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,           -- owner
    partner_name TEXT NOT NULL,
    partner_birth_date TEXT NOT NULL,
    partner_birth_time TEXT,         -- optional
    partner_timezone TEXT,
    partner_latitude REAL,
    partner_longitude REAL,
    partner_location_name TEXT,
    partner_avatar_url TEXT,
    is_favorite INTEGER DEFAULT 0,
    created_at TEXT,
    updated_at TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id)
)
```

### 1.2 OpenAPI Schema

**File:** `server/openapi_spec.yaml`

Add schemas:
- `RelationshipProfile` (list item)
- `CompatibilitySnapshot` (detail payload)
- `SynastryAspect`, `DomainScore`, `RelationshipPulse`, etc.

Add endpoints:
- `GET /api/v1/relationships` → list user's relationships
- `POST /api/v1/relationships` → add new relationship
- `GET /api/v1/relationships/{id}` → get relationship profile
- `DELETE /api/v1/relationships/{id}` → remove relationship
- `GET /api/v1/relationships/{id}/snapshot` → full CompatibilitySnapshot

### 1.3 Backend Stubs

**File:** `server/routes/compatibility.py` (or new `server/routes/relationships.py`)

```python
@compat_bp.route("/relationships", methods=["GET"])
def list_relationships():
    """List user's saved relationships."""
    # Return mock data initially, wire to DB later
    pass

@compat_bp.route("/relationships/<relationship_id>/snapshot", methods=["GET"])
def get_compatibility_snapshot(relationship_id: str):
    """Return full CompatibilitySnapshot for a relationship."""
    # Return structured mock matching client models
    pass
```

### 1.4 Client API Methods

**File:** `client/AstronovaApp/APIServices.swift`

```swift
func listRelationships() async throws -> [RelationshipProfile]
func createRelationship(_ profile: CreateRelationshipRequest) async throws -> RelationshipProfile
func deleteRelationship(id: String) async throws
func getCompatibilitySnapshot(relationshipId: String) async throws -> CompatibilitySnapshot
```

### Checkpoint
- [ ] `curl POST /api/v1/relationships` returns 201
- [ ] `curl GET /api/v1/relationships/{id}/snapshot` returns full mock snapshot
- [ ] Swift `APIServices.getCompatibilitySnapshot()` compiles

---

## Phase 2: Client Scaffolding (1.5 days)

### 2.1 Connect List Wiring

**File:** `client/AstronovaApp/ConnectView.swift`

Replace:
```swift
@State private var relationships: [RelationshipProfile] = RelationshipProfile.mockList
```

With:
```swift
@State private var relationships: [RelationshipProfile] = []
@State private var isLoading = true
@State private var error: Error?

.task {
    do {
        relationships = try await APIServices.shared.listRelationships()
    } catch {
        self.error = error
    }
    isLoading = false
}
```

Add:
- Loading shimmer state
- Empty state with "Add your first connection" CTA
- Error state with retry

### 2.2 Add Relationship Flow

**File:** `client/AstronovaApp/ConnectView.swift` (or new `AddRelationshipSheet.swift`)

- Name input
- Birth date picker
- Optional birth time picker
- Optional location search (reuse `MapKitLocationService`)
- Save → POST to API → refresh list

### 2.3 Relationship Detail Wiring

**File:** `client/AstronovaApp/RelationshipDetailView.swift`

Replace mock snapshot load:
```swift
.task {
    do {
        snapshot = try await APIServices.shared.getCompatibilitySnapshot(relationshipId: relationship.id)
    } catch {
        // Show error or fallback
    }
}
```

### 2.4 Loading States ("Never Blank")

**Files:**
- `client/AstronovaApp/ConnectView.swift`
- `client/AstronovaApp/RelationshipDetailView.swift`

Implement:
- Skeleton/shimmer while loading
- Cache last snapshot in memory
- Show stale data with "Updating..." indicator

### Checkpoint
- [ ] Connect list shows loading shimmer → empty state (no relationships yet)
- [ ] Add relationship sheet saves to backend
- [ ] Detail view loads snapshot from API (mock data from server)

---

## Phase 3: Hero Visuals with Mock Data (2 days)

### 3.1 SynastryCompassView Refinement

**File:** `client/AstronovaApp/SynastryCompassView.swift`

Already exists. Ensure:
- [ ] Accepts `SynastryData` from snapshot
- [ ] Tap aspect line → highlights + shows tooltip
- [ ] Tap planet → shows connections
- [ ] Domain filter chips work
- [ ] "Activated now" aspects shimmer

### 3.2 RelationshipPulseView Animation

**File:** `client/AstronovaApp/RelationshipPulseView.swift`

Already exists. Ensure:
- [ ] Accepts `RelationshipPulse` from snapshot
- [ ] Animation matches `PulseState` (flowing/electric/grounded/friction/magnetic)
- [ ] Tap → reveals "why" sheet

### 3.3 CompatibilityMeaningStack (Now/Next/Act)

**File:** `client/AstronovaApp/CompatibilityMeaningStack.swift`

Already exists. Ensure:
- [ ] Accepts `RelationshipNowInsight` + `NextShift` from snapshot
- [ ] Now: shared insight + theme
- [ ] Next: countdown + what shifts
- [ ] Act: do/avoid actions
- [ ] Tap each card → progressive disclosure sheet

### 3.4 Wire Components in Detail View

**File:** `client/AstronovaApp/RelationshipDetailView.swift`

Ensure Overview/Journey/Proof pillars use:
- `SynastryCompassView(synastry: snapshot.synastry, natalA: snapshot.natalA, natalB: snapshot.natalB)`
- `RelationshipPulseView(pulse: snapshot.now.pulse)`
- `CompatibilityMeaningStack(now: snapshot.now, next: snapshot.next)`

### Checkpoint
- [ ] Screenshot: Synastry compass renders aspect web
- [ ] Screenshot: Pulse animates based on state
- [ ] Screenshot: Meaning stack shows Now/Next/Act
- [ ] Tap interactions work with haptics

---

## Phase 4: Journey Mechanics (1.5 days)

### 4.1 Day Strip Component

**File:** `client/AstronovaApp/CompatibilityJourneyView.swift`

Implement:
- Horizontal scroll of 7 days (today highlighted)
- Each day shows intensity indicator (peak/neutral/challenging)
- Tap day → update selected date

### 4.2 30/90-Day Sparkline

**File:** `client/AstronovaApp/CompatibilityJourneyView.swift`

Add:
- `JourneySparklineView` showing 30-day forecast
- Peak windows highlighted
- Tap → expand to detail

### 4.3 Date Selection Updates Everything

**Files:**
- `client/AstronovaApp/RelationshipDetailView.swift`
- `client/AstronovaApp/CompatibilityJourneyView.swift`

When date changes:
- Animate pulse to new state
- Update meaning stack cards
- Aspect "activated now" states update
- Map aspect lines shimmer/fade appropriately

### 4.4 API: Date-Specific Snapshot

**File:** `server/routes/compatibility.py`

```python
@compat_bp.route("/relationships/<id>/snapshot", methods=["GET"])
def get_compatibility_snapshot(id: str):
    date = request.args.get("date")  # Optional, defaults to today
    # Compute snapshot for specific date
```

### Checkpoint
- [ ] Screenshot: Journey view with day strip + sparkline
- [ ] Scrubbing dates updates pulse/cards smoothly
- [ ] Peak windows are visually distinct

---

## Phase 5: Real Computation (3 days)

### 5.1 Synastry Aspect Calculator

**File:** `server/services/synastry_service.py` (NEW)

```python
class SynastryService:
    def calculate_aspects(self, chart_a: dict, chart_b: dict) -> list[SynastryAspect]:
        """Calculate all synastry aspects between two charts."""
        pass

    def get_domain_breakdown(self, aspects: list) -> list[DomainScore]:
        """Group aspects by domain (Identity, Emotion, Love, etc.)."""
        pass
```

### 5.2 Composite Chart Calculator

**File:** `server/services/composite_service.py` (NEW)

```python
class CompositeService:
    def calculate_composite(self, chart_a: dict, chart_b: dict) -> CompositePlacements:
        """Calculate midpoint composite chart."""
        pass
```

### 5.3 Transit Activation Service

**File:** `server/services/transit_activation_service.py` (NEW)

```python
class TransitActivationService:
    def get_activated_aspects(self, synastry: list, composite: dict, date: datetime) -> list[str]:
        """Which aspects are activated by current transits?"""
        pass

    def calculate_relationship_pulse(self, ...) -> RelationshipPulse:
        """Determine pulse state based on transit activations."""
        pass

    def scan_journey(self, ..., days: int = 30) -> JourneyForecast:
        """Scan next N days for peaks/troughs."""
        pass
```

### 5.4 Shared Insight Selection

**File:** `server/services/insight_selection_service.py` (NEW)

```python
def select_shared_insight(synastry: list, activations: list, ...) -> SharedInsight:
    """
    Deterministic selection:
    score = aspectStrength * activationStrength * domainWeight * noveltyWeight
    """
    pass
```

### 5.5 Wire Services into Snapshot Endpoint

**File:** `server/routes/compatibility.py`

```python
def get_compatibility_snapshot(relationship_id: str):
    # 1. Get relationship from DB
    # 2. Compute natal charts for both
    # 3. Calculate synastry aspects
    # 4. Calculate composite (optional)
    # 5. Get transit activations for date
    # 6. Calculate pulse state
    # 7. Select shared insight
    # 8. Build journey forecast
    # 9. Return CompatibilitySnapshot
```

### Checkpoint
- [ ] Unit tests pass for synastry aspect math
- [ ] Unit tests pass for composite midpoints
- [ ] Snapshot endpoint returns real computed data
- [ ] Compare: mock vs real data looks reasonable

---

## Phase 6: Sharing (1 day)

### 6.1 Share Card Renderer

**File:** `client/AstronovaApp/Components/ShareCardRenderer.swift` (NEW)

```swift
struct CompatibilityShareCard: View {
    let insight: SharedInsight
    let pair: RelationshipPair

    // Render shareable card
}

func renderShareImage() -> UIImage {
    // SwiftUI → UIImage
}
```

### 6.2 Share Sheet Integration

**File:** `client/AstronovaApp/RelationshipDetailView.swift`

- Share button on Meaning Stack
- Long-press aspect line → "Share this connection"
- Generate image + deep link

### 6.3 Deep Link Handling

**Files:**
- `client/AstronovaApp/AstronovaAppApp.swift`
- `server/routes/compatibility.py`

```python
@compat_bp.route("/share/<token>", methods=["GET"])
def get_shared_insight(token: str):
    """Return safe-to-display insight for deep link."""
    pass
```

### 6.4 Privacy Redaction

Ensure share output:
- Never includes birth time/place
- Only shows insight text + aspect glyph
- Footer: "Based on your charts"

### Checkpoint
- [ ] Share card generates clean image
- [ ] Deep link opens to correct insight
- [ ] No PII in shared content

---

## Phase 7: Polish + Performance (1.5 days)

### 7.1 Motion Tuning

**Files:**
- `client/AstronovaApp/SynastryCompassView.swift`
- `client/AstronovaApp/RelationshipPulseView.swift`
- `client/AstronovaApp/CompatibilityJourneyView.swift`

- Spring animations for interactions
- Crossfade for content updates
- Shimmer for loading/activated states

### 7.2 Accessibility

**All view files:**
- Dynamic type support
- VoiceOver labels for map elements
- Reduce motion alternatives

### 7.3 Performance Budget

- Map Canvas redraws < 16ms
- Aspect hit-testing optimized
- Snapshot caching in memory

### Checkpoint
- [ ] Instruments: no frame drops during scrubbing
- [ ] VoiceOver navigates all interactive elements
- [ ] Reduce Motion preference respected

---

## Phase 8: Instrumentation + Rollout (0.5 day)

### 8.1 Analytics Events

```swift
// Track engagement funnel
Analytics.track("compatibility_opened", ["relationship_id": id])
Analytics.track("aspect_tapped", ["aspect_id": aspectId])
Analytics.track("insight_expanded", ["insight_type": type])
Analytics.track("share_initiated", ["surface": "meaning_stack"])
```

### 8.2 Feature Flag

**File:** `client/AstronovaApp/AuthState.swift` (or feature flags)

```swift
var isCompatibilityV2Enabled: Bool {
    // Remote config or subscription tier
}
```

### Checkpoint
- [ ] Events firing in analytics dashboard
- [ ] Feature flag controls visibility
- [ ] A/B test infrastructure ready

---

## Testing Checklist

### Server Unit Tests

**File:** `server/tests/test_synastry_service.py` (NEW)

- [ ] Aspect detection with orb handling
- [ ] 360° wraparound edge cases
- [ ] Domain classification accuracy
- [ ] Composite midpoint math

### Server Integration Tests

**File:** `server/tests/test_compatibility_api.py` (NEW)

- [ ] `GET /api/v1/relationships` returns list
- [ ] `POST /api/v1/relationships` creates relationship
- [ ] `GET /api/v1/relationships/{id}/snapshot` returns full schema
- [ ] Date parameter affects journey/pulse

### Client UI Tests

**File:** `client/AstronovaAppUITests/CompatibilityTests.swift` (NEW)

- [ ] Tap relationship row → detail view appears
- [ ] Tap aspect line → tooltip appears
- [ ] Scrub day → cards update
- [ ] Share button → share sheet

---

## File Summary

### New Server Files
- `server/routes/relationships.py` (or extend compatibility.py)
- `server/services/synastry_service.py`
- `server/services/composite_service.py`
- `server/services/transit_activation_service.py`
- `server/services/insight_selection_service.py`
- `server/tests/test_synastry_service.py`
- `server/tests/test_compatibility_api.py`

### Modified Server Files
- `server/db.py` (add relationships table)
- `server/openapi_spec.yaml` (add schemas + endpoints)
- `server/routes/compatibility.py` (new endpoints)
- `server/routes/__init__.py` (register new routes if separate)

### New Client Files
- `client/AstronovaApp/AddRelationshipSheet.swift`
- `client/AstronovaApp/Components/ShareCardRenderer.swift`
- `client/AstronovaAppUITests/CompatibilityTests.swift`

### Modified Client Files
- `client/AstronovaApp/ConnectView.swift` (wire to API)
- `client/AstronovaApp/RelationshipDetailView.swift` (wire to API)
- `client/AstronovaApp/APIServices.swift` (add methods)
- `client/AstronovaApp/APIModels.swift` (ensure models match server)
- `client/AstronovaApp/SynastryCompassView.swift` (refinements)
- `client/AstronovaApp/RelationshipPulseView.swift` (refinements)
- `client/AstronovaApp/CompatibilityJourneyView.swift` (day strip + sparkline)
- `client/AstronovaApp/CompatibilityMeaningStack.swift` (refinements)

---

## Estimated Total: ~12 days

| Phase | Days |
|-------|------|
| 0: Audit | 0.5 |
| 1: Data Contract | 1 |
| 2: Client Scaffolding | 1.5 |
| 3: Hero Visuals | 2 |
| 4: Journey Mechanics | 1.5 |
| 5: Real Computation | 3 |
| 6: Sharing | 1 |
| 7: Polish | 1.5 |
| 8: Rollout | 0.5 |

---

## Decision Log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Synastry vs Composite | Both | Synastry for map/aspects, Composite for pulse/transits |
| Database for relationships | SQLite (existing) | Keep simple, same as other tables |
| Snapshot caching | Client memory | Avoid stale data, re-fetch on detail open |
| Share format | Image + deep link | Works everywhere, maintains brand |
