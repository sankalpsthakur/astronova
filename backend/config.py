import os
from datetime import timedelta

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY')
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', SECRET_KEY)
    
    if not SECRET_KEY:
        raise ValueError("SECRET_KEY environment variable must be set")
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=2)

    CACHE_TYPE = 'SimpleCache'
    CACHE_DEFAULT_TIMEOUT = 300

    ANTHROPIC_API_KEY = os.environ.get('ANTHROPIC_API_KEY', '')
    GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY', '')
    JPL_HORIZONS_URL = 'https://ssd-api.jpl.nasa.gov/'
