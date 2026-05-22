# 2026-05-21 Audit — Operator Handoff

This is the next-actor checklist for the 9 commits the agent landed on
local `main` between b6ca771 (pre-audit) and 4f1f3a6 (audit close). Each
section is one external dependency the agent could not fulfill solo.

## Status snapshot

- **Local `main` is 9 commits ahead of `origin/main`**
- **Render is `autoDeploy: true` on `branch: main`** — pushing ships
- **643 / 643 tests passing** (582 server + 59 iOS + 2 new UI tests build green)
- **Production is on an old build** — `/api/v1/horoscope` returns pre-themed-line content; `/api/v1/ephemeris/topo-substitutions` returns 404

## 1. Ship the audit fixes to production

This is the highest-value action — single command, deploys 14 bug fixes,
1 new endpoint, accessibility pass, paywall variant router activation,
i18n catalogs, and the 5x server cache.

```bash
cd /Users/sankalp/Projects/iosapps/astronova
git push origin main
```

Render's webhook triggers within seconds; build takes ~3-4 min on the
starter plan. Watch:

```bash
render deploys list <serviceID> -o json --confirm
render logs -r <serviceID> -o text --confirm --tail
```

Service ID lookup:

```bash
render services -o json --confirm | jq '.[] | select(.name=="astronova-backend")'
```

Post-deploy sanity:

```bash
curl https://astronova-ghcr.onrender.com/api/v1/ephemeris/topo-substitutions | jq
curl "https://astronova-ghcr.onrender.com/api/v1/horoscope?sign=aries&type=daily" | jq -r .content
```

Expected post-deploy:
- topo-substitutions returns the JSON shape from
  `qa-results/audit-2026-05-21/AUDIT-FINDINGS.md` (NOT 404)
- horoscope content for Aries daily includes the phrase "courage" or
  "bold action" (the new themed-line work)

## 2. Translator handoff for the new locale catalogs

The agent extracted gettext strings and initialized 6 existing locales
plus the missing Arabic catalog. Translators fill in `msgstr` fields.

```bash
cd server
ls translations/             # ar bn en es hi ta te
wc -l translations/ar/LC_MESSAGES/messages.po  # 7 locales, ~65 entries each
```

For each locale, open the `.po` file in Poedit (or any translator tool)
and translate the new entries (msgstr is currently empty for the
themed-line strings — they fall back to English at runtime). Then
recompile:

```bash
.venv/bin/python -m babel.messages.frontend compile -d translations
git add server/translations/
git commit -m "i18n: <locale> translations for themed-line strings"
git push
```

Render auto-deploys; live response then localizes the horoscope themed
lines based on the `Accept-Language` header.

## 3. StoreKit sandbox purchase trial

The paywall variant router is live across 9 call sites after this audit,
but the agent could not run a real transaction against Apple's sandbox.

Prerequisites:
- Apple Developer account in good standing
- Sandbox tester credentials (App Store Connect → Users and Access →
  Sandbox Testers)
- Physical iOS device or simulator signed into the sandbox account
  (Settings → App Store → Sandbox Account)

Run:

```bash
cd client
xcodebuild -project astronova.xcodeproj \
  -scheme AstronovaApp -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5" \
  build
xcrun simctl install booted build/Debug-iphonesimulator/AstronovaApp.app
xcrun simctl launch booted com.astronova.app
```

Manual paywall walk:
1. Settings → Get Pro → "Start astronova_pro_monthly"
2. Apple's sandbox dialog appears
3. Confirm with sandbox tester password
4. App receives `purchaseResult = .success`
5. Subscription state activates; Settings shows "Pro plan"

Run for all 3 variants — toggle via Remote Config key
`astronova_paywall_v1` ∈ {`control`, `tiered_v1`, `tiered_v2`}. Each
variant uses the same product IDs but a different presentation.

If a variant fails to render or its purchase button is unresponsive,
that's a bug — file it.

## 4. VoiceOver expert audit

The agent did the structural pass (179 Dynamic Type migrations, axis
row `.accessibilityElement(children: .combine)`, isHeader trait on
"Today", labels on icon buttons). A real screen-reader user should
walk Today + Map + Pulse + Decide + Journal + Settings + Paywall and
verify focus order + announcement quality.

