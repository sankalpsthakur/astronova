# Astronova — Privacy Audit (Wave 13)

**Date:** 2026-05-14
**Auditor:** Claude (Opus 4.7)
**Manifest under audit:** `client/AstronovaApp/PrivacyInfo.xcprivacy`
**Status:** PASS (with one cleanup recommendation — see §3)

---

## 1. What we say (PrivacyInfo.xcprivacy declarations)

### `NSPrivacyTracking`
- `false` — app does not track across apps/websites.

### `NSPrivacyTrackingDomains`
- Empty.

### `NSPrivacyAccessedAPITypes`
| Category | Reason | Note |
|---|---|---|
| UserDefaults | CA92.1 | Access info from same app |
| FileTimestamp | C617.1 | Access file timestamps inside app container |

### `NSPrivacyCollectedDataTypes`
| Data Type | Linked | Tracking | Purpose |
|---|---|---|---|
| Name | yes | no | App Functionality |
| Email Address | yes | no | App Functionality |
| Precise Location | yes | no | App Functionality |
| Contacts | no | no | App Functionality |
| User ID | yes | no | App Functionality |
| Purchase History | yes | no | App Functionality |
| Product Interaction | no | no | Analytics |
| Other Diagnostic Data | no | no | Analytics |
| Other Data Types (birth date/time) | yes | no | App Functionality |

---

## 2. What we do (actual behavior in code)

### Identity / Contact
- **Sign in with Apple** — `AuthenticationServices` in `RootView.swift`, `AuthState.swift`. Captures `name` + `email` (linked, App Functionality). ✅ matches manifest.
- **Email-based account fallback** — `AuthService` and `NetworkClient` send email to backend. ✅ matches.
- **Anonymous UUID** for analytics — generated locally via `IDStore` in shared `IOSAppsAnalytics` package; persisted in UserDefaults. ✅ matches User ID declaration.

### Location & Astrology Data
- **Birth location / coords** — collected via onboarding (`UserProfile.swift`, `APIModels.swift`, `APIServices.swift`); used for chart calculation; persisted server-side. ✅ matches Precise Location + Other Data Types.
- **Contacts** — `ContactPickerView.swift`, `Services/ContactsService.swift`. Used for compatibility analysis. ✅ matches Contacts declaration (Not Linked).

### Purchases
- **StoreKit** — `StoreKitManager.swift`. Receipts + transaction IDs flow to backend for entitlement checks. ✅ matches Purchase History.

### Analytics
- **Smartlook SDK** (`SmartlookAnalytics`) — referenced in `Analytics/AnalyticsService.swift` behind `#if canImport`. Session recording with PII masking. Emits Product Interaction + Other Diagnostic Data. ✅ matches manifest.
- **IOSAppsAnalytics** is wired (per Wave 12 plan) — no `track()` call sites found yet in client/ source (Wave 12 task pending). Manifest declarations remain valid since Smartlook is the active path.

### Required-reason APIs
- **UserDefaults** — 20 call sites across `NetworkClient`, `APIServices`, `UserProfile`, `RootView`, etc. ✅ CA92.1 declared.
- **FileTimestamp** — no direct call sites found in `client/AstronovaApp`. Declaration is conservative (URLCache + URLSession touch file attributes internally). ⚠ See §3.

---

## 3. Mismatches (RED = blocker, YELLOW = cleanup)

| # | Severity | Finding | Action |
|---|---|---|---|
| 1 | 🟡 YELLOW | `NSPrivacyAccessedAPICategoryFileTimestamp` declared but no direct app source calls `attributesOfItem` / `creationDate` / `modificationDate`. Apple's required-reason rule covers indirect SDK use, so this is **safe to keep**; documented here for transparency. | None required. Keep declaration — URLCache + NSData(contentsOf:) family touch timestamps; declaration is the safe posture. |

**No RED issues. Astronova is App Store privacy-clean.**

---

## 4. App Store Connect — nutrition label entries

Configure these in App Store Connect → App Privacy:

### Data Used to Track You
- **None.**

### Data Linked to User
- **Contact Info** → Name, Email Address — purpose: App Functionality.
- **Location** → Precise Location — purpose: App Functionality. *(Optional — origins of birth chart; treat as user-provided, not GPS-sampled.)*
- **Identifiers** → User ID — purpose: App Functionality.
- **Purchases** → Purchase History — purpose: App Functionality.
- **Other Data** → Other Data Types (birth date/time) — purpose: App Functionality.

### Data Not Linked to User
- **Contacts** → Contacts — purpose: App Functionality.
- **Usage Data** → Product Interaction — purpose: Analytics.
- **Diagnostics** → Other Diagnostic Data — purpose: Analytics.

### Privacy Practices
- Data collection: **Yes**.
- Tracks across apps: **No**.
- Privacy policy URL: `https://iosapps.io/astronova/privacy`.

---

## 5. User-facing privacy policy URL (per D3 umbrella)

**URL:** `https://iosapps.io/astronova/privacy` (D3 — single umbrella domain with per-app subpath).

The privacy policy at that URL must state:

1. **Identity & Contact** — Sign in with Apple captures name + email; users may sign in privately to suppress real email.
2. **Location** — Birth location is **user-provided** text/coordinate input, not sampled GPS. Used only for astrological chart calculation.
3. **Contacts** — Read only with explicit user consent at the point of compatibility selection; not transmitted in bulk; only selected entries leave the device.
4. **Purchases** — Standard Apple StoreKit receipt verification; no card data ever reaches our servers.
5. **Analytics** — Anonymous UUID-based product interaction telemetry; Smartlook session replays with PII masking enabled. Users can opt out from Settings.
6. **No tracking** — We do not share data with advertisers, brokers, or third parties for cross-app tracking.
7. **Data deletion** — `mailto:privacy@iosapps.io` or in-app "Delete Account" path; honors all data within 30 days.
8. **Contact** — `privacy@iosapps.io`.
9. **Children** — Not directed to children under 13; users self-attest birth date during onboarding.
10. **Jurisdiction & rights** — GDPR / CCPA access + delete rights honored.
