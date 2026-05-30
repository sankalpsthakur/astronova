# Wave 2 Uncommitted Tree Classification — Astronova

Date: 2026-05-30
Branch: `appstore/wave2-astronova`
HEAD at classification time: `a537800` (A-W1-01), 2 commits ahead of `main`
Author of classification: rejection-fix worker (foreground, incremental commits)

## Purpose

The working tree carried a LARGE pre-existing uncommitted change set dated
2026-05-23..05-27 that is **not** the App Store rejection work and is entangled
with it. This file freezes a file-level classification so the App Store
rejection fixes (A-W1-02 overclaims, A-W1-05 Temple gating) can be committed
surgically while the unrelated feature refactor is left uncommitted for an
owner decision.

Classification buckets:

- **R = rejection-relevant** — overclaim copy or Temple/Pooja gating that this
  task is authorized to touch and commit.
- **F = unrelated feature WIP** — the big 05-23..05-27 refactor (new
  onboarding, Self views, server feature routes/services, Topo refactor). NOT
  committed by this task.
- **N = generated / asset / evidence noise** — screenshots, app icon binary,
  qa-results, scripts, ASC metadata docs. NOT committed by this task.

A single path can be **partially** R and partially F when the same file holds
both rejection copy and refactor churn; those are flagged `R/F (entangled)` and
handled by committing only the safe rejection hunks (or, where hopelessly
entangled, left for the owner — see Entanglement Decisions).

---

## Tracked modifications (from `git diff --numstat`, +/- lines)