Suggested protocol:
1. Settings → Accessibility → VoiceOver: ON
2. Cold-launch Astronova
3. Walk every interactive element in reading order, noting:
   - Are labels clear without context?
   - Do hints add real information vs. restate the label?
   - Is the focus order top-to-bottom, left-to-right?
   - Do decorative icons get skipped?
4. File any tap targets that VoiceOver can't reach or that announce
   unhelpfully as accessibility-* bugs.

The 2 new UI regression tests (`testOnboardingAcceptsUnicodeName`,
`testGuestModeDisclosureIsVisibleBeforeTap`) cover the accessibility-
identifier contract for the auth-gate consent caption; a VoiceOver
expert pass complements them, not replaces them.

## 5. Dynamic Type capping for display-numeral outliers

The bulk migration left 40 fixed-size outliers (28-56pt hero numerals,
monospaced counters). The honest fix per the audit's analysis requires
either `@ScaledMetric` declarations per containing struct or
`Font.system(.titleStyle, design:)` conversion that changes the
default visual design.

This is a design-review-needed PR, not an automatable change. Loop in
the design partner before opening it.

## 6. Sunset module cleanup

The 2026-05-18 sunset comment in `RootView.swift` was updated by this
audit to distinguish live legacy references (DO NOT delete) from
truly-dead modules. A follow-up cleanup PR can delete:

  - `Features/Discover/` (12 files)
  - `Features/Self/SelfTabView.swift` and its private helpers
  - `Features/Temple/TempleView.swift` and the `TempleTab` view
  - `Features/Home/HomeView.swift` + `HomeViewModel.swift` +
    `HomeGuidanceService.swift`
  - `RootView.TimeTravelTab` + `switchToTimeTravelTab()`

Keep:
  - `OracleView` (Settings → Ask Oracle)
  - `NPSView` (root sheet)
  - `ChatPackagesSheet` (all 3 paywall variants + Oracle)
  - `EnhancedTimeTravelView` (referenced by SelfTabView, but if you
    delete SelfTabView you can also delete EnhancedTimeTravelView)

Run iOS tests after each deletion to catch cross-file references.

## 7. Implement a Today's Horoscope home/lock-screen widget

The `client/TodaysHoroscopeWidget/` directory was orphan scaffolding
when the audit started — Info.plist + asset catalog only, no Swift
code, no Xcode target, no references anywhere in the codebase
(scaffolded 2025-09-26, never implemented). The audit removed the
dead files. A real widget would be a strong competitive lever:

- Co-Star, The Pattern, and Sanctuary all ship working iOS widgets
- Astronova's `/api/v1/horoscope` is already shippable
- Small / medium / large sizes covered by one TimelineProvider
- App Group entitlement enables shared UserDefaults between main app
  and widget (sun sign, last-fetched timestamp)

Effort estimate: ~200 lines of Swift + Xcode target setup +
entitlement + background refresh. Plan for ~1 dev-day with simulator
test coverage.

## 8. Push notification timing

Co-Star's competitive moat is *when* it pushes ("you'll feel anxious
today at 3pm"). Astronova's push timing is currently `daily at 9am
local` (config: `daily_notification_default_hour`). A real improvement
would be ephemeris-aware push timing (push the moon-void warning 30 min
before voc; push the dasha transition notification on the day of
transit-exact). This is a product epic, not a bug fix.

## Items the audit closed (no operator action needed)

- 14 production bugs fixed across P0/P1/P2/P3
- 1 new server endpoint with 9 contract tests + iOS client wiring + 5 service tests
- 179 fixed Font.system(size:) calls migrated to Dynamic Type
- 9 paywall call sites moved to PaywallVariantRouter
- 7 locale catalogs initialized (Arabic created)
- Per-UTC-day server cache (5x cold→warm)
- Just-in-time guest mode disclosure caption
- Unicode-aware name validation
- Always-future void_end_time projection
- Stable drivers ordering on Today
- Domain composite formula normalized to [0,1]
- 10 horoscope rotation/uniqueness tests went 0→pass
- 2 new UI regression tests covering audit fixes
- Competitive scorecard documenting position vs 6 domain peers
- AppStore Privacy Nutrition Label still accurate (verified)

See `qa-results/audit-2026-05-21/AUDIT-FINDINGS.md` for the full
finding-by-finding write-up and
`qa-results/audit-2026-05-21/COMPETITIVE-SCORECARD.md` for the
positional analysis.
