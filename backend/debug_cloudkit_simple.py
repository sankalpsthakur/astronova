#!/usr/bin/env python3
"""
Simple CloudKit Test - Test basic zone listing first
"""

import os
import sys
import json
import time
import base64
import hashlib
from datetime import datetime
import requests
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.backends import default_backend

def test_simple_cloudkit():
    """Test simple CloudKit operation"""
    print("🧪 Simple CloudKit Test")
    print("=" * 40)
    
    # Environment variables
    key_id = os.getenv('CLOUDKIT_KEY_ID')
    private_key_path = os.getenv('CLOUDKIT_PRIVATE_KEY_PATH')
    environment = os.getenv('CLOUDKIT_ENVIRONMENT', 'development')
    
    print(f"Key ID: {key_id}")
    print(f"Private Key Path: {private_key_path}")
    print(f"Environment: {environment}")
    
    # Load private key
    print(f"\n📁 Loading private key...")
    try:
        with open(private_key_path, 'rb') as key_file:
            private_key = serialization.load_pem_private_key(
                key_file.read(),
                password=None,
                backend=default_backend()
            )
        print("✅ Private key loaded")
    except Exception as e:
        print(f"❌ Failed to load private key: {e}")
        return False
    
    # Test zone listing (simplest operation)
    print(f"\n🌐 Testing zone listing...")
    try:
        iso_date = datetime.now().strftime('%Y-%m-%dT%H:%M:%SZ')
        endpoint = "zones/list"
        method = "POST"
        request_path = f"/database/1/iCloud.com.sankalp.AstronovaApp/{environment}/private/{endpoint}"
        
        # Calculate body hash (SHA-256 then base64) - empty for zone listing
        request_body = ""
        body_hash = base64.b64encode(hashlib.sha256(request_body.encode()).digest()).decode()
        
        # Create subpath (URL path without base CloudKit API URL) - try public database
        subpath = f"/database/1/iCloud.com.sankalp.AstronovaApp/{environment}/public/{endpoint}"
        
        # Create canonical request string: "{iso_date}:{body_hash}:{subpath}"
        canonical_request = f"{iso_date}:{body_hash}:{subpath}"
        print(f"Canonical request: {canonical_request}")
        
        # Sign the request
        signature = private_key.sign(
            canonical_request.encode('utf-8'),
            ec.ECDSA(hashes.SHA256())
        )
        signature_b64 = base64.b64encode(signature).decode('utf-8')
        
        # Make the request - use public database URL
        url = f"https://api.apple-cloudkit.com{subpath}"
        headers = {
            'Content-Type': 'application/json',
            'X-Apple-CloudKit-Request-KeyID': key_id,
            'X-Apple-CloudKit-Request-ISO8601Date': iso_date,
            'X-Apple-CloudKit-Request-SignatureV1': signature_b64
        }
        
        print(f"URL: {url}")
        print(f"Headers: {json.dumps(dict(headers), indent=2)}")
        
        response = requests.post(url, headers=headers, json={})
        
        print(f"Response Status: {response.status_code}")
        print(f"Response Body: {response.text}")
        
        if response.status_code == 200:
            print("✅ CloudKit zone listing successful!")
            return True
        else:
            print(f"❌ CloudKit zone listing failed with status {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ CloudKit test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_simple_cloudkit()
    sys.exit(0 if success else 1)