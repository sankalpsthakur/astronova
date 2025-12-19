# Astronova – UX Journey Issue Log (E2E)

Date: 2025-12-19
Device: iPhone 16 Pro (iOS 18.6) Simulator
Backend: http://127.0.0.1:8080
Build: Debug (local)

Format: Journey → Phase → Screen → Interaction → Verification → Result → Notes → Evidence

## Journey A — Free → hits limit → buys credits → continues
- A1 | Limit Setup → Oracle → Tap prompt chip + Send (4x) → Expect free limit banner/lock after limit=2 → Result: No limit banner or blocking; send continues → Notes: Expected in debug/dev (free limit disabled) → Evidence: `docs/ux-journey-e2e/screenshots/journey-a-no-limit-after-4-sends.png`

## Journey B — Free → paywall → Pro → unlimited chat
- B1 | Purchase → Paywall (Cosmic Access) → Tap `startProButton` → Expect Pro activated + paywall state updated → Result: Paywall dismisses (sometimes), but reopening still shows “Start Pro for $9.99”; in later run paywall stayed open after tap → Notes: Pro state not persisted/recognized; purchase feedback unclear → Evidence: `docs/ux-journey-e2e/screenshots/journey-b-paywall-after-purchase.png`, `docs/ux-journey-e2e/screenshots/journey-b-paywall-after-purchase-2.png`
- B2 | Paywall → Paywall (Cosmic Access) → Attempt dismiss via swipe-left / swipe-down → Expect close/back control → Result: ~~No close control and gestures do not dismiss~~ **PARTIALLY FIXED (2025-12-19)**: Swipe-down now dismisses paywall; still no explicit close button → Notes: Paywall can be dismissed via gesture; explicit close control still missing → Evidence: `docs/ux-journey-e2e/screenshots/journey-b-paywall.png`
- B3 | Packages → Paywall → Tap “Get chat packages (no subscription)” → Expect chat packages sheet → Result: Paywall dismissed to Oracle, no packages sheet shown → Notes: CTA appears to no-op/open wrong destination → Evidence: `docs/ux-journey-e2e/screenshots/journey-b-chat-packages-missing.png`

## Journey C — Report purchase → generation → library
- C1 | Purchase → Reports Shop → Tap `reportBuyButton_report_love` → Expect purchase success state (purchased/generate CTA) → Result: Button stays “$12.99”; no confirmation UI → Notes: Purchase action appears to no-op → Evidence: `docs/ux-journey-e2e/screenshots/journey-c-report-purchase-no-state-change.png`, `docs/ux-journey-e2e/screenshots/journey-c-report-purchase-no-state-change-2.png`
- C2 | Library → Self (“Your Reports”) → After purchase attempt, check library → Expect purchased report listed → Result: Library still empty/placeholder → Notes: No report persisted or surfaced → Evidence: `docs/ux-journey-e2e/screenshots/journey-c-library-empty-after-purchase.png`

## Journey D — Time Travel value → upsell when blocked
- D1 | Save → Time Travel → After saving birth time/place, return to Time Travel → Expect prompt removed + dashas load → Result: Incomplete profile prompt persisted until tab switch (Self → Time Travel) → Notes: Screen state did not refresh after save; data exists in profile → Evidence: none (observed during flow)
- D2 | Profile Save → Birth Information edit form → Set Birth Time (e.g., 3:40 PM) + Location, tap Save → Expect time persisted → Result: Birth Time NOT saved; shows "Not set" after save → Notes: Birth Place saves correctly but Birth Time value is lost → Evidence: observed during testing 2025-12-19
- D3 | Profile Edit → Birth Time field → Observe default value when editing → Expect "Not set" or placeholder → Result: Defaults to current system time (e.g., 3:40 PM) → Notes: Confusing UX; user may unknowingly save wrong time → Evidence: observed during testing

## Journey E — Restore (Pro + Credits + Reports)
- E1 | Restore → Paywall (Cosmic Access) → Tap `restorePurchasesButton` → Expect restore confirmation or updated entitlement state → Result: No visible feedback; paywall remains unchanged → Notes: No spinner/toast/success state shown → Evidence: `docs/ux-journey-e2e/screenshots/journey-e-restore-no-feedback.png`

## Journey F — PurchaseFail (Credits + Pro + Report)
- F1 | Purchase Feedback → Paywall → Tap `startProButton` → Expect loading state + success/error feedback → Result: Paywall dismisses silently with NO feedback → Notes: No loading spinner, no success toast, no error message; impossible to distinguish success from failure → Evidence: observed during testing 2025-12-19
- F2 | Error Handling → All purchase flows → Observe error handling when StoreKit fails → Result: Cannot test failure scenarios in simulator; mock store silently succeeds/fails → Notes: Need StoreKit sandbox with configured failure scenarios or TestFlight for realistic testing; current debug build has no visible error handling path → Evidence: N/A (requires TestFlight)
- F3 | Network Error → Purchase flow → Simulate offline during purchase → Result: Not tested; requires network conditioning → Notes: Recommend testing with Network Link Conditioner before launch → Evidence: N/A

## Journey G — SubscriptionLifecycle
- G1 | Status Display → Self Tab / Paywall → Check subscription status indicator → Expect clear Pro/Free status shown → Result: No visible subscription status indicator on Self tab; paywall always shows "Start Pro" regardless of purchase state → Notes: Users cannot verify their subscription status within app → Evidence: observed during testing
- G2 | Expiration → Subscription expires → Expect graceful downgrade + notification → Result: Cannot test in simulator; requires StoreKit sandbox subscription lifecycle → Notes: Recommend TestFlight testing with sandbox accounts → Evidence: N/A (requires TestFlight)
- G3 | Renewal → Subscription renews → Expect seamless continuation → Result: Cannot test in simulator → Notes: Recommend TestFlight testing → Evidence: N/A

## Journey H — Offline/BackendDown
- H1 | Launch Offline → App launch with no network → Expect cached content or graceful offline message → Result: Not fully tested; requires network conditioning → Notes: Recommend testing with airplane mode before launch → Evidence: N/A
- H2 | Backend Down → App features when API returns errors → Expect error states with retry options → Result: Not fully tested in this session → Notes: Backend was running throughout testing; recommend killing backend to test error handling → Evidence: N/A
- H3 | Recovery → Network restored after offline → Expect automatic refresh or manual retry option → Result: Not tested → Notes: Important for App Store review resilience → Evidence: N/A

## Global / Cross-Journey
- X1 | Self → "Today's Energy" list → Observe trailing values → Expect qualitative labels/visuals only → Result: Numeric percentages visible (e.g., 85%, 72%, 65%, 57%) → Notes: Numeric display still present post-intensity change → Evidence: `docs/ux-journey-e2e/screenshots/journey-b-paywall-after-purchase.png`
- X2 | Self → Birth Date field → Observe default value → Expect placeholder or user's actual birth date → Result: Defaults to current date (2025-12-19) → Notes: Birth date should not default to today's date; confusing UX → Evidence: observed during testing
