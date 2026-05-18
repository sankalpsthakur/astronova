# Schemas

Three data contracts power the TopoSelf surface of Astronova: the Journal Entry (reflective capture), the Decision Simulator (single-question prospective read), and the Navigation Algorithm (user-curated rules store). All three share the Pattern Library as a lookup and the live astro engine as a context source.

Format convention for every schema below:

```
key: type — description
```

Types: `string`, `text`, `int`, `float`, `bool`, `iso_datetime`, `uuid`, `enum<...>`, `array<T>`, `object{...}`, `ref<schema>`. `nullable` is explicit. Ranges in brackets, e.g. `int [0..100]`.

---

## 1. Journal Entry Schema

The Journal is a 7-row reflective capture. The row sequence is fixed — it walks the user from event to learning in one pass. Each row binds to one cognitive layer (event, soma, narrative, pattern, behavior, alternative, integration). Rows are individually optional except the first, but the UI nudges completion.

### Envelope

```
entry_id: uuid — primary key for the entry.
created_at: iso_datetime — server-stamped on first save.
user_id: uuid — owning user.
current_transits_snapshot: array<object{planet: string, sign: string, degree: float, house: int, aspect_to_natal: string, orb: float}> — top 10 active transits captured at entry creation; immutable after save.
active_dasha_snapshot: object{mahadasha: string, antardasha: string, pratyantar: string, start: iso_datetime, end: iso_datetime} — Vedic period state at entry creation; immutable.
mood_before: int [0..100] — user-set pre-write mood slider.
mood_after: int [0..100] — user-set post-write mood slider; captured after row 7.
linked_pattern_id: nullable ref<Pattern> — single primary pattern this entry resolved to (set by row 4, may be null).
linked_planet: nullable enum<sun, moon, mercury, venus, mars, jupiter, saturn, rahu, ketu, uranus, neptune, pluto> — single primary planet implicated; derived from pattern or user-selected.
rows: object{row_1..row_7} — the 7 fields below.
status: enum<draft, complete> — draft = not all required fields filled.
```

### Row 1 — What happened?

```
field_id: what_happened
prompt: "What happened?"
placeholder: "I felt ignored in the meeting"
input_type: text_long
required: true
astro_link: false
validation: 1..500 chars; no markdown; trims whitespace.
```

### Row 2 — Body response

```
field_id: body_response
prompt: "Where did you feel it in the body?"
placeholder: "Tight chest, heat in face"
input_type: body_region_picker + text_short
required: false
astro_link: false
validation: regions multi-select from {crown, third_eye, throat, jaw, neck, shoulders, chest, heart, solar_plexus, gut, lower_back, hips, pelvis, legs, hands, whole_body}; free-text caption 0..120 chars.
```

### Row 3 — Story created

```
field_id: story_created
prompt: "What story did your mind tell?"
placeholder: "They don't respect my ideas"
input_type: text_long
required: false
astro_link: false
validation: 0..400 chars.
```

### Row 4 — Pattern activated

```
field_id: pattern_activated
prompt: "Which pattern fired?"
placeholder: "Recognition Threat"
input_type: pattern_picker
required: false
astro_link: true — picker pre-ranks patterns by current activation score from astro engine.
validation: multi-select from {recognition_threat, solitude_recharge, control_under_uncertainty, fast_execution_slow_recovery, emotional_delayed_processing, no_pattern_fits}; if no_pattern_fits is selected it must be the only value; max 3 selections otherwise; the first selection becomes linked_pattern_id on the envelope.
```

### Row 5 — What I did

```
field_id: what_i_did
prompt: "What did you actually do?"
placeholder: "Spoke sharply and interrupted"
input_type: text_long
required: false
astro_link: false
validation: 0..400 chars.
```

### Row 6 — Higher route

```
field_id: higher_route
prompt: "What was the higher route?"
placeholder: "Could have asked for clarity"
input_type: text_long
required: false
astro_link: true — engine may pre-fill from linked pattern's High Consciousness Route field as a suggestion (user can accept or rewrite).
validation: 0..400 chars.
```

