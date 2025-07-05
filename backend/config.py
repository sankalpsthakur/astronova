import os
from datetime import timedelta

class Config:
    # Security
    SECRET_KEY = os.environ.get('SECRET_KEY')
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', SECRET_KEY)
    
    if not SECRET_KEY:
        raise ValueError("SECRET_KEY environment variable must be set")
    
    # JWT Configuration
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=2)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)
    JWT_ERROR_MESSAGE_KEY = 'message'
    
    # Cache Configuration
    CACHE_TYPE = 'SimpleCache'
    CACHE_DEFAULT_TIMEOUT = 300
    
    # API Keys
    ANTHROPIC_API_KEY = os.environ.get('ANTHROPIC_API_KEY', '')
    GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY', '')
    
    # External Services
    JPL_HORIZONS_URL = 'https://ssd-api.jpl.nasa.gov/'
    
    # Request Timeouts (in seconds)
    DEFAULT_REQUEST_TIMEOUT = 30
    GEMINI_REQUEST_TIMEOUT = 30
    CLOUDKIT_REQUEST_TIMEOUT = 20
    
    # Rate Limiting
    RATELIMIT_STORAGE_URL = os.environ.get('REDIS_URL', 'memory://')
    RATELIMIT_DEFAULT = "200 per day, 50 per hour"
    
    # CORS Settings
    CORS_ORIGINS = os.environ.get('CORS_ORIGINS', '*').split(',')
    
    # Logging
    LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')
    
    # Production Settings
    PROPAGATE_EXCEPTIONS = True
    JSON_SORT_KEYS = False
    JSONIFY_PRETTYPRINT_REGULAR = False
