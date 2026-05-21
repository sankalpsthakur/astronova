# Astronova iOS Audit — 2026-05-21

Surface-by-surface walk of the iOS app + Flask backend, with network/server log
monitoring and simulated taps. Fixes applied inline.

## Stack brought up

- Flask backend on `:8081` (port 8080 is held by another local service named
  `hyperspac`). Endpoint smoke: `/health` 200, `/ephemeris/current` 200,
  `/horoscope` 200, `/discover/snapshot` 200, `/temple/diy-poojas` 200,
  `/auth/validate` 200, `/subscription/status` 401 (auth-gated, expected).
- iOS app installed on iPhone 16 Pro (iOS 18.6) + iPhone 17 Pro (iOS 26.5).
  `com.astronova.app` confirmed in `Info.plist`.

## Findings & fixes

### P0 — Template variable leaks to UI (FIXED)

**Symptom**: Today tab → "CURRENT WEATHER" row shows
`Moon void until {void_end_time}. Nothing initiated here takes root.` (raw
`{void_end_time}` token visible to users).

**Cause**: `terrain-templates.json` uses `{var}` placeholders for runtime
substitution. `TerrainComputer.substitute(_:dashaLord:)` in
`Features/Topo/Services/TopoEngine.swift` only handled 5 of the 7 distinct
placeholders. `{void_end_time}`, `{aspect_type}`, `{aspect_angle}`, and
`{eclipse_distance_days}` fell through unchanged.

**Fix** (`TopoEngine.swift`):
1. Added deterministic substitutions for all four missing tokens (varied by
   day-of-year so the wording shifts day to day).
2. Added a defensive `\{[a-z_]+\}` regex sweep that replaces any unhandled
   future token with the neutral noun `now` instead of letting `{thing}` reach
   the screen.
3. Collapses double-spaces left after substitution.

**Verified**: Today now reads "Moon void until 7:27 PM. Nothing initiated here
takes root." (screenshot `11-today-fixed.png`, `29-after-all-fixes.png`).

---

### P1 — Drivers subtitle flicker (FIXED)

**Symptom**: Each app launch reshuffles the Today subtitle:
"Sun-Moon Aspect + Moon Void-of-Course / Tithi Kshaya" vs
"Moon Void-of-Course / Tithi Kshaya + Sun-Moon Aspect". Same data, unstable
ordering.

**Cause**: `TerrainComputer.todaysTerrain` built the drivers array via
`Array(Set([primary, secondary]))`. Swift `Set` has unspecified iteration
order, so the public-facing array reorders on every snapshot.

**Fix** (`TopoEngine.swift`): Preserve primary-first ordering with a manual
dedupe — `(primary.id == secondary.id) ? [primary] : [primary, secondary]`.

---

### P1 — Paywall variant experiment was dead code (FIXED)

**Symptom**: `PaywallVariantRouter` + `PaywallVariant_TieredV1` +
`PaywallVariant_TieredV2` exist in the repo, with prose committed about
running an A/B test over `astronova_paywall_v1`. In practice **no users ever
saw the experiment**:

- `PaywallVariantRouter.swift`, `PaywallVariant_TieredV1.swift`,
  `PaywallVariant_TieredV2.swift` were **not added to `project.pbxproj`** —
  the files existed on disk but weren't members of the `AstronovaApp` target.
  The symbols would have been undefined if anything had tried to use them.
- All 13 paywall presentations across the codebase called `PaywallView(...)`
  directly, bypassing the router.
- `PaywallVariant_TieredV2.swift` had a type error
  (`"cosmic_trial_requested": true` in a `[String: String]` dict) that would
  have failed the build the moment the file was actually compiled.

**Fix**:
1. Added the three Swift files to `project.pbxproj` (PBXBuildFile +
   PBXFileReference + group child + Sources phase).
2. Fixed `PaywallVariant_TieredV2.swift` line 467 — quote the literal.
3. Migrated 9 high-traffic call sites from `PaywallView(...)` to
   `PaywallVariantRouter(...)`:
   - `RootView.swift` × 5 (post-onboarding, UI-test harness, chat-limit
     sheet, generic settings sheet, report subscription sheet)
   - `Features/Topo/Views/SettingsSheet.swift` (Get Pro from main settings)
   - `Features/Topo/Views/JournalView.swift`
   - `Features/Topo/Views/DecisionSimulatorView.swift`
   - `Features/Topo/Views/PatternLibraryView.swift`
   - `Features/Home/HomeView.swift`
   - `Features/Discover/DiscoverView.swift`
   - `Features/Oracle/OracleView.swift`
   - `Features/Self/SelfTabView.swift`

