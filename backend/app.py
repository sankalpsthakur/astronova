import logging
from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_caching import Cache

from config import Config
from routes.chat import chat_bp
from routes.horoscope import horoscope_bp
from routes.match import match_bp
from routes.chart import chart_bp
from routes.reports import reports_bp
from routes.ephemeris import ephemeris_bp
from routes.locations import locations_bp

cache = Cache()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    CORS(app)
    JWTManager(app)
    cache.init_app(app)

    limiter = Limiter(app=app, key_func=get_remote_address,
                      default_limits=["200 per day", "50 per hour"])

    app.register_blueprint(chat_bp, url_prefix="/api/v1/chat")
    app.register_blueprint(horoscope_bp, url_prefix="/api/v1/horoscope")
    app.register_blueprint(match_bp, url_prefix="/api/v1/match")
    app.register_blueprint(chart_bp, url_prefix="/api/v1/chart")
    app.register_blueprint(reports_bp, url_prefix="/api/v1/reports")
    app.register_blueprint(ephemeris_bp, url_prefix="/api/v1/ephemeris")
    app.register_blueprint(locations_bp, url_prefix="/api/v1/locations")

    @app.route('/health')
    def health():
        return jsonify({'status': 'ok'})

    return app

if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=8080)
