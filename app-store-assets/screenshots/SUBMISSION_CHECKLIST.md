# App Store Submission Checklist

## Screenshots - Local Assets Ready for App Store Connect Verification

All canonical screenshots were recaptured on 2026-05-23 from the current
Astronova iPhone 16 Pro Max simulator and verified at **1320 x 2868px** for the
iPhone 6.9-inch App Store screenshot slot. Treat the App Store Connect upload
state as a live gate until it is rechecked in App Store Connect:

- [x] Screenshot 1: Today dashboard - `01_hero.png`
- [x] Screenshot 2: Map Apple Maps globe - `02_valueprop.png`
- [x] Screenshot 3: Timeline live server overview - `03_painpoint.png`
- [x] Screenshot 4: Matrix Loshu/eigenvalues - `04_benefit.png`
- [x] Screenshot 5: Journal Free Will + decisions - `05_trust.png`
- [x] Screenshot 6: Pro paywall - `06_cta.png`

**Local total:** 6 canonical screenshots ready for `APP_IPHONE_67`, plus the
`iphone65-current/` derivatives for `APP_IPHONE_65`. Historical ASC evidence
exists at `qa-results/20260523-launch/asc-screenshot-sets-after.json`, but it
must be rechecked live before claiming current App Store Connect upload status.

## Text Content - Drafted

All text content prepared in `COPY_PASTE_READY.txt`:

- [x] Promotional Text: 120 characters (limit: 170)
- [x] Description: under 4,000 characters
- [x] Keywords: 89 characters (limit: 100)
- [ ] Support URL verified live and submitted in App Store Connect
- [ ] Marketing URL verified live: https://astronova-ghcr.onrender.com
- [ ] Privacy Policy URL verified live and submitted in App Store Connect
- [ ] Terms of Service URL verified live and submitted in App Store Connect

## Test Account / Reviewer Access

Planned reviewer account:
- [ ] User ID: `appstore-test-user-2026`
- [ ] Email: `appstore-test@astronova.app`
- [ ] Complete birth data: Jan 15, 1990, 2:30 PM, New York, NY
- [ ] Pro entitlement or sandbox subscription verified for premium testing
- [x] Guest preview path documented in App Review notes

## Backend Infrastructure

- [x] Local source defines Support URL endpoint: `/support`
- [x] Local source defines Terms endpoint: `/terms`
- [x] Local source defines Privacy endpoint: `/privacy`
- [x] Local compliance pages use support email: admin@100xai.engineering
- [ ] Deployed support URL verified live: `/support`
- [ ] Deployed terms URL verified live: `/terms`
- [ ] Deployed privacy URL verified live: `/privacy`
- [ ] Test user seeded in database, if reviewer credentials are used
- [ ] Backend API verified live at: https://astronova-ghcr.onrender.com

## App Review Information - Drafted

**Notes for Reviewer** (from `COPY_PASTE_READY.txt`):

```
Thank you for reviewing Astronova!

TESTING INSTRUCTIONS:

1. You can preview without Apple Sign-In by tapping "Preview calibration without signing in".
2. Complete calibration with sample data such as name "App Reviewer" and birth place "Delhi, India". You may leave the default date/time for review.
3. After "Profile Created", tap "Start Your Journey", skip the optional Identity Quiz if desired, and close the optional paywall using the Close button.
4. Explore the 5 main tabs:
   - Today: daily terrain, current dasha, actions, and horoscope reading
   - Map: personal astrocartography and life-domain map
   - Timeline: timing windows and prediction timeline
   - Matrix: numerology/Loshu and pattern deep dives
   - Journal: daily signal, reflections, and free-will log

FEATURES TO TEST:

✓ Today: See personalized timing and daily guidance
✓ Map: Explore the personal map and life-domain surfaces
✓ Timeline: Review timing windows and prediction states
✓ Matrix: Review numerology/Loshu pattern analysis
✓ Journal: Log or inspect daily signal/reflection states
✓ Settings: Open My Reports, Buy Reports, Ask the Oracle, Privacy, and Restore Purchases

SUBSCRIPTIONS:
- Free/guest preview includes the core app surfaces above on this device
- Sign in with Apple is required for Oracle chat, report purchases, and chat credit packs so entitlements attach to an account
- Pro subscription unlocks unlimited Ask/Oracle and complete journey paths
- One-time reports use these products: report_general, report_love, report_career, report_money, report_health, report_family, report_spiritual
- Chat credit packs use these products: chat_credits_5, chat_credits_15, chat_credits_50
- Pro subscriptions use these products: astronova_pro_monthly, astronova_pro_12_month_commitment
- Subscription testing works with sandbox accounts

THIRD-PARTY SERVICES:
- Backend API: Hosted on Render (https://astronova-ghcr.onrender.com)
- Ephemeris calculations: Swiss Ephemeris library
- AI guidance: OpenAI API (optional, degrades gracefully)
- Analytics: portfolio/local analytics. Smartlook package reference exists, but SmartlookAnalytics is not linked in the current Xcode project unless a source worker changes and verifies it before upload.

PERMISSIONS:
- No location access required (birth location stored manually)
- No camera or microphone access required
- Notifications for daily insights (optional, user consent)

Please contact us if you have any questions during review.
```

## 🎯 App Store Connect Settings

### App Information
- [ ] Category: Lifestyle (primary) verified in App Store Connect
- [ ] Age Rating: 4+ verified in App Store Connect
- [ ] Release: Manual release verified in App Store Connect

### Version Information
- [x] Local version copy: 1.0
- [ ] Uploaded build selected in App Store Connect
- [x] Local copyright copy: 2026 Astronova

### IAP Products
- [ ] Configure 12 products in App Store Connect.
- [ ] Include `astronova_pro_12_month_commitment` and `astronova_pro_monthly`.
- [ ] Include 7 report non-consumables and 3 chat-credit consumables.
- [ ] Sandbox-test products before review.

## Historical ASC Submission Evidence

The following local artifacts record an App Store Connect submission event from
2026-05-23. They are historical evidence only; recheck App Store Connect before
claiming the current Apple review state:

- App Privacy answers artifact: `qa-results/20260523-launch/asc-app-privacy-publish.json`
- App Review submission artifact: `qa-results/20260523-launch/asc-review-submit-latest.json`
- Historical ASC read-back artifact: version `1.0` and submission `821c7af6-6834-4242-a0e1-1f685b89c4b9`
- Historical submitted date: `2026-05-23T18:07:16.38Z`

Next live task is to verify App Store Connect/email for the current Apple review
state and any reviewer questions.

## 📊 Estimated Review Time

- Initial review: 24-48 hours (typically)
- If requested changes: 1-2 days per iteration
- Total: ~3-7 days for approval

## 📞 Contact During Review

- Email: admin@100xai.engineering
- Response time: Within 24 hours

---

**Status:** Local submission packet with historical ASC evidence; current Apple
review state is not verified in this document.
**Date Prepared:** May 23, 2026
