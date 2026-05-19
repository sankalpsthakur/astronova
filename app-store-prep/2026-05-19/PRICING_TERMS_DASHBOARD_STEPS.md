# Astronova PricingTerms Dashboard Steps

Date: 2026-05-19

## Goal

Configure the Astronova annual subscription as a 12-month commitment product if
Apple exposes PricingTerms for this developer account.

The App Store Connect REST API does not currently expose the PricingTerms
configuration for monthly-billed annual commitments. The subscription metadata
can be created and localized by API, but the commitment billing plan must be
checked in the App Store Connect dashboard.

## Target Subscription

- App: Astronova
- Bundle ID: `com.astronova.app`
- Product ID: `astronova_pro_12_month_commitment`
- Current fallback: standard annual auto-renewable subscription
- Intended premium shape: monthly payment cadence with 12-month commitment

## Dashboard Path

1. Open App Store Connect.
2. Go to Apps -> Astronova -> Monetization -> Subscriptions.
3. Open the Astronova Pro subscription group.
4. Open product `astronova_pro_12_month_commitment`.
5. Check whether Apple shows a pricing or offer control for commitment terms,
   monthly billing plan, or `PricingTerms`.
6. If available, configure:
   - Commitment duration: 12 months
   - Billing cadence: monthly
   - Display framing: 12-month commitment, billed monthly
7. Save, then wait for App Store Connect to reprocess the subscription state.

## Verification

After the dashboard save:

1. In sandbox/TestFlight, open Astronova paywall.
2. Confirm StoreKit returns the annual commitment product.
3. Confirm the paywall copy matches Apple's checkout sheet.
4. Confirm StoreKit transaction succeeds and restores.

## Fallback If The Control Is Not Available

Ship the same product ID as a standard annual auto-renewable subscription and
keep the client feature flag disabled for `STOREKIT_PRICING_TERMS_AVAILABLE`.
This preserves product continuity without claiming a billing model Apple has
not enabled for the account.

## Code References

- `client/AstronovaApp/StoreKitManager.swift`
- `client/astronova.xcodeproj/project.pbxproj`
- Build flag: `STOREKIT_PRICING_TERMS_AVAILABLE`

