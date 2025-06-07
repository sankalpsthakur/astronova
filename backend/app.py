from __future__ import annotations

from flask import Flask

from .routes.misc import misc_bp
from .services.reports_service import ReportsService


def create_app(anthropic_api_key: str) -> Flask:
    app = Flask(__name__)
    app.config["reports_service"] = ReportsService(anthropic_api_key)
    app.register_blueprint(misc_bp)
    return app


if __name__ == "__main__":
    import os

    api_key = os.environ.get("ANTHROPIC_API_KEY", "")
    app = create_app(api_key)
    app.run(debug=True)
