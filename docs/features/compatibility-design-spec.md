# Compatibility Feature Design Specification

## 0) Assumptions + Scope

- Both people have full birth profiles (date/time/place) in Astronova.
- We're designing a Compatibility experience that feels deep + interactive, not just "scores + paragraphs".
- We will take inspiration from the competitor's IA clarity (Story / Updates / Evidence) without copying UI, copy, or mechanics verbatim.

---

## 1) North Star (what we're actually building)

- Compatibility = "Us" as a living system.
- User promise: "Pick a person → understand our connection (now/next/act), explore why via a beautiful map, and share one shared insight that lands."
- Non-negotiables:
    - Reciprocity: every tap/drag/scroll responds in <100ms visually; meaning within <300ms (tooltip/sheet), never blank.
    - Trust: "why" is always available (evidence mode), but never forced.
    - Actionability: every insight ends with a concrete "try/avoid" that matches the astrological claim.

---

## 2) Re-think the section: Information Architecture

### 2.1 Connect (list + onboarding)

Goal: reduce friction to start a relationship reading.

- Top bar: Search + "Add" (import/contact/invite/manual chart)
- Quick Add carousel: suggested people (recent chats, frequent views, imported contacts)
- Relationship cards (primary list rows):
    - Avatar(s) + name
    - 1-line "shared signature" (e.g., "Warmth + honesty, watch power dynamics")
    - A tiny Pulse glyph (today's relationship weather)
    - CTA: tap row → Relationship Detail

### 2.2 Relationship Detail (3 pillars, not 3 screens)

We keep the competitor's clarity (Story / Updates / Evidence), but we make it touchable + visual.

- Overview (Story): immediate payoff + guided exploration
- Journey (Updates): time navigation + forecast, not just "today"
- Proof (Evidence): chart tables/circles + aspect list + "how computed"

This can be:

- a segmented control at the top, or
- a single scroll with sticky subnav chips ("Overview / Journey / Proof").

---

## 3) The Atomic Data Unit (single snapshot powers the screen)

### 3.1 Why this matters

If we want smooth interactions and "never blank," we can't stitch 6 endpoints live. We need one coherent payload.

### 3.2 CompatibilitySnapshot (server → client)

Minimum fields (expand later):

- pair: ids, display names, avatar URLs
- natalA, natalB: core placements needed for labels + evidence
- synastry:
    - topAspects[] (planetA, planetB, type, orb, strength, interpretationKey)
    - domainBreakdown[] (e.g., Identity/Emotion/Communication/Love/Desire/Values…)
- composite (optional but powerful):
    - compositePlacements (for "between the two of you" framing)
- now:
    - relationshipPulse (state + score + one-line label)
    - sharedInsight (title, sentence, suggestedAction, avoidAction, whyExpanded)
- next:
    - next meaningful shift timestamp + what changes
- journey:
    - daily markers for next N days (peak/neutral/challenging) + reasons
- share:
    - shareCardModel (safe-to-share text + highlighted connection ids)
- debug/evidence:
    - computation metadata (timezone handling, ephemeris version, house system, etc.)

---

## 4) The Logic (how ephemeris enables "deep" + "alive")

### 4.1 What's static

Computed once per pair (or when profiles change):

- Natal charts for A and B (placements + houses/angles if used)
- Synastry aspects (A↔B planet pair aspects + strength)
- Optional composite chart ("us" entity)

### 4.2 What's dynamic (ephemeris is essential here)

Ephemeris gives planet positions for today + future dates → enables:

- Relationship Pulse: "how are we today?"
    - Based on transits to:
        - the composite chart (best "us" signal), plus
        - key synastry links ("this connection is activated this week")
- Journey timeline: "when are we easiest / hardest?"
    - Scan next 30/90 days for activation peaks (enter/exit orb for high-weight triggers)
- "Next" card: nearest meaningful shift with reason ("Mars squares composite Venus in 6 days → friction about routines")

### 4.3 Selection logic for the "Shared Insight"

We need deterministic rules so it never feels random:

- Candidate pool:
    - top synastry aspects (static)
    - currently activated aspects (dynamic)
- Ranking:
    - score = aspectStrength * activationStrength * domainWeight * noveltyWeight
- Output:
    - 1 sentence (human) + 1 action + 1 avoid
    - Evidence binding: highlight the specific aspect line(s) on the map

---

## 5) The Experience (visual delight + deep interactivity)

### 5.1 Hero: "Synastry Compass" (interactive map)

A bespoke Canvas/Metal view (original) that makes learning tactile:

- Two planet sets:
    - A = gold family
    - B = rose/indigo family
- Aspect web:
    - line color by aspect flavor (harmonious / challenging / intense / neutral)
    - thickness by strength; shimmer when "activated now"
- Tap targets:
    - tap a line → highlight + tooltip in-place + haptic
    - tap a planet → show its top links + domain relevance
- "Focus mode" chip row:
    - "Emotions", "Communication", "Love", "Desire", etc. filters the web live

### 5.2 "Relationship Pulse" (tiny but addictive)

A compact animated component that works in list rows and header:

- A waveform / breathing orb / filament thread (pick one consistent metaphor)
- States: Flowing / Spiky / Quiet / Intense (not "good/bad")
- Tap pulse → reveals "why" (top 2 activations contributing)

### 5.3 The Meaning Stack for "Us" (Now / Next / Act)

Always visible near the top (collapses into a compact bar on scroll):

- Now: shared insight + 1-line theme + optional "why"
- Next: countdown + what shifts + "plan for it"
- Act: one concrete thing to do + one to avoid + "because…"

### 5.4 Journey (time navigation done better)

Not just "today"; a relationship forecast you can scrub:

- Horizontal date strip (7 days) for quick check-ins
- A 30/90-day sparkline with peaks/troughs
- Tap any day → pulse/map/cards update instantly
- "Peak windows" callouts (good for trips/tough talks)

### 5.5 Proof (Evidence without killing the vibe)

For skeptical users or power users:

- Toggle: Table | Circle (like competitor's concept, but our visual language)
- Lists:
    - placements for each person + composite (if enabled)
    - synastry aspect table (sortable by strength, activated-now, domain)
- "How computed" panel:
    - timezone normalization + ephemeris source/version + house system

---

## 6) Reciprocity Contract (micro-interactions + motion)

Define it like an API contract:

- Tap aspect line:
    - <100ms: line brightens + endpoints pulse + subtle sound/haptic optional
    - <300ms: tooltip appears (even if copy is loading, show placeholder)
    - <600ms: bottom sheet expands with deeper explanation + examples
- Change day (journey scrub):
    - map morphs (interpolated) + pulse animates to new state + cards crossfade
- Scroll:
    - header collapses into compact bar; pulse stays visible; context never lost
- Loading:
    - keep last snapshot; show "Updating…" shimmer; allow cancel if expensive

---

## 7) Sharing (make "shared insight" a first-class artifact)

### 7.1 Share surfaces

- Share button on Shared Insight card
- Long-press any aspect line → "Share this connection"
- Save (private) vs Share (public-safe)

### 7.2 Share output (not a screenshot dump)

Generate a clean "relationship card":

- Title ("Today's theme")
- One sentence
- Do / Avoid
- Subtle footer: "Based on your charts" (no raw birth data)
- Optional: tiny highlighted aspect glyph (not the full map)

### 7.3 Deep link

- Recipient opens → lands on the same insight (and highlighted connection) in-app
- If not logged in: view a safe preview, prompt to connect

---

## 8) Safety, privacy, and tone (critical for relationships)

- Avoid deterministic or coercive language ("don't give them your heart yet" style) unless you explicitly want that brand voice.
- Provide "tone settings":
    - Gentle / Direct / Playful (copy style, not the underlying logic)
- Privacy defaults:
    - sharing never includes birth time/place; always redacts
    - compatibility can be hidden/locked per relationship

---

## 9) Engineering Plan (granular milestones)

### Phase 0 — Audit + baseline

- Locate current Connect/Compatibility in app; map navigation + existing models
- Record baseline flow with XcodeBuildMCP (screenshots/video) for comparison

### Phase 1 — Data contract first

- Define CompatibilitySnapshot schema + OpenAPI route(s)
- Implement server stubs returning mocked but structured data
- Add contract tests so client+server stay synced

### Phase 2 — Client scaffolding

- Add new views behind feature flag:
    - Connect list (search + cards + pulse glyph)
    - Relationship detail skeleton (Overview/Journey/Proof containers)
- Implement "never blank" cache + loading states

### Phase 3 — Hero visuals (mock data)

- Implement SynastryCompassView with hit-testing + highlight states
- Implement RelationshipPulseView animation
- Implement Meaning Stack (Now/Next/Act) + progressive disclosure sheets

### Phase 4 — Journey mechanics

- Day strip + 30/90 day forecast chart
- Scrub updates map/pulse/cards with interpolation + haptics

### Phase 5 — Real computation

- Natal chart computation (if not already)
- Synastry aspects + composite (optional)
- Transit activation + forecast scanning (ephemeris-backed)
- Deterministic ranking for shared insight selection

### Phase 6 — Sharing

- Share card renderer (SwiftUI → image)
- Deep link handling
- Privacy redaction rules + "preview" mode

### Phase 7 — Polish + performance

- Motion tuning (springs, crossfades, shimmer)
- Accessibility pass (dynamic type, VoiceOver labels for map elements)
- Performance budget (Canvas redraws, caching, debouncing)

### Phase 8 — Instrumentation + rollout

- Metrics: open → engage (tap line) → expand → share → return next day
- Feature flag rollout + A/B tests on:
    - pulse styles
    - insight card layouts
    - journey horizon (7 vs 30 vs 90)

---

## 10) Testing Plan (so it stays correct + fast)

- Unit tests (server):
    - aspect math + orb handling + wraparound
    - forecast scanning determinism
- Contract tests:
    - snapshot fields present + typed
- UI tests (client):
    - tap aspect line highlights + opens sheet
    - scrub day updates Now/Next/Act
- Performance checks:
    - map interaction <16ms per frame target
- XcodeBuildMCP visual regression:
    - scripted navigation screenshots for key states (Overview/Journey/Proof)

---

## Current State Analysis

### Where Connect/Compatibility Lives

| Location | File | Status |
|----------|------|--------|
| Tab | `RootView.swift` Tab 2 "Connect" | UI shell exists |
| List View | `ConnectView.swift` | 100% mock data |
| Detail View | `RelationshipDetailView.swift` | Uses mock `CompatibilitySnapshot` |
| Models | `CompatibilityModels.swift` | Rich models, all `.mock` extensions |
| API Client | `APIServices.swift` | `calculateCompatibility()` exists, never called |
| Backend | `server/routes/compatibility.py` | `POST /api/v1/compatibility` works |
| Database | `server/db.py` | **NO relationships table** |

### What Needs Building

1. **Database**: `relationships` table (user_id, partner_birth_data, created_at, etc.)
2. **Backend API**: CRUD for relationships + enhanced compatibility endpoint
3. **Frontend Wiring**: Replace mock data with real API calls
4. **State Management**: Relationship cache + loading states
