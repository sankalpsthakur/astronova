# Astronova — Subscription Lifecycle Events

**Status:** Partial implementation (Wave 13). Verified direct StoreKit purchases
now emit typed purchase-success analytics; renewal/cancel/grace states remain
documented below.
**Source of truth:** `umbrella/analytics/ANALYTICS_DESIGN.md` §4 (monetization).
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
| Auto-renewal | `subscription_renewed` | `listenForTransactions` when `transaction.originalID != transaction.id` | `sku`, `tier`, `is_trial: false` | **No** |
| User disables auto-renew, still entitled | `subscription_cancelled` | `Product.SubscriptionInfo.Status` observer when `willAutoRenew == false` | `sku`, `tier`, `was_trial: bool`, `reason: "user_cancelled"` | **No** |
| User pauses subscription | `subscription_paused` | `RenewalState == .paused` | `sku`, `tier`, `until` | **No** |
| Resumed from pause | `subscription_resumed` | `RenewalState` returns to `.subscribed` from `.paused` | `sku`, `tier` | **No** |
| Grace period entered | `subscription_grace_period` | `RenewalState == .inGracePeriod` | `sku`, `tier` | **No** |
| Billing retry entered | `subscription_billing_retry` | `RenewalState == .inBillingRetryPeriod` | `sku`, `tier` | **No** |
| Expired (no recovery) | `subscription_lapsed` | `RenewalState == .expired` and entitlement removed | `sku`, `tier`, `reason` | **No** |
| Refund / family-sharing revoke | `subscription_refunded` | `transaction.revocationDate != nil` (also `RenewalState == .revoked`) | `sku`, `tier`, `reason` | **No** |
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

1. Link `IOSAppsAnalytics` Swift package into the `AstronovaApp` target.
2. Add a property on `StoreKitManager`:
   ```swift
   private let subscriptionEmitter = SubscriptionEventEmitter.wired(
       tierResolver: { ShopCatalog.tier(for: $0) },
       store: UserDefaultsPhaseStore(prefix: "astronova.subscription.phase.")
   )
   ```
3. In `listenForTransactions()`, after `try checkVerified`, call
   `subscriptionEmitter.handle(transaction: .init(transaction: transaction))`.
4. In `checkCurrentEntitlements()`, pass `isInitial: true` so launch replay
   doesn't refire `subscription_started`.
5. Add a `Task` that loops `Product.SubscriptionInfo.status` for the Pro
   products and forwards each change to
   `subscriptionEmitter.handle(status: .init(sku:, status:))`.

## Remaining risky states

- `subscription_renewed`: not emitted yet. `Transaction.updates` can include
  renewals, ask-to-buy approvals, and other out-of-band changes; without a
  phase store and a dedicated `subscription_renewed` schema entry, treating
  those as `subscription_started` would overcount.
- `subscription_cancelled`, `subscription_paused`, grace period, billing retry,
  lapsed, and refunded states are not emitted yet. They require observing
  `Product.SubscriptionInfo.Status` / renewal state, not just successful
  purchase transactions.
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
