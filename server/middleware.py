"""
Request/Response logging middleware for Flask
"""

import logging
import re
import time
import uuid
from functools import wraps
from typing import Optional, Tuple

from flask import g, jsonify, request

from portfolio_analytics import _classify_user_agent, _hash_ip, log_line, normalise_route

logger = logging.getLogger(__name__)

_REQUEST_ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{7,63}$")


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
    except RuntimeError:
        logger.error("JWT validation unavailable because auth configuration is unsafe")
        return None, {"error": "Authentication is not configured", "code": "AUTH_CONFIG_UNAVAILABLE"}
    except ImportError:
        logger.error("JWT validation unavailable because auth module could not be imported")
        return None, {"error": "Authentication is not configured", "code": "AUTH_CONFIG_UNAVAILABLE"}


def require_auth(f):
    """
    Decorator to require Bearer token authentication on an endpoint.

    Adds `g.user_id` with the authenticated user's ID.
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        user_id, error = get_authenticated_user_id()
        if error:
            status = 503 if error.get("code") == "AUTH_CONFIG_UNAVAILABLE" else 401
            return jsonify(error), status
        g.user_id = user_id
        return f(*args, **kwargs)
    return decorated_function


def setup_logging():
    """Configure structured logging for the application"""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] [req:%(request_id)s user:%(user_id)s] %(name)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    from utils.logging_utils import RequestContextFilter

    root_logger = logging.getLogger()
    for handler in root_logger.handlers:
        if any(isinstance(existing, RequestContextFilter) for existing in handler.filters):
            continue
        handler.addFilter(RequestContextFilter())


def add_request_id():
    """Attach a safe client request ID, or generate one when absent/invalid."""
    supplied = request.headers.get("X-Request-ID", "").strip()
    g.request_id = supplied if _REQUEST_ID_RE.fullmatch(supplied) else uuid.uuid4().hex
    g.start_time = time.time()


def log_request_response(response):
    """Log request and response details"""
    try:
        duration_ms = (time.time() - g.start_time) * 1000 if hasattr(g, "start_time") else 0
        request_id = g.request_id if hasattr(g, "request_id") else "unknown"

        rule = str(request.url_rule) if request.url_rule else None
        level = "error" if response.status_code >= 500 else (
            "warn" if response.status_code >= 400 else "info"
        )
        log_line(
            "astronova",
            level,
            "http_request",
            request_id=request_id,
            method=request.method,
            route=normalise_route(rule, request.path),
            status=response.status_code,
            latency_ms=int(round(duration_ms)),
            # Hash network identity and classify the user agent. Never retain
            # raw headers, query values, request bodies, auth, or user text.
            ip_hash=_hash_ip(request.remote_addr),
            user_agent_class=_classify_user_agent(request.headers.get("User-Agent")),
        )

        # Add request ID to response headers for tracing
        response.headers["X-Request-ID"] = request_id

    except Exception:
        # Do not include exception text or traceback: malformed header/body
        # values can surface in parser errors and must not be copied into logs.
        logger.error("Request logging middleware failed")

    return response
