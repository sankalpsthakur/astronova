"""UTC timestamp helpers for Python 3.14-safe current time access."""

from __future__ import annotations

from datetime import UTC, datetime


def utc_now_naive() -> datetime:
    """Return the current UTC time in the existing naive-datetime format."""
    return datetime.now(UTC).replace(tzinfo=None)


def utc_now_iso() -> str:
    """Return the current UTC timestamp as a naive ISO-8601 string."""
    return utc_now_naive().isoformat()
