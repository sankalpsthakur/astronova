# Chat Credits Update - Code Changes

**Apply these changes to 3 files**

---

## File 1: ShopCatalog.swift

**Location:** `/client/AstronovaApp/Services/ShopCatalog.swift`
**Lines:** 83-87

### BEFORE:
```swift
static let chatPacks: [ChatPack] = [
    .init(id: "c5", productId: "chat_credits_5", title: "5 Replies", subtitle: "Quick clarity", credits: 5),
    .init(id: "c15", productId: "chat_credits_15", title: "15 Replies", subtitle: "Deeper guidance", credits: 15),
    .init(id: "c50", productId: "chat_credits_50", title: "50 Replies", subtitle: "Best value", credits: 50)
]
```

### AFTER:
```swift
static let chatPacks: [ChatPack] = [
    .init(id: "c5", productId: "chat_credits_5", title: "50 Credits", subtitle: "Regular use", credits: 50),
    .init(id: "c15", productId: "chat_credits_15", title: "150 Credits", subtitle: "Extended guidance", credits: 150),
    .init(id: "c50", productId: "chat_credits_50", title: "500 Credits", subtitle: "Best value", credits: 500)
]
```

---

## File 2: BasicStoreManager.swift

**Location:** `/client/AstronovaApp/Services/BasicStoreManager.swift`
**Lines:** 33-39

### BEFORE:
```swift
if productId.hasPrefix("chat_credits_") {
    // Extract count from productId and add to chat credits
    let parts = productId.split(separator: "_")
    if let last = parts.last, let count = Int(last) {
        chatCredits += count
    }
}
```

### AFTER:
```swift
if productId.hasPrefix("chat_credits_") {
    // Map Product ID to actual credit amounts
    // Note: Product IDs can't be changed in App Store Connect,
    // so we use an explicit mapping instead of parsing the ID
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

---

## File 3: StoreKitManager.swift (CRITICAL)

**Location:** `/client/AstronovaApp/StoreKitManager.swift`
**Lines:** 216-224

### BEFORE:
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

### AFTER:
```swift
// Handle chat credit purchases (consumable)
if transaction.productID.hasPrefix("chat_credits_") {
    // Map Product ID to actual credit amounts
    // Note: Product IDs can't be changed in App Store Connect,
    // so we use an explicit mapping instead of parsing the ID
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

---

## Summary

- **3 files** to modify
- **~30 lines total** changed
- **Critical:** StoreKitManager change affects real production purchases
- **Test:** BasicStoreManager change affects mock/test purchases
- **UI:** ShopCatalog change affects display and production credit grants

---

## Testing Validation

After applying changes, verify:

1. Build succeeds
2. Run unit tests (should pass after updating expectations)
3. Test with Sandbox account:
   - Buy chat_credits_5 → Check balance increases by 50
   - Buy chat_credits_15 → Check balance increases by 150
   - Buy chat_credits_50 → Check balance increases by 500
4. Verify UI shows "50 Credits", "150 Credits", "500 Credits"

---

## Applying Changes with Edit Tool

Use these exact Edit tool commands:

### Command 1:
```
Edit file: /Users/sankalp/Projects/astronova/client/AstronovaApp/Services/ShopCatalog.swift
old_string: (exact lines 84-86)
new_string: (new chatPacks array)
```

### Command 2:
```
Edit file: /Users/sankalp/Projects/astronova/client/AstronovaApp/Services/BasicStoreManager.swift
old_string: (exact lines 33-39)
new_string: (new mapping logic)
```

### Command 3:
```
Edit file: /Users/sankalp/Projects/astronova/client/AstronovaApp/StoreKitManager.swift
old_string: (exact lines 217-223)
new_string: (new mapping logic)
```
