#!/usr/bin/env python3
"""
Debug CloudKit Authentication
Test script to debug CloudKit Web Services authentication issues.
"""

import os
import sys
import json
import time
import requests
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend
import jwt

def test_cloudkit_auth():
    """Test CloudKit authentication step by step"""
    print("🔐 Debugging CloudKit Authentication")
    print("=" * 50)
    
    # Environment variables
    key_id = os.getenv('CLOUDKIT_KEY_ID')
    team_id = os.getenv('CLOUDKIT_TEAM_ID') 
    private_key_path = os.getenv('CLOUDKIT_PRIVATE_KEY_PATH')
    environment = os.getenv('CLOUDKIT_ENVIRONMENT', 'development')
    
    print(f"Key ID: {key_id}")
    print(f"Team ID: {team_id}")
    print(f"Private Key Path: {private_key_path}")
    print(f"Environment: {environment}")
    
    if not all([key_id, team_id, private_key_path]):
        print("❌ Missing environment variables")
        return False
        
    # Load private key
    print(f"\n📁 Loading private key from: {private_key_path}")
    try:
        with open(private_key_path, 'rb') as key_file:
            private_key = serialization.load_pem_private_key(
                key_file.read(),
                password=None,
                backend=default_backend()
            )
        print("✅ Private key loaded successfully")
    except Exception as e:
        print(f"❌ Failed to load private key: {e}")
        return False
    
    # Generate JWT token
    print(f"\n🎫 Generating JWT token...")
    try:
        now = int(time.time())
        headers = {
            'alg': 'ES256',
            'kid': key_id
        }
        
        payload = {
            'iss': team_id,
            'iat': now,
            'exp': now + 3600,
            'aud': 'https://api.apple-cloudkit.com',
            'sub': 'iCloud.com.sankalp.AstronovaApp'
        }
        
        token = jwt.encode(payload, private_key, algorithm='ES256', headers=headers)
        print("✅ JWT token generated successfully")
        print(f"Token length: {len(token)} characters")
        
        # Decode to verify
        decoded = jwt.decode(token, options={"verify_signature": False})
        print(f"Token payload: {json.dumps(decoded, indent=2)}")
        
    except Exception as e:
        print(f"❌ JWT token generation failed: {e}")
        return False
    
    # Test CloudKit API call
    print(f"\n🌐 Testing CloudKit API call...")
    try:
        # Try the public database first as it requires less permissions
        url = f"https://api.apple-cloudkit.com/database/1/iCloud.com.sankalp.AstronovaApp/{environment}/public/zones/list"
        
        headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json',
            'User-Agent': 'AstronovaBackend/1.0'
        }
        
        print(f"URL: {url}")
        print(f"Headers: {json.dumps(dict(headers), indent=2)}")
        
        response = requests.post(url, headers=headers, json={})
        
        print(f"Response Status: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")
        print(f"Response Body: {response.text}")
        
        if response.status_code == 200:
            print("✅ CloudKit API call successful!")
            
            # Now try private database
            print(f"\n🔒 Testing private database access...")
            private_url = f"https://api.apple-cloudkit.com/database/1/iCloud.com.sankalp.AstronovaApp/{environment}/private/zones/list"
            private_response = requests.post(private_url, headers=headers, json={})
            print(f"Private DB Response Status: {private_response.status_code}")
            print(f"Private DB Response: {private_response.text}")
            
            return True
        else:
            print(f"❌ CloudKit API call failed with status {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ CloudKit API call failed: {e}")
        return False

if __name__ == "__main__":
    success = test_cloudkit_auth()
    if success:
        print("\n🎉 CloudKit authentication is working!")
    else:
        print("\n❌ CloudKit authentication failed")
    sys.exit(0 if success else 1)