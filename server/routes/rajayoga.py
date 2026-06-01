from __future__ import annotations

import logging

from flask import Blueprint, jsonify, request

from services.rajayoga_service import RajayogaService

rajayoga_bp = Blueprint("rajayoga", __name__)

logger = logging.getLogger(__name__)
_service = RajayogaService()


def _validate_planet_data(data: dict) -> tuple[bool, str]:
    """Validate the planet_data dictionary has the expected shape."""
    if not isinstance(data, dict):
        return False, "planet_data must be a JSON object."
    # Each planet entry should have sign and house at minimum
    for planet_name, planet_info in data.items():
        if not isinstance(planet_info, dict):
            return False, f"planet_data.{planet_name} must be a JSON object."
        if "sign" not in planet_info or "house" not in planet_info:
            return False, (
                f"planet_data.{planet_name} must include 'sign' and 'house' keys."
            )
    return True, ""


def _validate_lagna(lagna: str) -> tuple[bool, str]:
    """Validate lagna is a non-empty string."""
    if not lagna or not isinstance(lagna, str) or not lagna.strip():
        return False, "lagna must be a non-empty ascendant sign name."
    return True, ""


def _extract_payload() -> tuple[dict | None, str | None, tuple | None]:
    """Extract and validate planet_data and lagna from the request body.

    Returns (planet_data, lagna, error_response_tuple).
    """
    data = request.get_json(silent=True) or {}
    if not isinstance(data, dict):
        return None, None, (
            jsonify({"error": "Request body must be a JSON object.", "code": "INVALID_JSON"}),
            400,
        )

    planet_data = data.get("planet_data")
    lagna = data.get("lagna")

    # Validate planet_data presence
    if planet_data is None:
        return None, None, (
            jsonify({"error": "planet_data is required.", "code": "MISSING_PLANET_DATA"}),
            400,
        )

    # Validate lagna presence
    if lagna is None:
        return None, None, (
            jsonify({"error": "lagna is required.", "code": "MISSING_LAGNA"}),
            400,
        )

    # Validate planet_data shape
    ok, msg = _validate_planet_data(planet_data)
    if not ok:
        return None, None, (jsonify({"error": msg, "code": "INVALID_PLANET_DATA"}), 400)

    # Validate lagna type
    ok, msg = _validate_lagna(lagna)
    if not ok:
        return None, None, (jsonify({"error": msg, "code": "INVALID_LAGNA"}), 400)

    return planet_data, lagna.strip(), None


@rajayoga_bp.route("/report", methods=["POST"])
def full_report():
    """POST /api/v1/rajayoga/report

    Request body: {"planet_data": {...}, "lagna": "Sagittarius"}
    Returns: yoga_analysis, optimization_matrix, constraints, archetype.
    """
    planet_data, lagna, error = _extract_payload()
    if error is not None:
        return error

    try:
        result = _service.full_rajayoga_report(planet_data, lagna)
    except Exception:
        logger.exception("Rajayoga report generation failed")
        return jsonify({
            "error": "Failed to generate Rajayoga report.",
            "code": "RAJAYOGA_REPORT_FAILED",
        }), 500

    return jsonify(result)


@rajayoga_bp.route("/matrix", methods=["POST"])
def optimization_matrix():
    """POST /api/v1/rajayoga/matrix

    Request body: {"planet_data": {...}, "lagna": "Sagittarius"}
    Returns: optimization_matrix only.
    """
    planet_data, lagna, error = _extract_payload()
    if error is not None:
        return error

    try:
        result = _service.full_rajayoga_report(planet_data, lagna)
    except Exception:
        logger.exception("Rajayoga matrix generation failed")
        return jsonify({
            "error": "Failed to generate optimization matrix.",
            "code": "RAJAYOGA_MATRIX_FAILED",
        }), 500

    return jsonify(result["optimization_matrix"])
