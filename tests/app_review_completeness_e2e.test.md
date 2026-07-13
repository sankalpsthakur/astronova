# Astronova App Review Completeness E2E Evidence

Date: 2026-05-27

Scope:

- App Store completeness remediation for paywall copy, Oracle guest gating,
  report purchase gating, reviewer onboarding notes, and SKU/URL metadata.
- Manual simulator verification through XcodeBuildMCP plus accessibility-tree
  inspection from bridge4simulator.

Build command:

```sh
XcodeBuildMCP build_run_sim
```

Build result:

- Scheme: `AstronovaApp`
- Configuration: `Release`
- Simulator: `iPhone 17 Pro`, iOS Simulator
- Bundle ID: `com.astronova.app`
- Result: succeeded
- Final build log:
  `/Users/sankalp/Library/Developer/XcodeBuildMCP/workspaces/https-appstoreconnect-apple-com-apps-checkout-506b754bc7c6/logs/build_run_sim_2026-05-27T18-11-26-121Z_pid83031_7cd11008.log`

E2E checks:

1. Paywall annual plan copy
   - Path: Settings -> Get Pro.
   - Verified selected 12-month plan says `$49.99 per year`.
   - Verified footer says `14-day free trial, then annual auto-renewal at $49.99 per year until canceled`.
   - Verified stale `per month until canceled` copy is absent from the checked paywall surface.

2. Guest Oracle gating
   - Path: Settings -> Ask the Oracle.
   - Verified the Oracle screen exposes a `Done` button.
   - Verified guest overlay appears with `Sign In to Use Oracle`.
   - Verified `Dismiss sign-in prompt` removes the overlay.
   - Verified depth picker, input field, and send button remain disabled for guests.
   - Verified `Done` returns to Settings.

3. Guest report purchase gating
   - Path: Settings -> Buy Reports.
   - Verified guest report shop shows sign-in-required explanatory copy.
   - Verified report buy buttons read `Sign in required`.
   - Verified tapping a report buy button raises a `Purchase Failed` alert with
     `Sign in with Apple before buying reports so your purchase can be saved and generated.`
   - Verified the flow stops before StoreKit purchase.

4. Reviewer metadata alignment
   - Verified current local reviewer notes use the simulator-visible guest CTA
     `Preview calibration without signing in`.
   - Verified current local reviewer notes list `Today`, `Map`, `Timeline`,
     `Matrix`, and `Journal`.
   - Verified current local reviewer notes list report, chat-credit, and Pro SKU
     identifiers that match `ShopCatalog`.

Supporting command checks:

```sh
rg -n "7-day|Start 7|Continue without signing in|first 3|MISSING_METADATA|astronova_relationship_report|astronova_career_report|astronova_2026_yearly_report|chat_credits_20|astronova\\.onrender\\.com|Self / Time Travel|Time Travel|Temple:|Video consultations|video consultation|Expert Astrologers|sacred rituals|Discover tab hero|119\\.88|per month until canceled|Manage tab" app-store-assets app-store-prep client/AstronovaApp/Features/Paywall client/AstronovaApp/Services/ShopCatalog.swift client/AstronovaApp/Features/Self/PremiumGateView.swift client/AstronovaApp/RootView.swift client/AstronovaApp/StoreKitManager.swift server/app.py server/migrations/004_backfill_session_urls.py
```

Result:

- No stale reviewer-facing matches.

Capability mapping:

- `astronova.commerce_copy`: paywall plan/footer copy and stale trial-duration scan.
- `astronova.oracle_guest_gating`: guest Oracle prompt, dismiss, disabled input, and Done escape.
- `astronova.report_entitlements`: guest report purchase gate stops before StoreKit.
- `astronova.review_metadata`: local review-note, SKU, URL, and support-page copy scan.
- `astronova.reviewer_onboarding`: guest CTA and current 5-tab path in reviewer instructions.
