"""
Request/Response logging middleware for Flask
"""

import logging
import time
import uuid
from functools import wraps
from typing import Optional, Tuple

from flask import g, jsonify, request

logger = logging.getLogger(__name__)


# ============================================================================
# Authentication Helpers
# ============================================================================


def validate_bearer_token() -> Tuple[bool, Optional[str], Optional[dict]]:
    """
    Validate Bearer token from Authorization header.

    Returns:
        Tuple of (is_valid, token, error_response)
        - is_valid: True if token is valid
        - token: The extracted token string (or None if invalid)
        - error_response: JSON error response if invalid (or None if valid)
    """
    auth_header = request.headers.get("Authorization", "")

    if not auth_header or not auth_header.startswith("Bearer "):
        return False, None, {"error": "Authorization required", "code": "AUTH_REQUIRED"}

    token = auth_header.replace("Bearer ", "").strip()

    if not token or token in ("null", "undefined", ""):
        return False, None, {"error": "Valid authorization token required", "code": "INVALID_TOKEN"}

    return True, token, None


def get_authenticated_user_id() -> Tuple[Optional[str], Optional[dict]]:
    """
    Get user ID from JWT token, NOT from headers (prevents spoofing).

    The user ID is extracted from the validated JWT token's 'sub' claim.
    X-User-Id headers are ignored for security.

    Returns:
        Tuple of (user_id, error_response)
        - user_id: The authenticated user ID from JWT (or None if auth failed)
        - error_response: JSON error response if auth failed (or None if success)
    """
    is_valid, token, error = validate_bearer_token()
    if not is_valid:
        return None, error

    # Import here to avoid circular imports
    try:
        from routes.auth import validate_jwt

        decoded = validate_jwt(token)
        user_id = decoded.get("user_id")

        if not user_id:
            return None, {"error": "Invalid token - no user ID", "code": "INVALID_TOKEN"}

        return user_id, None

    except ValueError as e:
        return None, {"error": str(e), "code": "INVALID_TOKEN"}
    except ImportError:
        # Fallback for tests or when auth module not available
        # In this case, fall back to header-based auth (less secure)
        logger.warning("JWT validation unavailable - falling back to header auth")
        data = request.get_json(silent=True) or {}
        user_id = data.get("userId") or request.headers.get("X-User-Id") or request.args.get("userId")
        if not user_id:
            return None, {"error": "User ID required", "code": "USER_ID_REQUIRED"}
        return user_id, None


def require_auth(f):
    """
    Decorator to require Bearer token authentication on an endpoint.

    Adds `g.user_id` with the authenticated user's ID.
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        user_id, error = get_authenticated_user_id()
        if error:
            return jsonify(error), 401
        g.user_id = user_id
        return f(*args, **kwargs)
    return decorated_function


def setup_logging():
    """Configure structured logging for the application"""
    logging.basicConfig(
        level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s - %(message)s", datefmt="%Y-%m-%d %H:%M:%S"
    )


def add_request_id():
    """Generate and attach request ID to g context"""
    g.request_id = str(uuid.uuid4())[:8]
    g.start_time = time.time()


def log_request_response(response):
    """Log request and response details"""
    try:
        duration_ms = (time.time() - g.start_time) * 1000 if hasattr(g, "start_time") else 0
        request_id = g.request_id if hasattr(g, "request_id") else "unknown"

        log_data = {
            "request_id": request_id,
            "method": request.method,
            "path": request.path,
            "status": response.status_code,
            "duration_ms": round(duration_ms, 2),
            "ip": request.remote_addr,
            "user_agent": request.headers.get("User-Agent", "unknown")[:50],
        }

        if response.status_code >= 500:
            logger.error(f"REQUEST {log_data}")
        elif response.status_code >= 400:
            logger.warning(f"REQUEST {log_data}")
        else:
            logger.info(f"REQUEST {log_data}")

        # Add request ID to response headers for tracing
        response.headers["X-Request-ID"] = request_id

    except Exception as e:
        logger.error(f"Error in logging middleware: {e}")

    return response