| File | +/- | Bucket | Notes |
|------|-----|--------|-------|
| client/AstronovaApp/RootView.swift | 721/1010 | **R/F (entangled)** | Huge refactor (net -289). Also contains overclaim strings (lines ~4130, 4137, 6843, 7150). Entangled — see decisions. |
| client/AstronovaAppUITests/JourneyAcceptanceTests.swift | 378/125 | F | Test refactor for new feature surfaces. |
| client/AstronovaApp/Features/Topo/Views/JournalView.swift | 322/21 | F | Journal feature WIP. |
| server/openapi_spec.yaml | 282/0 | F | New API surface (numerology/predictions/rajayoga/synthesis). |
| client/AstronovaApp/Features/Topo/Views/TodayTerrainView.swift | 265/0 | F | New Topo view. |
| client/AstronovaApp/Features/Self/SelfTabView.swift | 225/0 | F | New Self tab content. |
| client/AstronovaApp/APIServices.swift | 177/0 | F | New API client methods for the feature WIP. (Temple methods here are pre-existing, not in this diff's risk scope.) |
| server/routes/misc.py | 145/2 | F | Server feature WIP. |
| server/tests/test_monetization_entitlements.py | 98/0 | **R** | Monetization entitlement test additions — part of A-W1-01 family; keep green. Already added on this branch's working tree; left as-is (green) — see pytest note. |
| server/db.py | 96/0 | F | Server schema for feature WIP. |
| client/AstronovaApp/StoreKitManager.swift | 88/8 | F (monetization-adjacent) | StoreKit refactor; not an overclaim/Temple change. Left uncommitted. |
| app-store-assets/APP_STORE_SUBMISSION.md | 75/122 | N | ASC metadata doc (Track B scope, not this task). |
| app-store-assets/COPY_PASTE_READY.txt | 59/102 | N | ASC metadata doc. |
| app-store-assets/screenshots/SUBMISSION_CHECKLIST.md | 58/68 | N | Screenshot checklist doc. |
| client/AstronovaApp/Features/Paywall/PaywallView.swift | 58/6 | **R/F (entangled)** | Overclaim strings ("unlimited") AND paywall refactor. See decisions. |
| client/AstronovaAppUITests/AstronovaAppUITests.swift | 44/34 | F | UI test refactor. |
| client/AstronovaApp/Features/Topo/Views/MyMapView.swift | 36/455 | F | Large deletion (map refactor). |
| client/AstronovaApp/TestEnvironment.swift | 36/2 | F | Adds `templeTab`/test IDs for feature WIP. |
| client/AstronovaApp/AuthState.swift | 35/5 | F | `hasUnlimitedAccess` entitlement flag (entitlement model, not user-facing copy). |
| client/AstronovaApp/APIModels.swift | 35/0 | F | New models for feature WIP. |
| app-store-assets/screenshots/APPSTORECONNECT_SELECTION.md | 31/9 | N | Screenshot doc. |
| client/AstronovaApp/Features/Paywall/PaywallVariantRouter.swift | 29/11 | F | Paywall routing refactor. |
| server/app.py | 22/11 | F | Server wiring for new routes. |
| client/AstronovaApp/Features/Chat/ChatPackagesSheet.swift | 21/4 | F | Chat feature WIP. |
| client/AstronovaApp/Config/AppConfig.swift | 20/10 | F | Config/flags for feature WIP. |
| client/AstronovaAppUITests/ChaosJourneyTests.swift | 18/41 | F | Test refactor. |
| client/AstronovaApp/Services/AstronovaFlags.swift | 16/2 | F | Feature flags. |
| client/AstronovaApp/Features/Paywall/PaywallVariant_TieredV2.swift | 15/8 | **R/F (entangled)** | "Unlimited" feature rows + variant refactor. See decisions. |
| client/AstronovaApp/Features/Paywall/PaywallVariant_TieredV1.swift | 14/7 | **R/F (entangled)** | "Unlimited" feature rows + variant refactor. See decisions. |
| server/migrations/004_backfill_session_urls.py | 12/12 | F | Migration churn. |
| client/AstronovaAppUITests/AccessibilityTests.swift | 8/21 | F | Test refactor. |
| server/routes/reports.py | 8/1 | F | Report route WIP. |
| server/routes/__init__.py | 8/0 | F | Registers new feature routes. |
| app-store-assets/IAP_COPY_PASTE_METADATA.txt | 7/6 | N | ASC metadata doc. |
| client/AstronovaApp/Services/ShopCatalog.swift | 6/6 | F (monetization-adjacent) | Catalog tweak; not overclaim copy. |
| client/AstronovaApp/Services/BasicStoreManager.swift | 6/2 | F | Store manager tweak. |
| client/AstronovaApp/Config/RemoteConfigService.swift | 4/0 | F | Remote config for flags. |
| client/AstronovaApp/AstronovaAppApp.swift | 3/3 | **R/F (entangled)** | Small diff; file ALSO contains `OpenTempleIntent` AppIntent + AppShortcut (A-W1-05 target). Needs care — see decisions. |
| app-store-assets/IAP_QUICK_CHECKLIST.md | 3/3 | N | ASC doc. |
| client/AstronovaApp/Features/Discover/NextUpTimeline.swift | 2/2 | F | Discover tweak. |
| client/AstronovaApp/Features/Discover/DiscoverView.swift | 2/2 | F | Discover tweak. |
| client/AstronovaApp/Config/remote_config.json | 1/2 | F | Remote config. |
| client/StoreKit/AstronovaProducts.storekit | 1/1 | F | StoreKit data tweak (trial already correct per A-W1-01). |
| client/AstronovaApp/Gamification/GamificationModels.swift | 1/1 | F | Gamification tweak. |
| client/AstronovaApp/Features/Self/MoreOptionsSheet.swift | 1/1 | F | Self tweak. |
| client/AstronovaApp/Features/Self/FoundationSection.swift | 1/1 | F | Self tweak. |
| client/AstronovaApp/Features/Discover/ContextAwareReportCTAs.swift | 1/1 | F | Discover tweak. |
| client/AstronovaApp/Assets.xcassets/AppIcon.appiconset/app-icon-1024.png | bin | N | App icon binary change. |
| app-store-assets/screenshots/0[1-6]_*.png | bin | N | Screenshot binaries. |

## Untracked paths

| Path | Bucket | Notes |
|------|--------|-------|
| client/AstronovaApp/Features/Onboarding/ | F | New onboarding feature (PhoneVectorStepView etc.). |
| client/AstronovaApp/Features/Self/{ArchetypeHeaderView,AstrocartographyMapView,BayesianSliderView,ConstraintCardView,CosmicMirrorView,LoshuGridView,MatrixView,PremiumGateView}.swift | F | New Self feature views. (PremiumGateView has an overclaim string but the FILE itself is brand-new feature WIP — left uncommitted; see decisions.) |
| client/AstronovaApp/Features/TimeTravel/Views/PredictionTimelineView.swift | F | New feature view. |
| client/AstronovaApp/Features/Topo/Views/{DailySignalCardView,MatrixDeepDiveView,TimelineTabView}.swift | F | New Topo views. |
| client/AstronovaApp/Services/{APIModelMappings,SynthesisRequestStubs,SynthesisService}.swift | F | New service layer for feature WIP. |
| server/routes/{numerology,predictions,rajayoga,synthesis}.py | F | New server feature routes. |
| server/services/{geographic_service,numerology_service,prediction_service,rajayoga_service,synthesis_engine}.py | F | New server feature services. |
| server/tests/test_{numerology,prediction,rajayoga}_service.py | F | New feature tests. |
| server/migrations/009_report_purchase_entitlements.py | F (monetization-adjacent) | New migration; not required by A-W1-02/05. |
| app-store-assets/screenshots/{01_today,02_map_globe,...}.png + 2026-05-23-current/ + archive-20260523-stale/ + iphone65-current/ | N | Screenshot regen output. |
| app-store-prep/2026-05-20/ | N | Pre-existing prep docs (already on disk). |
| docs/design-mockups/ | N | Design mockups. |
| qa-results/2026051816/, qa-results/20260523-launch/ | N | QA evidence. |
| scripts/{add_more_files_to_xcodeproj,add_swift_files_to_xcodeproj,asc_review_submit,generate_astronova_app_icon}.py | N | Tooling scripts. |
| tests/ | F/N | Top-level tests dir (feature WIP / scratch). |
| app-store-prep/WAVE2_TREE_CLASSIFICATION_2026-05-30.md | (this file) | The classification artifact; committed alone first. |

## Entanglement Decisions (A-W1-02 / A-W1-05)

The rejection work targets two narrow concerns that unfortunately live inside
files also carrying the big refactor:

1. **Overclaim copy (A-W1-02)** appears in:
   - `Features/Paywall/PaywallView.swift` — entangled with paywall refactor.
   - `Features/Paywall/PaywallVariant_TieredV1.swift` / `_TieredV2.swift` — entangled.
   - `RootView.swift` (lines ~4130/4137/6843/7150) — entangled with a 1700-line refactor.
   - `Features/Self/PremiumGateView.swift` — brand-new untracked feature file.
   - `Features/Topo/Views/SettingsSheet.swift` — needs verification of tracked/untracked state.
   - `Features/Self/LoshuGridView.swift:581` — "across your lifetime" is benign descriptive prose, NOT a monetization overclaim; LEAVE.

2. **Temple/Pooja (A-W1-05)** is a **fully built feature**, not just stale copy:
   - `Features/Temple/Shastriji/ShastrijiConsultView.swift` (astrologer consult UI)
   - `AstronovaAppApp.swift`: `OpenTempleIntent` AppIntent (Siri: "Open temple"/"Open pooja") + `AppShortcut` with shortTitle "Temple" — **reviewer-reachable via Shortcuts/Siri even if no tab**.
   - `TestEnvironment.swift`: `templeTab` accessibility ID — implies a Temple tab exists in some build configuration.
   - `Localization/LocalizedStrings.swift`: full Temple/Pooja/astrologer/booking strings.
   - `APIServices.swift`: full Temple/Pooja booking + Shastriji methods.
   - `Analytics/AnalyticsService.swift`: temple/pooja analytics events.

### Decision

- **Commit (rejection-safe):** isolated overclaim-copy edits in files where the
  edit can be made without pulling in refactor hunks, and the A-W1-05 gate of
  the AppIntent/AppShortcut + any reviewer-reachable Temple navigation. These go
  in two dedicated commits (`fix: remove App Store overclaims (A-W1-02)` and
  `fix: gate Temple/Pooja offerings (A-W1-05)`), staged with path/hunk-level
  precision so the big refactor is excluded.
- **Leave uncommitted (owner decision):** the entire 05-23..05-27 feature
  refactor (all **F** rows above) and all **N** noise. RootView.swift is the
  hardest case: it is both the overclaim host and the single largest refactor
  file. Per guardrails, if A-W1-02/A-W1-05 edits in a file are hopelessly
  entangled with the big refactor, only the safely separable hunks are
  committed and the rest is reported as left behind with the reason.

## Build & Test Status (as-of working tree, pre-rejection-commit)

- **Monetization pytest** (`server/tests/test_monetization_entitlements.py`):
  per the A-W1-01 commit message it was GREEN (11 passed) at `a537800`. The
  working-tree version adds +98 lines; re-run pending (Bash classifier was
  temporarily unstable during classification). To be re-confirmed before final
  sign-off.
- **Release sim build**: NOT yet attempted from this exact entangled tree.
  Because the tree mixes the refactor + new untracked files that may not be in
  the Xcode target, a Release build of the *raw* working tree is not a reliable
  signal for the rejection commits. The rejection commits are validated against
  a build after they land. Status: PENDING — to be confirmed.

## Owner Decisions Requested

1. The 05-23..05-27 feature refactor (new onboarding, Self/Topo views,
   server numerology/predictions/rajayoga/synthesis routes+services, StoreKit
   refactor) is a coherent unrelated workstream. It needs its own branch/PR and
   its own review — it should not ride on the rejection branch.
2. RootView.swift overclaim fixes: decide whether to (a) cherry-pick only the
   overclaim string hunks onto the committed tree, or (b) defer RootView
   overclaim edits until the refactor lands, to avoid a merge-hostile partial
   commit of a 1700-line-churn file.
