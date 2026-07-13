from __future__ import annotations

import logging
from typing import Any

from flask import Blueprint, jsonify, request
from werkzeug.exceptions import BadRequest

synthesis_bp = Blueprint("synthesis", __name__)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Defensive import — synthesis engine may not be deployed in all environments
# ---------------------------------------------------------------------------
try:
    from services.synthesis_engine import SynthesisEngine

    _engine_available = True
except ImportError:
    _engine_available = False
    logger.warning(
        "SynthesisEngine not available; synthesis endpoints will return 503"
    )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _validate_required_fields(data: dict[str, Any]) -> str | None:
    """Return error message if any required field is missing, else None."""
    required = ["birth_data", "planet_data", "lagna", "dasha_state"]
    for field in required:
        if field not in data or not data[field]:
            return f"Missing required field: {field}"
    return None


def _check_engine_available() -> str | None:
    """Return an error message string if the engine is not importable, else None."""
    if not _engine_available:
        return "SynthesisEngine is not available in this environment"
    return None


# ---------------------------------------------------------------------------
# POST /api/v1/synthesis/mirror — full Cosmic Mirror response
# ---------------------------------------------------------------------------
@synthesis_bp.route("/mirror", methods=["POST"])
def cosmic_mirror():
    """Return the unified CosmicMirrorResponse for the Self tab dashboard.

    Request body (JSON):
        {
            "birth_data": { "date", "time", "timezone", "latitude", "longitude" },
            "planet_data": { "Sun": { "sign", "degree", "house", "retrograde" }, ... },
            "lagna": "Sagittarius",
            "dasha_state": { "mahadasha_lord", "antardasha_lord", ... },
            "user_priors": { ... },       // optional
            "phone_digit_sum": 5          // optional
        }
    """
    err = _check_engine_available()
    if err:
        return jsonify({"error": err, "code": "ENGINE_UNAVAILABLE"}), 503

    try:
        payload = request.get_json(force=False, silent=False)
    except BadRequest:
        return jsonify({
            "error": "Request body must be valid JSON",
            "code": "INVALID_JSON",
        }), 400

    data: dict[str, Any] = payload or {}
    if not isinstance(data, dict):
        return jsonify({
            "error": "Request body must be a JSON object",
            "code": "INVALID_PAYLOAD",
        }), 400

    # --- Validate required fields ----------------------------------------
    field_err = _validate_required_fields(data)
    if field_err:
        return jsonify({"error": field_err, "code": "MISSING_REQUIRED_FIELD"}), 400

    # --- Optional phone_digit_sum type check -----------------------------
    phone_digit_sum = data.get("phone_digit_sum")
    if phone_digit_sum is not None and not isinstance(phone_digit_sum, int):
        return jsonify({
            "error": "phone_digit_sum must be an integer",
            "code": "INVALID_PHONE_DIGIT_SUM",
        }), 400

    # --- Compose ---------------------------------------------------------
    try:
        engine = SynthesisEngine()
        result = engine.compose_cosmic_mirror(
            birth_data=data["birth_data"],
            planet_data=data["planet_data"],
            lagna=data["lagna"],
            dasha_state=data["dasha_state"],
            user_priors=data.get("user_priors"),
            phone_digit_sum=data.get("phone_digit_sum"),
        )
    except Exception:
        logger.exception("Cosmic mirror composition failed")
        return jsonify({
            "error": "Failed to compose cosmic mirror",
            "code": "COMPOSITION_FAILED",
        }), 500

    return jsonify(result), 200


# ---------------------------------------------------------------------------
# POST /api/v1/synthesis/narrative — narrative + archetype only
# ---------------------------------------------------------------------------
@synthesis_bp.route("/narrative", methods=["POST"])
def synthesis_narrative():
    """Return synthesis_narrative string + archetype (lightweight).

    Same input shape as /mirror but returns only the narrative fields.
    Designed for push notifications, widgets, and share cards.
    """
    err = _check_engine_available()
    if err:
        return jsonify({"error": err, "code": "ENGINE_UNAVAILABLE"}), 503

    try:
        payload = request.get_json(force=False, silent=False)
    except BadRequest:
        return jsonify({
            "error": "Request body must be valid JSON",
            "code": "INVALID_JSON",
        }), 400

    data: dict[str, Any] = payload or {}
    if not isinstance(data, dict):
        return jsonify({
            "error": "Request body must be a JSON object",
            "code": "INVALID_PAYLOAD",
        }), 400

    field_err = _validate_required_fields(data)
    if field_err:
        return jsonify({"error": field_err, "code": "MISSING_REQUIRED_FIELD"}), 400

    # Compose the full mirror so we can extract the narrative-only slice.
    try:
        engine = SynthesisEngine()
        full = engine.compose_cosmic_mirror(
            birth_data=data["birth_data"],
            planet_data=data["planet_data"],
            lagna=data["lagna"],
            dasha_state=data["dasha_state"],
            user_priors=data.get("user_priors"),
            phone_digit_sum=data.get("phone_digit_sum"),
        )
    except Exception:
        logger.exception("Narrative extraction failed")
        return jsonify({
            "error": "Failed to generate synthesis narrative",
            "code": "NARRATIVE_FAILED",
        }), 500

    return jsonify({
        "synthesis_narrative": full.get("synthesis_narrative", ""),
        "archetype": full.get("archetype", {}),
    }), 200


# ---------------------------------------------------------------------------
# GET /api/v1/synthesis/status — health check for sub-services
# ---------------------------------------------------------------------------
@synthesis_bp.route("/status", methods=["GET"])
def synthesis_status():
    """Verify that all sub-services required by the synthesis engine are importable.

    Returns:
        {
            "status": "ok" | "degraded",
            "services": { "numerology": bool, "rajayoga": bool, ... }
        }
    """
    services: dict[str, bool] = {}
    for name, module_path in [
        ("numerology", "services.numerology_service"),
        ("rajayoga", "services.rajayoga_service"),
        ("prediction", "services.prediction_service"),
        ("dasha", "services.dasha_service"),
        ("strength", "services.planetary_strength_service"),
        ("synthesis_engine", "services.synthesis_engine"),
    ]:
        try:
            __import__(module_path)
            services[name] = True
        except ImportError:
            services[name] = False

    overall = all(services.values())
    return jsonify({
        "status": "ok" if overall else "degraded",
        "services": services,
    }), 200
