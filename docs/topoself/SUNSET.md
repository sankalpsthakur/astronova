# Astronova Tab Bar Sunset Plan

## 1. Tab Mapping (Old → New)

| Old Tab | Old View | New Tab | New View | Status | Notes |
|---------|----------|---------|----------|--------|-------|
| 0 | DiscoverView | 0 | Today's Terrain | **replace** | Redirect in RootView.swift:1915 |
| 1 | TimeTravelTab | 1 | Pulse | **keep** | Rename FloatingTabBar label, preserve route binding |
| 2 | TempleView | 2 | Pulse | **keep** | Existing PauseLayerView at Features/Topo/Views/PauseLayerView.swift |
| 3 | ConnectView | 4 | Decide | **replace** | Oracle + Chat → Decision Simulator |
| 4 | SelfTabView | 1 | Map | **replace** | Rename to My Map (life-domain radar) |

**Intent Route Compatibility:** RootView.swift:2037–2051 maps `AstronovaIntentRouteStore.Route` to tab indices. Routes must remain:
- `.today` → tab 0 (new Today's Terrain)
- `.timeTravel` → tab 1 (rename label only)
- `.temple` → tab 2 (Pulse → PauseLayerView, no change)
- `.connect` → tab 4 (Decision Simulator)
- `.profile` → new tab or deprecated (move to Settings)

---

## 2. View-Level Sunset Inventory

### Legacy Discover Feature
**Path:** `Features/Discover/`
**Files:** 12 Swift files
**LOC:** ~4,155 (including DiscoverView.swift at 606 lines)
**Status:** `fold-into-new`
**Replacement:** Today's Terrain (to be built at Features/Topo/Views/TodayTerrainView.swift)
**Risk:**
- DiscoverView instantiated at RootView.swift:1915, 1927 (tab 0 default fallback)
- Posts `.switchToTab(3)` and `.switchToTab(1)` notifications (DiscoverView.swift:241, 257, 288, 290, 292)
- **Dependency:** `Notification.Name.switchToTab` handler at RootView.swift:1995
- Migrate tab navigation calls to new indices before removing DiscoverView

### Legacy Temple Feature
**Path:** `Features/Temple/`
**Files:** ~6 Swift files
**LOC:** ~2,201 (TempleView.swift at 420 lines)
**Status:** `keep`
**Replacement:** None (PauseLayerView already at Features/Topo/Views/PauseLayerView.swift)
**Risk:**
- Tab 2 remains TempleView in RootView.swift:1920 (must rebind to PauseLayerView in new structure)
- `.temple` route at AstronovaIntentRouteStore:180 → tab 2 (preserve)
- OpenTempleIntent at AstronovaAppApp.swift:215 expects tab 2
- Move TempleView logic into PauseLayerView or deprecate if fully replaced by Pulse

### Legacy TimeTravel Feature
**Path:** `Features/TimeTravel/`
**Files:** 6 Swift files
**LOC:** ~3,613 (UnifiedTimeTravelView.swift primary)
**Status:** `keep` (rename to Pulse in tab bar)
**Replacement:** None
**Risk:**
- Tab 1 bound to TimeTravelTab (defined inline at RootView.swift:2221)
- `.timeTravel` route at AstronovaIntentRouteStore:178 → tab 1 (preserve)
- OpenTimeTravelIntent at AstronovaAppApp.swift:204 expects tab 1
- Update FloatingTabBar tabs array at RootView.swift:2330 (L10n.Tabs.timeTravel → "Pulse")

### Legacy Self Feature
**Path:** `Features/Self/`
**Files:** 11 Swift files
**LOC:** ~642 (SelfTabView.swift at 642 lines)
**Status:** `replace` (→ My Map radar view)
**Replacement:** Features/Topo/Views/MyMapRadarView.swift (to be built)
**Risk:**
- SelfTabView instantiated at RootView.swift:1924 (tab 4)
- `.profile` route at AstronovaIntentRouteStore:184 → tab 4 (must map to new tab or Settings)
- Posts `.switchToProfileSection` notification (used internally, low external risk)
- **Critical:** Migrate profile/auth state from SelfTabView before removal
- AppleSIgnIn, subscription state likely stored here

### Legacy Chat Feature
**Path:** `Features/Chat/`
**Files:** 1 Swift file (ChatPackagesSheet.swift at 279 lines)
**Status:** `fold-into-new`
**Replacement:** Part of Decision Simulator (Features/Topo/Views/DecisionSimulatorView.swift)
**Risk:**
- ChatPackagesSheet imported by ConnectView
- Low standalone risk; move into DecisionSimulatorView context

### Legacy Oracle Feature
**Path:** `Features/Oracle/`
**Files:** 4 Swift files
**LOC:** ~518 (OracleView.swift at 168 lines)
**Status:** `fold-into-new`
**Replacement:** Part of Decision Simulator
**Risk:**
- OracleView used by ConnectView (RootView.swift:1922, tab 3)
- `.connect` route at AstronovaIntentRouteStore:182 → tab 3 (must rebind to tab 4)
- OpenConnectIntent missing from AstronovaAppApp.swift (no Siri shortcut; low risk)
- Move OracleViewModel and OracleQuotaManager logic into Decision Simulator

---

## 3. Shared Dependencies to Preserve

### Notification Routes
**File:** `AstronovaAppApp.swift:141–145`
```
extension Notification.Name {
    static let switchToTab = Notification.Name("switchToTab")
    static let switchToProfileSection = Notification.Name("switchToProfileSection")
    static let openVideoSession = Notification.Name("openVideoSession")
}
```
**Impact:** All old tabs emit `.switchToTab` with old indices. **Action:** Update handlers in new views OR remap indices in RootView.swift:1995–2007.

### Intent Route Store
**File:** `AstronovaAppApp.swift:147–191`
**Routes:** `.today`, `.timeTravel`, `.temple`, `.connect`, `.profile`
**Mapping in RootView.swift:2037–2051:**
```
case .today: targetTab = 0
case .timeTravel: targetTab = 1
case .temple: targetTab = 2
case .connect: targetTab = 3
case .profile: targetTab = 4
```
**Action:** Update tab indices when renaming. `.connect` → tab 4 (Decision Simulator), `.profile` → move to Settings or deprecated route.

### App Intents
**File:** `AstronovaAppApp.swift:193–256`
- `OpenTodaysGuidanceIntent` → Route.today → tab 0 ✓ (preserved)
- `OpenTimeTravelIntent` → Route.timeTravel → tab 1 ✓ (preserved)
- `OpenTempleIntent` → Route.temple → tab 2 (must verify tab 2 = PauseLayerView)
- **Missing:** No OpenConnectIntent or OpenProfileIntent (low risk)

### Shortcuts Provider
**File:** `AstronovaAppApp.swift:226–258`
**Action:** Add intents for new tabs (TodayTerrainIntent, MyMapIntent, DecisionSimulatorIntent) or update existing intents' descriptions.

### URL Scheme Handling
**File:** `AstronovaAppApp.swift:172–190`
```
switch url.host {
    case "today", "guidance", "daily", "cosmic-weather": request(.today)
    case "time", "timeline", "time-travel", "muhurat": request(.timeTravel)
    case "temple", "ritual": request(.temple)
    case "connect", "oracle", "chat": request(.connect)
    case "profile", "blueprint", "pro", "paywall": request(.profile)
}
```
**Action:** Preserve routing; `.connect` handler must redirect to tab 4 (Decision Simulator).

### Widget Extension
**File:** `TodaysHoroscopeWidget/Info.plist` (no Swift code; asset-only)
**Impact:** Widget likely displays data from today tab. **Action:** Verify widget data source after Today's Terrain launch; update deeplink target from tab 0 (DiscoverView) to tab 0 (Today's Terrain).

