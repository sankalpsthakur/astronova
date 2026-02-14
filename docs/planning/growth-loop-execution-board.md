# Growth Loop Execution Board (Phases 4-6)

## Objective
Ship gamified engagement loops + funnel + measurement with visual feedback polish in Time Travel, aligned to:
- Phase 4: Gamify Core Flows
- Phase 5: Copy + Game Integration by Funnel
- Phase 6: Measurement Plan

**Status Date:** 2026-02-13 12:07 IST  
**Owner:** Product + iOS

---

## Parallel Subagent Deployment

### Deployment Event
- [x] Deployed lanes A–D in parallel to verify growth-loop completion.
- [x] Evidence captured at `2026-02-13 12:07 IST`.

### Subagent A — Gamification & Progression QA
- Validate Seeker progression stack and streak/XP model.
- Verify Journey Map milestones unlock logic and challenge rewards.
- Confirm weekly challenge actions map to the requested themes.
- ✅ Findings:
  - `Seeker`, `Alchemist`, `Oracle` and XP thresholds are implemented in gamification models/state.
  - Streak + daily signal draw flow is present and gated to once per day.
  - Arcana unlock and milestone tracking are implemented.
  - Weekly challenge mapping for Love/Career/Calm/Focus is implemented in model and discover UI.
- ⚠️ Risks:
  - `Challenge completion feedback visuals` still need UX polish checks in real sessions.

### Subagent B — Funnel & Messaging QA
- Validate onboarding identity quiz + archetype assignment path.
- Validate daily return touchpoint text and retention prompts.
- Validate paywall framing around “deeper journeys”.
- Verify copy in user-facing temples (Guidance/Pooja/Time Travel) avoids “Pandit” wording.
- ✅ Findings:
  - Archetype assignment is present and stored to shared gamification state.
  - Daily return CTA includes “Draw today's signal” and streak reward language.
  - Paywall framing is consistently “deeper journeys.”
  - Temple copy in iOS UI localizations now renders `Wisdom Guide`.
- ⚠️ Risks:
  - Backend/API “Pandit” terms remain in non-UI message surfaces; verify they are not externally shown.

### Subagent C — Analytics & Instrumentation QA
- Verify required phase-6 events are emitted in analytics service and feature flows:
  - activation_oracle_action
  - streak_check_in
  - retention_day_7
  - temple_engagement_completed
  - paywall_conversion
  - card_unlocked
  - insight_shared
  - weekly_challenge_completed
- ✅ Findings:
  - Required event names are defined in analytics service.
  - Core flow emits all required metrics in manager/paywall call sites.
  - 7-day retention is tracked from first launch age.
- ⚠️ Risks:
  - Dashboard dimensions and alerting rules are still pending.

### Subagent D — Motion & Time Travel Swarm QA
- Review Time Travel motion layer (`TimeTravelSwarmOverlay`, `UnifiedTimeTravelView`, `TimeTravelViewState`) for smoothness and perceived responsiveness.
- Verify loading/scrub transitions and feedback timing.
- Propose animation polish for simulator-visible feel.
- ✅ Findings:
  - Time Travel scrub/loading modes are wired through `UnifiedTimeTravelView` and rendered via overlay.
  - Scrub velocity drives movement and trailing particles for better perceived responsiveness.
  - Non-interactive overlay preserves underlying gesture hit-testing.
- ⚠️ Risks:
  - No simulator runtime verification has run yet; motion feel still unconfirmed on-device.

---

## Phase 4 — Gamify Core Flows

### Implemented (✅)
- [x] Seeker Levels: `Seeker`, `Alchemist`, `Oracle`
  - `client/AstronovaApp/Gamification/GamificationModels.swift`
  - `client/AstronovaApp/Gamification/GamificationManager.swift`
- [x] Streaks + check-in mechanics
  - `client/AstronovaApp/Gamification/GamificationManager.swift`
  - `client/AstronovaApp/Features/Self/SelfTabView.swift`
  - `client/AstronovaApp/Features/Temple/TempleBellView.swift`
