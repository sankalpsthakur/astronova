#!/usr/bin/env python3
"""
Test the chat API endpoint with Gemini integration
"""
import requests
import json
import os

def test_chat_endpoint():
    # Test data
    chat_data = {
        "message": "What's my daily horoscope for Aries?",
        "conversationId": "test-123"
    }
    
    headers = {
        "Content-Type": "application/json"
    }
    
    # Test against local server first
    local_url = "http://127.0.0.1:8080/api/v1/chat/send"
    
    print("Testing chat endpoint locally...")
    print(f"URL: {local_url}")
    print(f"Data: {json.dumps(chat_data, indent=2)}")
    
    try:
        response = requests.post(local_url, json=chat_data, headers=headers, timeout=30)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        if response.status_code == 200:
            print("✅ Chat endpoint is working with Gemini!")
        else:
            print("❌ Chat endpoint returned an error")
            
    except requests.exceptions.ConnectionError:
        print("❌ Could not connect to local server. Make sure Flask app is running.")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_chat_endpoint()