---

## 4. Recommended Sunset Strategy

**→ STRATEGY A: Hard Cutover + Legacy Headers**

Replace tab bindings in RootView.swift (lines 1912–1929), update FloatingTabBar labels (line 2328–2334), and add `// SUNSET 2026-05-18:` comment headers to all legacy view files. Leave `.swift` files in Git history for blame/reference. This minimizes code churn, keeps audit trail intact, and lets new views prove stable before aggressive cleanup. One-touch migration reduces merge risk and keeps old code visibly deprecated rather than partially orphaned.

---

## 5. RootView SimpleTabBarView Edit (Pseudo-Diff)

**Current (lines 1912–1929):**
```swift
switch selectedTab {
case 0:
    NavigationStack { DiscoverView() }
case 1:
    TimeTravelTab()
case 2:
    TempleView()
case 3:
    ConnectView()
case 4:
    SelfTabView()
default:
    NavigationStack { DiscoverView() }
}
```

**New:**
```swift
switch selectedTab {
case 0:
    NavigationStack { TodayTerrainView() }          // ← Replace DiscoverView
case 1:
    MyMapRadarView()                                // ← Replace SelfTabView
case 2:
    PauseLayerView()                                // ← Keep (rename from TempleView)
case 3:
    TimeTravelTab()                                 // ← Shift from tab 1
case 4:
    DecisionSimulatorView()                         // ← Replace ConnectView/Oracle
default:
    NavigationStack { TodayTerrainView() }
}
```