### Row 7 — Learning

```
field_id: learning
prompt: "What is the learning?"
placeholder: "I'm sensitive to being unseen"
input_type: text_long
required: false
astro_link: false
validation: 0..400 chars; learning text is the candidate for `rule_text` if user converts this entry into a Navigation Algorithm rule (see cross-schema relationships).
```

### Pattern picker rules

- Source list: the 5 canonical patterns from `patterns.md` plus the sentinel `no_pattern_fits`.
- Multi-select up to 3; ordered by user selection.
- `no_pattern_fits` is exclusive — selecting it clears all other selections.
- The picker is pre-sorted by current activation score so the most-fired pattern surfaces first.
- The first non-sentinel selection writes to `linked_pattern_id` on the envelope.

### Body region picker rules

- Anatomy map with 16 tap zones (listed in row 2 validation).
- Multi-select unbounded but UI caps at 5 visible chips.
- Optional free-text caption supplements but does not replace zones.
- Captured zones are exposed to the Decision Simulator as a body-signature feature.

### Example record

```
{
  "entry_id": "9a1f-...-1c",
  "created_at": "2026-05-18T14:22:09Z",
  "user_id": "u_4421",
  "current_transits_snapshot": [
    {"planet": "mars", "sign": "leo", "degree": 12.4, "house": 10, "aspect_to_natal": "conjunct_sun", "orb": 1.2}
  ],
  "active_dasha_snapshot": {"mahadasha": "shani", "antardasha": "mangal", "pratyantar": "budha", "start": "2025-11-02T00:00:00Z", "end": "2026-12-14T00:00:00Z"},
  "mood_before": 28,
  "mood_after": 61,
  "linked_pattern_id": "pat_recognition_threat",
  "linked_planet": "mars",
  "rows": {
    "what_happened": "I felt ignored in the meeting",
    "body_response": {"regions": ["chest", "jaw", "shoulders"], "caption": "Tight chest, heat in face"},
    "story_created": "They don't respect my ideas",
    "pattern_activated": ["recognition_threat"],
    "what_i_did": "Spoke sharply and interrupted",
    "higher_route": "Could have asked for clarity",
    "learning": "I'm sensitive to being unseen when Mars conjuncts my Sun"
  },
  "status": "complete"
}
```

---

## 2. Decision Simulator Schema

One question in, six axes out. The engine fuses live transits, active Vedic dasha, the user's three dominant natal patterns, the user's active Navigation Algorithm rules, and journal entries from the last 7 days filtered by decision class.

### Input

```
decision_id: uuid — primary key.
created_at: iso_datetime — server-stamped.
user_id: uuid — owning user.
prompt_text: text — the user's free-form question; 5..240 chars.
decision_class: enum<career, relationship, money, health, creative, family, other> — auto-classified; user may override.
time_horizon: enum<hours, days, weeks, months, years> — how soon the decision plays out.
reversibility: enum<high, medium, low, one_way_door> — cost of reversing the choice.
user_stated_inclination: enum<lean_yes, lean_no, unclear> — how the user already feels.
mood_at_input: int [0..100] — slider captured before the read.
```

### Compute inputs the engine must pull

```
transits_active: array<ref<Transit>> — top 5 transits ranked by orb-weighted strength at created_at.
dasha_state: object{mahadasha: string, antardasha: string, lord_of_class: string} — current Vedic period; lord_of_class is the planet ruling the decision_class bhava in the user's chart.
dominant_patterns: array<ref<Pattern>> [3] — top 3 patterns from the user's natal chart by baseline activation score.
matching_rules: array<ref<Rule>> — Navigation Algorithm rules where `trigger_pattern` is in `dominant_patterns` OR `trigger_context` == `decision_class` OR `trigger_astro` matches `transits_active`/`dasha_state`; only `active=true` rules.
recent_journal: array<ref<JournalEntry>> — entries from last 7 days where `linked_pattern_id` is in `dominant_patterns` OR free-text matches `decision_class` keywords.
```

