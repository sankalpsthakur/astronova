# TopoSelf Bridge — Astronova Architectural Overlay

**Branch:** `topo-bridge`
**Status:** Foundation content drafted. No Swift code yet.
**Goal:** Convert Astronova from a chart/horoscope app into a behavioral OS that uses astrology as symbolic UI.

---

## What this overlay actually is

Astronova today: accurate ephemerides, dashas, charts, AI horoscope. Predictive.
Astronova after TopoSelf bridge: pattern recognition + consciousness ladder + emotion routing + reflective journal + personal-rules store, all keyed to the same astrology engine. Agentic.

The chart does not change. Everything that hangs off it does.

---

## Content artifacts (this session's output)

All under `docs/topoself/content/`. Total: ~9,700 words, dual-system (Western + Vedic).

| File | Purpose | Used by |
|---|---|---|
| [patterns.md](content/patterns.md) | 5 named behavioral patterns × 6-row decomposition (Stimulus / Default Script / Hidden Need / Low Consciousness Output / High Consciousness Route / Optimal Action) | Today's Terrain, Pattern Library, Journal, Decision Simulator |
| [consciousness-levels.md](content/consciousness-levels.md) | 12 planets × 4-level maturity ladder with body cues, growth edges, regression triggers | My Map, Pattern detail view, Profile |
| [protocols.md](content/protocols.md) | 5 emotion → planet protocols (Anger/Mars, Sadness/Moon, Fear/Saturn, Desire/Venus, Confusion/Mercury) with 6-step intervention scripts | Pause Layer |
| [terrain-templates.md](content/terrain-templates.md) | 12 transit drivers × 5-axis daily templates + Vedic dasha overlays + pattern activation hints + tone rules | Today's Terrain compute engine |
| [schemas.md](content/schemas.md) | Data schemas for Journal Entry (7-row), Decision Simulator (6-axis), Navigation Algorithm (rules store) | All persistence + backend endpoints |

---

## The Core Framework (cross-cutting)

Every TopoSelf-aligned screen routes through this 5-step model:

```
Stimulus  →  Default Script  →  Hidden Need  →  Conscious Route  →  Optimal Action
(event)      (autopilot)        (truth)         (intervention)       (sayable)
```

Implementation note: this is one `CoreLoop` component, reused across:
- Pattern detail view (statically rendered from `patterns.md`)
- Journal entry create flow (the 7-row form maps 1:1 to the loop)
- Decision Simulator output (the 6 axes are an extended Core Loop)
- Today's Terrain daily card (Stimulus = today's transits, Optimal Action = "Highest Agency Move")

Single source of truth: a Swift `enum CoreLoopStage` + `struct LoopFragment`.

---

## Phased implementation roadmap

Each phase is one PR-sized chunk. Phases can ship independently after Phase 0.

### Phase 0 — Foundation (no UI; ~1 week)
- Seed content as bundled JSON resources (convert the 5 markdown files into JSON the app can ship offline).
- Swift types: `Pattern`, `ConsciousnessLevel`, `Protocol`, `TerrainAxis`, `JournalEntry`, `Decision`, `Rule`.
- `PatternMatcher` service: given a natal chart + current transits + active dasha → returns top 3 active patterns with activation scores.
- `TerrainComputer` service: given transits + user → fills the 5-axis daily templates.
- No UI changes. Verified via XCTest fixtures.

### Phase 1 — Pause Layer (smallest, highest moment-of-need value; ~1 week)
- New screen: 5 emotion buttons → planet protocol runner.
- 6-step protocol runner UI (name → locate → breathe → reframe → route → optional ritual).
- Haptic + breath-paced animation tied to the breath count in each protocol.
- Entry points: long-press app icon (3D Touch shortcut), Home widget tap, notification action.
- Logs to journal (mood_before, mood_after, which protocol).

### Phase 2 — Today's Terrain (replaces current Home; ~2 weeks)
- 5-axis terrain card replaces 3-tile Home grid.
- "Log a Moment" CTA — opens lightweight check-in (mood slider + free text + pattern picker).
- Daily Terrain Report (long form view): 5 axes + the dominant active pattern from `PatternMatcher`.
- Existing `ActionGuidance` struct deprecated — `TerrainComputer` supersedes.

### Phase 3 — My Map (replaces current Self tab; ~2 weeks)
- 6-axis radar (Career / Relationships / Family / Money / Inner World / Creativity) with Intensity/Friction/Opportunity scoring.
- Domain → house mapping (Career = 10H + Sun/MC; Inner World = 4H + 12H + Moon/Ketu; etc.).
- Tap a zone → drill into that domain's active patterns + transits + dasha lord context.
- Optional terrain-metaphor layer (Saturn = mountains, Mars = volcanoes) as visual treatment, not literal navigation.

### Phase 4 — Pattern Library browser (~1 week)
- List view of all patterns with activation badges.
- Per-pattern detail: the 6-row loop + body signature + chart conditions that fire it for THIS user.
- Cross-link: "see your journal entries tagged with this pattern."