**Also update FloatingTabBar.tabs array (line 2328–2334):**
```swift
private let tabs: [(title: String, icon: String, customIcon: String?)] = [
    (title: "Today", icon: "sun.max.fill", customIcon: nil),          // ← Today's Terrain
    (title: "Map", icon: "map.fill", customIcon: nil),                 // ← My Map
    (title: "Pulse", icon: "waveform.circle.fill", customIcon: nil),   // ← Pause Layer
    (title: "Pulse", icon: "clock.arrow.circlepath", customIcon: nil), // ← Keep TimeTravel label
    (title: "Decide", icon: "brain.fill", customIcon: nil)             // ← Decision Simulator
]
```

**Update intent route handler (line 2037–2051):**
```swift
let targetTab: Int
switch route {
case .today: targetTab = 0           // ✓ (no change)
case .timeTravel: targetTab = 3      // ← Shift from 1 → 3
case .temple: targetTab = 2          // ✓ (no change)
case .connect: targetTab = 4         // ← Shift from 3 → 4
case .profile: /* deprecated */ return  // Or route to Settings
}
```

---

## 6. Files to Delete in Next Cleanup Pass (Prioritized)

**Safe-to-delete candidates** (after new tabs stable, ~2–4 weeks):

1. **`Features/Discover/DiscoverShimmerView.swift`** (skeleton; subsumed by TodayTerrainView)
2. **`Features/Self/ProfileCompleteness.swift`** (helper; no external refs)
3. **`Features/Self/QuickBirthEditSheet.swift`** (sub-view; no external refs)
4. **`Features/Self/EssenceBar.swift`** (visual component; no external refs)
5. **`Features/Self/CosmicPulseView.swift`** (redundant with Pulse/Pause)
6. **`Features/Chat/ChatPackagesSheet.swift`** (folded into DecisionSimulatorView)
7. **`Features/Oracle/OracleView.swift`** (subsumed by DecisionSimulatorView)
8. **`Features/Oracle/OracleViewModel.swift`** (migrate to DecisionSimulatorViewModel)
9. **`Features/Temple/Shastriji/ShastrijiConsultView.swift`** (if unused after audit)
10. **`Features/TimeTravel/Views/TimeTravelSwarmOverlay.swift`** (if UI reimplemented in Pulse)

**Keep (core logic, external refs):**
- `Features/Self/SelfDataService.swift` (profile data → migrate to MyMapStore)
- `Features/Self/ReportDetailView.swift` (used by domain detail flows; audit further)
- `Features/Temple/TempleView.swift` (core — deprecate after PauseLayerView proven)
- `Features/Oracle/OracleQuotaManager.swift` (subscription tracking — migrate to DecisionSimulatorContext)

**Never delete without audit:**
- `Features/Discover/DomainDetailView.swift` (referenced by navigation; check target)
- `Features/TimeTravel/Views/UnifiedTimeTravelView.swift` (primary view; audit for reuse)

---

## Implementation Timeline

- **Week 1:** Build TodayTerrainView (Today's Terrain), MyMapRadarView (My Map), DecisionSimulatorView (Decide).
- **Week 1–2:** Update RootView.swift, FloatingTabBar, route handlers. Run QA on all intent routes, Siri shortcuts.
- **Week 2:** Soft launch with feature flag (optional); hard launch if confident.
- **Week 3–4:** Monitor crash reports, engagement metrics. Confirm new tabs stable.
- **Week 4+:** Cleanup pass (delete listed files, remove deprecated code).

---

**Audit Snapshots:**
- **Total legacy LOC:** ~10,766 (Discover 4155 + Self 642 + Temple 2201 + TimeTravel 3613 + Chat 279 + Oracle 518)
- **New feature LOC budgeted:** ~6,000 (TodayTerrainView 1500, MyMapRadarView 1200, DecisionSimulatorView 2000, utilities 1300)
- **Net reduction:** ~4,766 LOC after cleanup
