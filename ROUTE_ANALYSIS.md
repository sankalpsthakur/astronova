# iOS Frontend ↔ Backend Route Analysis

## ✅ **Correctly Configured Routes**

| iOS Frontend Call | Backend Route | Status |
|-------------------|---------------|---------|
| `/health` | `/health` | ✅ Match |
| `/api/v1/auth/apple` | `/api/v1/auth/apple` | ✅ Match |
| `/api/v1/auth/validate` | `/api/v1/auth/validate` | ✅ Match |
| `/api/v1/auth/refresh` | `/api/v1/auth/refresh` | ✅ Match |
| `/api/v1/auth/logout` | `/api/v1/auth/logout` | ✅ Match |
| `/api/v1/chart/generate` | `/api/v1/chart/generate` | ✅ Match |
| `/api/v1/chat/send` | `/api/v1/chat/send` | ✅ Match |
| `/api/v1/match` | `/api/v1/match` | ✅ Match |
| `/api/v1/reports/full` | `/api/v1/reports/full` | ✅ Match |
| `/api/v1/reports/{reportId}` | `/api/v1/reports/{report_id}` | ✅ Match |
| `/api/v1/reports/user/{userId}` | `/api/v1/reports/user/{user_id}` | ✅ Match |
| `/api/v1/locations/search` | `/api/v1/locations/search` | ✅ Match |
| `/api/v1/locations/timezone` | `/api/v1/locations/timezone` | ✅ Match |

## ⚠️ **Route Mismatches Found**

| iOS Frontend Call | Backend Route | Issue | Fix Needed |
|-------------------|---------------|-------|------------|
| `/api/v1/horoscope?sign=X&type=daily` | `/api/v1/horoscope` (GET) | ❌ Backend doesn't handle query params | Backend fix |
| `/api/v1/chart/aspects` | **MISSING** | ❌ Route doesn't exist | Add to backend |
| `/api/v1/chat/history` | **MISSING** | ❌ Route doesn't exist | Add to backend |
| `/api/reports/generate` | `/api/v1/reports/full` | ❌ Missing /v1/ prefix | Frontend fix |
| `/api/reports/{reportId}` | `/api/v1/reports/{report_id}` | ❌ Missing /v1/ prefix | Frontend fix |
| `/api/v1/ephemeris/positions` | `/api/v1/ephemeris/current` | ❌ Different endpoint names | Align names |

## 🔧 **Required Fixes**

### 1. Frontend Fixes (APIServices.swift)

```swift
// Fix report endpoints - add /v1/ prefix
endpoint: "/api/v1/reports/generate"  // Line 308
endpoint: "/api/v1/reports/\(reportId)"  // Line 318

// Fix ephemeris endpoint name  
endpoint: "/api/v1/ephemeris/current"  // Line 361, 383
```

### 2. Backend Fixes

#### Add missing chat history route (routes/chat.py):
```python
@chat_bp.route('/history', methods=['GET'])
@jwt_required()
def get_chat_history():
    user_id = get_jwt_identity()
    # Implementation needed
    return jsonify([])
```

#### Add missing chart aspects route (routes/chart.py):
```python
@chart_bp.route('/aspects', methods=['POST'])
@validate_request(ChartRequest)
def get_chart_aspects(data: ChartRequest):
    # Implementation needed
    return jsonify({"aspects": []})
```

#### Update horoscope route to handle query parameters (routes/horoscope.py):
```python
@horoscope_bp.route('', methods=['GET'])
def get_horoscope():
    sign = request.args.get('sign')
    horoscope_type = request.args.get('type', 'daily')
    date = request.args.get('date')
    # Implementation needed
    return jsonify({"sign": sign, "type": horoscope_type, "horoscope": "..."})
```

## 📊 **Summary**

- **✅ 13 routes correctly configured**
- **⚠️ 6 routes need fixes**
- **🔧 3 frontend fixes needed**
- **🔧 3 backend routes to add**

## 🎯 **Priority Fixes**

### High Priority (Core Features)
1. **Horoscope query parameters** - Daily horoscope won't work
2. **Report endpoint prefixes** - Report generation will fail

### Medium Priority (Extended Features)  
3. **Chat history route** - Chat history feature incomplete
4. **Chart aspects route** - Advanced chart features incomplete
5. **Ephemeris endpoint naming** - Planetary positions inconsistent

### Next Steps
1. Apply frontend fixes to APIServices.swift
2. Add missing backend routes
3. Test all endpoints after fixes
4. Update API documentation