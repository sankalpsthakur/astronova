from __future__ import annotations

import json
import uuid
from datetime import datetime, timedelta

from flask import Blueprint, jsonify, request

from db import upsert_user

auth_bp = Blueprint("auth", __name__)


def _fake_jwt() -> str:
    # Minimal dev token
    return "demo-token"


@auth_bp.route("", methods=["GET"])
def auth_info():
    return jsonify(
        {
            "service": "auth",
            "status": "available",
            "endpoints": {
                "POST /apple": "Authenticate with Apple Sign-In payload",
                "GET /validate": "Validate Bearer token",
                "POST /refresh": "Refresh token",
                "POST /logout": "Logout",
                "DELETE /delete-account": "Delete account (no-op)",
            },
        }
    )


@auth_bp.route("/apple", methods=["POST"])
def apple_auth():
    raw_body = request.get_data(cache=False, as_text=True)
    if raw_body.strip():
        try:
            payload = json.loads(raw_body)
        except json.JSONDecodeError:
            return (
                jsonify(
                    {
                        "error": "Request body must be valid JSON",
                        "code": "INVALID_JSON",
                    }
                ),
                400,
            )
    else:
        payload = {}

    data = payload or {}
    if not isinstance(data, dict):
        return jsonify({"error": "Request body must be a JSON object", "code": "INVALID_PAYLOAD"}), 400
    user_identifier = data.get("userIdentifier") or str(uuid.uuid4())
    email = data.get("email")
    first_name = data.get("firstName")
    last_name = data.get("lastName")
    full_name = (f"{first_name or ''} {last_name or ''}").strip() or (email or "User")

    upsert_user(user_identifier, email, first_name, last_name, full_name)

    resp = {
        "jwtToken": _fake_jwt(),
        "user": {
            "id": user_identifier,
            "email": email,
            "firstName": first_name,
            "lastName": last_name,
            "fullName": full_name,
            "createdAt": datetime.utcnow().isoformat(),
            "updatedAt": datetime.utcnow().isoformat(),
        },
        "expiresAt": (datetime.utcnow() + timedelta(days=30)).isoformat(),
    }
    return jsonify(resp)


@auth_bp.route("/validate", methods=["GET"])
def validate():
    token = request.headers.get("Authorization", "").replace("Bearer ", "")
    return jsonify({"valid": token == _fake_jwt()})


@auth_bp.route("/refresh", methods=["POST"])
def refresh():
    """Token refresh - requires valid token in Authorization header"""
    auth_header = request.headers.get("Authorization", "")

    if not auth_header or not auth_header.startswith("Bearer "):
        return jsonify({"error": "Authorization header with Bearer token required", "code": "AUTH_REQUIRED"}), 401

    token = auth_header.replace("Bearer ", "").strip()

    # In production, validate token. For demo, accept any non-empty token
    if not token or token == "null" or token == "undefined":
        return jsonify({"error": "Valid token required for refresh", "code": "INVALID_TOKEN"}), 401

    # Issue new token
    new_token = _fake_jwt()
    resp = {
        "jwtToken": new_token,
        "user": {
            "id": "demo-user",
            "email": None,
            "firstName": None,
            "lastName": None,
            "fullName": "Demo User (Refreshed)",
            "createdAt": datetime.utcnow().isoformat(),
            "updatedAt": datetime.utcnow().isoformat(),
        },
        "expiresAt": (datetime.utcnow() + timedelta(days=30)).isoformat(),
    }
    return jsonify(resp)


@auth_bp.route("/logout", methods=["POST"])
def logout():
    return jsonify({"status": "ok"})


@auth_bp.route("/delete-account", methods=["DELETE"])
def delete_account():
    # No-op in minimal build
    return jsonify({"status": "ok"})
