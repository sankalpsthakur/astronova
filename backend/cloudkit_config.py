"""
CloudKit Configuration for Astronova Backend

Simple CloudKit setup - set these environment variables or modify this file:
- CLOUDKIT_KEY_ID: Your key ID from Apple Developer Console
- CLOUDKIT_PRIVATE_KEY: Your private key content (for easy deployment)

The CloudKit schema defined in the ERD is correct and properly configured.
"""

import os

# Simple CloudKit configuration - single set of credentials
CLOUDKIT_KEY_ID = os.getenv('CLOUDKIT_KEY_ID', None)
CLOUDKIT_PRIVATE_KEY = os.getenv('CLOUDKIT_PRIVATE_KEY', None)

# CloudKit Configuration Status
def get_cloudkit_status():
    """Get CloudKit configuration status"""
    has_key_id = bool(CLOUDKIT_KEY_ID)
    has_private_key = bool(CLOUDKIT_PRIVATE_KEY)
    
    return {
        'configured': has_key_id and has_private_key,
        'key_id_set': has_key_id,
        'private_key_available': has_private_key
    }

# Instructions for setting up CloudKit credentials:
"""
To configure CloudKit Web Services:

1. Generate a private key:
   openssl ecparam -name prime256v1 -genkey -noout -out eckey.pem

2. Generate the public key:
   openssl ec -in eckey.pem -pubout

3. In Apple Developer Console:
   - Go to CloudKit Console
   - Create a Server-to-Server Key
   - Copy the Key ID
   - Paste the public key content

4. Set environment variables:
   export CLOUDKIT_KEY_ID="your-key-id-here"
   export CLOUDKIT_PRIVATE_KEY_PATH="/path/to/eckey.pem"

5. For production deployment (Render/Heroku):
   - Set CLOUDKIT_KEY_ID in environment variables
   - Set CLOUDKIT_PRIVATE_KEY with the full content of eckey.pem
   - Set CLOUDKIT_ENVIRONMENT to "production"
"""