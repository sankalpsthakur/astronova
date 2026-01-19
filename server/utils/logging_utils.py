from __future__ import annotations

import logging
from typing import Optional

from flask import g, has_request_context, request


def get_request_id() -> str:
    if has_request_context() and hasattr(g, "request_id"):
        return str(getattr(g, "request_id"))
    return "-"


def get_user_id() -> str:
    if not has_request_context():
        return "-"
    # Prefer authenticated user_id when present; fall back to header-based IDs for legacy routes.
    user_id: Optional[str] = getattr(g, "user_id", None) or request.headers.get("X-User-Id")
    return user_id or "-"


class RequestContextFilter(logging.Filter):
    """Inject request-scoped fields into log records when available."""

    def filter(self, record: logging.LogRecord) -> bool:  # pragma: no cover - tiny adapter
        record.request_id = get_request_id()
        record.user_id = get_user_id()
        return True

