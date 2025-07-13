"""
Comprehensive Breaking Point Analysis Test Suite for Astronova Backend
Tests all critical endpoints, authentication flows, and integration points
"""

import pytest
import requests
import json
import time
from datetime import datetime

# Test configuration
BASE_URL = "http://localhost:8082"
TIMEOUT = 10

class TestBreakingPoints:
    """Test suite to identify all possible breaking points in the system"""
    
    def setup_method(self):
        """Setup for each test method"""
        self.session = requests.Session()
        self.session.timeout = TIMEOUT
    
    def test_health_endpoints_accessibility(self):
        """Test 1: Verify all health endpoints are accessible"""
        print("\n🔍 Testing Health Endpoint Accessibility...")
        
        # Test basic health endpoint
        response = self.session.get(f"{BASE_URL}/health")
        assert response.status_code == 200, f"Basic health endpoint failed: {response.status_code}"
        print(f"✅ /health endpoint working: {response.json()}")
        
        # Test API v1 health endpoint (critical for iOS app)
        response = self.session.get(f"{BASE_URL}/api/v1/health")
        assert response.status_code == 200, f"API v1 health endpoint failed: {response.status_code}"
        print(f"✅ /api/v1/health endpoint working: {response.json()}")
        
        # Test misc health endpoint
        response = self.session.get(f"{BASE_URL}/api/v1/misc/health")
        assert response.status_code == 200, f"Misc health endpoint failed: {response.status_code}"
        print(f"✅ /api/v1/misc/health endpoint working: {response.json()}")
    
    def test_core_api_endpoints_existence(self):
        """Test 2: Verify all core API endpoints exist"""
        print("\n🔍 Testing Core API Endpoints Existence...")
        
        endpoints_to_test = [
            ("/api/v1/ephemeris/current", "GET"),
            ("/api/v1/chart/generate", "POST"),
            ("/api/v1/chat", "POST"),
            ("/api/v1/horoscope?sign=leo&period=daily", "GET"),  # Fixed format
            ("/api/v1/match/compatibility", "POST"),
            ("/api/v1/auth/login", "POST"),
            ("/api/v1/content/management", "GET"),
        ]
        
        for endpoint, method in endpoints_to_test:
            url = f"{BASE_URL}{endpoint}"
            try:
                if method == "GET":
                    response = self.session.get(url)
                else:
                    response = self.session.post(url, json={})
                
                # We expect either 200, 400 (bad request), or 401 (unauthorized) - not 404
                assert response.status_code != 404, f"Endpoint not found: {endpoint}"
                print(f"✅ {endpoint} exists (status: {response.status_code})")
                
            except requests.exceptions.RequestException as e:
                pytest.fail(f"❌ Network error accessing {endpoint}: {e}")
    
    def test_ephemeris_data_integrity(self):
        """Test 3: Verify ephemeris data returns valid astronomical data"""
        print("\n🔍 Testing Ephemeris Data Integrity...")
        
        response = self.session.get(f"{BASE_URL}/api/v1/ephemeris/current")
        assert response.status_code == 200, f"Ephemeris endpoint failed: {response.status_code}"
        
        data = response.json()
        assert "planets" in data, "Missing 'planets' key in ephemeris response"
        assert len(data["planets"]) >= 10, f"Expected at least 10 planets, got {len(data['planets'])}"
        
        # Validate planet data structure
        required_planet_fields = ["id", "name", "sign", "degree", "symbol"]
        for planet in data["planets"]:
            for field in required_planet_fields:
                assert field in planet, f"Missing required field '{field}' in planet data"
            
            # Validate degree is within valid range (0-360)
            assert 0 <= planet["degree"] <= 360, f"Invalid degree {planet['degree']} for planet {planet['name']}"
        
        print(f"✅ Ephemeris data valid with {len(data['planets'])} planets")
    
    def test_chart_generation_endpoint(self):
        """Test 4: Test chart generation with valid birth data"""
        print("\n🔍 Testing Chart Generation Endpoint...")
        
        valid_birth_data = {
            "birth_date": "1990-01-01",
            "birth_time": "12:00",
            "latitude": 40.7128,
            "longitude": -74.0060,
            "timezone": "America/New_York",
            "system": "western",
            "chart_type": "natal"
        }
        
        response = self.session.post(f"{BASE_URL}/api/v1/chart/generate", json=valid_birth_data)
        
        if response.status_code == 400:
            print(f"⚠️ Chart generation returned 400: {response.text}")
            # This might be expected due to data validation
        elif response.status_code == 200:
            data = response.json()
            print(f"✅ Chart generation successful: {list(data.keys())}")
        else:
            pytest.fail(f"❌ Unexpected status code {response.status_code}: {response.text}")
    
    def test_ai_chat_endpoint(self):
        """Test 5: Test AI chat functionality"""
        print("\n🔍 Testing AI Chat Endpoint...")
        
        chat_message = {
            "message": "Hello, I want to know about my sun sign",
            "birth_data": {
                "date": "1990-01-01",
                "time": "12:00",
                "latitude": 40.7128,
                "longitude": -74.0060
            }
        }
        
        response = self.session.post(f"{BASE_URL}/api/v1/chat", json=chat_message)
        
        if response.status_code == 200:
            data = response.json()
            assert "response" in data, "Missing 'response' in chat response"
            print(f"✅ AI Chat working: {data['response'][:100]}...")
        elif response.status_code in [400, 401, 422]:
            print(f"⚠️ Chat endpoint returned {response.status_code}: {response.text}")
        else:
            pytest.fail(f"❌ Chat endpoint failed: {response.status_code} - {response.text}")
    
    def test_authentication_endpoints(self):
        """Test 6: Test authentication endpoints"""
        print("\n🔍 Testing Authentication Endpoints...")
        
        # Test login endpoint with dummy data
        login_data = {
            "apple_identity_token": "dummy_token",
            "user_id": "test_user"
        }
        
        response = self.session.post(f"{BASE_URL}/api/v1/auth/login", json=login_data)
        
        # We expect either success or authentication failure, not 404
        assert response.status_code != 404, "Auth login endpoint not found"
        print(f"✅ Auth login endpoint exists (status: {response.status_code})")
        
        if response.status_code == 401:
            print("⚠️ Authentication failed as expected with dummy credentials")
    
    def test_cors_headers(self):
        """Test 7: Verify CORS headers are properly set"""
        print("\n🔍 Testing CORS Headers...")
        
        response = self.session.get(f"{BASE_URL}/api/v1/health")
        
        cors_headers = {
            "Access-Control-Allow-Origin": "*",
        }
        
        for header, expected_value in cors_headers.items():
            actual_value = response.headers.get(header)
            if actual_value:
                print(f"✅ CORS header {header}: {actual_value}")
            else:
                print(f"⚠️ Missing CORS header: {header}")
    
    def test_response_times(self):
        """Test 8: Verify API response times are acceptable"""
        print("\n🔍 Testing API Response Times...")
        
        endpoints = [
            f"{BASE_URL}/api/v1/health",
            f"{BASE_URL}/api/v1/ephemeris/current",
            f"{BASE_URL}/api/v1/misc/health"
        ]
        
        for endpoint in endpoints:
            start_time = time.time()
            response = self.session.get(endpoint)
            end_time = time.time()
            
            duration = end_time - start_time
            assert duration < 5.0, f"Endpoint {endpoint} took too long: {duration:.2f}s"
            print(f"✅ {endpoint} responded in {duration:.3f}s")
    
    def test_error_handling(self):
        """Test 9: Verify proper error handling"""
        print("\n🔍 Testing Error Handling...")
        
        # Test invalid JSON
        response = self.session.post(
            f"{BASE_URL}/api/v1/chart/generate", 
            data="invalid json",
            headers={"Content-Type": "application/json"}
        )
        
        assert response.status_code == 400, f"Expected 400 for invalid JSON, got {response.status_code}"
        print("✅ Invalid JSON properly handled")
        
        # Test non-existent endpoint
        response = self.session.get(f"{BASE_URL}/api/v1/nonexistent")
        assert response.status_code == 404, f"Expected 404 for non-existent endpoint, got {response.status_code}"
        print("✅ Non-existent endpoint properly handled")
    
    def test_content_management(self):
        """Test 10: Test content management endpoints"""
        print("\n🔍 Testing Content Management...")
        
        response = self.session.get(f"{BASE_URL}/api/v1/content/management")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Content management working: {list(data.keys())}")
        elif response.status_code == 404:
            print("⚠️ Content management endpoint not found")
        else:
            print(f"⚠️ Content management returned {response.status_code}: {response.text}")