### Output — the 6 axes

Each axis is:

```
{
  text: string — 1..280 chars, plain prose, no bullets.
  confidence: float [0..1] — engine self-rating of the read.
  citations: array<object{source: enum<transit, dasha, pattern, rule, journal>, id: string}> — every claim must cite at least one input; max 5 citations per axis.
}
```

Axis contracts:

1. **current_weather** — names the dominant active transit + dasha and how it colors the next time_horizon window. Must cite ≥1 transit and ≥1 dasha. Tone: descriptive, not advisory.
2. **your_default_pattern** — names the single pattern most likely to fire on this decision and the script it will run. Must cite exactly 1 pattern. Tone: diagnostic.
3. **risk** — the specific failure mode if the default pattern runs unchecked. Must cite ≥1 pattern and ≥1 transit OR rule. Tone: concrete, no abstractions.
4. **opportunity** — the specific upside if the user runs the High Consciousness Route instead. Must cite ≥1 pattern. Tone: concrete.
5. **best_route** — a single recommended next action sized to `time_horizon` and `reversibility`. Must cite ≥1 rule if any matching_rules exist, else ≥1 pattern. Tone: imperative, one verb.
6. **question_to_answer** — a reframe of the user's prompt as a clarity test, not a yes/no. Must NOT begin with "should". Must NOT end with "?yes/no". Format: "What would have to be true for X?" or "What is the smallest reversible version of X?" or similar. Cites ≥1 input.

### Engine constraints

- `best_route` must respect `reversibility`: if `one_way_door`, the route is a clarity step, never the decision itself.
- If `mood_at_input < 30`, every axis must include language acknowledging low-mood distortion and citations must favor `journal` and `pattern` over `transit`.
- If `matching_rules` is empty, the engine surfaces a one-line nudge in `best_route` suggesting the user codify a rule from this read.
- Total output token budget per simulation: 1200.

### Example record

```
{
  "decision_id": "dec_71a4",
  "created_at": "2026-05-18T15:02:00Z",
  "user_id": "u_4421",
  "prompt_text": "Should I launch my product now?",
  "decision_class": "career",
  "time_horizon": "weeks",
  "reversibility": "low",
  "user_stated_inclination": "lean_yes",
  "mood_at_input": 72,
  "output": {
    "current_weather": {"text": "Mars in Leo crossing your natal Sun for the next 9 days; Shani-Mangal antardasha is sharpening visibility and friction.", "confidence": 0.82, "citations": [{"source": "transit", "id": "t_mars_sun_conj"}, {"source": "dasha", "id": "d_shani_mangal"}]},
    "your_default_pattern": {"text": "Recognition Threat. You will read early feedback as a status verdict and accelerate to prove the doubters wrong.", "confidence": 0.78, "citations": [{"source": "pattern", "id": "pat_recognition_threat"}]},
    "risk": {"text": "Premature launch in a Mars conjunction window. You ship to win the argument with yourself, not because the product is ready.", "confidence": 0.74, "citations": [{"source": "pattern", "id": "pat_recognition_threat"}, {"source": "transit", "id": "t_mars_sun_conj"}]},
    "opportunity": {"text": "If you pause 72 hours, the same energy ships a tighter version with a clearer story. Mars sustains; it does not have to ignite.", "confidence": 0.69, "citations": [{"source": "pattern", "id": "pat_recognition_threat"}]},
    "best_route": {"text": "Ship the smallest reversible piece this week. Hold the full launch until Mars clears your Sun on May 27.", "confidence": 0.81, "citations": [{"source": "rule", "id": "rule_no_launches_under_mars_sun"}]},
    "question_to_answer": {"text": "What would have to be true for this launch to still feel right on May 28?", "confidence": 0.77, "citations": [{"source": "transit", "id": "t_mars_sun_conj"}]}
  }
}
```

---

## 3. Navigation Algorithm Schema

