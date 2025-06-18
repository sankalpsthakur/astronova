# CloudKit Schema Setup Guide

## 🎯 **CloudKit Dashboard Configuration**

To see records in CloudKit Dashboard, you need to:

1. **Go to CloudKit Console**: https://icloud.developer.apple.com/dashboard/
2. **Select Container**: `iCloud.com.sankalp.AstronovaApp`
3. **Create Record Types** (see below)
4. **Set Security Roles**
5. **Deploy to Production**

---

## 📋 **Record Types to Create**

### 1. **UserProfile** Record Type

**Fields:**
```
id                  : String (Queryable, Sortable)
fullName           : String
birthDate          : Date/Time
birthLocation      : String
birthTime          : String
preferredLanguage  : String
sunSign            : String (Optional)
moonSign           : String (Optional)
risingSign         : String (Optional)
bio                : String (Optional)
profileImageURL    : String (Optional)
birthCoordinates   : Location (Optional)
timezone           : String (Optional)
createdAt          : Date/Time (Queryable, Sortable)
updatedAt          : Date/Time (Queryable, Sortable)
```

**Indexes:**
- `id` (Queryable, Sortable)
- `createdAt` (Queryable, Sortable)
- `updatedAt` (Queryable, Sortable)

---

### 2. **ChatMessage** Record Type

**Fields:**
```
id                 : String (Queryable, Sortable)
userProfileId      : String (Queryable, Sortable)
conversationId     : String (Queryable, Sortable)
content            : String
isUser             : Int64 (0 = AI, 1 = User)
timestamp          : Date/Time (Queryable, Sortable)
messageType        : String (Queryable)
```

**Indexes:**
- `userProfileId` (Queryable, Sortable)
- `conversationId` (Queryable, Sortable)
- `timestamp` (Queryable, Sortable)
- `messageType` (Queryable)

---

### 3. **Horoscope** Record Type

**Fields:**
```
id                 : String (Queryable, Sortable)
userProfileId      : String (Queryable, Sortable)
date               : Date/Time (Queryable, Sortable)
type               : String (Queryable) // daily, weekly, monthly
content            : String
sign               : String (Queryable, Sortable)
luckyElements      : Asset (JSON data)
createdAt          : Date/Time (Queryable, Sortable)
```

**Indexes:**
- `userProfileId` (Queryable, Sortable)
- `date` (Queryable, Sortable)
- `type` (Queryable)
- `sign` (Queryable, Sortable)
- `createdAt` (Queryable, Sortable)

---

### 4. **KundaliMatch** Record Type

**Fields:**
```
id                 : String (Queryable, Sortable)
userProfileId      : String (Queryable, Sortable)
partnerName        : String
partnerBirthDate   : Date/Time
partnerLocation    : String
compatibilityScore : Int64 (Queryable, Sortable)
detailedAnalysis   : Asset (JSON data)
createdAt          : Date/Time (Queryable, Sortable)
```

**Indexes:**
- `userProfileId` (Queryable, Sortable)
- `compatibilityScore` (Queryable, Sortable)
- `createdAt` (Queryable, Sortable)

---

### 5. **BirthChart** Record Type

**Fields:**
```
id                 : String (Queryable, Sortable)
userProfileId      : String (Queryable, Sortable)
chartType          : String (Queryable) // natal, transit, progressed
systems            : String List // western, vedic, chinese
planetaryPositions : Asset (JSON data)
chartSVG           : Asset (Large data)
birthData          : Asset (JSON data)
createdAt          : Date/Time (Queryable, Sortable)
```

**Indexes:**
- `userProfileId` (Queryable, Sortable)
- `chartType` (Queryable)
- `createdAt` (Queryable, Sortable)

---

### 6. **BookmarkedReading** Record Type

**Fields:**
```
id                 : String (Queryable, Sortable)
userProfileId      : String (Queryable, Sortable)
readingType        : String (Queryable) // horoscope, chart, compatibility
title              : String
content            : String
originalDate       : Date/Time (Queryable, Sortable)
bookmarkedAt       : Date/Time (Queryable, Sortable)
```

**Indexes:**
- `userProfileId` (Queryable, Sortable)
- `readingType` (Queryable)
- `originalDate` (Queryable, Sortable)
- `bookmarkedAt` (Queryable, Sortable)

---

## 🔐 **Security Configuration**

### **Database**: Private Database

### **Security Roles:**
```
World Readable: None
World Writable: None

Authenticated Users:
- Read: Own records only (where createdBy == current user)
- Write: Own records only (where createdBy == current user)

Admin Role:
- Read: All records
- Write: All records
```

### **Record Zone**: Default Zone

---

## 🚀 **Next Steps**

After creating the schema:

1. **Deploy to Development Environment** first
2. **Test with iOS Simulator**
3. **Deploy to Production Environment**
4. **Update backend to use real CloudKit SDK**

---

## 📱 **iOS Integration**

Your iOS app should use:
```swift
import CloudKit

let container = CKContainer(identifier: "iCloud.com.sankalp.AstronovaApp")
let privateDatabase = container.privateCloudDatabase
```

---

## 🔧 **Backend Integration Options**

### Option 1: CloudKit Web Services API (Recommended)
```python
# Use CloudKit Web Services REST API
# Requires server-to-server key authentication
```

### Option 2: iOS App as Bridge
```python
# iOS app handles CloudKit operations
# Backend communicates via push notifications or polling
```

### Option 3: Third-party SDK
```python
# Use community CloudKit Python SDK
# Limited functionality compared to native iOS SDK
```