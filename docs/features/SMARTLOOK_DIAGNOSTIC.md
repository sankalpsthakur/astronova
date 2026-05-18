# Smartlook Integration Diagnostic Report

## Current Status

**Docs-pass result:** Smartlook has a Swift package reference, but the
`SmartlookAnalytics` SDK product is not linked to the `AstronovaApp` target in
the current repo state.

**Impact:** Unless another source worker links the SDK, `#if
canImport(SmartlookAnalytics)` evaluates to `false`, Smartlook never
initializes, and Smartlook events/recordings should be treated as inactive.

**Required source change:** Link `SmartlookAnalytics` into the app target in
Xcode or `project.pbxproj`, then rebuild and verify. This docs-only pass did
not make that source change.

## What's Present

1. **Package reference**
   - Package: `https://github.com/smartlook/analytics-swift-package`
   - Version: 2.2.15
   - Location: `Package.resolved`

2. **API Key Configuration**
   - Project Key: `3ea51a8cc18ecd6b6b43eec84450f694a65569ed`
   - Location: `AstronovaApp/AstronovaAppApp.swift:43`

3. **Initialization Code**
   ```swift
   Smartlook.instance.preferences.projectKey = "3ea51a8cc18ecd6b6b43eec84450f694a65569ed"
   Smartlook.instance.start()
   ```
   - Runs on app launch (line 22-26 in `AstronovaAppApp.swift`)
   - Skipped in UI test mode to avoid polluting recordings

4. **Analytics Service**
   - Location: `AstronovaApp/Analytics/AnalyticsService.swift`
   - Tracks 21 different events
   - Properly wrapped in `#if canImport(SmartlookAnalytics)`

## ⚠️ Confirmed Issue

### CONFIRMED: Package Not Linked to Target
**Diagnosis**: The Smartlook package reference exists, but `SmartlookAnalytics`
is not linked to the AstronovaApp target.
- Package reference: `Package.resolved` contains `analytics-swift-package@2.2.15`
- Not linked: zero references to `SmartlookAnalytics` in `project.pbxproj`
- Result unless source changes: `#if canImport(SmartlookAnalytics)` evaluates to
  `false`, so the SDK never initializes

**Fix Required (source/Xcode change)**:
1. Open `astronova.xcodeproj` in Xcode
2. Select **AstronovaApp** target
3. Go to **General** → **Frameworks, Libraries, and Embedded Content**
4. Check if **SmartlookAnalytics** is listed
5. If not:
   - Go to **Build Phases** → **Link Binary With Libraries**
   - Click **+**
   - Add **SmartlookAnalytics** from Swift Package Products

### Issue 2: Debug vs Release Configuration
**Behavior after the SDK is linked**:
- In DEBUG mode with UI tests: Smartlook is **disabled**
- In DEBUG mode without UI tests: Smartlook is **enabled**
- In RELEASE mode: Smartlook is always **enabled**

**To test**:
```bash
# Check if you're running in Debug mode
# If so, Smartlook might be disabled if TestEnvironment.isUITest is true
```

### Issue 3: Conditional Compilation
The code uses:
```swift
#if canImport(SmartlookAnalytics)
```

This may be returning `false` if the package isn't properly linked.

## 🔍 Verification Steps

### Step 1: Check Package Linking
```bash
cd /Users/sankalp/Projects/iosapps/astronova/client
xcodebuild -project astronova.xcodeproj -target AstronovaApp -showBuildSettings | grep PACKAGE
```

### Step 2: Build and Check for Smartlook
1. Build the app in Xcode
2. Check build logs for:
   - "Smartlook Session recording started" (should appear in Console)
   - Any import errors related to SmartlookAnalytics

### Step 3: Test Analytics Events
Run the app and check if events are being logged:
- Look for `[ANALYTICS]` logs in Xcode console
- These logs appear even if Smartlook isn't working
- If you see these logs, the events are being tracked locally

### Step 4: Check Smartlook Dashboard
1. Go to https://app.smartlook.com/
2. Sign in to your project: `3ea51a8cc18ecd6b6b43eec84450f694a65569ed`
3. Check:
   - **Recordings** → Should show recent sessions
   - **Events** → Should show tracked events
   - **Filters** → Make sure no filters are hiding your data