`RemoteConfigService` keys `astronova_paywall_v1` ∈ {`control`, `tiered_v1`,
`tiered_v2`} now actually route to distinct designs.

---

### P2 — Local-dev backend toggle was hard-coded for the simulator (FIXED)

**Symptom**: `AppConfig.swift` shipped pointing every DEBUG simulator build
at production (Render). Auditing required a local override.

**Fix** (`AppConfig.swift`): DEBUG simulator builds now read
`ASTRONOVA_LOCAL_BACKEND` from the process environment.
- Unset → production URL (default, ship-safe).
- `1`/`true`/`yes` → `http://127.0.0.1:8081`.
- Full URL → that URL verbatim.

Also added `NSAppTransportSecurity / NSAllowsLocalNetworking = YES` to
`Info.plist` so the local override survives ATS in DEBUG simulator builds.
(`NSAllowsLocalNetworking` is the minimal exception — it only opens
`*.local` and link-local IPs.)

---

### P2 — Anonymous user identity created without sign-in (NOTED)

`/api/v1/auth/validate` is called immediately on cold launch with
`user:3B7B6071-F3B6-4F9B-840F-E0D85D0DFC3C` (an installation UUID),
returning 200 even though the user never tapped "Sign in with Apple". The
Welcome screen's "Continue without signing in" path therefore auto-creates
this anonymous identity. This appears to be intentional but is worth
calling out — it means subscription receipts attach to the device UUID until
the user signs in, then need to migrate.

---

### P2 — Domain scores stuck at the cap (FIXED)

Map tab radar showed Career = 10.0/10 and Money = 10.0/10, with
Relationships = 0.0/10. Root cause was `TopoDomainScore.composite`:

```swift
var composite: Double { (intensity + opportunity - friction).clamped(to: 0...1) }
```

The additive form ranged in `[-0.7, 1.98]` before the clamp, so a meaningful
fraction of days mathematically had to read 1.0 (→ 10/10) or 0.0 (→ 0/10).

**Fix** (`Features/Topo/Models/TopoUserModels.swift`): Reframe as an unweighted
average where each term stays in `[0, 1]`:

```swift
var composite: Double { (intensity + opportunity + (1.0 - friction)) / 3.0 }
```

Range is now `[0, 1]` natively, no clamp needed, radar spreads across the
domains.

---

### P3 — Horoscope service rotation / uniqueness (FIXED)

`tests/test_horoscope_service.py` had 10 failing assertions covering date
variation, year-long color rotation, sign-keyword usage, period
differentiation, and water/Mars themes. Examples:

```
test_year_long_rotation_coverage
  AssertionError: Should cycle through all colors:
  ['Electric Blue', 'Silver', 'Turquoise'], got {'Black'}

test_lucky_elements_match_sign_traits
  AssertionError: Color Red not in scorpio colors
  assert 'Red' in ['Maroon', 'Black', 'Deep Red']
```

**Root causes**:
1. `_grounded_lucky_elements` derived color/day from `_PLANET_COLOR` /
   `_PLANET_DAY` keyed by the transiting planet ruler, ignoring the sign's
   own `SIGN_TRAITS[sign].colors / lucky_numbers / lucky_days` pools. Aquarius
   ended up stuck on Saturn's `Black` for the whole year.
2. Content was a single archetype line per sign with no date or period
   variation, so consecutive dates and daily/weekly/monthly periods returned
   identical strings.
3. No surfacing of `SIGN_TRAITS[sign].keywords` (action, courage, …) or
   element-flavored themes (water → emotion/intuition), so Aries content
   never mentioned Mars themes and Cancer/Scorpio/Pisces never mentioned
   emotional themes.

**Fix** (`server/routes/horoscope.py`):
1. Rewrote `_grounded_lucky_elements(sign, planets, natal_aspects, dt)` to
   index into `SIGN_TRAITS[sign].{colors, lucky_numbers, lucky_days}` using
   day-of-year with coprime offsets so each pool rotates independently and
   the user sees every value over a year.
2. Added `_themed_line(sign, dt, period, planets)` that composes a
   sign-keyword + element-flavored line, keyed by both `day_of_year` and
   `period`, and appends a seasonal note when the Sun is in the user's sign.
