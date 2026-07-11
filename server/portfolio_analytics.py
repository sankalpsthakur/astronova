# Self-contained: this is the source of truth for astronova. Originally
# derived from a shared design doc; that doc has been retired.
"""Structured logging middleware for the astronova Flask backend.

Emits one JSON line per HTTP request to stdout. The schema is documented in
``ANALYTICS_INTEGRATION.md`` (server log schema section). Render forwards
stdout to a BetterStack log drain; errors duplicate into Sentry.

Usage::

    from flask import Flask
    from portfolio_analytics import install

    app = Flask(__name__)
    install(app, app_id="astronova")
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import secrets
import sys
import time
from typing import Any

from flask import Flask, g, request

__all__ = ["install", "log_line", "normalise_route", "internals"]

_LEVEL_RANK = {"debug": 10, "info": 20, "warn": 30, "error": 40}


def _env_level() -> int:
    return _LEVEL_RANK.get(os.environ.get("LOG_LEVEL", "info"), 20)


_SALT: str | None = None


def _resolve_salt() -> str:
    """Return the IP hash salt.

    IPv4 has ~4B values; without a salt SHA-256(IP) is trivially
    reversible via a rainbow table built from the public IPv4 space. So:

    - If ``IP_HASH_SALT`` is set (>= 8 chars), use it.
    - In production (``FLASK_ENV=production``, ``APP_ENV=production``,
      or ``ENV=production``)
      raise loudly if unset.
    - Otherwise generate a per-process fallback and warn once.
    """
    supplied = os.environ.get("IP_HASH_SALT", "")
    if supplied and len(supplied) >= 8:
        return supplied
    is_production = any(
        os.environ.get(name, "").lower() == "production"
        for name in ("FLASK_ENV", "APP_ENV", "ENV")
    )
    if is_production:
        raise RuntimeError(
            "IP_HASH_SALT must be set (>= 8 chars) in production. "
            "See ANALYTICS_INTEGRATION.md (Privacy posture)."
        )
    fallback = secrets.token_hex(16)
    sys.stderr.write(
        "[astronova portfolio_analytics] IP_HASH_SALT not set; using ephemeral "
        "per-process salt. Set IP_HASH_SALT to enable cross-process "
        "consistent IP grouping.\n"
    )
    return fallback


def _get_salt() -> str:
    global _SALT
    if _SALT is None:
        _SALT = _resolve_salt()
    return _SALT


def _hash_ip(ip: str | None) -> str | None:
    if not ip:
        return None
    digest = hashlib.sha256(f"{ip}|{_get_salt()}".encode("utf-8")).hexdigest()
    return digest[:16]


_IOS_UA = re.compile(r"(?:iPhone\s+OS|iPad\s+OS|iOS)\s+([\d_]+)", re.IGNORECASE)
_ANDROID_UA = re.compile(r"Android\s+([\d.]+)", re.IGNORECASE)
_BOT_UA = re.compile(r"bot|crawl|spider", re.IGNORECASE)


def _classify_user_agent(ua: str | None) -> str:
    if not ua:
        return "unknown"
    if "iphone" in ua.lower() or "ipad" in ua.lower() or "ios" in ua.lower():
        m = _IOS_UA.search(ua)
        return f"ios/{m.group(1).replace('_', '.') if m else 'unknown'}"
    if "android" in ua.lower():
        m = _ANDROID_UA.search(ua)
        return f"android/{m.group(1) if m else 'unknown'}"
    if _BOT_UA.search(ua):
        return "bot"
    return "other"


_UUID_RE = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)


def normalise_route(rule: str | None, raw_path: str) -> str:
    """Prefer Flask's route rule (``/users/<int:id>``) over the literal path.

    Falls back to numeric and UUID substitution when no rule matched (404s).
    """
    if rule:
        return re.sub(r"<(?:[a-z_]+:)?([a-z_]+)>", r":\1", rule)
    parts = raw_path.split("?", 1)[0].split("/")
    out: list[str] = []
    for seg in parts:
        if not seg:
            out.append(seg)
            continue
        if seg.isdigit():
            out.append(":id")
        elif _UUID_RE.match(seg):
            out.append(":id")
        else:
            out.append(seg)
    return "/".join(out)


def _client_ip() -> str | None:
    forwarded = request.headers.get("X-Forwarded-For", "")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.remote_addr


def _user_anon_id() -> str | None:
    auth_ctx = getattr(g, "auth", None)
    if auth_ctx and isinstance(auth_ctx, dict):
        anon = auth_ctx.get("anon_id")
        if anon:
            return anon
    return request.cookies.get("anon_id")


def _generate_request_id() -> str:
    ms = int(time.time() * 1000)
    rnd = secrets.randbits(32)
    combined = (ms << 32) | rnd
    digits = "0123456789ABCDEFGHIJKLMNOPQRSTUV"
    out = []
    v = combined
    while v > 0:
        v, r = divmod(v, 32)
        out.append(digits[r])
    return "".join(reversed(out)).rjust(16, "0")[:16]


_SECRET_KEY_RE = re.compile(
    r"(authorization|password|token|secret|jwt|api[_-]?key|birth|ssn)",
    re.IGNORECASE,
)
_BEARER_RE = re.compile(r"Bearer\s+[A-Za-z0-9\-._~+/]+=*", re.IGNORECASE)


def scrub(value: Any) -> Any:
    """Redact secrets and sensitive substrings from log fields."""
    if value is None:
        return None
    if isinstance(value, dict):
        return {
            k: ("[REDACTED]" if _SECRET_KEY_RE.search(str(k)) else scrub(v))
            for k, v in value.items()
        }
    if isinstance(value, (list, tuple)):
        return [scrub(v) for v in value]
    if isinstance(value, str):
        cleaned = _BEARER_RE.sub("Bearer [REDACTED]", value)
        # Drop long JWT-looking blobs.
        if cleaned.count(".") >= 2 and len(cleaned) > 40:
            return "[REDACTED]"
        return cleaned
    return value


def log_line(app_id: str, level: str, event: str, **fields: Any) -> None:
    """Write one JSON line to stdout. Honours ``LOG_LEVEL``."""
    if _LEVEL_RANK.get(level, 0) < _env_level():
        return
    payload: dict[str, Any] = {
        "ts": time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime())
        + f".{int((time.time() % 1) * 1000):03d}Z",
        "level": level,
        "app": app_id,
        "event": event,
    }
    payload.update({k: scrub(v) for k, v in fields.items() if v is not None})
    sys.stdout.write(json.dumps(payload) + "\n")
    sys.stdout.flush()


def install(app: Flask, *, app_id: str) -> None:
    """Wire the request and error logging into the Flask app."""

    @app.before_request
    def _before():
        g.request_started_at = time.perf_counter()
        rid = request.headers.get("X-Request-ID")
        if not rid:
            rid = _generate_request_id()
        g.request_id = rid

    @app.after_request
    def _after(response):
        rid = getattr(g, "request_id", None)
        if rid:
            response.headers["X-Request-ID"] = rid
        started = getattr(g, "request_started_at", None)
        if started is None:
            return response
        latency = (time.perf_counter() - started) * 1000.0
        rule = str(request.url_rule) if request.url_rule else None
        level = "error" if response.status_code >= 500 else (
            "warn" if response.status_code >= 400 else "info"
        )
        log_line(
            app_id,
            level,
            "http_request",
            request_id=rid,
            method=request.method,
            route=normalise_route(rule, request.path),
            status=response.status_code,
            latency_ms=int(round(latency)),
            user_anon_id=_user_anon_id(),
            ip_hash=_hash_ip(_client_ip()),
            user_agent_class=_classify_user_agent(request.headers.get("User-Agent")),
        )
        return response

    @app.errorhandler(Exception)
    def _on_error(err):
        rid = getattr(g, "request_id", None)
        rule = str(request.url_rule) if request.url_rule else None
        stack = ""
        tb = getattr(err, "__traceback__", None)
        if tb:
            import traceback

            frames = traceback.format_tb(tb)[:3]
            stack = " | ".join(f.strip() for f in frames)
        status_code = getattr(err, "code", 500) or 500
        log_line(
            app_id,
            "error",
            "http_error",
            request_id=rid,
            method=request.method,
            route=normalise_route(rule, request.path),
            status=status_code,
            error_class=type(err).__name__,
            error_message=str(err)[:200],
            stack_top=stack,
        )
        # Return a generic JSON error so we don't leak stack traces or the
        # framework's debug page. The structured log line above already
        # captured the diagnostic detail.
        return {"error": "internal_error", "request_id": rid}, status_code if status_code >= 400 else 500


# Exposed for tests.
internals = {
    "hash_ip": _hash_ip,
    "classify_user_agent": _classify_user_agent,
    "generate_request_id": _generate_request_id,
}
