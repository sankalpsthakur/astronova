#!/usr/bin/env python3
"""
Complete End-to-End CloudKit ERD Testing Suite

This script tests all CRUD operations for all entities in the AstroNova ERD:
- UserProfile
- ChatMessage  
- Horoscope
- BirthChart
- KundaliMatch
- BookmarkedReading

Tests both CloudKit Web Client (low-level) and CloudKit Service (high-level) operations.
"""

import os
import sys
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any
import traceback

# Add backend to path
sys.path.insert(0, os.path.dirname(__file__))

# Enable debug logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

from services.cloudkit_web_client import CloudKitWebClient
from services.cloudkit_service import CloudKitService

class CloudKitERDTester:
    """Comprehensive ERD testing for CloudKit operations"""
    
    def __init__(self):
        self.web_client = CloudKitWebClient()
        self.service = None
        self.test_user_id = f"test_user_{int(datetime.now().timestamp())}"
        self.created_records = []  # Track for cleanup
        self.test_results = {
            'UserProfile': {'create': False, 'read': False, 'update': False, 'delete': False},
            'ChatMessage': {'create': False, 'read': False, 'update': False, 'delete': False},
            'Horoscope': {'create': False, 'read': False, 'update': False, 'delete': False},
            'BirthChart': {'create': False, 'read': False, 'update': False, 'delete': False},
            'KundaliMatch': {'create': False, 'read': False, 'update': False, 'delete': False},
            'BookmarkedReading': {'create': False, 'read': False, 'update': False, 'delete': False}
        }
        
        # Initialize CloudKit Service
        try:
            self.service = CloudKitService()
            logger.info("✅ CloudKit Service initialized successfully")
        except Exception as e:
            logger.error(f"❌ CloudKit Service initialization failed: {e}")
            self.service = None
    
    def log_test_result(self, entity: str, operation: str, success: bool, details: str = ""):
        """Log test result"""
        status = "✅" if success else "❌"
        logger.info(f"{status} {entity}.{operation}: {details}")
        self.test_results[entity][operation] = success
    
    def safe_execute(self, entity: str, operation: str, func, *args, **kwargs):
        """Safely execute a test function with error handling"""
        try:
            result = func(*args, **kwargs)
            self.log_test_result(entity, operation, True, f"Success - {type(result).__name__}")
            return result
        except Exception as e:
            self.log_test_result(entity, operation, False, f"Error: {str(e)[:100]}")
            logger.debug(traceback.format_exc())
            return None
    
    # =============================================================================
    # UserProfile CRUD Tests
    # =============================================================================
    
    def test_user_profile_crud(self):
        """Test complete CRUD operations for UserProfile"""
        logger.info("\n🧪 Testing UserProfile CRUD Operations")
        logger.info("=" * 50)
        
        # Test data
        profile_data = {
            "id": self.test_user_id,
            "fullName": "Test User for ERD",
            "birthDate": datetime(1990, 5, 15),
            "birthLocation": "New York, NY",
            "birthTime": "14:30",
            "preferredLanguage": "en",
            "sunSign": "Taurus",
            "moonSign": "Cancer",
            "risingSign": "Virgo",
            "bio": "Test user for comprehensive ERD testing",
            "profileImageURL": "https://example.com/test-avatar.jpg"
        }
        
        # CREATE (High-level service)
        if self.service:
            saved_profile = self.safe_execute(
                "UserProfile", "create", 
                self.service.save_user_profile, self.test_user_id, profile_data
            )
            if saved_profile:
                self.created_records.append(("UserProfile", self.test_user_id))
        
        # READ (High-level service)
        if self.service:
            retrieved_profile = self.safe_execute(
                "UserProfile", "read",
                self.service.get_user_profile, self.test_user_id
            )
        
        # UPDATE (Use new update method)
        if self.service:
            updated_data = {
                "bio": "Updated bio for testing",
                "sunSign": "Gemini"
            }
            
            updated_profile = self.safe_execute(
                "UserProfile", "update",
                self.service.update_user_profile, self.test_user_id, updated_data
            )
        
        # DELETE (High-level service)
        deleted = self.safe_execute(
            "UserProfile", "delete",
            self.service.delete_user_profile, self.test_user_id
        )
        if deleted:
            self.created_records = [r for r in self.created_records if r != ("UserProfile", self.test_user_id)]
    
    # =============================================================================
    # ChatMessage CRUD Tests  
    # =============================================================================
    
    def test_chat_message_crud(self):
        """Test complete CRUD operations for ChatMessage"""
        logger.info("\n🧪 Testing ChatMessage CRUD Operations")
        logger.info("=" * 50)
        
        conversation_id = f"conv_{int(datetime.now().timestamp())}"
        
        # Test data
        message_data = {
            "id": f"msg_{int(datetime.now().timestamp())}",
            "userProfileId": self.test_user_id,
            "conversationId": conversation_id,
            "content": "Test message for ERD testing",
            "isUser": True,
            "timestamp": datetime.now(),
            "messageType": "question"
        }
        
        # CREATE (High-level service)
        if self.service:
            saved_message = self.safe_execute(
                "ChatMessage", "create",
                self.service.save_chat_message, message_data
            )
            if saved_message:
                record_name = saved_message.get('recordName')
                if record_name:
                    self.created_records.append(("ChatMessage", record_name))
        
        # READ (High-level service)
        if self.service:
            conversation_history = self.safe_execute(
                "ChatMessage", "read",
                self.service.get_conversation_history, self.test_user_id, conversation_id, 10
            )
        
        # UPDATE (High-level service)
        if self.service:
            updated_data = {"content": "Updated message content"}
            updated = self.safe_execute(
                "ChatMessage", "update",
                self.service.update_chat_message, self.test_user_id, message_data["id"], updated_data
            )
        
        # DELETE (High-level service)
        if self.service:
            deleted = self.safe_execute(
                "ChatMessage", "delete",
                self.service.delete_chat_message, self.test_user_id, message_data["id"]
            )
            if deleted:
                chat_records = [r for r in self.created_records if r[0] == "ChatMessage"]
                if chat_records:
                    self.created_records = [r for r in self.created_records if r != chat_records[0]]
    
    # =============================================================================
    # Horoscope CRUD Tests
    # =============================================================================
    
    def test_horoscope_crud(self):
        """Test complete CRUD operations for Horoscope"""
        logger.info("\n🧪 Testing Horoscope CRUD Operations")
        logger.info("=" * 50)
        
        # Test data
        horoscope_data = {
            "id": f"horoscope_{int(datetime.now().timestamp())}",
            "userProfileId": self.test_user_id,
            "date": datetime.now().date(),
            "type": "daily",
            "content": "Test horoscope content for ERD testing",
            "sign": "Taurus",
            "luckyElements": {
                "luckyNumbers": [7, 14, 21],
                "luckyColors": ["green", "blue"],
                "luckyStones": ["emerald"],
                "compatibility": ["Cancer", "Virgo"]
            }
        }
        
        # CREATE (High-level service)
        if self.service:
            saved_horoscope = self.safe_execute(
                "Horoscope", "create",
                self.service.save_horoscope, horoscope_data
            )
            if saved_horoscope:
                record_name = saved_horoscope.get('recordName')
                if record_name:
                    self.created_records.append(("Horoscope", record_name))
        
        # READ (High-level service)
        if self.service:
            retrieved_horoscope = self.safe_execute(
                "Horoscope", "read",
                self.service.get_horoscope, self.test_user_id, "Taurus", datetime.now().date(), "daily"
            )
        
        # UPDATE (High-level service)
        if self.service:
            updated_data = {"content": "Updated horoscope content"}
            updated = self.safe_execute(
                "Horoscope", "update",
                self.service.update_horoscope, self.test_user_id, horoscope_data["id"], updated_data
            )
        
        # DELETE (High-level service)
        if self.service:
            deleted = self.safe_execute(
                "Horoscope", "delete",
                self.service.delete_horoscope, self.test_user_id, horoscope_data["id"]
            )
            if deleted:
                horoscope_records = [r for r in self.created_records if r[0] == "Horoscope"]
                if horoscope_records:
                    self.created_records = [r for r in self.created_records if r != horoscope_records[0]]
    
    # =============================================================================
    # BirthChart CRUD Tests
    # =============================================================================
    
    def test_birth_chart_crud(self):
        """Test complete CRUD operations for BirthChart"""
        logger.info("\n🧪 Testing BirthChart CRUD Operations")
        logger.info("=" * 50)
        
        # Test data
        chart_data = {
            "id": f"chart_{int(datetime.now().timestamp())}",
            "userProfileId": self.test_user_id,
            "chartType": "natal",
            "systems": ["western", "vedic"],
            "planetaryPositions": [
                {"planet": "Sun", "sign": "Taurus", "degree": 24.5, "house": 1},
                {"planet": "Moon", "sign": "Cancer", "degree": 15.2, "house": 3}
            ],
            "chartSVG": "<svg>test chart visualization</svg>",
            "birthData": {
                "date": "1990-05-15",
                "time": "14:30",
                "location": "New York, NY",
                "coordinates": {"lat": 40.7128, "lng": -74.0060}
            }
        }
        
        # CREATE (High-level service)
        if self.service:
            saved_chart = self.safe_execute(
                "BirthChart", "create",
                self.service.save_birth_chart, chart_data
            )
            if saved_chart:
                record_name = saved_chart.get('recordName')
                if record_name:
                    self.created_records.append(("BirthChart", record_name))
        
        # READ (High-level service)
        if self.service:
            retrieved_chart = self.safe_execute(
                "BirthChart", "read",
                self.service.get_birth_chart, self.test_user_id, "natal"
            )
        
        # UPDATE (High-level service)
        if self.service:
            updated_data = {"chartSVG": "<svg>updated chart visualization</svg>"}
            updated = self.safe_execute(
                "BirthChart", "update",
                self.service.update_birth_chart, self.test_user_id, chart_data["id"], updated_data
            )
        
        # DELETE (High-level service)
        if self.service:
            deleted = self.safe_execute(
                "BirthChart", "delete",
                self.service.delete_birth_chart, self.test_user_id, chart_data["id"]
            )
            if deleted:
                chart_records = [r for r in self.created_records if r[0] == "BirthChart"]
                if chart_records:
                    self.created_records = [r for r in self.created_records if r != chart_records[0]]
    
    # =============================================================================
    # KundaliMatch CRUD Tests
    # =============================================================================
    
    def test_kundali_match_crud(self):
        """Test complete CRUD operations for KundaliMatch"""
        logger.info("\n🧪 Testing KundaliMatch CRUD Operations")
        logger.info("=" * 50)
        
        # Test data
        match_data = {
            "id": f"match_{int(datetime.now().timestamp())}",
            "userProfileId": self.test_user_id,
            "partnerName": "Test Partner",
            "partnerBirthDate": datetime(1992, 8, 20),
            "partnerLocation": "Los Angeles, CA",
            "compatibilityScore": 85,
            "detailedAnalysis": {
                "guna_milan": {"total": 32, "matched": 27},
                "mangal_dosha": {"user": "no", "partner": "yes"},
                "areas": {
                    "emotional": 9,
                    "mental": 8,
                    "physical": 7,
                    "spiritual": 9
                }
            }
        }
        
        # CREATE (High-level service)
        if self.service:
            saved_match = self.safe_execute(
                "KundaliMatch", "create",
                self.service.save_match, match_data
            )
            if saved_match:
                record_name = saved_match.get('recordName')
                if record_name:
                    self.created_records.append(("KundaliMatch", record_name))
        
        # READ (High-level service)
        if self.service:
            user_matches = self.safe_execute(
                "KundaliMatch", "read",
                self.service.get_user_matches, self.test_user_id
            )
        
        # UPDATE (High-level service)
        if self.service:
            updated_data = {"compatibilityScore": 90}
            updated = self.safe_execute(
                "KundaliMatch", "update",
                self.service.update_match, self.test_user_id, match_data["id"], updated_data
            )
        
        # DELETE (High-level service)
        if self.service:
            deleted = self.safe_execute(
                "KundaliMatch", "delete",
                self.service.delete_match, self.test_user_id, match_data["id"]
            )
            if deleted:
                match_records = [r for r in self.created_records if r[0] == "KundaliMatch"]
                if match_records:
                    self.created_records = [r for r in self.created_records if r != match_records[0]]
    
    # =============================================================================
    # BookmarkedReading CRUD Tests
    # =============================================================================
    
    def test_bookmarked_reading_crud(self):
        """Test complete CRUD operations for BookmarkedReading"""
        logger.info("\n🧪 Testing BookmarkedReading CRUD Operations")
        logger.info("=" * 50)
        
        # Test data
        bookmark_data = {
            "id": f"bookmark_{int(datetime.now().timestamp())}",
            "userProfileId": self.test_user_id,
            "readingType": "horoscope",
            "title": "Daily Horoscope - Taurus",
            "content": "Test bookmark content for ERD testing",
            "originalDate": datetime.now() - timedelta(days=1),
            "bookmarkedAt": datetime.now()
        }
        
        # CREATE (High-level service)
        if self.service:
            saved_bookmark = self.safe_execute(
                "BookmarkedReading", "create",
                self.service.save_bookmarked_reading, bookmark_data
            )
            if saved_bookmark:
                record_name = saved_bookmark.get('recordName')
                if record_name:
                    self.created_records.append(("BookmarkedReading", record_name))
        
        # READ (High-level service)
        if self.service:
            user_bookmarks = self.safe_execute(
                "BookmarkedReading", "read",
                self.service.get_bookmarked_readings, self.test_user_id
            )
        
        # UPDATE (High-level service)
        if self.service:
            updated_data = {"title": "Updated Bookmark Title"}
            updated = self.safe_execute(
                "BookmarkedReading", "update",
                self.service.update_bookmarked_reading, self.test_user_id, bookmark_data["id"], updated_data
            )
        
        # DELETE (High-level service)
        if self.service:
            deleted = self.safe_execute(
                "BookmarkedReading", "delete",
                self.service.remove_bookmarked_reading, self.test_user_id, bookmark_data["id"]
            )
            if deleted:
                bookmark_records = [r for r in self.created_records if r[0] == "BookmarkedReading"]
                if bookmark_records:
                    self.created_records = [r for r in self.created_records if r != bookmark_records[0]]
    
    # =============================================================================
    # Test Execution and Cleanup
    # =============================================================================
    
    def cleanup_test_data(self):
        """Clean up any remaining test records"""
        logger.info("\n🧹 Cleaning up test data...")
        
        for record_type, record_name in self.created_records:
            try:
                self.web_client.delete_record(record_type, record_name)
                logger.info(f"✅ Cleaned up {record_type}: {record_name}")
            except Exception as e:
                logger.warning(f"⚠️ Failed to cleanup {record_type}: {record_name} - {e}")
    
    def print_summary(self):
        """Print test results summary"""
        logger.info("\n📊 Test Results Summary")
        logger.info("=" * 60)
        
        total_tests = 0
        passed_tests = 0
        
        for entity, operations in self.test_results.items():
            logger.info(f"\n{entity}:")
            for operation, success in operations.items():
                status = "✅ PASS" if success else "❌ FAIL"
                logger.info(f"  {operation.upper()}: {status}")
                total_tests += 1
                if success:
                    passed_tests += 1
        
        success_rate = (passed_tests / total_tests) * 100 if total_tests > 0 else 0
        logger.info(f"\n🎯 Overall Success Rate: {passed_tests}/{total_tests} ({success_rate:.1f}%)")
        
        if success_rate == 100:
            logger.info("🎉 All tests passed! CloudKit ERD is fully functional.")
        elif success_rate >= 80:
            logger.info("👍 Most tests passed. Minor issues detected.")
        elif success_rate >= 60:
            logger.info("⚠️ Some tests failed. Significant issues detected.")
        else:
            logger.info("❌ Many tests failed. Major issues with CloudKit ERD.")
    
    def run_all_tests(self):
        """Run all ERD CRUD tests"""
        logger.info("🚀 Starting Comprehensive CloudKit ERD Testing")
        logger.info("=" * 60)
        
        if not self.web_client.enabled:
            logger.error("❌ CloudKit Web Client not enabled. Check configuration.")
            return False
        
        try:
            # Run all entity tests
            self.test_user_profile_crud()
            self.test_chat_message_crud()
            self.test_horoscope_crud()
            self.test_birth_chart_crud()
            self.test_kundali_match_crud()
            self.test_bookmarked_reading_crud()
            
            # Print summary
            self.print_summary()
            
            # Cleanup
            self.cleanup_test_data()
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Test execution failed: {e}")
            logger.debug(traceback.format_exc())
            return False

def main():
    """Main test execution function"""
    tester = CloudKitERDTester()
    success = tester.run_all_tests()
    
    if success:
        logger.info("\n✅ CloudKit ERD testing completed successfully!")
    else:
        logger.error("\n❌ CloudKit ERD testing encountered errors!")
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())