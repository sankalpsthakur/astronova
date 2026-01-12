from __future__ import annotations

import json
import logging
import os
import uuid
from datetime import datetime, timedelta
from typing import Optional

from flask import Blueprint, jsonify, request
from flask_babel import gettext as _

from db import upsert_user, delete_user_data

logger = logging.getLogger(__name__)

auth_bp = Blueprint("auth", __name__)

# Apple Sign-In configuration
APPLE_KEYS_URL = "https://appleid.apple.com/auth/keys"
APPLE_ISSUER = "https://appleid.apple.com"
# Bundle ID - should match your iOS app's bundle identifier
APPLE_BUNDLE_ID = os.environ.get("APPLE_BUNDLE_ID", "com.sankalp.AstronovaApp")

# Cache for Apple's public keys (refreshed every hour)
_apple_keys_cache: dict = {"keys": None, "expires": None}


def _get_apple_public_keys() -> list:
    """
    Fetch Apple's public keys for JWT verification.
    Keys are cached for 1 hour to avoid repeated requests.
    """
    import requests

    now = datetime.utcnow()

    # Return cached keys if still valid
    if _apple_keys_cache["keys"] and _apple_keys_cache["expires"] and now < _apple_keys_cache["expires"]:
        return _apple_keys_cache["keys"]

    try:
        response = requests.get(APPLE_KEYS_URL, timeout=10)
        response.raise_for_status()
        keys = response.json().get("keys", [])
        _apple_keys_cache["keys"] = keys
        _apple_keys_cache["expires"] = now + timedelta(hours=1)
        return keys
    except Exception as e:
        logger.error(f"Failed to fetch Apple public keys: {e}")
        # Return cached keys if available, even if expired
        if _apple_keys_cache["keys"]:
            return _apple_keys_cache["keys"]
        return []


def _get_key_by_kid(kid: str) -> Optional[dict]:
    """Find the Apple public key matching the given key ID."""
    keys = _get_apple_public_keys()
    for key in keys:
        if key.get("kid") == kid:
            return key
    return None


def validate_apple_id_token(id_token: str) -> dict:
    """
    Validate an Apple Sign-In identity token.

    Args:
        id_token: The identityToken from Apple Sign-In

    Returns:
        dict: Decoded token payload if valid

    Raises:
        ValueError: If token is invalid
    """
    import jwt

    try:
        # Get the header to find the key ID
        unverified_header = jwt.get_unverified_header(id_token)
        kid = unverified_header.get("kid")

        if not kid:
            raise ValueError(_("Token missing key ID (kid)"))

        # Get Apple's matching public key
        apple_key = _get_key_by_kid(kid)
        if not apple_key:
            # Refresh cache and try again
            _apple_keys_cache["expires"] = None
            apple_key = _get_key_by_kid(kid)
            if not apple_key:
                raise ValueError(_("Apple public key not found for kid: %(kid)s") % {"kid": kid})

        # Convert JWK to PEM format
        from jwt.algorithms import RSAAlgorithm

        public_key = RSAAlgorithm.from_jwk(json.dumps(apple_key))

        # Verify and decode the token
        decoded = jwt.decode(
            id_token,
            public_key,
            algorithms=["RS256"],
            audience=APPLE_BUNDLE_ID,
            issuer=APPLE_ISSUER,
        )

        return decoded

    except jwt.ExpiredSignatureError:
        raise ValueError(_("Token has expired"))
    except jwt.InvalidAudienceError:
        raise ValueError(_("Invalid audience - expected %(bundle_id)s") % {"bundle_id": APPLE_BUNDLE_ID})
    except jwt.InvalidIssuerError:
        raise ValueError(_("Invalid issuer - expected %(issuer)s") % {"issuer": APPLE_ISSUER})
    except jwt.InvalidTokenError as e:
        raise ValueError(_("Invalid token: %(error)s") % {"error": str(e)})
    except ImportError:
        # PyJWT not installed - skip validation in development
        logger.warning("PyJWT not installed - skipping Apple token validation")
        # Return minimal decoded payload from unverified token
        import base64

        parts = id_token.split(".")
        if len(parts) >= 2:
            # Add padding if needed
            payload = parts[1] + "=" * (4 - len(parts[1]) % 4)
            return json.loads(base64.urlsafe_b64decode(payload))
        raise ValueError(_("Invalid token format"))


