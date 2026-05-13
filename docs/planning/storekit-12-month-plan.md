# Astronova StoreKit 12-Month Plan

Astronova Pro now has two local catalog products:

- `astronova_pro_12_month_commitment` - default first-paywall plan; intended for a 12-month commitment billed monthly.
- `astronova_pro_monthly` - existing month-to-month fallback plan.

The client uses `Product.SubscriptionInfo.pricingTerms` on iOS 26.4+ to prefer StoreKit's monthly billing term display for the 12-month plan. When those terms are absent, the UI falls back to the stable local catalog copy: `$9.99 per month for 12 months`, `$119.88 first-year commitment`.

Purchase behavior:

- iOS 26.4+: `astronova_pro_12_month_commitment` purchases with `Product.PurchaseOption.billingPlanType(.monthly)`.
- Older OS versions: the same product falls back to normal `product.purchase()`.
- `astronova_pro_monthly` always uses normal `product.purchase()`.

Local StoreKit limitation: `AstronovaProducts.storekit` can carry the 12-month product ID and annual recurring placeholder, but the monthly billing-plan terms must be configured in App Store Connect before `pricingTerms` returns the real monthly plan and commitment display.
