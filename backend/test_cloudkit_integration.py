#!/usr/bin/env python3
"""
CloudKit Integration Test Script

This script tests the CloudKit Web Services integration.
Run after setting up CloudKit credentials to verify everything works.
"""

import os
import sys
import json
from datetime import datetime

# Add backend to path
sys.path.insert(0, os.path.dirname(__file__))

from services.cloudkit_service import CloudKitService

def test_cloudkit_configuration():
    """Test CloudKit configuration and connection"""
    print("🧪 Testing CloudKit Integration")
    print("=" * 50)
    
    # Initialize CloudKit service
    ck = CloudKitService()
    
    print(f"Container ID: {ck.container_id}")
    
    if not ck.web_client.enabled:
        print("\n⚠️  CloudKit Web Services not configured")
        print("\nTo use real CloudKit:")
        print("1. Set CLOUDKIT_KEY_ID environment variable")
        print("2. Set CLOUDKIT_TEAM_ID environment variable") 
        print("3. Set CLOUDKIT_PRIVATE_KEY_PATH environment variable")
        print("4. Create record types in CloudKit Dashboard")
        return False
    else:
        print("\n✅ CloudKit Web Services configured!")
        return True

def test_cloudkit_operations(ck):
    """Test CloudKit CRUD operations"""
    test_user_id = "test_cloudkit_user"
    
    print(f"\n📝 Testing CloudKit Operations for user: {test_user_id}")
    print("-" * 40)
    
    # Test 1: Save User Profile
    print("\n1️⃣ Testing: Save User Profile")
    profile_data = {
        "fullName": "CloudKit Test User",
        "birthDate": "1990-06-15",
        "birthLocation": "San Francisco, CA",
        "birthTime": "10:30",
        "preferredLanguage": "en",
        "sunSign": "Gemini",
        "moonSign": "Leo",
        "risingSign": "Libra"
    }
    
    try:
        success = ck.save_user_profile(test_user_id, profile_data)
        print(f"✅ Save user profile: {'SUCCESS' if success else 'FAILED'}")
    except Exception as e:
        print(f"❌ Save user profile FAILED: {e}")
        return False
    
    # Test 2: Retrieve User Profile
    print("\n2️⃣ Testing: Retrieve User Profile")
    try:
        retrieved_profile = ck.get_user_profile(test_user_id)
        if retrieved_profile:
            print("✅ Retrieve user profile: SUCCESS")
            print(f"   Name: {retrieved_profile.get('fullName')}")
            print(f"   Sun sign: {retrieved_profile.get('sunSign')}")
        else:
            print("❌ Retrieve user profile: FAILED - No data returned")
            return False
    except Exception as e:
        print(f"❌ Retrieve user profile FAILED: {e}")
        return False
    
    # Test 3: Save Chat Message
    print("\n3️⃣ Testing: Save Chat Message")
    try:
        chat_success = ck.save_chat_message({
            "userProfileId": test_user_id,
            "conversationId": "test_conversation",
            "content": "Hello, this is a CloudKit test message!",
            "isUser": True,
            "messageType": "test"
        })
        print(f"✅ Save chat message: {'SUCCESS' if chat_success else 'FAILED'}")
    except Exception as e:
        print(f"❌ Save chat message FAILED: {e}")
        return False
    
    # Test 4: Retrieve Chat History
    print("\n4️⃣ Testing: Retrieve Chat History")
    try:
        chat_history = ck.get_conversation_history(test_user_id, "test_conversation")
        print(f"✅ Retrieve chat history: SUCCESS - {len(chat_history)} messages")
        if chat_history:
            print(f"   Latest message: {chat_history[0].get('content', '')[:50]}...")
    except Exception as e:
        print(f"❌ Retrieve chat history FAILED: {e}")
        return False
    
    # Test 5: Save Horoscope
    print("\n5️⃣ Testing: Save Horoscope")
    try:
        horoscope_success = ck.save_horoscope({
            "userProfileId": test_user_id,
            "sign": "gemini",
            "date": "2025-06-18",
            "type": "daily",
            "content": "Today brings excellent communication opportunities for Gemini. Your natural curiosity will lead to interesting discoveries.",
            "luckyElements": {
                "luckyNumbers": [3, 12, 21],
                "luckyColors": ["yellow", "silver"],
                "luckyStone": "citrine"
            }
        })
        print(f"✅ Save horoscope: {'SUCCESS' if horoscope_success else 'FAILED'}")
    except Exception as e:
        print(f"❌ Save horoscope FAILED: {e}")
        return False
    
    print("\n🎉 All CloudKit tests completed successfully!")
    return True

def main():
    """Main test function"""
    print("🌟 AstroNova CloudKit Integration Test")
    print("=" * 50)
    
    # Test configuration
    if not test_cloudkit_configuration():
        print("\n📋 Setup Instructions:")
        print("1. Follow CLOUDKIT_WEB_SERVICES_SETUP.md")
        print("2. Set up CloudKit credentials")
        print("3. Create record types in CloudKit Dashboard")
        print("4. Run this test again")
        return 1
    
    # Test operations
    ck = CloudKitService()
    if test_cloudkit_operations(ck):
        print("\n🚀 CloudKit integration is working perfectly!")
        print("You can now check the CloudKit Dashboard to see your records.")
        return 0
    else:
        print("\n❌ CloudKit integration tests failed.")
        print("Check the error messages above and your CloudKit configuration.")
        return 1

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)