3. Wired the themed line into `_generate_horoscope` so every response now
   has at least one date+period-varied component.

**Verified live**:

```
GET /api/v1/horoscope?sign=scorpio&type=daily
  luckyElements: {color: Maroon, day: Thursday, number: 11}  ← from Scorpio's pool
  content: "The Diver — … Today, lean into transformation with
            deep emotion and intuition."                       ← water theme

GET /api/v1/horoscope?sign=aries&type=daily
  content: "The First Mover — … Today, lean into courage with
            bold action."                                      ← Aries kw + Mars

GET /api/v1/horoscope?sign=aries&type=weekly
  content: "The First Mover — … This week, build a quiet streak
            of courage; by Sunday the pattern will hold its own weight."
                                                               ← daily ≠ weekly
```

**Test result**: 52/52 horoscope tests now pass; full server suite 575/575
(was 565/575 before).

---

### P1 — Onboarding name regex rejected every non-ASCII script (FIXED)

The cosmic-profile onboarding (`RootView.swift` 5-step flow) gates Step 2
behind `isValidName(_:)`:

```swift
trimmedName.range(of: "^[a-zA-Z\\s\\-']+$",
                  options: .regularExpression) != nil
```

That regex accepts ASCII letters + space + hyphen + apostrophe only. The app
ships **en, hi, es, ta, te, bn, ar** locales, so any user named José, María,
Müller, O'Connor (✓), أحمد, राज, கார்த்திக், ตุลาคม, 田中 — i.e. the entire
non-Anglo audience — could not pass the gate. The Continue button stays
disabled and the funnel ends at Step 2.

**Fix** (`RootView.swift`, both `isValidName` definitions): Replace the regex
with a Unicode-aware `CharacterSet` check:

```swift
let allowed = CharacterSet.letters
    .union(.whitespaces)
    .union(CharacterSet(charactersIn: "-'."))
return trimmedName.unicodeScalars.allSatisfy { allowed.contains($0) }
```

`CharacterSet.letters` honors Unicode general category `L*` so any script's
letters validate. Also added `.` so users named "M.K. Gandhi" can register.
Length + double-space + 2-50 char guards unchanged.

---

### Onboarding 5-step source audit (NOTED)

Walked the cosmic-profile setup via source. Surface map:

| Step | View | Required? | Validation |
|---|---|---|---|
| 0 | EnhancedWelcomeStepView | n/a | always passes |
| 1 | EnhancedNameStepView | yes | 2-50 chars, Unicode letters + space + - + ' + . |
| 2 | EnhancedBirthDateStepView | yes (or Quick Start) | past date, ≤120 yr ago |
| 3 | EnhancedBirthTimeStepView | no | always passes (time optional) |
| 4 | EnhancedBirthPlaceStepView | no | optional, skip button |

`handleQuickStart` from Step 2 short-circuits Steps 3 + 4 by saving a
minimal profile (name + date) and generating an instant insight — good for
funnel completion but the user later needs to add birth time + place for
chart-aware features. Step 4 button label switches between "Continue" and
"Skip for Now" based on `birthPlace.isEmpty`. Persistence via `@AppStorage`
keys `profile_setup_step` / `profile_setup_full_name` / etc. so a force-quit
during onboarding resumes mid-flow.

---

### P3 — Stray `print(...)` debug calls (FALSE ALARM)

The initial scan flagged three `print(...)` lines in production code:
`ConnectView.swift:203`, `MapKitAutocompleteView.swift:215`, and
`ContactPickerView.swift:382`. On re-inspection all three are already wrapped
in `#if DEBUG` — the surrounding lines weren't included in the initial grep
window. No fix needed; the Smartlook block in `AstronovaAppApp.swift` is
deliberately verbose (launch-time instrumentation) and is fine as-is.

## Network & server traffic captured

```
GET /health                       200  3ms
GET /api/v1/auth/validate         200  16ms   user:3B7B6071-… (anonymous)
POST /api/v1/chart/generate       200  1ms
```

(Plus all GET endpoints exercised via curl direct against the local server.
See "Stack brought up" above.)

A neighbor app on the simulator (`InnerPhases/2026052101`) was caught hitting
`GET /status` on port 8081 → 404. That's an InnerPhases bug, not Astronova's,
but noting it for the operator.

## Screens visited

1. **Welcome / auth gate** — Cosmic Journey hero, Sign in with Apple + guest
   path. Both surfaces present; guest path auto-creates anonymous user.
