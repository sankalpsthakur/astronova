import os
from datetime import timedelta

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'secret')
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', SECRET_KEY)
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=24)

    CACHE_TYPE = 'SimpleCache'
    CACHE_DEFAULT_TIMEOUT = 300

    ANTHROPIC_API_KEY = os.environ.get('ANTHROPIC_API_KEY', '')
    JPL_HORIZONS_URL = 'https://ssd-api.jpl.nasa.gov/'