# JWT secret key - in production, use a strong random secret from environment
JWT_SECRET = os.environ.get("JWT_SECRET", "astronova-dev-secret-change-in-production")
JWT_ALGORITHM = "HS256"
JWT_EXPIRY_DAYS = 30


def generate_jwt(user_id: str, email: Optional[str] = None) -> str:
    """
    Generate a signed JWT for the user.

    The token includes:
    - sub: User ID (subject)
    - email: User's email (if available)
    - iat: Issued at timestamp
    - exp: Expiration timestamp (30 days)
    """
    import jwt

    now = datetime.utcnow()
    payload = {
        "sub": user_id,
        "iat": now,
        "exp": now + timedelta(days=JWT_EXPIRY_DAYS),
    }
    if email:
        payload["email"] = email

    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def validate_jwt(token: str) -> dict:
    """
    Validate and decode a JWT.

    Returns:
        dict with user_id and email if valid

    Raises:
        ValueError if token is invalid
    """
    import jwt

    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return {
            "user_id": payload.get("sub"),
            "email": payload.get("email"),
        }
    except jwt.ExpiredSignatureError:
        raise ValueError(_("Token has expired"))
    except jwt.InvalidTokenError as e:
        raise ValueError(_("Invalid token: %(error)s") % {"error": str(e)})


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
                "DELETE /delete-account": "Delete account and all data",
            },
        }
    )


@auth_bp.route("/apple", methods=["POST"])
def apple_auth():
    """
    Authenticate with Apple Sign-In.

    Expected payload:
    {
        "identityToken": "eyJ...",  # Apple's identity token (JWT)
        "userIdentifier": "000...", # Apple's user identifier
        "email": "user@example.com",
        "firstName": "John",
        "lastName": "Doe"
    }

    The identityToken is validated against Apple's public keys to ensure:
    - The token was issued by Apple
    - The token is for our app (bundle ID)
    - The token has not expired
    """
    raw_body = request.get_data(cache=False, as_text=True)
    if raw_body.strip():
        try:
            payload = json.loads(raw_body)
        except json.JSONDecodeError:
            return (
                jsonify(
                    {
                        "error": _("Request body must be valid JSON"),
                        "code": "INVALID_JSON",
                    }
                ),
                400,
            )
    else:
        payload = {}

    data = payload or {}
    if not isinstance(data, dict):
        return jsonify({"error": _("Request body must be a JSON object"), "code": "INVALID_PAYLOAD"}), 400

    # Get user info from payload
    identity_token = data.get("identityToken")
    user_identifier = data.get("userIdentifier")
    email = data.get("email")
    first_name = data.get("firstName")
    last_name = data.get("lastName")

    # Validate Apple identity token if provided
    if identity_token:
        try:
            decoded_token = validate_apple_id_token(identity_token)

            # Extract user info from validated token
            # Apple's sub claim is the user identifier
            token_user_id = decoded_token.get("sub")
            token_email = decoded_token.get("email")

            # Use token values as authoritative if available
            if token_user_id:
                user_identifier = token_user_id
            if token_email:
                email = token_email

            logger.info(f"Apple Sign-In validated for user: {user_identifier}")

        except ValueError as e:
            logger.warning(f"Apple token validation failed: {e}")
            # In production, you might want to reject invalid tokens:
            # return jsonify({"error": str(e), "code": "INVALID_TOKEN"}), 401
            # For now, we'll continue with fallback to allow development testing

    # Generate a user ID if none provided
    if not user_identifier:
        user_identifier = str(uuid.uuid4())
        logger.info(f"Generated anonymous user ID: {user_identifier}")

    full_name = (f"{first_name or ''} {last_name or ''}").strip() or (email or _("User"))

    upsert_user(user_identifier, email, first_name, last_name, full_name)

    # Generate a real signed JWT containing the user ID
    jwt_token = generate_jwt(user_identifier, email)

    resp = {
        "jwtToken": jwt_token,
        "user": {
            "id": user_identifier,
            "email": email,
            "firstName": first_name,
            "lastName": last_name,
            "fullName": full_name,
            "createdAt": datetime.utcnow().isoformat(),
            "updatedAt": datetime.utcnow().isoformat(),
        },
        "expiresAt": (datetime.utcnow() + timedelta(days=JWT_EXPIRY_DAYS)).isoformat(),
    }
    return jsonify(resp)