## 🛠️ REQUIRED FIX (Step-by-Step)

### Fix 1: Link SmartlookAnalytics to Target (CONFIRMED REQUIRED)

**Current Status**: Package reference exists, but SDK product is not linked
(verified via `project.pbxproj` analysis)

**Steps to Fix in Xcode**:

**Option A: Link Existing Package (Faster)**
1. Open `astronova.xcodeproj` in Xcode
2. Click on project in Project Navigator (top-left)
3. Select **AstronovaApp** target (not the project)
4. Go to **General** tab
5. Scroll to **Frameworks, Libraries, and Embedded Content** section
6. Click **+** button
7. Select **SmartlookAnalytics** from Swift Package Products
8. Click **Add**
9. Verify it appears in the list
10. Clean build folder: **Product → Clean Build Folder** (Cmd+Shift+K)
11. Build and run: **Product → Run** (Cmd+R)

**Option B: Re-add Package (If Option A doesn't show SmartlookAnalytics)**
1. In Xcode: **File → Add Package Dependencies**
2. Enter: `https://github.com/smartlook/analytics-swift-package`
3. Select version: **2.2.15** or **Up to Next Major**
4. Check **Add to Target: AstronovaApp**
5. Click **Add Package**
6. Clean build folder (Cmd+Shift+K)
7. Build and run (Cmd+R)

### Fix 2: Verify Privacy Copy Before Claiming Smartlook Runtime

Do not claim Smartlook session replay is active in release docs until the SDK is
linked, a build proves `canImport(SmartlookAnalytics)`, and a fresh device or
simulator session appears in Smartlook.

### Fix 3: Force Enable in Debug Only for Source-Level Testing
In `AstronovaAppApp.swift`, temporarily remove the UI test check:
```swift
init() {
    // ALWAYS initialize Smartlook for testing
    Self.setupSmartlook()  // Remove the #if DEBUG check

    _authState = StateObject(wrappedValue: AuthState())
}
```

## 📊 Events Being Tracked

The following events SHOULD appear in Smartlook:

**Core Events**:
- `app_launched` - App starts
- `sign_in_success` - User signs in
- `home_viewed` - Home tab viewed

**Feature Events**:
- `oracle_chat_sent` - User sends chat message
- `oracle_chat_received` - AI responds
- `temple_booking_started` - User starts booking
- `temple_booking_completed` - Booking confirmed
- `dasha_timeline_viewed` - Time Travel viewed
- `compatibility_analyzed` - Relationship analysis
- `chart_generated` - Birth chart created

**Error Events**:
- `network_error` - Network failures
- `api_error` - API call failures
- `authentication_error` - Auth issues
- `decoding_error` - JSON parsing failures

## 🎯 Verification After Fix

After linking the package and rebuilding, check Xcode console output when app launches:

**✅ Success - Look for these messages:**
```
✅ [Smartlook] SDK is available - starting setup
✅ [Smartlook] Session recording started with project key: 3ea51a8...9ed
✅ [Smartlook] Check dashboard at: https://app.smartlook.com/
[ANALYTICS] ✅ Smartlook tracked: app_launched
```

**❌ Still Broken - If you see:**
```
❌ [Smartlook] SDK NOT available - SmartlookAnalytics cannot be imported
❌ [Smartlook] Check if package is properly linked to target
[ANALYTICS] ⚠️ Smartlook SDK not available - event logged locally only
```
→ Package still not linked. Try Option B (re-add package) instead.

**🔍 Check Smartlook Dashboard**:
1. Go to https://app.smartlook.com/
2. Sign in with your account
3. Navigate to your project (key: `3ea51a8cc18ecd6b6b43eec84450f694a65569ed`)
4. Check **Recordings** → You should see a new session within 1-2 minutes
5. Check **Events** → Filter by `app_launched` to verify event tracking

## 📞 Support

If issues persist:
1. Check Xcode → Window → Devices and Simulators → Console logs
2. Look for Smartlook-related errors
3. Verify the project key is correct in Smartlook dashboard
4. Check if project has data collection enabled (some plans have limits)
