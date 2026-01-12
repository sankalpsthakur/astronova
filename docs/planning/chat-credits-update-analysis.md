# Chat Credits Quantity Update - Comprehensive Analysis

**Date:** January 13, 2026
**Issue:** Update chat credit quantities from (5, 15, 50) to (50, 150, 500)

---

## 📊 Current vs. Target Configuration

| Product ID | Old Quantity | New Quantity | Price | Multiplier |
|------------|--------------|--------------|-------|------------|
| `chat_credits_5` | 5 credits | **50 credits** | $14.99 | 10x |
| `chat_credits_15` | 15 credits | **150 credits** | $34.99 | 10x |
| `chat_credits_50` | 50 credits | **500 credits** | $89.99 | 10x |

---

## 🔍 Impact Analysis

### ❌ **CRITICAL ISSUE: Product ID Mismatch**

The current implementation extracts credit quantities from the Product ID:
- `chat_credits_5` → extracts "5" → adds 5 credits
- `chat_credits_15` → extracts "15" → adds 15 credits
- `chat_credits_50` → extracts "50" → adds 50 credits

**Problem:** Product IDs **cannot be changed** in App Store Connect after creation!

**Result:** With current Product IDs, the code will ALWAYS add the wrong quantities:
- User buys `chat_credits_5` expecting 50 credits → gets only **5 credits** ❌
- User buys `chat_credits_15` expecting 150 credits → gets only **15 credits** ❌
- User buys `chat_credits_50` expecting 500 credits → gets only **50 credits** ❌

---

## 📱 **CLIENT SIDE (iOS) - Required Changes**

### 1. **ShopCatalog.swift** (Lines 83-87)
**Status:** ⚠️ MUST UPDATE

**Current Code:**
```swift
static let chatPacks: [ChatPack] = [
    .init(id: "c5", productId: "chat_credits_5", title: "5 Replies", subtitle: "Quick clarity", credits: 5),
    .init(id: "c15", productId: "chat_credits_15", title: "15 Replies", subtitle: "Deeper guidance", credits: 15),
    .init(id: "c50", productId: "chat_credits_50", title: "50 Replies", subtitle: "Best value", credits: 50)
]
```

**Required Update:**
```swift
static let chatPacks: [ChatPack] = [
    .init(id: "c5", productId: "chat_credits_5", title: "50 Credits", subtitle: "Regular use", credits: 50),
    .init(id: "c15", productId: "chat_credits_15", title: "150 Credits", subtitle: "Extended guidance", credits: 150),
    .init(id: "c50", productId: "chat_credits_50", title: "500 Credits", subtitle: "Best value", credits: 500)
]
```

**Why:** This is the source of truth for UI display and credit amounts in production StoreKit flow.

**Files Affected:**
- `ChatPackagesSheet.swift` - Uses `pack.credits` from ShopCatalog (line 149)
- Any UI displaying chat pack info

---

### 2. **BasicStoreManager.swift** (Lines 33-39)
**Status:** ⚠️ MUST UPDATE (Mock/Test Only)

**Current Code:**
```swift
if productId.hasPrefix("chat_credits_") {
    // Extract count from productId and add to chat credits
    let parts = productId.split(separator: "_")
    if let last = parts.last, let count = Int(last) {
        chatCredits += count
    }
}
```

**Required Update:**
```swift
if productId.hasPrefix("chat_credits_") {
    // Map Product ID to actual credit amounts
    let creditAmounts: [String: Int] = [
        "chat_credits_5": 50,
        "chat_credits_15": 150,
        "chat_credits_50": 500
    ]

    if let credits = creditAmounts[productId] {
        chatCredits += credits
    }
}
```

**Why:** This mock manager is used in DEBUG mode and UI tests. Must match production behavior.

---

### 3. **StoreKitManager.swift** (Lines 217-223)
**Status:** 🔴 **CRITICAL - MUST UPDATE**

**Current Code:**
```swift
// Handle chat credit purchases (consumable)
if transaction.productID.hasPrefix("chat_credits_") {
    let parts = transaction.productID.split(separator: "_")
    if let last = parts.last, let count = Int(last) {
        let currentCredits = UserDefaults.standard.integer(forKey: "chat_credits")
        UserDefaults.standard.set(currentCredits + count, forKey: "chat_credits")
    }
}
```

**Required Update:**
```swift
// Handle chat credit purchases (consumable)
if transaction.productID.hasPrefix("chat_credits_") {
    // Map Product ID to actual credit amounts
    let creditAmounts: [String: Int] = [
        "chat_credits_5": 50,
        "chat_credits_15": 150,
        "chat_credits_50": 500
    ]

    if let credits = creditAmounts[transaction.productID] {
        let currentCredits = UserDefaults.standard.integer(forKey: "chat_credits")
        UserDefaults.standard.set(currentCredits + credits, forKey: "chat_credits")
    }
}
```

