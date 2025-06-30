import os
import json
import hashlib
import hmac
import base64
import time
from datetime import datetime
from typing import Dict, List, Optional, Any
import requests
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.backends import default_backend
import jwt
import logging

logger = logging.getLogger(__name__)

class CloudKitWebClient:
    """CloudKit Web Services API Client"""
    
    def __init__(self):
        self.container_id = "iCloud.com.sankalp.AstronovaApp"
        self.environment = os.getenv('CLOUDKIT_ENVIRONMENT', 'development')  # development or production
        self.base_url = f"https://api.apple-cloudkit.com/database/1/{self.container_id}/{self.environment}/private"
        
        # Server-to-Server Authentication configuration
        # TODO: SECURITY - Move these to environment variables for production
        # For deployment testing, hardcoded values are used temporarily
        self.key_id = self._get_cloudkit_key_id()
        self.private_key_path = self._get_private_key_path()
        self.private_key_content = self._get_private_key_content()
        
        # Headers for all requests
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json',
            'User-Agent': 'AstronovaBackend/1.0'
        })
        
        # Validate configuration
        if not all([self.key_id, (self.private_key_path or self.private_key_content)]):
            logger.warning("CloudKit Web Services not configured. Set CLOUDKIT_KEY_ID and CLOUDKIT_PRIVATE_KEY_PATH environment variables.")
            self.enabled = False
        else:
            self.enabled = True
            self._load_private_key()
    
    def _get_cloudkit_key_id(self) -> str:
        """Get CloudKit Key ID from environment or config"""
        # Try environment variable first
        env_key_id = os.getenv('CLOUDKIT_KEY_ID')
        if env_key_id:
            return env_key_id
        
        # Try importing from cloudkit_config
        try:
            from cloudkit_config import CLOUDKIT_KEY_ID
            return CLOUDKIT_KEY_ID
        except ImportError:
            return None
    
    def _get_private_key_path(self) -> str:
        """Get private key path from environment variable or config"""
        env_path = os.getenv('CLOUDKIT_PRIVATE_KEY_PATH')
        if env_path:
            return env_path
        
        # Try importing from cloudkit_config
        try:
            from cloudkit_config import CLOUDKIT_PRIVATE_KEY_PATH
            return CLOUDKIT_PRIVATE_KEY_PATH
        except ImportError:
            return None
    
    def _get_private_key_content(self) -> str:
        """Get private key content from config"""
        # Try environment variable first
        if self._get_private_key_path():
            return None
        
        # Try importing from cloudkit_config
        try:
            from cloudkit_config import CLOUDKIT_PRIVATE_KEY
            return CLOUDKIT_PRIVATE_KEY
        except ImportError:
            return None
    
    def _load_private_key(self):
        """Load the private key for CloudKit authentication"""
        try:
            # Try loading from file path first (environment variable)
            if self.private_key_path:
                with open(self.private_key_path, 'rb') as key_file:
                    key_data = key_file.read()
                logger.info("CloudKit private key loaded from file")
            # Fall back to hardcoded content
            elif self.private_key_content:
                key_data = self.private_key_content.encode('utf-8')
                logger.info("CloudKit private key loaded from hardcoded content")
            else:
                raise Exception("No private key source available")
            
            self.private_key = serialization.load_pem_private_key(
                key_data,
                password=None,
                backend=default_backend()
            )
            logger.info("CloudKit private key loaded successfully")
        except Exception as e:
            logger.error(f"Failed to load CloudKit private key: {e}")
            self.enabled = False
    
    def _generate_server_to_server_token(self) -> str:
        """Generate CloudKit Server-to-Server authentication token"""
        if not self.enabled:
            raise Exception("CloudKit Web Services not properly configured")
        
        # For CloudKit Server-to-Server, we use the key ID directly as the token
        # This is different from JWT-based authentication
        return self.key_id
    
    def _generate_signature_with_date(self, method: str, endpoint: str, data: Optional[Dict] = None, iso_date: str = None) -> str:
        """Generate ECDSA signature for CloudKit Server-to-Server authentication"""
        if not self.enabled:
            raise Exception("CloudKit Web Services not properly configured")
        
        # Use provided ISO date or generate new one
        if not iso_date:
            iso_date = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
        
        # Calculate body hash (SHA-256 then base64)
        if data:
            request_body = json.dumps(data, separators=(',', ':'))
        else:
            request_body = ""
        
        body_hash = base64.b64encode(
            hashlib.sha256(request_body.encode('utf-8')).digest()
        ).decode('utf-8')
        
        # Create subpath (URL path without base CloudKit API URL)
        subpath = f"/database/1/{self.container_id}/{self.environment}/private/{endpoint}"
        
        # Create canonical request string: "{method}:{iso_date}:{body_hash}:{subpath}"
        canonical_request = f"{method}:{iso_date}:{body_hash}:{subpath}"
        
        logger.debug(f"Canonical request: {canonical_request}")
        
        # Sign the canonical request
        try:
            signature = self.private_key.sign(
                canonical_request.encode('utf-8'),
                ec.ECDSA(hashes.SHA256())
            )
            # Return base64 encoded signature
            signature_b64 = base64.b64encode(signature).decode('utf-8')
            logger.debug(f"Generated signature: {signature_b64}")
            return signature_b64
        except Exception as e:
            logger.error(f"Failed to generate signature: {e}")
            raise
    
    def _make_request(self, method: str, endpoint: str, data: Optional[Dict] = None) -> Dict:
        """Make authenticated request to CloudKit Web Services"""
        if not self.enabled:
            raise Exception("CloudKit Web Services not configured")
        
        url = f"{self.base_url}/{endpoint}"
        
        # Generate ISO date (must be same for signature and header)
        iso_date = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
        
        # Generate authentication token and signature
        token = self._generate_server_to_server_token()
        signature = self._generate_signature_with_date(method, endpoint, data, iso_date)
        
        # Add CloudKit Server-to-Server authorization headers
        headers = {
            'X-Apple-CloudKit-Request-KeyID': token,
            'X-Apple-CloudKit-Request-ISO8601Date': iso_date,
            'X-Apple-CloudKit-Request-SignatureV1': signature
        }
        
        try:
            logger.debug(f"CloudKit API request: {method} {url}")
            logger.debug(f"Headers: {headers}")
            if data:
                logger.debug(f"Request body: {json.dumps(data, indent=2)}")
            
            if method == 'GET':
                response = self.session.get(url, headers=headers)
            elif method == 'POST':
                response = self.session.post(url, headers=headers, json=data)
            elif method == 'PUT':
                response = self.session.put(url, headers=headers, json=data)
            elif method == 'DELETE':
                response = self.session.delete(url, headers=headers)
            else:
                raise ValueError(f"Unsupported HTTP method: {method}")
            
            logger.debug(f"Response status: {response.status_code}")
            logger.debug(f"Response body: {response.text}")
            
            response.raise_for_status()
            return response.json()
            
        except requests.exceptions.RequestException as e:
            logger.error(f"CloudKit API request failed: {e}")
            if hasattr(e, 'response') and e.response is not None:
                logger.error(f"Response status: {e.response.status_code}")
                logger.error(f"Response headers: {e.response.headers}")
                logger.error(f"Response body: {e.response.text}")
                
                # Try to parse CloudKit error details
                try:
                    error_data = e.response.json()
                    if 'errors' in error_data:
                        for error in error_data['errors']:
                            logger.error(f"CloudKit error: {error}")
                except:
                    pass
            raise
    
    # MARK: - Record Operations
    
    def save_record(self, record_type: str, fields: Dict, record_name: Optional[str] = None) -> Dict:
        """Save a record to CloudKit"""
        record_data = {
            'records': [{
                'recordType': record_type,
                'fields': self._format_fields_for_cloudkit(fields)
            }]
        }
        
        if record_name:
            record_data['records'][0]['recordName'] = record_name
        
        result = self._make_request('POST', 'records/modify', record_data)
        return result.get('records', [{}])[0]
    
    def fetch_record(self, record_name: str) -> Optional[Dict]:
        """Fetch a record by name from CloudKit"""
        try:
            result = self._make_request('GET', f'records/{record_name}')
            return result
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 404:
                return None
            raise
    
    def query_records(self, record_type: str, filters: Optional[List[Dict]] = None, sort_by: Optional[str] = None, limit: int = 100) -> List[Dict]:
        """Query records from CloudKit"""
        query_data = {
            'query': {
                'recordType': record_type
            }
        }
        
        if filters:
            query_data['query']['filterBy'] = filters
        
        if sort_by:
            query_data['query']['sortBy'] = [{'fieldName': sort_by, 'ascending': False}]
        
        if limit:
            query_data['query']['resultsLimit'] = limit
        
        result = self._make_request('POST', 'records/query', query_data)
        return result.get('records', [])
    
    def delete_record(self, record_type: str, record_name: str) -> bool:
        """Delete a record from CloudKit"""
        try:
            # CloudKit delete endpoint uses record name only, record_type is for validation
            self._make_request('DELETE', f'records/{record_name}')
            logger.info(f"Successfully deleted {record_type} record: {record_name}")
            return True
        except requests.exceptions.HTTPError as e:
            logger.error(f"Failed to delete {record_type} record {record_name}: {e}")
            return False
    
    def delete_record_by_name(self, record_name: str) -> bool:
        """Delete a record from CloudKit by name only (legacy method)"""
        try:
            self._make_request('DELETE', f'records/{record_name}')
            return True
        except requests.exceptions.HTTPError:
            return False
    
    # MARK: - Field Formatting
    
    def _format_fields_for_cloudkit(self, fields: Dict) -> Dict:
        """Format fields for CloudKit Web Services API"""
        formatted_fields = {}
        
        for key, value in fields.items():
            if isinstance(value, str):
                formatted_fields[key] = {'value': value}
            elif isinstance(value, int):
                formatted_fields[key] = {'value': value}
            elif isinstance(value, float):
                formatted_fields[key] = {'value': value}
            elif isinstance(value, bool):
                formatted_fields[key] = {'value': 1 if value else 0}
            elif isinstance(value, datetime):
                # CloudKit expects timestamps in milliseconds
                timestamp = int(value.timestamp() * 1000)
                formatted_fields[key] = {'value': timestamp}
            elif isinstance(value, list):
                # Handle string arrays - CloudKit supports string lists natively
                if all(isinstance(item, str) for item in value):
                    formatted_fields[key] = {'value': value}
                else:
                    # For now, convert complex lists to JSON string to avoid asset issues
                    # TODO: Implement proper CloudKit asset upload for complex data
                    json_data = json.dumps(value)
                    formatted_fields[key] = {'value': json_data}
            elif isinstance(value, dict):
                # For now, convert complex objects to JSON string to avoid asset issues
                # TODO: Implement proper CloudKit asset upload for complex data
                json_data = json.dumps(value)
                formatted_fields[key] = {'value': json_data}
            else:
                # Default: convert to string
                formatted_fields[key] = {'value': str(value)}
        
        return formatted_fields
    
    
    def _parse_cloudkit_fields(self, cloudkit_record: Dict) -> Dict:
        """Parse CloudKit record fields back to Python types"""
        if 'fields' not in cloudkit_record:
            return {}
        
        parsed_fields = {}
        for key, field_data in cloudkit_record['fields'].items():
            value = field_data.get('value')
            
            # Handle different CloudKit field types
            if isinstance(value, str):
                # Try to parse as JSON if it looks like JSON
                if value.startswith(('{', '[')):
                    try:
                        parsed_fields[key] = json.loads(value)
                    except json.JSONDecodeError:
                        parsed_fields[key] = value
                else:
                    parsed_fields[key] = value
            else:
                parsed_fields[key] = value
        
        return parsed_fields
    
    # MARK: - User-specific Queries
    
    def query_user_records(self, record_type: str, user_id: str, limit: int = 100) -> List[Dict]:
        """Query records for a specific user"""
        try:
            # For UserProfile, query by record name (which is the user ID)
            if record_type == 'UserProfile':
                try:
                    record = self.fetch_record(user_id)
                    if record:
                        return [self._parse_cloudkit_fields(record)]
                    else:
                        return []
                except:
                    return []
            
            # For other record types, query by userProfileId field
            filters = [{
                'fieldName': 'userProfileId',
                'comparator': 'EQUALS',
                'fieldValue': {'value': user_id}
            }]
            
            records = self.query_records(record_type, filters=filters, limit=limit)
            return [self._parse_cloudkit_fields(record) for record in records]
        except Exception as e:
            logger.error(f"Error querying user records for {record_type}: {e}")
            return []
    
    def save_user_record(self, record_type: str, user_id: str, fields: Dict) -> Dict:
        """Save a record for a specific user"""
        # Add user ID to fields (except for UserProfile which uses user_id as record name)
        if record_type != 'UserProfile':
            fields['userProfileId'] = user_id
        
        # Add timestamps
        now = datetime.now()
        if 'createdAt' not in fields:
            fields['createdAt'] = now
        fields['updatedAt'] = now
        
        # For UserProfile, use user_id as the record name
        record_name = user_id if record_type == 'UserProfile' else None
        
        return self.save_record(record_type, fields, record_name)