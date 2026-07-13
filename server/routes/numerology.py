from __future__ import annotations

import logging
import re
from typing import Any, Dict

from flask import Blueprint, jsonify, request
from werkzeug.exceptions import BadRequest

from services.numerology_service import NumerologyService

numerology_bp = Blueprint("numerology", __name__)

logger = logging.getLogger(__name__)


def _parse_dob_to_digits(dob: str) -> list[int]:
    """Extract all digits from a DOB string like '1999-12-24' -> [1,9,9,9,1,2,2,4]."""
    digits: list[int] = [int(ch) for ch in dob if ch.isdigit()]
    return digits


def _validate_dob(dob: str) -> str | None:
    """Validate DOB format. Returns error message or None if valid."""
    if not dob or not isinstance(dob, str) or not dob.strip():
        return "Date of birth is required (field: dob)"

    # Accept YYYY-MM-DD or DD-MM-YYYY
    pattern = r"^\d{4}-\d{2}-\d{2}$|^\d{2}-\d{2}-\d{4}$"
    if not re.match(pattern, dob.strip()):
        return "Date of birth must be in YYYY-MM-DD or DD-MM-YYYY format (field: dob)"

    return None


@numerology_bp.route("/report", methods=["POST"])
def numerology_report() -> tuple[Any, int]:
    """Generate a full Loshu Grid numerology report from date of birth.

    Request body (JSON):
        {
            "dob": "1999-12-24",            // required, YYYY-MM-DD or DD-MM-YYYY
            "phone_digit_sum": 5            // optional
        }

    Returns the complete numerology report including grid construction,
    eigenvalue analysis, plane completion, driver/conductor numbers,
    and optional phone-number integration.
    """
    try:
        payload = request.get_json(force=False, silent=False)
    except BadRequest:
        return jsonify({
            "error": "Request body must be valid JSON",
            "code": "INVALID_JSON",
        }), 400

    data: Dict[str, Any] = payload or {}
    if not isinstance(data, dict):
        return jsonify({
            "error": "Request body must be a JSON object",
            "code": "INVALID_PAYLOAD",
        }), 400

    # --- Validate DOB ---------------------------------------------------
    dob: str | None = data.get("dob")
    error: str | None = _validate_dob(dob if isinstance(dob, str) else None)
    if error is not None:
        return jsonify({"error": error, "code": "INVALID_DOB"}), 400

    # --- Parse DOB into digits ------------------------------------------
    try:
        digits: list[int] = _parse_dob_to_digits(dob)
    except Exception:
        return jsonify({
            "error": "Failed to parse date of birth digits",
            "code": "DOB_PARSE_ERROR",
        }), 400

    if not digits:
        return jsonify({
            "error": "Date of birth contains no digits",
            "code": "EMPTY_DOB",
        }), 400

    # --- Optional phone digit sum ---------------------------------------
    phone_digit_sum_raw = data.get("phone_digit_sum")
    phone_digit_sum: int | None = None
    if phone_digit_sum_raw is not None:
        if not isinstance(phone_digit_sum_raw, int):
            return jsonify({
                "error": "phone_digit_sum must be an integer",
                "code": "INVALID_PHONE_DIGIT_SUM",
            }), 400
        phone_digit_sum = phone_digit_sum_raw

    # --- Generate report ------------------------------------------------
    try:
        service = NumerologyService()
        report = service.full_numerology_report(digits, phone_digit_sum)
    except Exception:
        logger.exception("Numerology report generation failed")
        return jsonify({
            "error": "Failed to generate numerology report",
            "code": "REPORT_GENERATION_FAILED",
        }), 500

    # --- Return ---------------------------------------------------------
    return jsonify({"disclaimer": "For entertainment purposes only. Not professional advice.", **report}), 200