**Why:** This is the **PRODUCTION** code that runs when users make real purchases via StoreKit. MUST give correct credit amounts!

---

### 4. **OracleQuotaManager.swift**
**Status:** ✅ NO CHANGES NEEDED

**Why:** This file only tracks and consumes credits. Credit quantities are added by StoreKitManager/BasicStoreManager.

---

### 5. **ChatPackagesSheet.swift**
**Status:** ✅ NO CHANGES NEEDED

**Why:** Gets credit amounts from `ShopCatalog.chatPacks`. Once ShopCatalog is updated, this will work correctly.

**Key Line (149):**
```swift
chatCredits += pack.credits  // Uses value from ShopCatalog
```

---

## 🖥️ **SERVER SIDE (Backend) - Analysis**

### Status: ✅ NO CHANGES NEEDED

**Why:**
1. **No server-side credit tracking** - Credits are stored client-side in `AppStorage("chat_credits")`
2. **No IAP receipt validation** - StoreKit 2 handles verification
3. **No purchase history** - Only tracks subscription status in `subscription_status` table
4. **Chat endpoints don't check credits** - Client-side quota management only

**Database Tables Checked:**
- `users` - No credit balance column
- `subscription_status` - Only tracks Pro subscription
- `chat_conversations` - No credit tracking
- `chat_messages` - No credit tracking

**Backend Logic:**
- Oracle/chat endpoints (`server/routes/chat.py`) only check authentication
- No server-side credit validation or consumption

---

## 💾 **DATABASE SIDE - Analysis**

### Status: ✅ NO CHANGES NEEDED

**Why:** All credit tracking is client-side only.

**Storage Location:**
```swift
@AppStorage("chat_credits") var credits: Int = 0
```

Stored in: `UserDefaults` (iOS local storage, per-device)

**No server database columns for:**
- ❌ User credit balance
- ❌ Credit purchase history
- ❌ Credit consumption logs

**Implications:**
- ✅ No migration needed
- ✅ No backfill required
- ⚠️ Credits lost if user uninstalls app (expected behavior for consumables)
- ⚠️ Credits don't sync across devices (StoreKit limitation for consumables)

---

## 🧪 **TESTING REQUIREMENTS**

### Unit Tests to Update

1. **BasicStoreManager Tests** (`AstronovaAppTests.swift`)
   - Update mock purchase tests to expect new quantities
   - Test: Buy chat_credits_5 → Assert +50 credits (not +5)

2. **ShopCatalog Tests**
   - Verify chatPacks array has correct credit counts
   - Test: chatPacks[0].credits == 50 (not 5)

### Integration Tests

3. **StoreKit Sandbox Testing**
   - Test each product purchase with sandbox account
   - Verify correct credit amounts added:
     - chat_credits_5 → +50
     - chat_credits_15 → +150
     - chat_credits_50 → +500

4. **UI Tests** (`ChatPackagesSheet`)
   - Verify display titles show "50 Credits", "150 Credits", "500 Credits"
   - Test purchase flow adds correct amounts

### Manual QA Checklist

- [ ] Purchase chat_credits_5 → Verify +50 credits
- [ ] Purchase chat_credits_15 → Verify +150 credits
- [ ] Purchase chat_credits_50 → Verify +500 credits
- [ ] Verify credit balance persists after app restart
- [ ] Verify credits consumed correctly (1 per Quick, 2 per Deep)
- [ ] Verify "Available credits" display updates
- [ ] Verify purchase success overlay shows correct amount

---

## ⚠️ **MIGRATION CONSIDERATIONS**

### Existing Users with Old Credits

**Scenario:** Users who purchased chat credits BEFORE this update.

**Current State:**
- User bought chat_credits_5 → received 5 credits
- User bought chat_credits_15 → received 15 credits
- User bought chat_credits_50 → received 50 credits

**After Update:**
- These users keep their existing balances (no automatic upgrade)
- New purchases give new quantities (50, 150, 500)

**Recommendation:**
✅ **No retroactive upgrade** - Old purchases were fulfilled correctly at time of purchase. New quantities only apply to future purchases.

**Alternative (Generous Approach):**
Could multiply existing balances by 10x on app update:
- User with 5 credits → 50 credits
- User with 15 credits → 150 credits
- User with 50 credits → 500 credits

**Implementation (if desired):**
```swift
// In AppDelegate or App init
func migrateOldCreditBalances() {
    let migrationKey = "credits_migration_v2_applied"
    guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

    let oldCredits = UserDefaults.standard.integer(forKey: "chat_credits")
    if oldCredits > 0 && oldCredits < 100 {
        // Likely old quantities, multiply by 10
        let newCredits = oldCredits * 10
        UserDefaults.standard.set(newCredits, forKey: "chat_credits")
    }

    UserDefaults.standard.set(true, forKey: migrationKey)
}
```

---

