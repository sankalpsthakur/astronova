"""
Miscellaneous utility endpoints for the Astronova API.
Provides health checks, utility information, and general purpose endpoints.
"""

from fastapi import APIRouter, HTTPException, Request
from slowapi import Limiter
from slowapi.util import get_remote_address
import sys
import os
from datetime import datetime

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)

@router.get('/health')
@limiter.limit("200/hour")
async def health_check(request: Request):
    """
    Health check endpoint for monitoring and load balancers.
    
    Returns:
        JSON response with service status and basic system information
    """
    return {
        'status': 'healthy',
        'service': 'astronova-api',
        'version': '2.1.0',
        'timestamp': datetime.utcnow().isoformat(),
        'environment': os.getenv('ENVIRONMENT', 'unknown')
    }

@router.get('/info')
@limiter.limit("100/hour")
async def service_info(request: Request):
    """
    Service information endpoint providing API details.
    
    Returns:
        JSON response with API information and capabilities
    """
    return {
        'service': 'Astronova API',
        'version': '2.1.0',
        'description': 'AI-powered astrological insights and cosmic guidance',
        'features': [
            'Daily horoscopes',
            'Birth chart analysis',
            'Compatibility matching',
            'AI astrologer chat',
            'Planetary ephemeris data',
            'Location services'
        ],
        'endpoints': {
            'chat': '/api/v1/chat',
            'horoscope': '/api/v1/horoscope',
            'match': '/api/v1/match',
            'chart': '/api/v1/chart',
            'reports': '/api/v1/reports',
            'ephemeris': '/api/v1/ephemeris',
            'locations': '/api/v1/locations',
            'content': '/api/v1/content'
        },
        'rate_limits': {
            'daily': 200,
            'hourly': 50
        }
    }

@router.get('/zodiac-signs')
@limiter.limit("100/hour")
async def zodiac_signs(request: Request):
    """
    Get information about all zodiac signs.
    
    Returns:
        JSON response with zodiac sign details
    """
    signs = [
        {
            'name': 'Aries',
            'symbol': '♈',
            'element': 'Fire',
            'dates': 'March 21 - April 19',
            'ruling_planet': 'Mars'
        },
        {
            'name': 'Taurus',
            'symbol': '♉',
            'element': 'Earth',
            'dates': 'April 20 - May 20',
            'ruling_planet': 'Venus'
        },
        {
            'name': 'Gemini',
            'symbol': '♊',
            'element': 'Air',
            'dates': 'May 21 - June 20',
            'ruling_planet': 'Mercury'
        },
        {
            'name': 'Cancer',
            'symbol': '♋',
            'element': 'Water',
            'dates': 'June 21 - July 22',
            'ruling_planet': 'Moon'
        },
        {
            'name': 'Leo',
            'symbol': '♌',
            'element': 'Fire',
            'dates': 'July 23 - August 22',
            'ruling_planet': 'Sun'
        },
        {
            'name': 'Virgo',
            'symbol': '♍',
            'element': 'Earth',
            'dates': 'August 23 - September 22',
            'ruling_planet': 'Mercury'
        },
        {
            'name': 'Libra',
            'symbol': '♎',
            'element': 'Air',
            'dates': 'September 23 - October 22',
            'ruling_planet': 'Venus'
        },
        {
            'name': 'Scorpio',
            'symbol': '♏',
            'element': 'Water',
            'dates': 'October 23 - November 21',
            'ruling_planet': 'Pluto'
        },
        {
            'name': 'Sagittarius',
            'symbol': '♐',
            'element': 'Fire',
            'dates': 'November 22 - December 21',
            'ruling_planet': 'Jupiter'
        },
        {
            'name': 'Capricorn',
            'symbol': '♑',
            'element': 'Earth',
            'dates': 'December 22 - January 19',
            'ruling_planet': 'Saturn'
        },
        {
            'name': 'Aquarius',
            'symbol': '♒',
            'element': 'Air',
            'dates': 'January 20 - February 18',
            'ruling_planet': 'Uranus'
        },
        {
            'name': 'Pisces',
            'symbol': '♓',
            'element': 'Water',
            'dates': 'February 19 - March 20',
            'ruling_planet': 'Neptune'
        }
    ]
    
    return {
        'zodiac_signs': signs,
        'total_count': len(signs)
    }

@router.get('/system-status')
@limiter.limit("50/hour")
async def system_status(request: Request):
    """
    Detailed system status for administrative monitoring.
    
    Returns:
        JSON response with detailed system information
    """
    try:
        # Basic system info
        status_info = {
            'python_version': f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}",
            'environment': os.getenv('ENVIRONMENT', 'unknown'),
            'uptime': datetime.utcnow().isoformat(),
        }
        
        # Check environment variables (without exposing sensitive data)
        env_status = {
            'anthropic_api_configured': bool(os.getenv('ANTHROPIC_API_KEY')),
            'google_places_configured': bool(os.getenv('GOOGLE_PLACES_API_KEY')),
            'redis_configured': bool(os.getenv('REDIS_URL')),
            'ephemeris_path_configured': bool(os.getenv('EPHEMERIS_PATH'))
        }
        
        return {
            'status': 'operational',
            'system': status_info,
            'environment': env_status,
            'timestamp': datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))