### Phase 5 — Decision Simulator (replaces Oracle; ~2 weeks)
- Input: free-text decision + structured fields (time horizon, reversibility, inclination).
- Output: 6 axes (Current Weather / Default Pattern / Risk / Opportunity / Best Route / Question to Answer).
- Citations: every axis links back to specific transits, dasha, patterns, rules.
- Wait gate: if `mood_at_input > 70` (high arousal), suggest running a Pause Layer protocol first.

### Phase 6 — Journal & Insights (~2 weeks)
- 7-row structured journal (per schemas.md): what happened / body / story / pattern / what I did / higher route / learning.
- Body-region picker (anatomy SVG, tap regions).
- Pattern auto-suggestion from `PatternMatcher` at the moment of entry.
- Mood before/after + active transit snapshot stored automatically.
- Insights tab: pattern frequency over time, common stories, growth edges.

### Phase 7 — Navigation Algorithm (~1 week)
- Rules store + UI.
- Rule extraction prompt at end of each journal entry: "Is there a rule worth saving from this?"
- Suggested rules from app (based on repeated patterns).
- Decision Simulator pulls active rules into the "Best Route" axis.
- Per-rule analytics: invoked / followed / broken counters.

---

## Compute requirements (backend side)

Most of this lives in the Flask backend at `server/`. Endpoints to add:

| Endpoint | Returns | Used by |
|---|---|---|
| `POST /api/v1/topo/patterns/active` | Top N patterns with activation scores for given chart + datetime | Today's Terrain, Pattern Library |
| `POST /api/v1/topo/terrain/today` | Filled 5-axis terrain report | Home |
| `POST /api/v1/topo/domains/score` | 6-axis domain radar scores (Career/Relationships/Family/Money/Inner World/Creativity) | My Map |
| `POST /api/v1/topo/decision/simulate` | 6-axis decision output | Decision Simulator |
| `POST /api/v1/topo/protocols/log` | Records a Pause Layer run | Pause Layer |
| `GET/POST/PUT /api/v1/topo/journal` | Journal CRUD | Journal |
| `GET/POST/PUT /api/v1/topo/rules` | Navigation Algorithm CRUD | Rules store |

The pattern-matcher, terrain-computer, and domain-scorer share a `ChartFeatures` extractor (planets in houses, aspects, dignities, dasha lord, antardasha lord, retrogrades, void-of-course/tithi-kshaya). Build that once.

---

## Brand voice rules (apply everywhere)

Lifted from content artifacts — codified here so every future writer follows.

- Maximum 12 words per UI line.
- No prediction. Always conditions + agency.
- No "the universe wants you to..." mysticism.
- "Avoid" is permission to skip, not a curse.
- "Best Use" is the user's leverage, not the planet's gift.
- Verbs imperative for action axes; observational for condition axes.
- No emojis. No exclamation marks except in Sanskrit mantras.
- Body cues must be observable, not interpretive ("shoulders drop, breath slows to 4-count" not "feels grounded").

---

## Open decisions (not made this session)

1. **Tab bar architecture.** Current: Home / Discover / Self / Temple / TimeTravel / Chat. TopoSelf demands at least Pause + Journal as first-class. Do we replace TimeTravel + Discover, or add a 7th tab, or hide existing tabs behind a "More" menu?
2. **Onboarding to consciousness model.** First-time users will not have language for "Recognition Threat." How do we introduce the framework without a 5-minute tutorial?
3. **Privacy of journal + rules.** These are intimate. Local-only with optional encrypted iCloud sync? Server-side at all? Affects schema (`user_id` may be device-local).
4. **Personalization debt.** Patterns are pre-authored. The framework demands they feel personal. Either: (a) heavy chart-aware copy templating, (b) LLM-generated per-user pattern phrasing at first use cached forever, (c) author 3x the patterns and pick best match. Pick one before Phase 4.
5. **What happens to existing Compatibility / Synastry features.** They don't fit TopoSelf. Keep as-is, retire, or rewrite through the same Core Loop lens (relationship as terrain)?
6. **Monetization.** Existing paywall gates reports. Where does it gate now? Pause Layer must be free (moment of need). Decision Simulator could be premium. Pattern Library + Journal: probably free, with depth/insights premium.

---

## What ships first (recommendation)

Phase 0 + Phase 1 (Pause Layer) in 2 weeks. Reasons:
- Smallest scope, smallest risk to existing UX.
- Only feature that gives users a reason to open the app **at peak emotion** instead of casual scroll. That's the moat.
- Validates the content library (protocols.md) before committing to the larger surfaces.
- Naturally generates the first journal entries (mood_before / mood_after), seeding Phase 6.

If Phase 1 shows engagement lift, ship Phase 2 (Today's Terrain) next. If not, the content library is still reusable — the protocols can become a standalone widget, marketing surface, or App Clip.
