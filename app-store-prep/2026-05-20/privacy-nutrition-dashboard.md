# Astronova Privacy Nutrition — ASC Dashboard Entry

App: Astronova - Vedic Astrology (ASC ID 6746982743, bundle TBD)
Source of truth: `client/AstronovaApp/PrivacyInfo.xcprivacy`
Date: 2026-05-20

## API status

Apple does NOT expose App Privacy Details (nutrition labels) in the public
App Store Connect API. The official OpenAPI spec (923 paths, ASC sample
download 2026-05-20) contains zero `privacy*`, `dataUsage*`, `nutrition*`,
`idfa*`, or `tracking*` paths. `usesIdfa` is not a writable field on the
`apps` resource. The probed candidates all 404:

- `/v1/apps/{id}/appPrivacyDetails`
- `/v1/appDataUsages?filter[app]=...`
- `/v1/appPrivacyDetail`, `/v1/privacyDeclarations`, `/v1/privacyDetails`
- `/v1/dataUsageDataProtections`, `/v1/privacyDataUsages`
- `/v1/appPrivacyManifests`, `/v1/privacyManifests`, `/v1/privacyAnswers`

Conclusion: Privacy Nutrition Labels must be entered via the
**ASC Dashboard -> App Information -> App Privacy** UI. The table below
is paste-ready.

## Tracking gate

- "Do you or your third-party partners use data from this app to track
  users?" -> **NO**
- This matches `NSPrivacyTracking=false` and an empty
  `NSPrivacyTrackingDomains` in `PrivacyInfo.xcprivacy`.

## Data Types Collected (9 categories)

For every row: Linked to user = Yes unless noted; Used for tracking = No
(all rows); Purpose = App Functionality unless noted.

| # | ASC category       | ASC data type           | Linked | Tracking | Purposes           | Source / notes                          |
|---|--------------------|-------------------------|--------|----------|--------------------|-----------------------------------------|
| 1 | Contact Info       | Name                    | Yes    | No       | App Functionality  | Profile + chart owner display           |
| 2 | Contact Info       | Email Address           | Yes    | No       | App Functionality  | Sign in with Apple identity             |
| 3 | Location           | Precise Location        | Yes    | No       | App Functionality  | Birth coords + timezone for chart calc  |
| 4 | Contacts           | Contacts                | **No** | No       | App Functionality  | Compatibility lookup; not linked        |
| 5 | Identifiers        | User ID                 | Yes    | No       | App Functionality  | Anonymous device-scoped user id         |
| 6 | Purchases          | Purchase History        | Yes    | No       | App Functionality  | StoreKit receipts / subscription state  |
| 7 | Usage Data         | Product Interaction     | Yes    | No       | **Analytics**      | Feature usage events                    |
| 8 | Diagnostics        | Other Diagnostic Data   | Yes    | No       | **Analytics**      | Session diagnostics for stability       |
| 9 | Other Data         | Other Data Types        | Yes    | No       | App Functionality  | Birth date/time for astrology calc      |

## Entry procedure (operator)

1. ASC -> My Apps -> Astronova -> App Privacy -> "Edit" on Data Types.
2. Answer Tracking gate: **No**.
3. For each row above:
   a. Click "+" -> select category -> tick data type.
   b. Linked to user: row 4 = No, all others = Yes.
   c. Used for tracking: No for all.
   d. Purposes: pick "App Functionality" for rows 1-6, 9; pick
      "Analytics" for rows 7-8.
   e. Save.
4. After all 9 rows in, click "Publish".

## Cross-check with manifest

After publishing, diff the ASC summary against
`client/AstronovaApp/PrivacyInfo.xcprivacy`. The 9 `NSPrivacyCollectedDataType`
entries (Name, EmailAddress, PreciseLocation, Contacts, UserID,
PurchaseHistory, ProductInteraction, OtherDiagnosticData,
OtherDataTypes) must map 1:1 to the ASC dashboard rows above.
