# Smartlook Fix - Quick Guide

## Problem
Smartlook SDK is downloaded but not linked to AstronovaApp target → Events not tracked.

## Fix (Do This in Xcode)

### Step 1: Link Package to Target
1. Open `astronova.xcodeproj` in Xcode
2. Select **AstronovaApp** target (in Project Navigator)
3. Go to **General** tab
4. Scroll to **Frameworks, Libraries, and Embedded Content**
5. Click **+** button
6. Select **SmartlookAnalytics** from Swift Package Products
7. Click **Add**

### Step 2: Clean & Build
```
Product → Clean Build Folder (Cmd+Shift+K)
Product → Run (Cmd+R)
```

### Step 3: Verify Console Output
You should see:
```
✅ [Smartlook] SDK is available - starting setup
✅ [Smartlook] Session recording started
```

If you see "❌ SDK NOT available", the package wasn't linked properly. Try again.

### Step 4: Check Dashboard
- Go to https://app.smartlook.com/
- Your project: `3ea51a8cc18ecd6b6b43eec84450f694a65569ed`
- Check **Recordings** for new session (appears within 1-2 minutes)
- Check **Events** for `app_launched`

## Alternative: Re-add Package
If Option A doesn't work:
1. **File → Add Package Dependencies**
2. URL: `https://github.com/smartlook/analytics-swift-package`
3. Version: **2.2.15**
4. Check: **Add to Target: AstronovaApp**
5. Click **Add Package**
6. Clean build & run

---

**Full diagnostic**: See `SMARTLOOK_DIAGNOSTIC.md` for complete troubleshooting guide.
