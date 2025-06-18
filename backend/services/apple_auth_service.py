import jwt
import requests
import time
import base64
import os
from typing import Dict, Optional
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend
import logging

logger = logging.getLogger(__name__)

class AppleAuthService:
    """
    Service for verifying Apple ID tokens
    """
    
    APPLE_KEYS_URL = "https://appleid.apple.com/auth/keys"
    APPLE_ISSUER = "https://appleid.apple.com"
    
    def __init__(self):
        self._apple_keys = None
        self._keys_cache_time = None
        self.client_id = os.getenv('APPLE_CLIENT_ID', 'com.sankalp.AstronovaApp')
    
    def verify_token(self, id_token: str) -> Optional[Dict]:
        """
        Verify Apple ID token and return user data
        """
        try:
            # 1. Decode token header to get key ID
            unverified_header = jwt.get_unverified_header(id_token)
            key_id = unverified_header.get('kid')
            
            if not key_id:
                logger.error("No key ID in Apple ID token")
                return None
            
            # 2. Get Apple's public keys
            apple_keys = self._get_apple_public_keys()
            if not apple_keys:
                logger.error("Failed to get Apple public keys")
                return None
            
            # 3. Find the correct key
            public_key = None
            for key_data in apple_keys.get('keys', []):
                if key_data.get('kid') == key_id:
                    public_key = self._construct_public_key(key_data)
                    break
            
            if not public_key:
                logger.error(f"No matching key found for kid: {key_id}")
                return None
            
            # 4. Verify and decode the token
            payload = jwt.decode(
                id_token,
                public_key,
                algorithms=['RS256'],
                audience=self.client_id,  # Your app's bundle ID
                issuer=self.APPLE_ISSUER
            )
            
            # 5. Additional validations
            if payload.get('iss') != self.APPLE_ISSUER:
                logger.error("Invalid issuer in Apple ID token")
                return None
                
            # Check token expiration
            exp = payload.get('exp')
            if exp and exp < time.time():
                logger.error("Apple ID token has expired")
                return None
                
            return payload
            
        except jwt.ExpiredSignatureError:
            logger.error("Apple ID token has expired")
            return None
        except jwt.InvalidTokenError as e:
            logger.error(f"Invalid Apple ID token: {str(e)}")
            return None
        except Exception as e:
            logger.error(f"Apple token verification failed: {str(e)}")
            return None
    
    def _get_apple_public_keys(self) -> Optional[Dict]:
        """
        Fetch Apple's public keys (with caching)
        """
        try:
            # Simple caching - in production, use Redis
            current_time = time.time()
            if (self._apple_keys and self._keys_cache_time and 
                current_time - self._keys_cache_time < 3600):  # 1 hour cache
                return self._apple_keys
            
            response = requests.get(self.APPLE_KEYS_URL, timeout=10)
            response.raise_for_status()
            
            self._apple_keys = response.json()
            self._keys_cache_time = current_time
            
            logger.info("Successfully fetched Apple public keys")
            return self._apple_keys
            
        except Exception as e:
            logger.error(f"Failed to fetch Apple public keys: {str(e)}")
            return None
    
    def _construct_public_key(self, key_data: Dict):
        """
        Construct RSA public key from Apple's JWK format
        """
        try:
            # Convert base64url to standard base64
            def base64url_decode(data):
                # Add padding if needed
                data += '=' * (4 - len(data) % 4)
                return base64.urlsafe_b64decode(data)
            
            n = int.from_bytes(base64url_decode(key_data['n']), 'big')
            e = int.from_bytes(base64url_decode(key_data['e']), 'big')
            
            # Create RSA public key
            public_numbers = rsa.RSAPublicNumbers(e, n)
            public_key = public_numbers.public_key(backend=default_backend())
            
            return public_key
            
        except Exception as e:
            logger.error(f"Failed to construct public key: {str(e)}")
            return None
    
    def get_apple_user_info(self, user_identifier: str) -> Optional[Dict]:
        """
        Get additional user info from Apple (if available)
        Note: Apple provides limited user info only on first sign-in
        """
        # Apple doesn't provide a direct API to fetch user info by identifier
        # User info is only available during the initial sign-in flow
        # This method is here for future extension if needed
        return None