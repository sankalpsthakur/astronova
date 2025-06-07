from __future__ import annotations

import datetime as _dt

from flask import Blueprint, current_app, request, send_file, abort

from ..services.reports_service import ReportsService

misc_bp = Blueprint("misc", __name__)


def _get_user_profile(user_id: str) -> dict:
    """Placeholder for fetching a user profile."""
    # In production this would fetch from a database.
    return {
        "full_name": "Test User",
        "birth_datetime": _dt.datetime(1990, 1, 1, 12, 0),
        "latitude": 0.0,
        "longitude": 0.0,
    }


@misc_bp.route("/report", methods=["GET"])
def generate_report() -> "flask.Response":
    user_id = request.headers.get("X-User-ID")
    if not user_id:
        abort(401)

    profile = _get_user_profile(user_id)
    service: ReportsService = current_app.config["reports_service"]
    pdf_io = service.build_report(profile)
    return send_file(
        pdf_io,
        mimetype="application/pdf",
        as_attachment=True,
        download_name="report.pdf",
    )