The Navigation Algorithm is the user's personal rules store — small, hand-written heuristics that guide decisions under pressure. Rules are not advice from the app; they are the user's earned conclusions, often extracted from journal learnings. Rules decay unless reviewed.

### Rule

```
rule_id: uuid — primary key.
created_at: iso_datetime — server-stamped.
user_id: uuid — owning user.
rule_text: text — 1..240 chars; the rule in the user's own voice.
trigger_pattern: nullable enum<recognition_threat, solitude_recharge, control_under_uncertainty, fast_execution_slow_recovery, emotional_delayed_processing> — pattern that activates this rule.
trigger_astro: nullable object{condition: enum<transit, dasha, retrograde, ingress, eclipse>, body: string, qualifier: string} — astro condition that activates this rule (e.g. {condition: retrograde, body: mercury, qualifier: "any"}).
trigger_context: enum<work, love, family, money, health, decision, generic> — life domain.
source: enum<manual_entry, extracted_from_journal, suggested_by_app> — provenance.
confidence: int [1..5] — user-assigned trust score; 1 = experimental, 5 = bedrock.
created_after_event_id: nullable uuid — references the JournalEntry that birthed this rule.
decay_review_date: iso_datetime — when the app prompts the user to re-test the rule; default `created_at + 90 days`.
times_invoked: int [0..n] — count of Decision Simulator runs where this rule was cited or surfaced.
times_followed: int [0..n] — count of those where the user confirmed they followed it.
times_broken: int [0..n] — count of those where the user confirmed they broke it.
active: bool — false means archived but retained for audit.
```

### RuleSet envelope

```
ruleset_id: uuid — primary key per user.
user_id: uuid — owning user.
version: int — increments on any rule add, edit, or status change.
last_reviewed_at: iso_datetime — last time the user did a full rules audit.
total_active_rules: int — count of rules with active=true.
top_invoked_rules: array<ref<Rule>> [5] — top 5 rules by times_invoked over last 90 days.
```

### Validation

- A rule must have at least one of `trigger_pattern`, `trigger_astro`, or a non-generic `trigger_context` — pure-generic rules with no triggers are rejected.
- `times_followed + times_broken <= times_invoked`.
- If `confidence == 5` and `times_broken / max(times_invoked, 1) > 0.4`, the app flags the rule for review regardless of decay date.
- Editing `rule_text` resets `decay_review_date` to `now + 90 days` and bumps `version`.

### Example record

```
{
  "rule_id": "rule_71b3",
  "created_at": "2026-02-12T18:00:00Z",
  "user_id": "u_4421",
  "rule_text": "I do not send important messages after 9pm during Mercury retrograde.",
  "trigger_pattern": null,
  "trigger_astro": {"condition": "retrograde", "body": "mercury", "qualifier": "any"},
  "trigger_context": "decision",
  "source": "extracted_from_journal",
  "confidence": 4,
  "created_after_event_id": "9a1f-...-1c",
  "decay_review_date": "2026-05-13T18:00:00Z",
  "times_invoked": 11,
  "times_followed": 9,
  "times_broken": 2,
  "active": true
}
```

---

## Cross-schema relationships

The three schemas form a closed loop. A Journal Entry's `learning` row is the canonical seed for a Navigation Algorithm rule — when the user promotes a learning, the new Rule carries `source: extracted_from_journal` and `created_after_event_id` pointing back to that entry, preserving the lived event behind the heuristic. The Decision Simulator never invents rules; it pulls the user's `active=true` Rules into `matching_rules` and cites them by `rule_id` in the `best_route` axis, then writes back `times_invoked` (and, on user confirmation, `times_followed` or `times_broken`) so the rules earn or lose trust empirically. The Pattern Library defined in `patterns.md` is the shared lookup for all three: Journal Entries link via `linked_pattern_id`, Decision Simulator computes `dominant_patterns` and `your_default_pattern` against it, and Rules reference it via `trigger_pattern`. One pattern ID flows cleanly through reflection, prediction, and codification, which is what makes the TopoSelf surface a single coherent system rather than three disconnected features.
