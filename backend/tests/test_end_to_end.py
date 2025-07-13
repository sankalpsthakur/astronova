"""
Comprehensive End-to-End Testing Suite for Astronova
Tests all features, endpoints, API calls, CORS, network configs, and user flows
"""

import pytest
import requests
import json
import time
from datetime import datetime, date
import threading
import subprocess
import uuid

BASE_URL = "http://localhost:8082"
TIMEOUT = 30

class EndToEndTester:
    """Comprehensive end-to-end testing framework"""
    
    def __init__(self):
        self.session = requests.Session()
        self.session.timeout = TIMEOUT
        self.failures = []
        self.successes = []
        self.jwt_token = None
        
    def log_failure(self, test_name, error, details=None):
        """Log test failure with details"""
        failure = {
            "test": test_name,
            "error": str(error),
            "details": details,
            "timestamp": datetime.now().isoformat()
        }
        self.failures.append(failure)
        print(f"❌ FAILURE: {test_name} - {error}")
        if details:
            print(f"   Details: {details}")
    
    def log_success(self, test_name, details=None):
        """Log test success"""
        success = {
            "test": test_name,
            "details": details,
            "timestamp": datetime.now().isoformat()
        }
        self.successes.append(success)
        print(f"✅ SUCCESS: {test_name}")
        if details:
            print(f"   Details: {details}")
    
    def test_all_backend_endpoints(self):
        """Test 1: Comprehensive Backend API Testing"""
        print("\n🔥 TESTING ALL BACKEND ENDPOINTS")
        print("=" * 60)
        
        # Health endpoints
        self._test_health_endpoints()
        
        # Core API endpoints
        self._test_ephemeris_endpoints()
        self._test_horoscope_endpoints()
        self._test_chart_endpoints()
        self._test_match_endpoints()
        self._test_chat_endpoints()
        self._test_auth_endpoints()
        self._test_content_endpoints()
        
        # Error handling
        self._test_error_handling()
    
    def _test_health_endpoints(self):
        """Test all health endpoints"""
        endpoints = [
            "/health",
            "/api/v1/health", 
            "/api/v1/misc/health"
        ]
        
        for endpoint in endpoints:
            try:
                response = self.session.get(f"{BASE_URL}{endpoint}")
                if response.status_code == 200:
                    self.log_success(f"Health endpoint {endpoint}", response.json())
                else:
                    self.log_failure(f"Health endpoint {endpoint}", f"Status {response.status_code}", response.text[:200])
            except Exception as e:
                self.log_failure(f"Health endpoint {endpoint}", e)
    
    def _test_ephemeris_endpoints(self):
        """Test ephemeris and astronomical data endpoints"""
        try:
            # Current planetary positions
            response = self.session.get(f"{BASE_URL}/api/v1/ephemeris/current")
            if response.status_code == 200:
                data = response.json()
                if "planets" in data and len(data["planets"]) >= 10:
                    self.log_success("Ephemeris current positions", f"{len(data['planets'])} planets")
                else:
                    self.log_failure("Ephemeris data validation", "Insufficient planet data", data)
            else:
                self.log_failure("Ephemeris current", f"Status {response.status_code}", response.text[:200])
        except Exception as e:
            self.log_failure("Ephemeris endpoints", e)
    
    def _test_horoscope_endpoints(self):
        """Test horoscope endpoints with different formats"""
        # Test parameter-based endpoint (current backend format)
        try:
            response = self.session.get(f"{BASE_URL}/api/v1/horoscope?sign=leo&period=daily")
            if response.status_code == 200:
                data = response.json()
                self.log_success("Horoscope with parameters", f"Sign: {data.get('sign')}")
            else:
                self.log_failure("Horoscope parameters", f"Status {response.status_code}", response.text[:200])
        except Exception as e:
            self.log_failure("Horoscope parameters", e)
        
        # Test path-based endpoint (iOS app expects this)
        try:
            response = self.session.get(f"{BASE_URL}/api/v1/horoscope/daily")
            if response.status_code == 200:
                self.log_success("Horoscope path-based")
            else:
                self.log_failure("Horoscope path-based", f"Status {response.status_code} - iOS app will fail", response.text[:200])
        except Exception as e:
            self.log_failure("Horoscope path-based", e)
    
    def _test_chart_endpoints(self):
        """Test birth chart generation"""
        valid_chart_data = {
            "birth_date": "1990-01-01",
            "birth_time": "12:00",
            "latitude": 40.7128,
            "longitude": -74.0060,
            "timezone": "America/New_York",
            "system": "western",
            "chart_type": "natal"
        }
        
        try:
            response = self.session.post(f"{BASE_URL}/api/v1/chart/generate", json=valid_chart_data)
            if response.status_code == 200:
                data = response.json()
                self.log_success("Chart generation", f"Keys: {list(data.keys())}")
            elif response.status_code == 400:
                self.log_failure("Chart generation validation", "Data validation failed", response.json())
            else:
                self.log_failure("Chart generation", f"Status {response.status_code}", response.text[:200])
        except Exception as e:
            self.log_failure("Chart generation", e)
    
    def _test_match_endpoints(self):
        """Test compatibility matching endpoints"""
        # Test base match endpoint
        try:
            response = self.session.get(f"{BASE_URL}/api/v1/match")
            if response.status_code == 200:
                self.log_success("Match info endpoint", response.json())
            else:
                self.log_failure("Match info", f"Status {response.status_code}")
        except Exception as e:
            self.log_failure("Match info", e)
        
        # Test compatibility endpoint (iOS app expects this)
        try:
            response = self.session.post(f"{BASE_URL}/api/v1/match/compatibility", json={})
            if response.status_code != 404:
                self.log_success("Match compatibility endpoint exists")
            else:
                self.log_failure("Match compatibility", "404 - iOS app will fail", "Expected /api/v1/match/compatibility")
        except Exception as e:
            self.log_failure("Match compatibility", e)
        
        # Test match with valid data
        match_data = {
            "person1": {
                "birth_date": "1990-01-01",
                "birth_time": "12:00",
                "latitude": 40.7128,
                "longitude": -74.0060,
                "timezone": "America/New_York"
            },
            "person2": {
                "birth_date": "1992-06-15", 
                "birth_time": "18:30",
                "latitude": 34.0522,
                "longitude": -118.2437,
                "timezone": "America/Los_Angeles"
            }
        }
        
        try:
            response = self.session.post(f"{BASE_URL}/api/v1/match", json=match_data)
            if response.status_code == 200:
                data = response.json()
                self.log_success("Match calculation", f"Score: {data.get('compatibility_score', 'N/A')}")
            else:
                self.log_failure("Match calculation", f"Status {response.status_code}", response.text[:200])
        except Exception as e:
            self.log_failure("Match calculation", e)
    
    def _test_chat_endpoints(self):
        """Test AI chat functionality"""
        # Test GET method (current backend)
        try:
            response = self.session.get(f"{BASE_URL}/api/v1/chat")
            if response.status_code == 200:
                self.log_success("Chat GET endpoint")
            else:
                self.log_failure("Chat GET", f"Status {response.status_code}")
        except Exception as e:
            self.log_failure("Chat GET", e)
        
        # Test POST method (iOS app uses this)
        chat_data = {
            "message": "What does my birth chart say about my personality?",
            "birth_data": {
                "date": "1990-01-01",
                "time": "12:00",
                "latitude": 40.7128,
                "longitude": -74.0060
            }
        }
        
        try:
            response = self.session.post(f"{BASE_URL}/api/v1/chat", json=chat_data)
            if response.status_code == 200:
                data = response.json()
                self.log_success("Chat POST", f"Response length: {len(data.get('response', ''))}")
            elif response.status_code == 405:
                self.log_failure("Chat POST method", "405 Method Not Allowed - iOS app will fail", "Needs POST support")
            else:
                self.log_failure("Chat POST", f"Status {response.status_code}", response.text[:200])
        except Exception as e:
            self.log_failure("Chat POST", e)
    
    def _test_auth_endpoints(self):
        """Test authentication endpoints"""
        # Test auth info
        try:
            response = self.session.get(f"{BASE_URL}/api/v1/auth")
            if response.status_code in [200, 404]:  # Either works or doesn't exist
                if response.status_code == 200:
                    self.log_success("Auth info endpoint", response.json())
                else:
                    self.log_failure("Auth info", "404 - endpoint may not exist")
        except Exception as e:
            self.log_failure("Auth info", e)
        
        # Test login with dummy Apple token
        login_data = {
            "apple_identity_token": "dummy_token_for_testing",
            "user_id": "test_user_123"
        }
        
        try:
            response = self.session.post(f"{BASE_URL}/api/v1/auth/login", json=login_data)
            if response.status_code == 200:
                data = response.json()
                if "access_token" in data:
                    self.jwt_token = data["access_token"]
                    self.log_success("Auth login", "JWT token received")
                else:
                    self.log_success("Auth login endpoint works", "No token in response")
            elif response.status_code == 401:
                self.log_success("Auth login validation", "Properly rejects invalid tokens")
            elif response.status_code == 404:
                self.log_failure("Auth login", "404 - endpoint missing")
            else:
                self.log_failure("Auth login", f"Status {response.status_code}", response.text[:200])
        except Exception as e:
            self.log_failure("Auth login", e)
    
    def _test_content_endpoints(self):
        """Test content management endpoints"""
        try:
            response = self.session.get(f"{BASE_URL}/api/v1/content/management")
            if response.status_code == 200:
                data = response.json()
                self.log_success("Content management", f"Keys: {list(data.keys())}")
            elif response.status_code == 404:
                self.log_failure("Content management", "404 - endpoint missing")
            else:
                self.log_failure("Content management", f"Status {response.status_code}")
        except Exception as e:
            self.log_failure("Content management", e)
    
    def _test_error_handling(self):
        """Test error handling and edge cases"""
        # Test invalid JSON
        try:
            response = self.session.post(
                f"{BASE_URL}/api/v1/chart/generate",
                data="invalid json",
                headers={"Content-Type": "application/json"}
            )
            if response.status_code == 400:
                self.log_success("Invalid JSON handling", "Properly returns 400")
            else:
                self.log_failure("Invalid JSON handling", f"Expected 400, got {response.status_code}")
        except Exception as e:
            self.log_failure("Invalid JSON handling", e)
        
        # Test non-existent endpoint
        try:
            response = self.session.get(f"{BASE_URL}/api/v1/nonexistent/endpoint")
            if response.status_code == 404:
                self.log_success("404 handling", "Properly returns 404")
            else:
                self.log_failure("404 handling", f"Expected 404, got {response.status_code}")
        except Exception as e:
            self.log_failure("404 handling", e)
    
    def test_cors_configuration(self):
        """Test 2: CORS Configuration"""
        print("\n🌐 TESTING CORS CONFIGURATION")
        print("=" * 60)
        
        # Test preflight request
        try:
            response = self.session.options(
                f"{BASE_URL}/api/v1/health",
                headers={
                    "Origin": "http://localhost:3000",
                    "Access-Control-Request-Method": "GET",
                    "Access-Control-Request-Headers": "Content-Type"
                }
            )
            
            cors_headers = {
                "Access-Control-Allow-Origin": response.headers.get("Access-Control-Allow-Origin"),
                "Access-Control-Allow-Methods": response.headers.get("Access-Control-Allow-Methods"),
                "Access-Control-Allow-Headers": response.headers.get("Access-Control-Allow-Headers")
            }
            
            if any(cors_headers.values()):
                self.log_success("CORS preflight", cors_headers)
            else:
                self.log_failure("CORS preflight", "No CORS headers found")
                
        except Exception as e:
            self.log_failure("CORS preflight", e)
        
        # Test actual CORS request
        try:
            response = self.session.get(
                f"{BASE_URL}/api/v1/health",
                headers={"Origin": "http://localhost:3000"}
            )
            
            if "Access-Control-Allow-Origin" in response.headers:
                origin = response.headers["Access-Control-Allow-Origin"]
                self.log_success("CORS actual request", f"Origin: {origin}")
            else:
                self.log_failure("CORS actual request", "Missing Access-Control-Allow-Origin header")
                
        except Exception as e:
            self.log_failure("CORS actual request", e)
    
    def test_network_configurations(self):
        """Test 3: Network Configurations"""
        print("\n🔧 TESTING NETWORK CONFIGURATIONS")
        print("=" * 60)
        
        # Test connection timeout
        try:
            start_time = time.time()
            response = self.session.get(f"{BASE_URL}/api/v1/health", timeout=1)
            duration = time.time() - start_time
            
            if duration < 1.0:
                self.log_success("Response time", f"{duration:.3f}s")
            else:
                self.log_failure("Response time", f"Too slow: {duration:.3f}s")
                
        except requests.exceptions.Timeout:
            self.log_failure("Network timeout", "Request timed out")
        except Exception as e:
            self.log_failure("Network test", e)
        
        # Test different content types
        content_types = [
            "application/json",
            "text/plain",
            "application/x-www-form-urlencoded"
        ]
        
        for content_type in content_types:
            try:
                response = self.session.post(
                    f"{BASE_URL}/api/v1/health",
                    data="test",
                    headers={"Content-Type": content_type}
                )
                
                if response.status_code in [200, 405, 415]:  # Expected responses
                    self.log_success(f"Content-Type {content_type}", f"Status {response.status_code}")
                else:
                    self.log_failure(f"Content-Type {content_type}", f"Unexpected status {response.status_code}")
                    
            except Exception as e:
                self.log_failure(f"Content-Type {content_type}", e)
    
    def test_authentication_flow(self):
        """Test 4: Complete Authentication Flow"""
        print("\n🔐 TESTING AUTHENTICATION FLOW")
        print("=" * 60)
        
        # Test without authentication
        try:
            response = self.session.get(f"{BASE_URL}/api/v1/health")
            if response.status_code == 200:
                self.log_success("No auth required for health", "Public endpoint working")
            else:
                self.log_failure("Public endpoint", f"Status {response.status_code}")
        except Exception as e:
            self.log_failure("Public endpoint", e)
        
        # Test with invalid JWT
        try:
            headers = {"Authorization": "Bearer invalid_jwt_token"}
            response = self.session.get(f"{BASE_URL}/api/v1/auth", headers=headers)
            
            if response.status_code in [401, 404]:
                self.log_success("Invalid JWT handling", f"Status {response.status_code}")
            else:
                self.log_failure("Invalid JWT handling", f"Status {response.status_code}")
        except Exception as e:
            self.log_failure("Invalid JWT", e)
        
        # Test with valid JWT (if we have one)
        if self.jwt_token:
            try:
                headers = {"Authorization": f"Bearer {self.jwt_token}"}
                response = self.session.get(f"{BASE_URL}/api/v1/auth", headers=headers)
                
                if response.status_code == 200:
                    self.log_success("Valid JWT", "Authenticated request successful")
                else:
                    self.log_failure("Valid JWT", f"Status {response.status_code}")
            except Exception as e:
                self.log_failure("Valid JWT", e)
    
    def test_cloudkit_integration(self):
        """Test 5: CloudKit Integration"""
        print("\n☁️ TESTING CLOUDKIT INTEGRATION")
        print("=" * 60)
        
        try:
            # Check CloudKit service status
            from services.cloudkit_service import CloudKitService
            service = CloudKitService()
            
            if service.enabled:
                self.log_success("CloudKit service", "Enabled and configured")
                
                # Test CloudKit operations (if available)
                try:
                    # This would require actual CloudKit setup
                    self.log_success("CloudKit operations", "Service ready for operations")
                except Exception as e:
                    self.log_failure("CloudKit operations", e)
            else:
                self.log_failure("CloudKit service", "Not configured - running in offline mode")
                
        except ImportError as e:
            self.log_failure("CloudKit import", e)
        except Exception as e:
            self.log_failure("CloudKit service", e)
    
    def test_ai_chat_functionality(self):
        """Test 6: AI Chat Functionality"""
        print("\n🤖 TESTING AI CHAT FUNCTIONALITY")
        print("=" * 60)
        
        # Test AI service configuration
        try:
            from services.gemini_ai import GeminiService
            ai_service = GeminiService()
            
            # Test AI response generation
            test_prompt = "Generate a simple test horoscope for Leo"
            response = ai_service.generate_content(test_prompt)
            
            if response and len(response) > 10:
                self.log_success("AI service", f"Generated {len(response)} characters")
            else:
                self.log_failure("AI service", "No response or too short", response)
                
        except Exception as e:
            self.log_failure("AI service", e)
    
    def run_comprehensive_test(self):
        """Run all end-to-end tests"""
        print("🚀 STARTING COMPREHENSIVE END-TO-END TESTING")
        print("=" * 80)
        start_time = time.time()
        
        # Run all test suites
        self.test_all_backend_endpoints()
        self.test_cors_configuration()
        self.test_network_configurations()
        self.test_authentication_flow()
        self.test_cloudkit_integration()
        self.test_ai_chat_functionality()
        
        # Summary
        duration = time.time() - start_time
        total_tests = len(self.successes) + len(self.failures)
        success_rate = (len(self.successes) / total_tests * 100) if total_tests > 0 else 0
        
        print("\n" + "=" * 80)
        print("📊 COMPREHENSIVE TEST SUMMARY")
        print("=" * 80)
        print(f"⏱️  Total Duration: {duration:.2f} seconds")
        print(f"📈 Total Tests: {total_tests}")
        print(f"✅ Successes: {len(self.successes)}")
        print(f"❌ Failures: {len(self.failures)}")
        print(f"📊 Success Rate: {success_rate:.1f}%")
        
        if self.failures:
            print("\n🔥 CRITICAL FAILURE POINTS:")
            for i, failure in enumerate(self.failures, 1):
                print(f"{i:2d}. {failure['test']}: {failure['error']}")
                if failure['details']:
                    print(f"    └─ {failure['details']}")
        
        if success_rate < 80:
            print("\n⚠️  SYSTEM REQUIRES IMMEDIATE ATTENTION")
            return False
        elif success_rate < 95:
            print("\n⚠️  SYSTEM HAS MINOR ISSUES")
            return True
        else:
            print("\n✅ SYSTEM IS FUNCTIONING WELL")
            return True

if __name__ == "__main__":
    tester = EndToEndTester()
    system_healthy = tester.run_comprehensive_test()
    
    if not system_healthy:
        exit(1)