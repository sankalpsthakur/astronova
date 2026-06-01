# Astronova - App Store Submission Materials

**Version:** 1.0
**Date:** May 27, 2026
**Bundle ID:** com.astronova.app

**Release status:** Draft materials only. No TestFlight upload, App Store build
selection, or public App Store listing is confirmed in this document.

**External gates:** App Store Connect access, API key secrets, signing assets,
bundle ID/App ID ownership, sandbox IAP records, reviewer/test account creation,
and public URL verification must be completed outside this docs-only pass.

---

## 📱 Screenshots Required

**iPhone 6.5" Display** (1242 × 2688px or 1284 × 2778px)
**Required:** 3 screenshots (you can add up to 10)

### Recommended Screenshots (in order):

1. **Screenshot 1: Today Dashboard** (Hero Shot)
   - Shows the Today tab with daily terrain, timing, and practical guidance
   - Demonstrates the core value proposition

2. **Screenshot 2: Map**
   - Shows the personal map / astrocartography-inspired view
   - Demonstrates spatial chart exploration

3. **Screenshot 3: Timeline**
   - Shows timing windows and prediction states
   - Demonstrates long-range timing and dasha context

**Note:** Screenshot files are present under `app-store-assets/screenshots/`.
Upload status must be verified in App Store Connect; this document does not
claim screenshots are already uploaded.

---

## 📝 App Store Text Content

### Promotional Text (170 characters max)
**Current:** 120 characters

```
Personalized Vedic astrology, timing maps, numerology patterns, journaling, and AI guidance in one calm cosmic companion.
```

**Alternative (161 characters):**
```
Explore your birth chart with daily timing, astro maps, numerology, journaling, and optional Oracle guidance grounded in Vedic astrology.
```

---

### Description (4000 characters max)
**Current:** under 4,000 characters

```
DISCOVER YOUR COSMIC TIMING COMPANION

Astronova brings Vedic astrology, numerology, personal timing, and reflective journaling into one focused iPhone experience. Start with a guest preview, create a birth profile, then explore the patterns shaping your day, direction, and decisions.

TODAY

See your daily terrain, current dasha context, signal strength, and practical actions built around your birth details.

MAP

Explore a personal astrocartography-inspired map and life-domain surfaces for a visual way to understand your chart.

TIMELINE

Review timing windows, prediction states, and longer-range shifts so you can see how different periods unfold.

MATRIX

Study numerology, Loshu patterns, archetype signals, and deeper pattern analysis in a dedicated matrix view.

JOURNAL

Capture reflections, inspect your daily signal, and keep a free-will log alongside the app's guidance.

REPORTS AND ORACLE

Ask the Oracle for AI-assisted astrological guidance and unlock detailed one-time reports. Sign in with Apple is required for Oracle chat, report purchases, and chat credit packs so entitlements can be saved to your account.

PRIVACY AND CONTROL

• Birth data is used to personalize your experience
• Sign in with Apple keeps account access simple
• Purchases are handled through Apple In-App Purchase
• You can preview core surfaces before signing in

ROOTED IN ASTROLOGICAL SYSTEMS

Astronova uses authentic Vedic astrology calculations:

• Swiss Ephemeris for planetary positions
• Lahiri ayanamsha for sidereal zodiac
• Traditional Vimshottari dasha system
• Classical chart, dasha, and numerology-inspired interpretation layers

Whether you are new to astrology or already follow your chart closely, Astronova gives you a calmer way to inspect timing, patterns, and personal decisions.

Download now and begin your cosmic journey.

---

SUBSCRIPTION INFORMATION

Astronova Pro unlocks:
• Unlimited Ask/Oracle guidance
• Complete journey paths and deeper pattern views
• Premium report and insight access
• Priority cosmic guidance

Subscriptions auto-renew unless cancelled 24 hours before the period ends. Manage subscriptions in your App Store account settings.

Terms: https://astronova-ghcr.onrender.com/terms
Privacy: https://astronova-ghcr.onrender.com/privacy
```

---

### Keywords (100 characters max)
**Current:** 89 characters

