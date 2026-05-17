# App Store Submission Checklist

## Screenshots - Prepared, Upload Pending

All screenshots captured and resized to **1284 × 2778px** (iPhone 6.7" display requirement):

- ✅ Screenshot 1: Discover tab (Daily insights) - 1.5MB
- ✅ Screenshot 2: Temple Muhurat timings - 893KB
- ✅ Screenshot 3: Temple Expert Astrologers - 895KB
- ✅ Screenshot 4: Time Travel dasha wheel - 1.8MB
- ✅ Screenshot 5: Oracle AI chat interface - 238KB
- ✅ Screenshot 6: Self tab cosmic pulse - 2.3MB

**Total:** 6 screenshot files prepared for upload. App Store Connect upload
status must be verified separately.

## Text Content - Drafted, Public URL Verification Pending

All text content prepared in `COPY_PASTE_READY.txt`:

- ✅ Promotional Text: 143 characters (limit: 170)
- ✅ Description: 2,847 characters (limit: 4,000)
- ✅ Keywords: 99 characters (limit: 100)
- [ ] Support URL: https://astronova.onrender.com/support (verify live before submission)
- ✅ Marketing URL: https://astronova.onrender.com
- [ ] Privacy Policy URL: https://astronova.onrender.com/privacy (verify live before submission)
- [ ] Terms of Service URL: https://astronova.onrender.com/terms (verify live before submission)

## Test Account - External Gate

Planned reviewer account:
- [ ] User ID: `appstore-test-user-2026`
- [ ] Email: `appstore-test@astronova.app`
- [ ] Complete birth data: Jan 15, 1990, 2:30 PM, New York, NY
- [ ] Pro entitlement or sandbox subscription verified for premium testing
- [ ] Skip-sign-in path verified in the uploaded build

## Backend Infrastructure - Verify Before Submission

- [ ] Support URL endpoint deployed: `/support`
- [ ] Terms endpoint deployed: `/terms`
- [ ] Privacy endpoint deployed: `/privacy`
- [ ] All endpoints use correct email: admin@100xai.engineering
- [ ] Test user seeded in database, if reviewer credentials are used
- [ ] Backend API live at: https://astronova.onrender.com

## App Review Information - Drafted

**Notes for Reviewer** (from `COPY_PASTE_READY.txt`):

```
Thank you for reviewing Astronova!

TESTING INSTRUCTIONS:

1. You can skip Apple Sign-In by tapping "Continue without signing in"
2. Complete the onboarding flow to create a sample birth profile
3. Explore the 5 main tabs:
   - Discover: Daily cosmic insights and domain cards
   - Time Travel: Dasha timeline visualization
   - Temple: Astrologer listings and Pooja bookings
   - Connect: Relationship compatibility (requires auth)
   - Self: Profile and settings

FEATURES TO TEST:

✓ Daily Insights: See personalized planetary influences
✓ Domain Cards: Tap any domain to see detailed explanations
✓ Time Travel: Navigate through months/years on the Dasha wheel
✓ Temple: Browse astrologers and pooja offerings
✓ Muhurat Timings: View auspicious times for the day
✓ Oracle Chat: Ask questions about life, career, relationships

SUBSCRIPTIONS:
- Free tier includes basic daily insights and limited features
- Pro subscription unlocks full timeline, reports, and unlimited chat
- Subscription testing works with sandbox accounts

THIRD-PARTY SERVICES:
- Backend API: Hosted on Render (https://astronova.onrender.com)
- Video consultations: WebRTC video service (for pandit consultations)
- Ephemeris calculations: Swiss Ephemeris library
- AI guidance: OpenAI API (optional, degrades gracefully)
- Analytics: portfolio/local analytics. Smartlook package reference exists, but SmartlookAnalytics is not linked in the current Xcode project unless a source worker changes and verifies it before upload.

PERMISSIONS:
- No location access required (birth location stored manually)
- No camera/microphone access unless booking video consultation
- Notifications for daily insights (optional, user consent)

Please contact us if you have any questions during review.
```

## 🎯 App Store Connect Settings

### App Information
- ✅ Category: Lifestyle (primary)
- ✅ Age Rating: 4+
- ✅ Release: Manual release (recommended)

### Version Information
- ✅ Version: 1.0
- [ ] Build uploaded and selected in App Store Connect
- ✅ Copyright: 2026 Astronova

### IAP Products
- [ ] Configure 12 products in App Store Connect.
- [ ] Include `astronova_pro_12_month_commitment` and `astronova_pro_monthly`.
- [ ] Include 7 report non-consumables and 3 chat-credit consumables.
- [ ] Sandbox-test products before review.

## 🚀 Next Steps

1. **Build & Archive in Xcode:**
   ```bash
   open client/astronova.xcodeproj
   # Product → Archive
   # Upload to App Store Connect
   ```

2. **Upload Screenshots to App Store Connect:**
   - Navigate to app version → iPhone 6.7" Display
   - Upload all 6 screenshots in order
   - Add optional captions (see SCREENSHOTS_SUMMARY.md)

3. **Fill in App Store Connect Form:**
   - Copy-paste text from `COPY_PASTE_READY.txt`
   - Paste reviewer notes
   - Verify all URLs work

4. **Submit for Review only after external gates are green:**
   - Select manual release
   - Confirm an uploaded build is selected
   - Confirm IAP products and reviewer access work
   - Submit for review
   - Monitor status in App Store Connect

## 📊 Estimated Review Time

- Initial review: 24-48 hours (typically)
- If requested changes: 1-2 days per iteration
- Total: ~3-7 days for approval

## 📞 Contact During Review

- Email: admin@100xai.engineering
- Response time: Within 24 hours

---

**Status:** Draft materials prepared; App Store Connect upload, live URL checks,
IAP records, and reviewer account gates remain pending.
**Date Prepared:** January 9, 2026
