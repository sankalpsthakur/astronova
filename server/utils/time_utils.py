"""UTC timestamp helpers for Python 3.10+ (`timezone.utc`; `datetime.UTC` is 3.11-only)."""

from __future__ import annotations

from datetime import datetime, timezone


def utc_now_naive() -> datetime:
    """Return the current UTC time in the existing naive-datetime format."""
    return datetime.now(timezone.utc).replace(tzinfo=None)


def utc_now_iso() -> str:
    """Return the current UTC timestamp as a naive ISO-8601 string."""
    return utc_now_naive().isoformat()
