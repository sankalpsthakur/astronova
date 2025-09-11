from __future__ import annotations

import logging
import os
from flask import Flask, jsonify
from flask_cors import CORS

from routes.horoscope import horoscope_bp
from routes.ephemeris import ephemeris_bp
from routes.misc import misc_bp
from routes.auth import auth_bp
from routes.chat import chat_bp
from routes.chart import chart_bp
from routes.locations import locations_bp
from routes.reports import reports_bp
from routes.astrology import astrology_bp
from routes.compatibility import compat_bp
from routes.content import content_bp
from db import init_db

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def create_app():
    app = Flask(__name__)
    CORS(app)

    # Ensure local SQLite is initialized once on startup
    try:
        init_db()
    except Exception as e:
        logger.warning(f"DB init failed: {e}")

    # Register minimal blueprints
    app.register_blueprint(horoscope_bp, url_prefix="/api/v1/horoscope")
    app.register_blueprint(ephemeris_bp, url_prefix="/api/v1/ephemeris")
    app.register_blueprint(misc_bp, url_prefix="/api/v1")
    app.register_blueprint(auth_bp, url_prefix="/api/v1/auth")
    app.register_blueprint(chat_bp, url_prefix="/api/v1/chat")
    app.register_blueprint(chart_bp, url_prefix="/api/v1/chart")
    app.register_blueprint(locations_bp, url_prefix="/api/v1/location")
    app.register_blueprint(reports_bp, url_prefix="/api/v1/reports")

    # Backward-compatibility alias: redirect singular to plural
    @app.route('/api/v1/report', defaults={'path': ''}, methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH'])
    @app.route('/api/v1/report/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH'])
    def report_alias(path: str):
        from flask import redirect
        target = '/api/v1/reports' + ('' if not path else f'/{path}')
        return redirect(target, code=307)
    app.register_blueprint(astrology_bp, url_prefix="/api/v1/astrology")
    app.register_blueprint(compat_bp, url_prefix="/api/v1/compatibility")
    app.register_blueprint(content_bp, url_prefix="/api/v1/content")

    # Health endpoints
    @app.route('/health', methods=['GET'])
    def root_health():
        return jsonify({'status': 'ok'})

    @app.route('/api/v1/health', methods=['GET'])
    def api_health():
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

    return app


if __name__ == '__main__':
    debug_mode = os.environ.get("FLASK_DEBUG", "False").lower() == "true"
    port = int(os.environ.get("PORT", 8080))
    app = create_app()
    app.run(host='0.0.0.0', port=port, debug=debug_mode)
