from __future__ import annotations

import logging
import os
import time
from datetime import datetime
from flask import Flask, jsonify, request, g
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from services.cache_service import cache

from config import Config
from routes.chat import chat_bp
from routes.horoscope import horoscope_bp
from routes.match import match_bp
from routes.chart import chart_bp
from routes.reports import reports_bp
from routes.ephemeris import ephemeris_bp
# from routes.locations import locations_bp
from routes.content import content_bp
from routes.misc import misc_bp
from services.reports_service import ReportsService

# Enhanced logging configuration
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - [%(filename)s:%(lineno)d] - %(message)s',
    handlers=[
        logging.FileHandler('astronova_debug.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def create_app(api_key: str | None = None):
    app = Flask(__name__)
    app.config.from_object(Config)
    CORS(app)
    
    # Enhanced JWT setup with custom handlers
    jwt = JWTManager(app)
    
    # Enhanced request/response logging middleware
    @app.before_request
    def log_request_info():
        g.start_time = time.time()
        logger.info(f"🔵 REQUEST START: {request.method} {request.url}")
        logger.info(f"📍 Remote Address: {request.remote_addr}")
        logger.info(f"🧭 User Agent: {request.headers.get('User-Agent', 'Unknown')}")
        
        # Log headers (excluding sensitive ones)
        headers_to_log = {}
        for key, value in request.headers:
            if key.lower() not in ['authorization', 'cookie', 'x-api-key']:
                headers_to_log[key] = value
            else:
                headers_to_log[key] = '[REDACTED]'
        logger.info(f"📋 Headers: {headers_to_log}")
        
        # Log request body for POST/PUT requests
        if request.method in ['POST', 'PUT', 'PATCH']:
            if request.is_json:
                try:
                    body = request.get_json()
                    # Redact sensitive fields
                    if isinstance(body, dict):
                        safe_body = {}
                        for k, v in body.items():
                            if any(sensitive in k.lower() for sensitive in ['password', 'token', 'key', 'secret']):
                                safe_body[k] = '[REDACTED]'
                            else:
                                safe_body[k] = v
                        logger.info(f"📄 Request Body: {safe_body}")
                    else:
                        logger.info(f"📄 Request Body: {str(body)[:500]}...")
                except Exception as e:
                    logger.warning(f"⚠️ Could not parse request body: {e}")
            elif request.data:
                logger.info(f"📄 Request Data: {str(request.data[:200])}...")

    @app.after_request  
    def log_response_info(response):
        duration = time.time() - g.get('start_time', time.time())
        
        logger.info(f"🟢 RESPONSE: {response.status_code} - Duration: {duration:.3f}s")
        logger.info(f"📊 Response Size: {len(response.get_data())} bytes")
        
        # Log response headers
        response_headers = dict(response.headers)
        logger.info(f"📋 Response Headers: {response_headers}")
        
        # Log response body (truncated for large responses)
        if response.status_code >= 400:
            logger.error(f"❌ Error Response Body: {response.get_data(as_text=True)}")
        else:
            response_text = response.get_data(as_text=True)
            if len(response_text) > 1000:
                logger.info(f"📄 Response Body (truncated): {response_text[:1000]}...")
            else:
                logger.info(f"📄 Response Body: {response_text}")
        
        logger.info(f"🔴 REQUEST END: {request.method} {request.url} - {response.status_code}")
        logger.info("=" * 80)
        
        return response

    # Add JWT error handlers with enhanced logging
    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        logger.warning(f"🔑 JWT Token Expired - Header: {jwt_header}, Payload: {jwt_payload}")
        return jsonify({
            'error': 'Token has expired',
            'code': 'TOKEN_EXPIRED',
            'message': 'Please sign in again'
        }), 401

    @jwt.invalid_token_loader
    def invalid_token_callback(error):
        logger.error(f"🔑 Invalid JWT Token - Error: {error}")
        return jsonify({
            'error': 'Invalid token',
            'code': 'TOKEN_INVALID',
            'message': 'The provided token is invalid'
        }), 401

    @jwt.unauthorized_loader
    def missing_token_callback(error):
        logger.warning(f"🔑 Missing JWT Token - Error: {error}")
        return jsonify({
            'error': 'Authorization required',
            'code': 'TOKEN_MISSING',
            'message': 'A valid token is required for this request'
        }), 401
    
    cache.init_app(app)

    if api_key:
        app.config["reports_service"] = ReportsService(api_key)
        logger.info(f"🔧 Reports service initialized with API key: {api_key[:10]}...")

    # Register authentication blueprint first
    from routes.auth import auth_bp
    app.register_blueprint(auth_bp, url_prefix="/api/v1/auth")
    logger.info("🔧 Registered auth blueprint")
    
    # Register existing blueprints
    app.register_blueprint(chat_bp, url_prefix="/api/v1/chat")
    app.register_blueprint(horoscope_bp, url_prefix="/api/v1/horoscope")
    app.register_blueprint(match_bp, url_prefix="/api/v1/match")
    app.register_blueprint(chart_bp, url_prefix="/api/v1/chart")
    app.register_blueprint(reports_bp, url_prefix="/api/v1/reports")
    app.register_blueprint(ephemeris_bp, url_prefix="/api/v1/ephemeris")
    # app.register_blueprint(locations_bp, url_prefix="/api/v1/locations")
    app.register_blueprint(content_bp, url_prefix="/api/v1/content")
    app.register_blueprint(misc_bp, url_prefix="/api/v1/misc")
    logger.info("🔧 All blueprints registered successfully")

    @app.route('/health')
    def health():
        logger.info("💚 Health check requested")
        return jsonify({'status': 'ok', 'timestamp': datetime.now().isoformat()})
    
    @app.route('/api/v1/health')
    def health_v1():
        logger.info("💚 Health check v1 requested")
        return jsonify({'status': 'ok', 'timestamp': datetime.now().isoformat()})
    
    # Enhanced global error handlers
    @app.errorhandler(404)
    def not_found(error):
        logger.warning(f"🔍 404 Not Found: {request.url}")
        return jsonify({
            'error': 'Endpoint not found',
            'message': 'The requested resource was not found',
            'code': 'NOT_FOUND',
            'requested_url': request.url
        }), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        logger.error(f"💥 Internal server error: {str(error)}")
        logger.error(f"💥 Error type: {type(error)}")
        import traceback
        logger.error(f"💥 Traceback: {traceback.format_exc()}")
        return jsonify({
            'error': 'Internal server error',
            'message': 'An unexpected error occurred. Please try again later.',
            'code': 'INTERNAL_ERROR'
        }), 500
    
    @app.errorhandler(503)
    def service_unavailable(error):
        logger.error(f"🚫 Service unavailable: {str(error)}")
        return jsonify({
            'error': 'Service temporarily unavailable',
            'message': 'The service is temporarily unavailable. Please try again later.',
            'code': 'SERVICE_UNAVAILABLE'
        }), 503
    
    @app.errorhandler(400)
    def bad_request(error):
        logger.warning(f"⚠️ Bad request: {str(error)}")
        return jsonify({
            'error': 'Bad request',
            'message': 'The request could not be processed due to invalid data.',
            'code': 'BAD_REQUEST'
        }), 400
    
    # Handle validation errors from Pydantic
    @app.errorhandler(ValueError)
    def validation_error(error):
        logger.warning(f"✅ Validation error: {str(error)}")
        return jsonify({
            'error': 'Validation failed',
            'message': str(error),
            'code': 'VALIDATION_ERROR'
        }), 400

    # Log environment configuration on startup
    logger.info("🚀 Astronova Backend Starting Up")
    logger.info(f"🔧 Flask Debug Mode: {app.config.get('DEBUG', False)}")
    logger.info(f"🔧 Secret Key Set: {'Yes' if app.config.get('SECRET_KEY') else 'No'}")
    logger.info(f"🔧 JWT Secret Key Set: {'Yes' if app.config.get('JWT_SECRET_KEY') else 'No'}")
    logger.info(f"🔧 Anthropic API Key Set: {'Yes' if app.config.get('ANTHROPIC_API_KEY') else 'No'}")
    logger.info(f"🔧 CORS Origins: {app.config.get('CORS_ORIGINS', ['*'])}")
    
    return app

if __name__ == '__main__':
    # Load environment variables
    from dotenv import load_dotenv
    load_dotenv()
    
    api_key = os.environ.get("GEMINI_API_KEY", "") or os.environ.get("ANTHROPIC_API_KEY", "")
    debug_mode = os.environ.get("FLASK_DEBUG", "False").lower() == "true"
    port = int(os.environ.get("PORT", 8080))
    
    logger.info(f"🌟 Starting Astronova Backend on port {port}")
    logger.info(f"🔧 Debug mode: {debug_mode}")
    logger.info(f"🔑 API Key available: {'Yes' if api_key else 'No'}")
    
    app = create_app(api_key)
    app.run(host='0.0.0.0', port=port, debug=debug_mode)