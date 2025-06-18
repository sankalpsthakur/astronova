#!/usr/bin/env python3
"""
Test CloudKit Record Save - Debug the INTERNAL_ERROR
"""

import os
import sys
import json
import logging
from datetime import datetime

# Add backend to path
sys.path.insert(0, os.path.dirname(__file__))

# Enable debug logging
logging.basicConfig(level=logging.DEBUG)

from services.cloudkit_web_client import CloudKitWebClient

def test_record_save():
    """Test saving a simple record to CloudKit"""
    print("🧪 Testing CloudKit Record Save")
    print("=" * 40)
    
    client = CloudKitWebClient()
    
    if not client.enabled:
        print("❌ CloudKit not configured")
        return False
    
    print("✅ CloudKit client initialized")
    
    # Try saving a very simple UserProfile record
    print("\n💾 Testing UserProfile record save...")
    
    try:
        # Simple record data
        record_data = {
            "id": "test_user_debug",
            "fullName": "Debug Test User",
            "birthDate": datetime.now(),
            "sunSign": "Gemini"
        }
        
        print(f"Record data: {record_data}")
        
        # Save the record
        result = client.save_record("UserProfile", record_data, "test_user_debug")
        
        print(f"✅ Record saved successfully!")
        print(f"Result: {json.dumps(result, indent=2)}")
        
        return True
        
    except Exception as e:
        print(f"❌ Record save failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_record_save()
    sys.exit(0 if success else 1)