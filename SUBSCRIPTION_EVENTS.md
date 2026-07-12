# Astronova — Subscription Lifecycle Events

**Status:** Partial implementation (Wave 14). Verified direct StoreKit purchases
emit typed purchase-success analytics. Transaction updates and opportunistic
subscription-status reads now emit privacy-safe lifecycle events with persisted
deduplication; a long-lived status observer and sandbox validation remain.
**Source of truth:** [`ANALYTICS_INTEGRATION.md`](ANALYTICS_INTEGRATION.md) — monetization event vocabulary.
**Implementation target:** local `StoreKitManager` until the portfolio
`SubscriptionEventEmitter` package is linked.

## SKUs

Resolved via `Bundle.main["AppStoreProductIDs"]` (Info.plist), falling back to
`ShopCatalog.allProductIDs`. Current source/storekit truth is 12 total SKUs:
2 Pro subscriptions, 7 report non-consumables, and 3 chat-credit consumables.
The Pro family is the only subscription product set; chat-credit bundles are
consumables and emit `iap_purchased` instead.

| SKU | Tier | Plan |
|-----|------|------|
| `astronova_pro_12_month_commitment` | `annual` / `twelve_month_commitment` | Current default Pro plan; StoreKit auto-renew |
| `astronova_pro_monthly` | `monthly` | StoreKit auto-renew |
| `report_general`, `report_love`, `report_career`, `report_money`, `report_health`, `report_family`, `report_spiritual` | n/a — non-consumable | `iap_purchased` only |
| `chat_credits_*` | n/a — consumable | `iap_purchased` only |

`ShopCatalog.isProProduct(productID)` is the boundary check that decides
whether a transaction is a subscription.

## Event matrix

Current emissions route through `Analytics.shared.track(...)`, which fans out
to the local `PortfolioAnalytics` shim for portfolio-standard event names. The
"where to call" column references `client/AstronovaApp/StoreKitManager.swift`.

| State transition | Event | Where to call | Properties | Currently emitted? |
|------------------|-------|---------------|------------|--------------------|
| Trial begins | `trial_started` | `handleSuccessfulPurchase(transaction:)` when `transaction.offerType == .introductory` | `sku`, `tier`, `is_trial: true`, `expiration_date` | **No** |
| First paid charge or trial → paid | `subscription_started` | `purchaseProduct(productId:billingPlan:)` after verified StoreKit success | `sku`, `product`, `product_type: "subscription"`, `tier: "pro"`, `period`, `billing_plan`, `is_trial: false`, `source: "purchase_flow"` | **Yes, direct purchase only** |
| Auto-renewal | `subscription_renewed` | `listenForTransactions` when `transaction.originalID != transaction.id` | `sku`, `tier`, `is_trial: false` | **Yes, transaction updates; deduplicated** |
| User disables auto-renew, still entitled | `subscription_cancelled` | status read when `willAutoRenew == false` | `sku`, `tier`, `was_trial: bool`, `reason: "user_cancelled"` | **Yes, opportunistic; deduplicated** |
| User pauses subscription | `subscription_paused` | `RenewalState == .paused` | `sku`, `tier`, `until` | **No** |
| Resumed from pause | `subscription_resumed` | `RenewalState` returns to `.subscribed` from `.paused` | `sku`, `tier` | **No** |
| Grace period entered | `subscription_grace_period` | `RenewalState == .inGracePeriod` | `sku`, `tier` | **Yes, opportunistic; deduplicated** |
| Billing retry entered | `subscription_billing_retry` | `RenewalState == .inBillingRetryPeriod` | `sku`, `tier` | **Yes, opportunistic; deduplicated** |
| Expired (no recovery) | `subscription_lapsed` | `RenewalState == .expired` and entitlement removed | `sku`, `tier`, `reason` | **Yes, opportunistic; deduplicated** |
| Refund / family-sharing revoke | `subscription_refunded` | `transaction.revocationDate != nil` (also `RenewalState == .revoked`) | `sku`, `tier`, `reason` | **Yes, transaction/status reads; deduplicated** |
| Consumable IAP purchase | `iap_purchased` | `purchaseProduct(productId:billingPlan:)` after verified StoreKit success for `chat_credits_*` | `sku`, `product`, `product_type: "consumable"`, `is_consumable: true`, `credits`, `source: "purchase_flow"` | **Yes** |
| Report IAP purchase | `iap_purchased` | `purchaseProduct(productId:billingPlan:)` after verified StoreKit success for report SKUs | `sku`, `product`, `product_type: "non_consumable"`, `is_consumable: false`, `source: "purchase_flow"` | **Yes** |

## Implemented now

1. `StoreKitManager.purchaseAnalyticsEvents(for:source:)` classifies SKUs via
   `ShopCatalog`.
2. Direct verified StoreKit purchases call those emissions after local purchase
   state is updated.
3. `purchase_success` remains a legacy Smartlook/debug event and no longer fans
   out as portfolio `iap_purchased`, because it does not carry enough product
   type information to distinguish subscriptions from consumables.

## Remaining implementation plan

1. Add a long-lived subscription-status observation task so cancel/grace/retry/
   lapse transitions do not depend on another transaction update arriving.
2. Preserve the local `SubscriptionLifecycleStateStore` phase history if the
   portfolio `IOSAppsAnalytics` package is linked later.
3. In `checkCurrentEntitlements()`, keep launch replay analytics-silent while
   still syncing server entitlements.
4. Sandbox-test first buy, renewal, cancellation, grace/billing retry, expiry,
   refund, restore, and family-sharing revoke against the emitted event stream.

## Remaining risky states

- Lifecycle emissions are locally deduplicated, but cancel/grace/retry/lapse
  discovery remains opportunistic until a long-lived status observer is added.
- `subscription_paused` and `subscription_resumed` remain unimplemented.
- Trial detection remains pending. The current direct-purchase event stamps
  `is_trial: false` because the active local code does not safely inspect and
  persist introductory-offer phase.

## Notes

- `paywall_converted` should fire from `purchaseProduct(productId:billingPlan:)`
  *before* the StoreKit purchase resolves (so we capture intent). The
  `subscription_started` event from the emitter follows on success and is the
  authoritative LTV signal.
- Astronova sells consumables (chat credits) — those keep using the existing
  `iap_purchased` event; the emitter ignores them.