## 📋 **IMPLEMENTATION CHECKLIST**

### Phase 1: Code Changes (Client Only)

- [ ] Update `ShopCatalog.swift` chatPacks array (credits: 50, 150, 500)
- [ ] Update `BasicStoreManager.swift` credit mapping (mock/test mode)
- [ ] Update `StoreKitManager.swift` handleSuccessfulPurchase() credit mapping (**CRITICAL**)
- [ ] Update display strings ("50 Credits" not "5 Replies")

### Phase 2: Testing

- [ ] Run unit tests
- [ ] Update test expectations
- [ ] Test with Sandbox account (all 3 products)
- [ ] Verify credit balance updates correctly
- [ ] Test credit consumption (Oracle usage)

### Phase 3: Deployment

- [ ] Commit code changes
- [ ] Push to TestFlight
- [ ] Test on real device with Sandbox
- [ ] Submit app update to App Store

### Phase 4: App Store Connect

- [ ] Already done: Product IDs created (can't change)
- [ ] Already done: Prices set ($14.99, $34.99, $89.99)
- [ ] Add metadata (Display Names: "50 Credits", "150 Credits", "500 Credits")
- [ ] Add descriptions (mention actual quantities)

---

## 🚨 **CRITICAL WARNINGS**

### 1. Product IDs Cannot Change

❌ **DO NOT** try to:
- Create new products with different IDs
- Delete old products
- Rename Product IDs

✅ **MUST** use existing Product IDs:
- `chat_credits_5`
- `chat_credits_15`
- `chat_credits_50`

### 2. Code Must Override ID-Based Logic

**Old logic:** Extract number from Product ID
**New logic:** Explicit mapping table

**Why:** Product IDs don't match quantities, so we need a lookup table.

### 3. Both Managers Must Match

**StoreKitManager** (production) and **BasicStoreManager** (mock/test) must have identical credit mappings, or tests will fail and mock purchases won't match real behavior.

---

## 💡 **RECOMMENDED IMPLEMENTATION ORDER**

1. ✅ **App Store Connect Metadata** (Done - use IAP_COPY_PASTE_METADATA.txt)
2. 🔧 **Update ShopCatalog.swift** (Display + credit amounts)
3. 🔧 **Update StoreKitManager.swift** (Production purchase handler) **CRITICAL**
4. 🔧 **Update BasicStoreManager.swift** (Mock/test purchase handler)
5. 🧪 **Test with Sandbox account**
6. 🚀 **Deploy to TestFlight**
7. 📱 **Submit to App Store**

---

## 📐 **CODE DIFF SUMMARY**

### Files to Modify: **3 files**

| File | Lines | Change Type | Impact |
|------|-------|-------------|--------|
| `ShopCatalog.swift` | 84-86 | Update credit values | UI display + production credit grants |
| `StoreKitManager.swift` | 217-223 | Replace extraction logic with mapping | **CRITICAL** - Production purchases |
| `BasicStoreManager.swift` | 33-39 | Replace extraction logic with mapping | Mock/test mode |

### Files Not Requiring Changes: **5+ files**

- `OracleQuotaManager.swift` - Only consumes credits
- `ChatPackagesSheet.swift` - Uses ShopCatalog data
- `PaywallView.swift` - No chat credit logic
- Server files - No server-side credit tracking
- Database schema - No credit balance columns

---

## ✅ **VALIDATION CRITERIA**

### Success Metrics

After implementation, verify:

1. ✅ Purchase chat_credits_5 → User receives **50 credits** (not 5)
2. ✅ Purchase chat_credits_15 → User receives **150 credits** (not 15)
3. ✅ Purchase chat_credits_50 → User receives **500 credits** (not 50)
4. ✅ UI displays "50 Credits", "150 Credits", "500 Credits"
5. ✅ Oracle consumes 1 credit per Quick question
6. ✅ Oracle consumes 2 credits per Deep question
7. ✅ Credits persist after app restart
8. ✅ Multiple purchases accumulate correctly
9. ✅ Sandbox testing matches production behavior
10. ✅ Mock purchases (tests) match real purchases (StoreKit)

---

## 🎯 **FINAL RECOMMENDATION**

### Action Plan

1. **Immediate:** Update all 3 Swift files with new credit mappings
2. **Before Deploy:** Test all 3 products with Sandbox account
3. **Validation:** Run full integration test suite
4. **Deploy:** Push to TestFlight first, verify, then App Store

### Estimated Effort

- Code changes: **15 minutes**
- Testing: **30 minutes**
- TestFlight validation: **1 hour**
- Total: **~2 hours**

### Risk Assessment

- **Risk Level:** Medium
- **Impact:** High (affects all future purchases)
- **Mitigation:** Thorough sandbox testing before App Store release

---

**Status:** Ready for implementation
**Blocker:** None (all analysis complete)
**Next Step:** Update 3 Swift files per specifications above
