# App Store Connect IAP - Quick Setup Checklist

## 📋 11 Products to Configure

### ✅ STEP 1: Create Subscription Group
- [ ] Create group: **"Astronova Pro"**

### ✅ STEP 2: Add 1 Auto-Renewable Subscription

| # | Product ID | Price | Duration |
|---|------------|-------|----------|
| 1 | `astronova_pro_monthly` | $9.99 | 1 Month |

### ✅ STEP 3: Add 7 Non-Consumable Reports

| # | Product ID | Display Name | Price |
|---|------------|--------------|-------|
| 2 | `report_general` | General Life Report | $12.99 |
| 3 | `report_love` | Love & Relationships Report | $12.99 |
| 4 | `report_career` | Career & Ambitions Report | $12.99 |
| 5 | `report_money` | Money & Wealth Report | $12.99 |
| 6 | `report_health` | Health & Vitality Report | $12.99 |
| 7 | `report_family` | Family & Home Report | $12.99 |
| 8 | `report_spiritual` | Spiritual Path Report | $12.99 |

### ✅ STEP 4: Add 3 Consumable Chat Credits

| # | Product ID | Display Name | Price |
|---|------------|--------------|-------|
| 9 | `chat_credits_5` | 5 Chat Credits | $14.99 |
| 10 | `chat_credits_15` | 15 Chat Credits | $34.99 |
| 11 | `chat_credits_50` | 50 Chat Credits | $89.99 |

---

## ⚡ Quick Links

**Detailed Setup Guide:** `APP_STORE_CONNECT_IAP_SETUP.md`

**App Store Connect:** https://appstoreconnect.apple.com

**IAP Section:** Your App → Features → In-App Purchases

**Subscriptions:** Your App → Features → Subscriptions

---

## ⚠️ Critical Rules

1. **Product IDs MUST match code exactly** (case-sensitive)
2. Product IDs **cannot be changed** after creation
3. Test with **Sandbox account** before submission
4. Submit **all IAP products** with app for review
5. Subscription group name doesn't matter (internal only)

---

## 🧪 Testing Checklist

- [ ] Sandbox tester account created
- [ ] Subscribe to Pro Monthly ($9.99)
- [ ] Purchase at least one report ($12.99)
- [ ] Purchase chat credits ($14.99)
- [ ] Cancel subscription
- [ ] Restore purchases
- [ ] Verify price localization (if applicable)

---

## 📞 Common Issues

**"Product not found"**
→ Check Product ID matches code exactly

**"Purchase failed"**
→ Use Sandbox account, sign out of regular Apple ID first

**"Invalid product"**
→ Product may still be pending approval

**"Restore failed"**
→ Ensure signed in with correct Sandbox account

---

**Total Revenue Model:**

- **Subscription:** $9.99/month recurring → **Primary revenue**
- **Reports:** $12.99 each × 7 = $90.93 total → One-time sales
- **Chat Credits:** $14.99 - $89.99 → A la carte option

**Estimated Setup Time:** 30-45 minutes for all 11 products