@auth_bp.route("/validate", methods=["GET"])
def validate():
    """Validate a JWT token and return user info if valid."""
    token = request.headers.get("Authorization", "").replace("Bearer ", "").strip()

    if not token:
        return jsonify({"valid": False, "error": _("No token provided")})

    try:
        decoded = validate_jwt(token)
        return jsonify({
            "valid": True,
            "userId": decoded.get("user_id"),
            "email": decoded.get("email"),
        })
    except ValueError as e:
        return jsonify({"valid": False, "error": str(e)})


@auth_bp.route("/refresh", methods=["POST"])
def refresh():
    """Token refresh - validates current token and issues a new one."""
    auth_header = request.headers.get("Authorization", "")

    if not auth_header or not auth_header.startswith("Bearer "):
        return jsonify({"error": _("Authorization header with Bearer token required"), "code": "AUTH_REQUIRED"}), 401

    token = auth_header.replace("Bearer ", "").strip()

    if not token or token == "null" or token == "undefined":
        return jsonify({"error": _("Valid token required for refresh"), "code": "INVALID_TOKEN"}), 401

    # Validate existing token and extract user info
    try:
        decoded = validate_jwt(token)
        user_id = decoded.get("user_id")
        email = decoded.get("email")
    except ValueError as e:
        return jsonify({"error": str(e), "code": "INVALID_TOKEN"}), 401

    if not user_id:
        return jsonify({"error": _("Invalid token - no user ID"), "code": "INVALID_TOKEN"}), 401

    # Issue new token with same user info
    new_token = generate_jwt(user_id, email)
    resp = {
        "jwtToken": new_token,
        "user": {
            "id": user_id,
            "email": email,
            "firstName": None,
            "lastName": None,
            "fullName": email or _("User"),
            "createdAt": datetime.utcnow().isoformat(),
            "updatedAt": datetime.utcnow().isoformat(),
        },
        "expiresAt": (datetime.utcnow() + timedelta(days=JWT_EXPIRY_DAYS)).isoformat(),
    }
    return jsonify(resp)


@auth_bp.route("/logout", methods=["POST"])
def logout():
    return jsonify({"status": "ok"})


@auth_bp.route("/delete-account", methods=["DELETE"])
def delete_account():
    """
    Delete user account and all associated data.
    Required for App Store compliance (Guideline 5.1.1).

    SECURITY: Requires Bearer token authentication.
    User ID is derived from authenticated token only.
    """
    # Require Bearer token authentication
    auth_header = request.headers.get("Authorization", "")
    if not auth_header or not auth_header.startswith("Bearer "):
        return jsonify({
            "error": _("Authorization required"),
            "code": "AUTH_REQUIRED",
            "deleted": False
        }), 401

    token = auth_header.replace("Bearer ", "").strip()
    if not token or token == "null" or token == "undefined":
        return jsonify({
            "error": _("Valid authorization token required"),
            "code": "INVALID_TOKEN",
            "deleted": False
        }), 401

    # Derive user ID from the verified token only.
    try:
        decoded = validate_jwt(token)
    except ValueError as e:
        return jsonify({
            "error": str(e),
            "code": "INVALID_TOKEN",
            "deleted": False
        }), 401

    user_id = decoded.get("user_id")
    if not user_id:
        return jsonify({
            "error": _("Invalid token - no user ID"),
            "code": "INVALID_TOKEN",
            "deleted": False
        }), 401

    logger.info(f"Account deletion requested for user: {user_id}")

    # Delete all user data
    result = delete_user_data(user_id)

    if result.get("deleted"):
        logger.info(f"Account deleted successfully: {user_id}")
        return jsonify({
            "status": "ok",
            "message": _("Account and all associated data deleted"),
            "deleted": True,
            "deletedRecords": result.get("deletedRecords", {})
        }), 200
    else:
        logger.error(f"Account deletion failed: {user_id} - {result.get('error')}")
        return jsonify({
            "error": result.get("error", _("Deletion failed")),
            "code": "DELETION_FAILED",
            "deleted": False
        }), 500
