from __future__ import annotations

from datetime import datetime

from flask import Blueprint, jsonify, request
from utils.time_utils import utc_now_naive

predictions_bp = Blueprint("predictions", __name__)

# PredictionService may not exist yet — import defensively.
_PredictionService = None
_SERVICE_IMPORT_ERROR: str | None = None

try:
    from services.prediction_service import PredictionService

    _PredictionService = PredictionService
except ImportError as exc:
    _SERVICE_IMPORT_ERROR = (
        f"prediction_service not available ({exc}). "
        "Prediction endpoints will return 503 until the service is deployed."
    )


def _get_service():
    """Return a PredictionService instance or raise a 503-friendly error."""
    if _PredictionService is None:
        raise RuntimeError(_SERVICE_IMPORT_ERROR or "PredictionService is unavailable")
    return _PredictionService()


def _parse_date(value: str, field_name: str) -> datetime:
    """Parse YYYY-MM-DD string; raise ValueError with a field name on failure."""
    if not value:
        raise ValueError(f"'{field_name}' is required")
    try:
        return datetime.strptime(value, "%Y-%m-%d")
    except (ValueError, TypeError):
        raise ValueError(f"'{field_name}' must be in YYYY-MM-DD format")


def _normalize_dasha_state(dasha_state: dict) -> dict:
    """Accept flat client dasha keys and feed PredictionService's nested shape."""
    if not isinstance(dasha_state, dict):
        return {}

    if "mahadasha" in dasha_state or "antardasha" in dasha_state:
        return dasha_state

    return {
        "mahadasha": {
            "lord": dasha_state.get("mahadasha_lord", ""),
            "start": dasha_state.get("mahadasha_start", ""),
            "end": dasha_state.get("mahadasha_end", ""),
        },
        "antardasha": {
            "lord": dasha_state.get("antardasha_lord", ""),
        },
    }


@predictions_bp.route("/timeline", methods=["POST"])
def timeline():
    """Generate a full prediction timeline for a birth chart + dasha state.

    POST body:
        birth_data   — dict  (date, time, timezone, latitude, longitude)
        dasha_state  — dict  (mahadasha_lord, antardasha_lord)
        start_date   — str   YYYY-MM-DD
        end_date     — str   YYYY-MM-DD
        user_priors  — dict  (optional) projects, career_target, location, current_focus

    Returns:
        triggers, monthly_timeline, summary, peak_windows
    """
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Request body must be valid JSON"}), 400

    birth_data = data.get("birth_data")
    dasha_state = data.get("dasha_state")
    start_date = data.get("start_date")
    end_date = data.get("end_date")
    user_priors = data.get("user_priors")

    # --- Validate required fields ---
    errors: list[str] = []

    if not birth_data or not isinstance(birth_data, dict):
        errors.append("'birth_data' is required and must be an object")
    else:
        for field in ("date", "time", "timezone", "latitude", "longitude"):
            if field not in birth_data:
                errors.append(f"'birth_data.{field}' is required")

    if not dasha_state or not isinstance(dasha_state, dict):
        errors.append("'dasha_state' is required and must be an object")
    else:
        for field in ("mahadasha_lord", "antardasha_lord"):
            if field not in dasha_state:
                errors.append(f"'dasha_state.{field}' is required")

    try:
        _parse_date(start_date or "", "start_date")
    except ValueError as exc:
        errors.append(str(exc))

    try:
        _parse_date(end_date or "", "end_date")
    except ValueError as exc:
        errors.append(str(exc))

    if errors:
        return jsonify({"error": "Validation failed", "details": errors}), 400

    # --- Call the service ---
    try:
        service = _get_service()
    except RuntimeError as exc:
        return jsonify({"error": "Service unavailable", "message": str(exc)}), 503

    report = service.full_prediction_report(
        birth_data=birth_data,
        dasha_state=_normalize_dasha_state(dasha_state),
        start_date=start_date,
        end_date=end_date,
        user_priors=user_priors,
    )

    return jsonify(report)


@predictions_bp.route("/peaks", methods=["GET"])
def peaks():
    """Return only peak_windows for the next N months (lightweight, home-screen widget).

    Query params:
        birth_date        — str  YYYY-MM-DD (required)
        birth_time        — str  HH:MM    (default "12:00")
        timezone          — str           (default "UTC")
        lat               — float         (required)
        lon               — float         (required)
        lookahead_months  — int           (default 12)

    Returns:
        peak_windows list for the requested lookahead.
    """
    birth_date = request.args.get("birth_date")
    birth_time = request.args.get("birth_time", "12:00")
    timezone = request.args.get("timezone", "UTC")
    lat = request.args.get("lat")
    lon = request.args.get("lon")
    lookahead_months = request.args.get("lookahead_months", "12")

    errors: list[str] = []

    if not birth_date:
        errors.append("'birth_date' query parameter is required")
    if not lat:
        errors.append("'lat' query parameter is required")
    if not lon:
        errors.append("'lon' query parameter is required")

    try:
        lookahead = int(lookahead_months)
    except (TypeError, ValueError):
        errors.append("'lookahead_months' must be an integer")
        lookahead = 12

    if errors:
        return jsonify({"error": "Validation failed", "details": errors}), 400

    try:
        _parse_date(birth_date, "birth_date")
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 400

    try:
        lat_val = float(lat)
        lon_val = float(lon)
    except (TypeError, ValueError):
        return jsonify({"error": "'lat' and 'lon' must be valid numbers"}), 400

    birth_data = {
        "date": birth_date,
        "time": birth_time,
        "timezone": timezone,
        "latitude": lat_val,
        "longitude": lon_val,
    }

    try:
        service = _get_service()
    except RuntimeError as exc:
        return jsonify({"error": "Service unavailable", "message": str(exc)}), 503

    report = service.full_prediction_report(
        birth_data=birth_data,
        dasha_state={},
        start_date=utc_now_naive().strftime("%Y-%m-%d"),
        end_date=utc_now_naive().strftime("%Y-%m-%d"),
        user_priors=None,
    )

    # The /peaks endpoint only surfaces peak_windows. If the service returns a
    # richer report, filter down to what the lightweight client needs.
    peak_windows = report.get("peak_windows", []) if isinstance(report, dict) else []

    # Slice to the requested lookahead window (the service may return more).
    from datetime import timedelta

    cutoff = utc_now_naive() + timedelta(days=lookahead * 30)
    cutoff_str = cutoff.strftime("%Y-%m-%d")
    filtered = [pw for pw in peak_windows if pw.get("date", "") <= cutoff_str]

    return jsonify({"peak_windows": filtered, "lookahead_months": lookahead})
