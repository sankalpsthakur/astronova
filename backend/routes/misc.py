"""
Miscellaneous utility endpoints for the Astronova API.
Provides health checks, utility information, and general purpose endpoints.
"""

from flask import Blueprint, jsonify, current_app
import sys
import os
from datetime import datetime

misc_bp = Blueprint('misc', __name__)

@misc_bp.route('/health', methods=['GET'])
def health_check():
    """
    Health check endpoint for monitoring and load balancers.
    
    Returns:
        JSON response with service status and basic system information
    """
    return jsonify({
        'status': 'healthy',
        'service': 'astronova-api',
        'version': '2.1.0',
        'timestamp': datetime.utcnow().isoformat(),
        'environment': current_app.config.get('FLASK_ENV', 'unknown')
    })

@misc_bp.route('/info', methods=['GET'])
def service_info():
    """
    Service information endpoint providing API details.
    
    Returns:
        JSON response with API information and capabilities
    """
    return jsonify({
        'service': 'Astronova API',
        'version': '2.1.0',
        'description': 'AI-powered astrological insights and cosmic guidance',
        'features': [
            'Daily horoscopes',
            'Birth chart analysis',
            'Compatibility matching',
            'AI astrologer chat',
            'Planetary ephemeris data'
        ],
        'endpoints': {
            'chat': '/api/v1/chat',
            'horoscope': '/api/v1/horoscope',
            'match': '/api/v1/match',
            'chart': '/api/v1/chart',
            'reports': '/api/v1/reports',
            'ephemeris': '/api/v1/ephemeris',
            'content': '/api/v1/content'
        },
        'rate_limits': {
            'daily': 200,
            'hourly': 50
        }
    })

@misc_bp.route('/zodiac-signs', methods=['GET'])
def zodiac_signs():
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
    
    return jsonify({
        'zodiac_signs': signs,
        'total_count': len(signs)
    })

@misc_bp.route('/system-status', methods=['GET'])
def system_status():
    """
    Detailed system status for administrative monitoring.
    
    Returns:
        JSON response with detailed system information
    """
    try:
        # Basic system info
        status_info = {
            'python_version': f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}",
            'flask_env': current_app.config.get('FLASK_ENV', 'unknown'),
            'debug_mode': current_app.debug,
            'testing_mode': current_app.testing,
            'uptime': datetime.utcnow().isoformat(),
        }
        
        # Check environment variables (without exposing sensitive data)
        env_status = {
            'anthropic_api_configured': bool(os.getenv('ANTHROPIC_API_KEY')),
            'gemini_api_configured': bool(os.getenv('GEMINI_API_KEY')),
            'secret_key_configured': bool(os.getenv('SECRET_KEY'))
        }
        
        return jsonify({
            'status': 'operational',
            'system': status_info,
            'environment': env_status,
            'timestamp': datetime.utcnow().isoformat()
        })
        
    except Exception as e:
        return jsonify({
            'status': 'error',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }), 500