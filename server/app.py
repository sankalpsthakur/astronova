from __future__ import annotations

import logging
import os

from flask import Flask, Response, jsonify, redirect, request
from flask_babel import Babel
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

from db import get_user_preferred_language, init_db
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
SUPPORTED_LOCALES = ["en", "hi", "es", "ta", "te", "bn", "ar"]
babel = Babel()


def create_app():
    app = Flask(__name__)

    def select_locale() -> str:
        user_id = request.headers.get("X-User-Id")
        if user_id:
            preferred_language = get_user_preferred_language(user_id)
            if preferred_language in SUPPORTED_LOCALES:
                return preferred_language

        best_match = request.accept_languages.best_match(SUPPORTED_LOCALES)
        return best_match or "en"

    app.config["BABEL_DEFAULT_LOCALE"] = "en"
    app.config["BABEL_SUPPORTED_LOCALES"] = SUPPORTED_LOCALES
    babel.init_app(app, locale_selector=select_locale)

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
        default_limits=["2000 per day", "500 per hour"],
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

    # Marketing landing page
    @app.route("/", methods=["GET"])
    def landing_page():
        html = """<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Astronova - Authentic Vedic Astrology</title>
    <meta name="description" content="Decode cosmic frequencies with authentic Vedic astrology. Personalized insights, AI oracle, expert consultations, and sacred ceremonies.">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            color: #F5F0E6;
            background: #0E0E14;
            overflow-x: hidden;
        }

        /* Hero Section */
        .hero {
            position: relative;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
            padding: 40px 20px;
            background: linear-gradient(135deg, #0E0E14 0%, #1A1A2E 50%, #0D1B2A 100%);
            overflow: hidden;
        }
        .hero::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: radial-gradient(circle at 50% 50%, rgba(212, 168, 83, 0.1) 0%, transparent 70%);
            animation: pulse 8s ease-in-out infinite;
        }
        @keyframes pulse {
            0%, 100% { opacity: 0.3; transform: scale(1); }
            50% { opacity: 0.6; transform: scale(1.1); }
        }
        .hero-content {
            position: relative;
            z-index: 1;
            max-width: 900px;
        }
        .logo {
            font-size: 48px;
            margin-bottom: 20px;
            background: linear-gradient(135deg, #D4A853 0%, #B08D57 50%, #C67D4D 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            font-weight: 700;
            letter-spacing: 2px;
        }
        h1 {
            font-size: 56px;
            font-weight: 800;
            margin-bottom: 24px;
            line-height: 1.1;
            background: linear-gradient(135deg, #F5F0E6 0%, #D4A853 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .hero p {
            font-size: 22px;
            color: #B8B8B8;
            margin-bottom: 40px;
            max-width: 700px;
            margin-left: auto;
            margin-right: auto;
        }
        .cta-buttons {
            display: flex;
            gap: 20px;
            justify-content: center;
            flex-wrap: wrap;
        }
        .btn {
            display: inline-block;
            padding: 16px 40px;
            font-size: 18px;
            font-weight: 600;
            text-decoration: none;
            border-radius: 12px;
            transition: all 0.3s ease;
            cursor: pointer;
            border: none;
        }
        .btn-primary {
            background: linear-gradient(135deg, #D4A853 0%, #B08D57 50%, #C67D4D 100%);
            color: #0E0E14;
            box-shadow: 0 8px 24px rgba(212, 168, 83, 0.3);
        }
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 12px 32px rgba(212, 168, 83, 0.4);
        }
        .btn-secondary {
            background: rgba(212, 168, 83, 0.1);
            color: #D4A853;
            border: 2px solid #D4A853;
        }
        .btn-secondary:hover {
            background: rgba(212, 168, 83, 0.2);
            transform: translateY(-2px);
        }

        /* Features Section */
        .features {
            padding: 100px 20px;
            background: #0E0E14;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .section-title {
            text-align: center;
            font-size: 42px;
            font-weight: 700;
            margin-bottom: 20px;
            background: linear-gradient(135deg, #D4A853 0%, #B08D57 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .section-subtitle {
            text-align: center;
            font-size: 20px;
            color: #B8B8B8;
            margin-bottom: 60px;
            max-width: 600px;
            margin-left: auto;
            margin-right: auto;
        }
        .feature-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 40px;
            margin-bottom: 80px;
        }
        .feature-card {
            background: linear-gradient(135deg, rgba(26, 26, 46, 0.6) 0%, rgba(13, 27, 42, 0.6) 100%);
            padding: 40px;
            border-radius: 20px;
            border: 1px solid rgba(212, 168, 83, 0.2);
            transition: all 0.3s ease;
        }
        .feature-card:hover {
            transform: translateY(-8px);
            border-color: rgba(212, 168, 83, 0.5);
            box-shadow: 0 12px 40px rgba(212, 168, 83, 0.2);
        }
        .feature-icon {
            font-size: 48px;
            margin-bottom: 20px;
        }
        .feature-card h3 {
            font-size: 24px;
            margin-bottom: 16px;
            color: #D4A853;
        }
        .feature-card p {
            color: #B8B8B8;
            line-height: 1.7;
        }

        /* How It Works */
        .how-it-works {
            padding: 100px 20px;
            background: linear-gradient(180deg, #0E0E14 0%, #1A1A2E 100%);
        }
        .steps {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 30px;
            margin-top: 60px;
        }
        .step {
            text-align: center;
            padding: 30px;
        }
        .step-number {
            width: 60px;
            height: 60px;
            border-radius: 50%;
            background: linear-gradient(135deg, #D4A853 0%, #C67D4D 100%);
            color: #0E0E14;
            font-size: 28px;
            font-weight: 700;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
        }
        .step h3 {
            font-size: 22px;
            margin-bottom: 12px;
            color: #F5F0E6;
        }
        .step p {
            color: #B8B8B8;
        }

        /* Social Proof */
        .social-proof {
            padding: 100px 20px;
            background: #0E0E14;
            text-align: center;
        }
        .stats {
            display: flex;
            justify-content: center;
            gap: 80px;
            flex-wrap: wrap;
            margin-top: 60px;
        }
        .stat {
            text-align: center;
        }
        .stat-number {
            font-size: 48px;
            font-weight: 700;
            background: linear-gradient(135deg, #D4A853 0%, #C67D4D 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 8px;
        }
        .stat-label {
            color: #B8B8B8;
            font-size: 18px;
        }

        /* CTA Section */
        .cta-section {
            padding: 100px 20px;
            background: linear-gradient(135deg, #1A1A2E 0%, #0D1B2A 100%);
            text-align: center;
            position: relative;
            overflow: hidden;
        }
        .cta-section::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 50%;
            width: 600px;
            height: 600px;
            background: radial-gradient(circle, rgba(212, 168, 83, 0.15) 0%, transparent 70%);
            transform: translate(-50%, -50%);
        }
        .cta-content {
            position: relative;
            z-index: 1;
        }
        .cta-section h2 {
            font-size: 42px;
            margin-bottom: 20px;
        }
        .cta-section p {
            font-size: 20px;
            color: #B8B8B8;
            margin-bottom: 40px;
            max-width: 600px;
            margin-left: auto;
            margin-right: auto;
        }

        /* Footer */
        footer {
            padding: 60px 20px 40px;
            background: #0A0A0F;
            text-align: center;
        }
        .footer-links {
            display: flex;
            justify-content: center;
            gap: 40px;
            margin-bottom: 30px;
            flex-wrap: wrap;
        }
        .footer-links a {
            color: #B8B8B8;
            text-decoration: none;
            transition: color 0.3s ease;
        }
        .footer-links a:hover {
            color: #D4A853;
        }
        .copyright {
            color: #706860;
            font-size: 14px;
        }

        /* Responsive */
        @media (max-width: 768px) {
            h1 { font-size: 36px; }
            .hero p { font-size: 18px; }
            .section-title { font-size: 32px; }
            .feature-grid { grid-template-columns: 1fr; }
            .stats { gap: 40px; }
            .cta-buttons { flex-direction: column; }
        }
    </style>
</head>
<body>
    <!-- Hero Section -->
    <section class="hero">
        <div class="hero-content">
            <div class="logo">✦ ASTRONOVA</div>
            <h1>Decode the Cosmic Frequencies<br>Shaping Your Life</h1>
            <p>Authentic Vedic astrology powered by 5,000 years of wisdom and NASA-grade planetary calculations. Your personal guide to timing, relationships, and life's deeper patterns.</p>
            <div class="cta-buttons">
                <a href="#" class="btn btn-primary">Download for iOS</a>
                <a href="#features" class="btn btn-secondary">Learn More</a>
            </div>
        </div>
    </section>

    <!-- Features Section -->
    <section id="features" class="features">
        <div class="container">
            <h2 class="section-title">Everything You Need</h2>
            <p class="section-subtitle">From daily insights to expert consultations, unlock the full spectrum of Vedic astrology</p>

            <div class="feature-grid">
                <div class="feature-card">
                    <div class="feature-icon">🌟</div>
                    <h3>Personalized Daily Insights</h3>
                    <p>Every morning, receive guidance calculated specifically for your unique birth chart. Know where to focus energy, which relationships need attention, and when to take action.</p>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">⏳</div>
                    <h3>Dasha Timeline</h3>
                    <p>See your life's planetary periods mapped on an interactive wheel. Understand which cosmic energies influence you right now and when they shift.</p>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">🔮</div>
                    <h3>AI Oracle</h3>
                    <p>Ask specific questions about timing, decisions, and direction. Get astrological wisdom combined with your birth chart data for personalized guidance.</p>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">💫</div>
                    <h3>Compatibility Analysis</h3>
                    <p>Explore relationship dynamics through synastry and composite charts. Understand how your frequencies interact with others.</p>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">🕉️</div>
                    <h3>Temple Services</h3>
                    <p>Book authentic poojas performed by verified pandits at real temples. Participate via live video streaming from anywhere in the world.</p>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">👤</div>
                    <h3>Expert Consultations</h3>
                    <p>Video sessions with verified Vedic astrologers specializing in career, relationships, health, or spiritual growth. Real expertise, real results.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- How It Works -->
    <section class="how-it-works">
        <div class="container">
            <h2 class="section-title">How It Works</h2>
            <p class="section-subtitle">Get started in minutes, gain insights for a lifetime</p>

            <div class="steps">
                <div class="step">
                    <div class="step-number">1</div>
                    <h3>Create Your Profile</h3>
                    <p>Enter your birth date, time, and location. We calculate your complete Vedic birth chart using Swiss Ephemeris precision.</p>
                </div>

                <div class="step">
                    <div class="step-number">2</div>
                    <h3>Get Daily Insights</h3>
                    <p>Every day, discover personalized guidance based on current planetary transits and your unique chart.</p>
                </div>

                <div class="step">
                    <div class="step-number">3</div>
                    <h3>Explore & Deepen</h3>
                    <p>Dive into your dasha timeline, ask the Oracle questions, or book consultations with expert astrologers.</p>
                </div>

                <div class="step">
                    <div class="step-number">4</div>
                    <h3>Live in Flow</h3>
                    <p>Use cosmic timing to make better decisions, understand relationships, and navigate life with clarity.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Social Proof -->
    <section class="social-proof">
        <div class="container">
            <h2 class="section-title">Trusted by Seekers Worldwide</h2>

            <div class="stats">
                <div class="stat">
                    <div class="stat-number">5,000+</div>
                    <div class="stat-label">Years of Wisdom</div>
                </div>

                <div class="stat">
                    <div class="stat-number">100%</div>
                    <div class="stat-label">Authentic Vedic</div>
                </div>

                <div class="stat">
                    <div class="stat-number">NASA</div>
                    <div class="stat-label">Grade Calculations</div>
                </div>
            </div>
        </div>
    </section>

    <!-- CTA Section -->
    <section class="cta-section">
        <div class="cta-content">
            <h2>Start Your Cosmic Journey Today</h2>
            <p>Join thousands discovering authentic Vedic astrology. Download Astronova and decode the frequencies shaping your life.</p>
            <a href="#" class="btn btn-primary">Download Now</a>
        </div>
    </section>

    <!-- Footer -->
    <footer>
        <div class="footer-links">
            <a href="/support">Support</a>
            <a href="/privacy">Privacy Policy</a>
            <a href="/terms">Terms of Service</a>
        </div>
        <p class="copyright">© 2026 Astronova. All rights reserved.</p>
    </footer>
</body>
</html>"""
        return Response(html, mimetype="text/html")

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
    <p>For questions about these Terms, contact us at <a href="mailto:admin@100xai.engineering">admin@100xai.engineering</a></p>
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
        <li><strong>Usage Analytics:</strong> App usage and session diagnostics collected via Smartlook</li>
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
    <p>We do not sell or trade your personal information. Limited service providers (such as Smartlook) process analytics and session diagnostics strictly to help us improve Astronova.</p>

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
    <p>For privacy-related questions, contact us at <a href="mailto:admin@100xai.engineering">admin@100xai.engineering</a></p>
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
                <a href="mailto:admin@100xai.engineering">admin@100xai.engineering</a><br>
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
        <p>Yes, if you're signed in. Go to <strong>Manage</strong> tab → <strong>Settings</strong> → <strong>Delete Account</strong>. This will permanently remove your account and all associated data.</p>
    </div>

    <h2>Technical Issues</h2>
    <p>If you're experiencing technical problems:</p>
    <ul>
        <li>Make sure you're running the latest version of Astronova from the App Store</li>
        <li>Check your internet connection (required for most features)</li>
        <li>Try force-quitting and restarting the app</li>
        <li>Restart your device if issues persist</li>
    </ul>
    <p>If the problem continues, email us at <a href="mailto:admin@100xai.engineering">admin@100xai.engineering</a> with:</p>
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
