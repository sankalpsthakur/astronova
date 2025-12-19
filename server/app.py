from __future__ import annotations

import logging
import os

from flask import Flask, Response, jsonify, redirect
from flask_cors import CORS

from db import init_db
from middleware import add_request_id, log_request_response, setup_logging
from routes import (
    astrology_bp,
    auth_bp,
    chart_bp,
    chat_bp,
    compat_bp,
    content_bp,
    discover_bp,
    ephemeris_bp,
    horoscope_bp,
    locations_bp,
    misc_bp,
    reports_bp,
)

setup_logging()
logger = logging.getLogger(__name__)


def create_app():
    app = Flask(__name__)
    CORS(app)

    # Add request logging middleware
    app.before_request(add_request_id)
    app.after_request(log_request_response)

    # Ensure local SQLite is initialized once on startup
    try:
        init_db()
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"DB init failed: {e}", exc_info=True)

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
    @app.route("/api/v1/report", defaults={"path": ""}, methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
    @app.route("/api/v1/report/<path:path>", methods=["GET", "POST", "PUT", "DELETE", "PATCH"])
    def report_alias(path: str):
        from flask import redirect

        target = "/api/v1/reports" + ("" if not path else f"/{path}")
        return redirect(target, code=307)

    app.register_blueprint(astrology_bp, url_prefix="/api/v1/astrology")
    app.register_blueprint(compat_bp, url_prefix="/api/v1/compatibility")
    app.register_blueprint(content_bp, url_prefix="/api/v1/content")
    app.register_blueprint(discover_bp, url_prefix="/api/v1/discover")

    # OpenAPI + Swagger UI (no extra dependencies).
    @app.route("/api/v1/openapi.yaml", methods=["GET"])
    def openapi_spec():
        spec_path = os.path.join(os.path.dirname(__file__), "openapi_spec.yaml")
        try:
            with open(spec_path, "r", encoding="utf-8") as f:
                payload = f.read()
        except OSError:
            payload = "openapi: 3.0.0\ninfo:\n  title: AstroNova Backend API\n  version: 1.0.0\npaths: {}\n"

        return Response(payload, mimetype="application/yaml")

    @app.route("/api/v1/docs", methods=["GET"])
    def docs_alias():
        return redirect("/docs", code=302)

    @app.route("/docs", methods=["GET"])
    def swagger_docs():
        html = """<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Astronova API Docs</title>
    <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css" />
    <style>
      body { margin: 0; background: #0b1020; }
      #swagger-ui { background: #fff; }
    </style>
  </head>
  <body>
    <div id="swagger-ui"></div>
    <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
    <script>
      window.onload = function () {
        SwaggerUIBundle({
          url: "/api/v1/openapi.yaml",
          dom_id: "#swagger-ui",
          deepLinking: true,
          presets: [SwaggerUIBundle.presets.apis],
          layout: "BaseLayout"
        });
      };
    </script>
  </body>
</html>
"""
        return Response(html, mimetype="text/html")

    # OpenAPI parity: /api/v1/match maps to compatibility.
    @app.route("/api/v1/match", methods=["GET"])
    def match_info():
        return jsonify(
            {
                "service": "match",
                "status": "available",
                "endpoints": {
                    "POST /api/v1/match": "Calculate compatibility between two people",
                    "POST /api/v1/compatibility": "Canonical compatibility endpoint",
                },
            }
        )

    @app.route("/api/v1/match", methods=["POST"])
    def match():
        from routes.compatibility import compatibility as compatibility_handler

        return compatibility_handler()

    # Health endpoints
    @app.route("/health", methods=["GET"])
    def root_health():
        return jsonify({"status": "ok"})

    @app.route("/api/v1/health", methods=["GET"])
    def api_health():
        return jsonify({"status": "ok"})

    # Global error handlers
    @app.errorhandler(404)
    def not_found(error):
        return (
            jsonify({"error": "Endpoint not found", "message": "The requested resource was not found", "code": "NOT_FOUND"}),
            404,
        )

    @app.errorhandler(500)
    def internal_error(error):
        logger.error(f"Internal server error: {str(error)}")
        return (
            jsonify(
                {
                    "error": "Internal server error",
                    "message": "An unexpected error occurred. Please try again later.",
                    "code": "INTERNAL_ERROR",
                }
            ),
            500,
        )

    return app


if __name__ == "__main__":
    debug_mode = os.environ.get("FLASK_DEBUG", "False").lower() == "true"
    port = int(os.environ.get("PORT", 8080))
    app = create_app()
    app.run(host="0.0.0.0", port=port, debug=debug_mode)