- [x] XP economy for meaningful actions
  - Oracle action, Time Travel snapshot, temple bell, sharing, challenges
  - `client/AstronovaApp/Gamification/GamificationManager.swift`
- [x] Sigils/Arcana cards and unlock progression
  - `client/AstronovaApp/Gamification/GamificationModels.swift`
  - `client/AstronovaApp/Gamification/GamificationManager.swift`
  - `client/AstronovaApp/Features/Discover/DiscoverView.swift`
- [x] Weekly themes: Love/Career/Calm/Focus + rewards
  - `client/AstronovaApp/Gamification/GamificationModels.swift`
- [x] Weekly challenge actions wired to core mechanics
  - Love → share daily insight
  - Career → Oracle interaction
  - Calm → Temple bell
  - Focus → Time Travel snapshot
  - `client/AstronovaApp/Features/Discover/DiscoverView.swift`

### Pending/Verification (⚠️)
- [ ] Confirm challenge completion feedback visuals are clear enough in onboarding-to-retention path.
- [ ] Confirm Time Travel challenge navigation opens the correct slice for first-run users.
- [ ] Add light haptic confirmation for new challenge completion and chapter milestone (optional polish).

---

## Phase 5 — Copy + Funnel Integration

### Implemented (✅)
- [x] Onboarding identity quiz and archetype assignment
  - `client/AstronovaApp/RootView.swift`
- [x] Daily return surface: “Draw today's signal” + streak reward
  - `client/AstronovaApp/Features/Discover/DiscoverView.swift`
  - `client/AstronovaApp/Gamification/GamificationManager.swift`
- [x] Conversion framing as “deeper journeys” in paywall copy
  - `client/AstronovaApp/Features/Paywall/PaywallView.swift`
- [x] Temple copy moved away from “Pandit” labels in UI strings
  - `client/AstronovaApp/en.lproj/Localizable.strings`
  - `client/AstronovaApp/es.lproj/Localizable.strings`
  - `client/AstronovaApp/hi.lproj/Localizable.strings`
  - `client/AstronovaApp/ta.lproj/Localizable.strings`
  - `client/AstronovaApp/te.lproj/Localizable.strings`
  - `client/AstronovaApp/bn.lproj/Localizable.strings`

### Pending/Verification (⚠️)
- [ ] Add a retention follow-up nudge after daily signal completion (optional).
- [ ] Add a final “what next” coach copy after weekly completion.
- [x] Verify no customer-facing “Pandit” text remains in remaining localization payloads outside API/backend docs.
- [ ] Audit API/backend copy surfaces and user-visible responses for “Pandit” wording if that is in scope.

---

## Phase 6 — Measurement Plan

### Primary Metrics Instrumentation (✅ implemented, monitor dashboard mapping)
| Metric | Event |
|---|---|
| Activation rate (first oracle action) | `activation_oracle_action` |
| Day-7 retention | `retention_day_7` |
| Temple engagement/session completion | `temple_engagement_completed` |
| Paywall conversion | `paywall_conversion` |

### Secondary Metrics (✅ event plumbing, dashboard pending)
| Metric | Event |
|---|---|
| Streak participation | `streak_check_in` |
| Card unlock rate | `card_unlocked` |
| Share rate | `insight_shared` |

### Pending (⚠️)
- [ ] Wire event properties to dashboard-friendly dimensions (context, cohort, profile age, locale).
- [ ] Add weekly KPI report template for retention/chapter completion trends.
- [ ] Add CI guard to alert when key events drop to zero for release build.

---

## Execution Queue

1. [x] Close parallel QA lanes (A–D), capture evidence notes.
2. [ ] Close remaining Phase 4/5 verification items.
3. [ ] Add dashboard definitions for all metric fields.
4. [ ] Add weekly KPI/reporting coverage for retention/chapter completion.
5. [ ] Run simulator smoke check on:
   - Discover daily signal
   - Time Travel scrub + swarm motion
   - Temple guidance section wording
6. [ ] Final pass + release candidate confidence review.