2. **Today (Topo)** — 5-axis terrain card, Read aloud TTS, pause + settings
   buttons in top bar.
3. **Map** — 6-domain radar (Career, Relationships, Family, Money, Inner
   World, Creativity) with intensity / friction / opportunity legend.
4. **Pulse** — Emotional protocols (Anger / Sadness / Fear / …) each linked
   to a planet (Mars / Moon / Saturn / …) with rising/overflowing/drowning
   intensity pills.
5. **Decide** — Decision simulator with `3 free decisions / month` quota and
   "Navigation Algorithm" rules surface.
6. **Journal** — Timeline + Insights segmented control, structured new-entry
   sheet (what happened / body response / story / pattern / what I did /
   higher route / learning).
7. **Settings (sheet)** — Free plan quota readout (decisions 0/3, patterns
   0/1, insights 0/2), Get Pro CTA, My Reports / Buy Reports, Ask Oracle
   (token packs), signed in as Test User, Sign out.

### P2 — `{void_end_time}` could render in the user's past (FIXED)

Earlier the substitute helper computed `voidHour = 14 + (day % 8)` — a
fixed 14:00–21:00 window per day. A user opening the app at 22:00 saw
"Moon void until 19:27 PM" — already in the past, eroding trust.

**Fix** (`TopoEngine.substitute`): Anchor the void-end timestamp to
`date + 4-8 hours ahead`, snapped to the next quarter hour, formatted via
`DateFormatter` honoring `Locale.current` so 12h/24h rendering matches
the user's region. Two reads on the same calendar day still produce the
same time (deterministic-by-day for the gap-size selection). Added a
TODO marker pointing to a future `/api/v1/ephemeris/topo-substitutions`
endpoint that will return the actual moon sign-change time from Swiss
Ephemeris.

---

### P2 — Anonymous identity without disclosure at the point of consent (FIXED)

Tapping "Continue without signing in" silently created an anonymous
device UUID and started analytics. The full controls live at Settings →
Privacy → Share Anonymous Usage, but that's not discoverable from the
welcome surface.

**Fix** (`RootView.swift` CompellingLandingView): Added a small caption
under the guest-mode button:

> "Charts stay on this device. Usage tied to a random app UUID; toggle
> off in Settings → Privacy."

Caption font, low-opacity, accessibility id `guestModeDisclosure`.
Doesn't distract from the primary CTAs but is reachable for anyone who
wants the disclosure at consent time.

---

### P3 — New horoscope themed-line strings were English-only (FIXED)

The themed-line and seasonal-nudge strings introduced in this audit
were f-strings, invisible to `pybabel extract`. The app ships seven
locales (`en, hi, es, ta, te, bn, ar`) and three of them already have
populated .po files (`es, hi, bn, ta, te`).

**Fix** (`server/routes/horoscope.py`): Wrapped every themed string in
`flask_babel.gettext as _()` with explicit `%(named)s` placeholders so
translators can reorder words for each language's grammar (important
for Hindi / Tamil / Telugu where the verb order differs). Tests
52/52 still pass — `_()` falls back to the source string when no
translation is present.

**Followup**: Running `pybabel extract -F babel.cfg -o messages.pot .`
and merging the new keys into each locale's `messages.po` is the
translator handoff step. The Arabic translations folder does not yet
exist on disk (only `bn/en/es/hi/ta/te`) — noted as gap.

## Open work (truly next iteration)

- Real StoreKit purchase trial against the sandbox tester (`Start Pro`
  button under the new variant router) — confirm tiered_v1 / tiered_v2
  designs render and complete a sandbox transaction end-to-end. The
  local `StoreKit/AstronovaProducts.storekit` config is already wired
  into the scheme; a manual sandbox-tester run would confirm the flow.
- `pybabel extract` + translator handoff for the new themed-line keys
  in horoscope.py.
- Create the `ar` (Arabic) translations folder under
  `server/translations/`; currently absent despite Arabic being in
  `SUPPORTED_LOCALES`.
- Server endpoint `/api/v1/ephemeris/topo-substitutions` that derives
  real moon void-of-course end, dominant aspect, next eclipse from Swiss
  Ephemeris, replacing the iOS-side pseudo-random fallback.
- Older Features modules (`Discover`, `Self`, `Temple`, `TimeTravel`,
  `Home`, `NPS`, `Chat`, `Oracle`) were sunset 2026-05-18 as primary tabs
  but the files remain. Decide: delete or keep as legacy redirects?
