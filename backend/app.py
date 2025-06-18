from __future__ import annotations

import logging
import os
from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from services.cache_service import cache

from config import Config
from routes.chat import chat_bp
from routes.horoscope import horoscope_bp
from routes.match import match_bp
from routes.chart import chart_bp
from routes.reports import reports_bp
from routes.ephemeris import ephemeris_bp
from routes.locations import locations_bp
from routes.content import content_bp
from routes.misc import misc_bp
from services.reports_service import ReportsService

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_app(anthropic_api_key: str | None = None):
    app = Flask(__name__)
    app.config.from_object(Config)
    CORS(app)
    
    # Enhanced JWT setup with custom handlers
    jwt = JWTManager(app)
    
    # Add JWT error handlers
    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        return jsonify({
            'error': 'Token has expired',
            'code': 'TOKEN_EXPIRED',
            'message': 'Please sign in again'
        }), 401

    @jwt.invalid_token_loader
    def invalid_token_callback(error):
        return jsonify({
            'error': 'Invalid token',
            'code': 'TOKEN_INVALID',
            'message': 'The provided token is invalid'
        }), 401

    @jwt.unauthorized_loader
    def missing_token_callback(error):
        return jsonify({
            'error': 'Authorization required',
            'code': 'TOKEN_MISSING',
            'message': 'A valid token is required for this request'
        }), 401
    
    cache.init_app(app)

    if anthropic_api_key:
        app.config["reports_service"] = ReportsService(anthropic_api_key)

    limiter = Limiter(app=app, key_func=get_remote_address,
                      default_limits=["200 per day", "50 per hour"])

    # Register authentication blueprint first
    from routes.auth import auth_bp
    app.register_blueprint(auth_bp, url_prefix="/api/v1/auth")
    
    # Register existing blueprints
    app.register_blueprint(chat_bp, url_prefix="/api/v1/chat")
    app.register_blueprint(horoscope_bp, url_prefix="/api/v1/horoscope")
    app.register_blueprint(match_bp, url_prefix="/api/v1/match")
    app.register_blueprint(chart_bp, url_prefix="/api/v1/chart")
    app.register_blueprint(reports_bp, url_prefix="/api/v1/reports")
    app.register_blueprint(ephemeris_bp, url_prefix="/api/v1/ephemeris")
    app.register_blueprint(locations_bp, url_prefix="/api/v1/locations")
    app.register_blueprint(content_bp, url_prefix="/api/v1/content")
    app.register_blueprint(misc_bp, url_prefix="/api/v1/misc")

    @app.route('/health')
    def health():
        return jsonify({'status': 'ok'})
    
    # Global error handlers
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({
            'error': 'Endpoint not found',
            'message': 'The requested resource was not found',
            'code': 'NOT_FOUND'
        }), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        logger.error(f"Internal server error: {str(error)}")
        return jsonify({
            'error': 'Internal server error',
            'message': 'An unexpected error occurred. Please try again later.',
            'code': 'INTERNAL_ERROR'
        }), 500
    
    @app.errorhandler(503)
    def service_unavailable(error):
        return jsonify({
            'error': 'Service temporarily unavailable',
            'message': 'The service is temporarily unavailable. Please try again later.',
            'code': 'SERVICE_UNAVAILABLE'
        }), 503
    
    # Handle validation errors from Pydantic
    @app.errorhandler(ValueError)
    def validation_error(error):
        return jsonify({
            'error': 'Validation failed',
            'message': str(error),
            'code': 'VALIDATION_ERROR'
        }), 400

    return app

if __name__ == '__main__':
    api_key = os.environ.get("ANTHROPIC_API_KEY", "")
    debug_mode = os.environ.get("FLASK_DEBUG", "False").lower() == "true"
    app = create_app(api_key)
    app.run(host='0.0.0.0', port=8080, debug=debug_mode)
