"""
Minimal misc endpoints: health and system status.
"""

from flask import Blueprint, jsonify, request
import sys
from datetime import datetime
from db import init_db, get_subscription

misc_bp = Blueprint('misc', __name__)


@misc_bp.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'service': 'astronova-api',
        'version': 'minimal',
        'timestamp': datetime.utcnow().isoformat()
    })


@misc_bp.route('/system-status', methods=['GET'])
def system_status():
    return jsonify({
        'status': 'operational',
        'system': {
            'python_version': f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}",
            'timestamp': datetime.utcnow().isoformat(),
        },
        'endpoints': {
            'health': '/api/v1/health',
            'horoscope': '/api/v1/horoscope',
            'ephemeris': '/api/v1/ephemeris',
            'chart': '/api/v1/chart',
            'auth': '/api/v1/auth',
            'chat': '/api/v1/chat',
            'locations': '/api/v1/location',
            'reports': '/api/v1/reports'
        }
    })


@misc_bp.route('/subscription/status', methods=['GET'])
def subscription_status():
    # Optional userId to check real status; defaults to inactive
    init_db()
    user_id = request.args.get('userId')
    return jsonify(get_subscription(user_id))


@misc_bp.route('/config', methods=['GET'])
def remote_config():
    """Lightweight remote configuration for the client.

    Mirrors the structure of client's remote_config.json and can be extended over time.
    """
    return jsonify({
        'paywall_variant': 'A',
        'widget_prompt_enabled': True,
        'daily_notification_default_hour': 9,
        'home_quick_tiles_enabled': True,
    })