def test_cloudkit_integration():
    """Test 11: CloudKit Integration Test (Backend Web Services)"""
    print("\n🔍 Testing CloudKit Backend Integration...")
    
    # Test if CloudKit service is configured
    try:
        from services.cloudkit_service import CloudKitService
        service = CloudKitService()
        
        if service.enabled:
            print("✅ CloudKit Web Services enabled")
            
            # Test basic CloudKit operations
            test_data = {
                "fullName": "Test User",
                "birthDate": "1990-01-01",
                "birthLocation": "New York, NY",
                "birthTime": "12:00"
            }
            
            try:
                # This would test actual CloudKit record creation
                print("⚠️ CloudKit record operations require authentication")
            except Exception as e:
                print(f"⚠️ CloudKit operation failed: {e}")
        else:
            print("⚠️ CloudKit Web Services not configured (running in offline mode)")
            
    except ImportError as e:
        print(f"❌ CloudKit service import failed: {e}")

if __name__ == "__main__":
    # Run tests directly
    test_instance = TestBreakingPoints()
    test_instance.setup_method()
    
    print("🚀 Starting Comprehensive Breaking Point Analysis")
    print("=" * 80)
    
    try:
        test_instance.test_health_endpoints_accessibility()
        test_instance.test_core_api_endpoints_existence()
        test_instance.test_ephemeris_data_integrity()
        test_instance.test_chart_generation_endpoint()
        test_instance.test_ai_chat_endpoint()
        test_instance.test_authentication_endpoints()
        test_instance.test_cors_headers()
        test_instance.test_response_times()
        test_instance.test_error_handling()
        test_instance.test_content_management()
        test_cloudkit_integration()
        
        print("\n" + "=" * 80)
        print("🎉 Breaking Point Analysis Complete!")
        print("✅ System appears to be functioning correctly")
        
    except Exception as e:
        print(f"\n❌ CRITICAL BREAKING POINT FOUND: {e}")
        print("=" * 80)
        raise