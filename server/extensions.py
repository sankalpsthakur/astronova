"""Shared Flask extensions.

Defined separately from app.py so route blueprints can import and apply
per-endpoint decorators (e.g. rate limits) without creating an import cycle
with the application factory.
"""

from __future__ import annotations

import os

from flask import request
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address


def rate_limit_key() -> str:
    """Identify the caller for rate limiting.

    Security: the identity is derived from the *verified* JWT bearer token,
    never from the client-supplied ``X-User-Id`` header. Trusting that header
    would let an attacker exhaust another user's limit (or evade their own by
    rotating fake IDs). Unauthenticated requests fall back to the remote IP.
    """
    auth_header = request.headers.get("Authorization", "")
    if auth_header.startswith("Bearer "):
        token = auth_header[len("Bearer "):].strip()
        if token and token not in ("null", "undefined"):
            try:
                from routes.auth import validate_jwt

                decoded = validate_jwt(token)
                user_id = decoded.get("user_id")
                if user_id:
                    return f"user:{user_id}"
            except Exception:
                # Invalid/expired token: fall through to IP-based limiting so
                # a bad token can't be used to bypass limits entirely.
                pass
    return get_remote_address()


# Prefer a shared store (Redis) in multi-process deployments so limits are
# enforced across Gunicorn workers. Without it, each worker keeps its own
# in-memory counters and the effective limit is multiplied by the worker count.
_storage_uri = (
    os.environ.get("RATELIMIT_STORAGE_URI")
    or os.environ.get("REDIS_URL")
    or "memory://"
)

limiter = Limiter(
    key_func=rate_limit_key,
    default_limits=["2000 per day", "500 per hour"],
    storage_uri=_storage_uri,
)
