# CloudKit Web Services Setup Guide

## 🔑 **Authentication Setup**

To use CloudKit Web Services, you need to set up server-to-server authentication with Apple.

### **Step 1: Create CloudKit Key in Apple Developer Console**

1. **Go to Apple Developer Console**: [https://developer.apple.com/account/](https://developer.apple.com/account/)
2. **Navigate to**: Certificates, Identifiers & Profiles → Keys
3. **Click**: "+" to create a new key
4. **Configure**:
   - Key Name: `AstronovaCloudKitKey`
   - Enable: **CloudKit**
   - Configure: Select your CloudKit container `iCloud.com.sankalp.AstronovaApp`
5. **Download**: The `.p8` private key file (keep it secure!)
6. **Note**: Your Key ID (e.g., `ABC123DEF4`)

### **Step 2: Get Your Team ID**

1. **Go to**: Apple Developer Console → Membership
2. **Copy**: Your Team ID (e.g., `ABCD123456`)

### **Step 3: Configure Environment Variables**

Add these to your backend `.env` file:

```bash
# CloudKit Web Services Configuration
CLOUDKIT_KEY_ID=ABC123DEF4
CLOUDKIT_TEAM_ID=ABCD123456
CLOUDKIT_PRIVATE_KEY_PATH=/path/to/your/AuthKey_ABC123DEF4.p8
CLOUDKIT_ENVIRONMENT=development  # or 'production'
```

---

## 📋 **CloudKit Schema Setup**

### **Required Record Types in CloudKit Dashboard**

Go to **CloudKit Console**: [https://icloud.developer.apple.com/dashboard/](https://icloud.developer.apple.com/dashboard/)

#### **1. UserProfile**
```text
Fields:
- id (String, Queryable, Sortable)
- fullName (String)
- birthDate (Date/Time)
- birthLocation (String)
- birthTime (String)
- preferredLanguage (String)
- sunSign (String)
- moonSign (String)
- risingSign (String)
- bio (String)
- profileImageURL (String)
- timezone (String)
- createdAt (Date/Time, Queryable, Sortable)
- updatedAt (Date/Time, Queryable, Sortable)

Indexes:
- id (Queryable, Sortable)
- createdAt (Queryable, Sortable)
```

#### **2. ChatMessage**
```
Fields:
- id (String, Queryable, Sortable)
- userProfileId (String, Queryable, Sortable)
- conversationId (String, Queryable, Sortable)
- content (String)
- isUser (Int64) // 0 = AI, 1 = User
- timestamp (Date/Time, Queryable, Sortable)
- messageType (String, Queryable)

Indexes:
- userProfileId (Queryable, Sortable)
- conversationId (Queryable, Sortable)
- timestamp (Queryable, Sortable)
```

#### **3. Horoscope**
```
Fields:
- id (String, Queryable, Sortable)
- userProfileId (String, Queryable, Sortable)
- date (Date/Time, Queryable, Sortable)
- type (String, Queryable) // daily, weekly, monthly
- content (String)
- sign (String, Queryable, Sortable)
- luckyElements (Asset) // JSON data
- createdAt (Date/Time, Queryable, Sortable)

Indexes:
- userProfileId (Queryable, Sortable)
- date (Queryable, Sortable)
- sign (Queryable, Sortable)
```

#### **4. KundaliMatch**
```
Fields:
- id (String, Queryable, Sortable)
- userProfileId (String, Queryable, Sortable)
- partnerName (String)
- partnerBirthDate (Date/Time)
- partnerLocation (String)
- compatibilityScore (Int64, Queryable, Sortable)
- detailedAnalysis (Asset) // JSON data
- createdAt (Date/Time, Queryable, Sortable)

Indexes:
- userProfileId (Queryable, Sortable)
- compatibilityScore (Queryable, Sortable)
```

#### **5. BirthChart**
```
Fields:
- id (String, Queryable, Sortable)
- userProfileId (String, Queryable, Sortable)
- chartType (String, Queryable) // natal, transit, progressed
- systems (String List) // western, vedic, chinese
- planetaryPositions (Asset) // JSON data
- chartSVG (Asset) // Large data
- birthData (Asset) // JSON data
- createdAt (Date/Time, Queryable, Sortable)

Indexes:
- userProfileId (Queryable, Sortable)
- chartType (Queryable)
```

#### **6. BookmarkedReading**
```
Fields:
- id (String, Queryable, Sortable)  
- userProfileId (String, Queryable, Sortable)
- readingType (String, Queryable) // horoscope, chart, compatibility
- title (String)
- content (String)
- originalDate (Date/Time, Queryable, Sortable)
- bookmarkedAt (Date/Time, Queryable, Sortable)

Indexes:
- userProfileId (Queryable, Sortable)
- readingType (Queryable)
- bookmarkedAt (Queryable, Sortable)
```

---

## 🔐 **Security Configuration**

### **Database**: Private Database

### **Security Roles**
```
World Readable: None
World Writable: None

Authenticated Users:
- Read: Own records only
- Write: Own records only

Admin Role (for backend):
- Read: All records  
- Write: All records
```

---

## 🧪 **Testing CloudKit Integration**

### **1. Install Dependencies**
```bash
cd backend
pip install cryptography PyJWT ecdsa
```

### **2. Set Environment Variables**
```bash
export CLOUDKIT_KEY_ID=your_key_id
export CLOUDKIT_TEAM_ID=your_team_id  
export CLOUDKIT_PRIVATE_KEY_PATH=/path/to/AuthKey.p8
export CLOUDKIT_ENVIRONMENT=development
```

### **3. Test Connection**
```python
from services.cloudkit_service import CloudKitService

# Test CloudKit connection
ck = CloudKitService()
if not ck.use_simulation:
    print("✅ CloudKit Web Services configured!")
    
    # Test saving a record
    success = ck.save_user_profile("test_user", {
        "fullName": "Test User",
        "birthDate": "1990-01-01",
        "birthLocation": "New York, NY"
    })
    
    if success:
        print("✅ CloudKit record saved successfully!")
    else:
        print("❌ CloudKit record save failed")
else:
    print("⚠️  Using file simulation - CloudKit not configured")
```

---

## 📱 **iOS App Integration**

Your iOS app should work seamlessly with the backend CloudKit integration:

```swift
import CloudKit

// Your iOS app will see the same records
let container = CKContainer(identifier: "iCloud.com.sankalp.AstronovaApp")
let privateDatabase = container.privateCloudDatabase

// Query records that were created by the backend
let query = CKQuery(recordType: "UserProfile", predicate: NSPredicate(value: true))
privateDatabase.perform(query) { records, error in
    // Handle records created by backend
}
```

---

## 🚨 **Troubleshooting**

### **Common Issues**

1. **"Invalid JWT token"**
   - Check your Team ID and Key ID
   - Ensure the .p8 file path is correct
   - Verify the private key file is readable

2. **"Record type not found"**
   - Create the record types in CloudKit Dashboard
   - Deploy schema to Development environment

3. **"Permission denied"**
   - Set up security roles correctly
   - Ensure private database is configured

4. **"Asset upload failed"**
   - Large JSON data is stored as CloudKit assets
   - Check asset upload permissions

### **Debug Mode**
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

---

## 🎯 **Next Steps**

1. ✅ Set up CloudKit Key and get credentials
2. ✅ Create record types in CloudKit Dashboard  
3. ✅ Configure environment variables
4. ✅ Test CloudKit connection
5. ✅ Deploy schema to production when ready

Once configured, your backend will automatically use real CloudKit instead of file simulation!