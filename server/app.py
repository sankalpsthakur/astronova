from __future__ import annotations

import logging
import os

from flask import Flask, Response, jsonify, redirect, request
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

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
    temple_bp,
)

setup_logging()
logger = logging.getLogger(__name__)


def create_app():
    app = Flask(__name__)

    # CORS configuration - restrict to known origins
    # iOS native apps don't send Origin headers, so this mainly protects against browser-based attacks
    allowed_origins = [
        "https://astronova.onrender.com",
        "https://astronova.app",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
    ]
    CORS(app, origins=allowed_origins, supports_credentials=True)

    # Rate limiting to prevent abuse
    # Uses IP address as key; applies sensible defaults per endpoint type
    def get_key():
        # Prefer X-User-Id for authenticated requests, fall back to IP
        user_id = request.headers.get("X-User-Id")
        if user_id:
            return f"user:{user_id}"
        return get_remote_address()

    limiter = Limiter(
        key_func=get_key,
        app=app,
        default_limits=["200 per day", "60 per hour"],
        storage_uri="memory://",
    )

    # Apply stricter limits to expensive endpoints
    @limiter.limit("20 per minute")
    @app.before_request
    def limit_expensive_endpoints():
        # Stricter rate limits for computationally expensive endpoints
        expensive_prefixes = [
            "/api/v1/reports",
            "/api/v1/chart/generate",
            "/api/v1/compatibility",
            "/api/v1/astrology/dashas",
        ]
        for prefix in expensive_prefixes:
            if request.path.startswith(prefix) and request.method == "POST":
                return  # Rate limit applied

    # Rate limit handler
    @app.errorhandler(429)
    def ratelimit_handler(e):
        return jsonify({
            "error": "Rate limit exceeded",
            "message": str(e.description),
            "code": "RATE_LIMIT_EXCEEDED"
        }), 429

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
    app.register_blueprint(temple_bp, url_prefix="/api/v1/temple")

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

    # Legal pages (App Store compliance - required for subscription apps)
    @app.route("/terms", methods=["GET"])
    def terms_of_service():
        html = """<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Terms of Service - Astronova</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; line-height: 1.6; background: #0E0E14; color: #F5F0E6; }
        h1 { color: #D4A853; border-bottom: 1px solid #2A2A36; padding-bottom: 10px; }
        h2 { color: #B08D57; margin-top: 30px; }
        a { color: #9B7ED9; }
        .updated { color: #706860; font-size: 14px; }
    </style>
</head>
<body>
    <h1>Terms of Service</h1>
    <p class="updated">Last updated: December 2024</p>

    <h2>1. Acceptance of Terms</h2>
    <p>By downloading, installing, or using Astronova ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.</p>

    <h2>2. Entertainment Purposes Only</h2>
    <p><strong>Astronova is an entertainment application.</strong> All astrological content, including horoscopes, birth charts, compatibility analyses, forecasts, and insights, is provided solely for entertainment and informational purposes. The App does not provide medical, financial, legal, or professional advice of any kind.</p>

    <h2>3. Subscription Terms</h2>
    <p>Astronova Pro is a monthly auto-renewing subscription. Payment will be charged to your Apple ID account at confirmation of purchase. Your subscription automatically renews unless canceled at least 24 hours before the end of the current period. You can manage and cancel your subscription in your Apple ID account settings.</p>

    <h2>4. No Refunds</h2>
    <p>All purchases are final. Refund requests must be directed to Apple through their standard refund process.</p>

    <h2>5. User Content</h2>
    <p>You retain ownership of any personal data you provide (birth date, time, location). By using the App, you grant us permission to use this data to provide astrological services.</p>

    <h2>6. Disclaimer of Warranties</h2>
    <p>The App is provided "as is" without warranties of any kind. We do not guarantee the accuracy of astrological calculations or interpretations.</p>

    <h2>7. Limitation of Liability</h2>
    <p>We shall not be liable for any decisions you make based on astrological content provided by the App.</p>

    <h2>8. Changes to Terms</h2>
    <p>We reserve the right to modify these terms at any time. Continued use of the App constitutes acceptance of updated terms.</p>

    <h2>9. Contact</h2>
    <p>For questions about these Terms, contact us at <a href="mailto:support@astronova.app">support@astronova.app</a></p>
</body>
</html>"""
        return Response(html, mimetype="text/html")

    @app.route("/privacy", methods=["GET"])
    def privacy_policy():
        html = """<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Privacy Policy - Astronova</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; line-height: 1.6; background: #0E0E14; color: #F5F0E6; }
        h1 { color: #D4A853; border-bottom: 1px solid #2A2A36; padding-bottom: 10px; }
        h2 { color: #B08D57; margin-top: 30px; }
        a { color: #9B7ED9; }
        .updated { color: #706860; font-size: 14px; }
        ul { padding-left: 20px; }
        li { margin-bottom: 8px; }
    </style>
</head>
<body>
    <h1>Privacy Policy</h1>
    <p class="updated">Last updated: December 2024</p>

    <h2>1. Information We Collect</h2>
    <p>Astronova collects the following information to provide our services:</p>
    <ul>
        <li><strong>Account Information:</strong> Name and email address (via Sign in with Apple)</li>
        <li><strong>Birth Data:</strong> Date, time, and location of birth for astrological calculations</li>
        <li><strong>Location Data:</strong> Birth location for chart calculations (not your current location)</li>
        <li><strong>Purchase History:</strong> In-app purchases and subscription status</li>
        <li><strong>Device Identifier:</strong> Anonymous user ID for account management</li>
    </ul>

    <h2>2. How We Use Your Information</h2>
    <p>We use your information solely to:</p>
    <ul>
        <li>Generate personalized astrological charts and readings</li>
        <li>Provide compatibility analyses</li>
        <li>Deliver horoscope content</li>
        <li>Manage your subscription</li>
    </ul>

    <h2>3. Data Sharing</h2>
    <p>We do not sell, trade, or share your personal information with third parties. Your birth data is stored securely and used only for astrological calculations.</p>

    <h2>4. Data Retention</h2>
    <p>We retain your data while your account is active. You can delete your account and all associated data at any time through the app settings.</p>

    <h2>5. Data Security</h2>
    <p>We implement appropriate security measures to protect your personal information against unauthorized access.</p>

    <h2>6. Your Rights</h2>
    <p>You have the right to:</p>
    <ul>
        <li>Access your personal data</li>
        <li>Request deletion of your account and data</li>
        <li>Opt out of promotional communications</li>
    </ul>

    <h2>7. Children's Privacy</h2>
    <p>Astronova is not intended for children under 13. We do not knowingly collect personal information from children.</p>

    <h2>8. Changes to This Policy</h2>
    <p>We may update this Privacy Policy from time to time. We will notify you of significant changes through the App.</p>

    <h2>9. Contact Us</h2>
    <p>For privacy-related questions, contact us at <a href="mailto:privacy@astronova.app">privacy@astronova.app</a></p>
</body>
</html>"""
        return Response(html, mimetype="text/html")

    @app.route("/support", methods=["GET"])
    def support_page():
        html = """<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Support - Astronova</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; line-height: 1.6; background: #0E0E14; color: #F5F0E6; }
        h1 { color: #D4A853; border-bottom: 1px solid #2A2A36; padding-bottom: 10px; }
        h2 { color: #B08D57; margin-top: 30px; }
        a { color: #9B7ED9; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .contact-box { background: #1A1A24; border: 1px solid #2A2A36; border-radius: 8px; padding: 20px; margin-top: 20px; }
        .contact-method { display: flex; align-items: center; margin: 15px 0; }
        .contact-icon { font-size: 24px; margin-right: 15px; }
        ul { padding-left: 20px; }
        li { margin-bottom: 8px; }
        .faq-item { margin-bottom: 25px; }
        .faq-question { font-weight: 600; color: #D4A853; margin-bottom: 8px; }
    </style>
</head>
<body>
    <h1>Support</h1>

    <h2>Get Help</h2>
    <p>We're here to help you with Astronova. Choose the best way to reach us:</p>

    <div class="contact-box">
        <div class="contact-method">
            <span class="contact-icon">📧</span>
            <div>
                <strong>Email Support</strong><br>
                <a href="mailto:support@astronova.app">support@astronova.app</a><br>
                <small style="color: #706860;">Response within 24-48 hours</small>
            </div>
        </div>
    </div>

    <h2>Frequently Asked Questions</h2>

    <div class="faq-item">
        <div class="faq-question">How do I update my birth information?</div>
        <p>Go to the <strong>Manage</strong> tab (bottom right), tap <strong>Edit Profile</strong>, and update your birth date, time, location, or timezone. Changes will be reflected immediately in your chart and daily insights.</p>
    </div>

    <div class="faq-item">
        <div class="faq-question">How do I cancel my subscription?</div>
        <p>Subscriptions are managed through your Apple ID:</p>
        <ol>
            <li>Open the <strong>Settings</strong> app on your iPhone</li>
            <li>Tap your name at the top</li>
            <li>Tap <strong>Subscriptions</strong></li>
            <li>Select <strong>Astronova Pro</strong></li>
            <li>Tap <strong>Cancel Subscription</strong></li>
        </ol>
        <p>Your subscription will remain active until the end of the current billing period.</p>
    </div>

    <div class="faq-item">
        <div class="faq-question">Why don't I see my daily insights?</div>
        <p>Daily insights require a complete birth profile. Make sure you've entered:</p>
        <ul>
            <li>Birth date</li>
            <li>Birth time (as accurate as possible)</li>
            <li>Birth location (city/town)</li>
            <li>Timezone</li>
        </ul>
        <p>Update your profile in the <strong>Manage</strong> tab if any information is missing.</p>
    </div>

    <div class="faq-item">
        <div class="faq-question">How do I book a pooja or consult an astrologer?</div>
        <p>Go to the <strong>Temple</strong> tab to browse:</p>
        <ul>
            <li><strong>Expert Astrologers:</strong> Book video consultations with verified pandits</li>
            <li><strong>Sacred Rituals:</strong> Schedule authentic poojas performed on your behalf</li>
        </ul>
        <p>Select a service, choose a time slot, and complete the booking. You'll receive a confirmation with session details.</p>
    </div>

    <div class="faq-item">
        <div class="faq-question">What is Vimshottari Dasha?</div>
        <p>Vimshottari Dasha is the primary timing system in Vedic astrology. It divides your life into planetary periods (Mahadasha, Antardasha, Pratyantardasha) that influence different life areas. Explore your timeline in the <strong>Time Travel</strong> tab.</p>
    </div>

    <div class="faq-item">
        <div class="faq-question">How accurate are the astrological calculations?</div>
        <p>Astronova uses the Swiss Ephemeris library for planetary positions, the Lahiri ayanamsha for sidereal zodiac calculations, and traditional Vimshottari dasha formulas. All calculations follow authentic Vedic astrology principles.</p>
    </div>

    <div class="faq-item">
        <div class="faq-question">Can I delete my account?</div>
        <p>Yes. Go to <strong>Manage</strong> tab → <strong>Settings</strong> → <strong>Delete Account</strong>. This will permanently remove your account and all associated data.</p>
    </div>

    <h2>Technical Issues</h2>
    <p>If you're experiencing technical problems:</p>
    <ul>
        <li>Make sure you're running the latest version of Astronova from the App Store</li>
        <li>Check your internet connection (required for most features)</li>
        <li>Try force-quitting and restarting the app</li>
        <li>Restart your device if issues persist</li>
    </ul>
    <p>If the problem continues, email us at <a href="mailto:support@astronova.app">support@astronova.app</a> with:</p>
    <ul>
        <li>Your device model and iOS version</li>
        <li>A description of the issue</li>
        <li>Screenshots if applicable</li>
    </ul>

    <h2>App Store Reviews</h2>
    <p>Love Astronova? Please leave us a review on the App Store! Your feedback helps us improve and helps others discover the app.</p>

    <h2>Legal</h2>
    <ul>
        <li><a href="/terms">Terms of Service</a></li>
        <li><a href="/privacy">Privacy Policy</a></li>
    </ul>

    <p style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #2A2A36; color: #706860; font-size: 14px;">
        Astronova - Your Cosmic Blueprint<br>
        © 2026 Astronova. All rights reserved.
    </p>
</body>
</html>"""
        return Response(html, mimetype="text/html")

    # Health endpoints - exempt from rate limiting for Render health checks
    @app.route("/health", methods=["GET"])
    @limiter.exempt
    def root_health():
        return jsonify({"status": "ok"})

    @app.route("/api/v1/health", methods=["GET"])
    @limiter.exempt
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