```
astrology,vedic,horoscope,birth chart,dasha,kundli,jyotish,transit,numerology,oracle

```

**Alternative Focus (Journaling):**
```
astrology,vedic,horoscope,birth chart,dasha,kundli,jyotish,journal,timing,map,oracle
```

---

## 🔗 URLs

### Support URL (Required)
```
https://astronova-ghcr.onrender.com/support
```
*Note: Create this endpoint or use existing help/contact page*
*Gate: verify this URL live before pasting into App Store Connect.*

### Marketing URL (Optional)
```
https://astronova-ghcr.onrender.com
```

---

## 📋 App Review Information

### Sign-In Information
**Sign-in required:** Yes (optional - users can skip)

**Test Account (if needed):**
- Username: `appstore-reviewer@astronova.app`
- Password: `ReviewAstro2026!`

*Note: Create this test account with complete birth data filled in so reviewers can test all features.*
*Gate: this account must be created and verified before submission; do not mark
review credentials complete from this document alone.*

### Contact Information
- **First Name:** Sankalp
- **Last Name:** Thakur
- **Phone:** +91 91110 35899
- **Email:** shaurya@climitra.com

### Notes for Reviewer

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
- Analytics: portfolio/local analytics. Smartlook package reference exists, but
  `SmartlookAnalytics` is not linked in the current Xcode project unless a
  source worker changes and verifies it before upload.

PERMISSIONS:
- No location access required (birth location stored manually)
- No camera or microphone access required
- Notifications for daily insights (optional, user consent)

Please contact us if you have any questions during review.
```

---

## 🎯 App Category

**Primary Category:** Lifestyle
**Secondary Category:** Health & Fitness (optional)

**Age Rating:** 4+ (No objectionable content)

---

## 📅 Release Schedule

**Release Option:** Manually release this version

*Recommended: Choose manual release so you can coordinate marketing announcements with the actual launch.*

---

## ✅ Pre-Submission Checklist

Before submitting, ensure:

- [ ] All 3 screenshots uploaded (6.5" display size)
- [ ] App icon included in bundle (1024×1024px)
- [ ] Description and promotional text finalized
- [ ] Keywords optimized (100 char limit)
- [ ] Support URL is live and functional
- [ ] Test account created with valid credentials
- [ ] Backend API (https://astronova-ghcr.onrender.com) is running
- [ ] Privacy Policy URL is live
- [ ] Terms of Service URL is live
- [ ] 12 App Store products configured: `astronova_pro_12_month_commitment`, `astronova_pro_monthly`, 7 report products, and 3 chat-credit products
- [ ] Build archived and uploaded via Xcode Cloud or Transporter
- [ ] Uploaded build selected in App Store Connect
- [ ] App Review Information filled out completely
- [ ] Contact information is current
- [ ] Age rating set to 4+
- [ ] Pricing and availability configured
- [ ] Subscription products created and sandbox tested

---

## 🚀 Submission Tips

1. **Screenshots Matter:** Your first screenshot is the most important-it appears in search results. Use the Today dashboard hero shot.

2. **Keywords Strategy:** Focus on core terms: "astrology", "vedic", "horoscope", "birth chart", and "dasha".

3. **Description First 170 Characters:** This appears in search results without "more" click. Front-load your value proposition.

4. **Review Notes:** Be thorough. Help reviewers understand the app quickly to avoid rejections.

5. **Test Account:** Ensure it works! Reviewers will reject if they can't sign in.

6. **Response Time:** Be ready to respond to reviewer questions within 24 hours to avoid delays.

---

## 📊 Post-Launch Recommendations

After approval:

1. **Monitor Reviews:** Respond to user feedback within 48 hours
2. **Track Analytics:** Watch user engagement in App Store Connect
3. **A/B Test Screenshots:** Try different screenshot orders after 2 weeks
4. **Update Keywords:** Refine based on search performance data
5. **Localization:** Consider Hindi, Tamil, Telugu for Indian market
6. **Marketing:** Prepare social media posts, blog content, press release

---

**Good luck with your submission! 🌟**

*For questions or support during the review process, contact: [your-email]*
