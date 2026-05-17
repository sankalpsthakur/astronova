# Astronova StoreKit Local Testing

Local StoreKit config:

`client/StoreKit/AstronovaProducts.storekit`

Use this file only for local simulator/device testing through Xcode's StoreKit test environment. The products still need matching App Store Connect records before TestFlight or App Review.

Expected product IDs:

- `astronova_pro_12_month_commitment`
- `astronova_pro_monthly`
- `report_general`
- `report_love`
- `report_career`
- `report_money`
- `report_health`
- `report_family`
- `report_spiritual`
- `chat_credits_5`
- `chat_credits_15`
- `chat_credits_50`

Current product count: 12 total SKUs (2 Pro subscriptions, 7 report non-consumables, 3 chat-credit consumables). The 12-month Pro product is the current default Pro plan in `ShopCatalog`.

Before App Store submission, verify that the Xcode run scheme has this StoreKit configuration selected for local testing, then remove reliance on local config and verify sandbox products from App Store Connect.
