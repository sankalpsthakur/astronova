"""Unit tests for portfolio_analytics.scrub and request-id correlation helpers."""

from __future__ import annotations

import portfolio_analytics as pa


def test_scrub_redacts_authorization_key():
    out = pa.scrub({"Authorization": "Bearer abc.def.ghi", "ok": "fine"})
    assert out["Authorization"] == "[REDACTED]"
    assert out["ok"] == "fine"


def test_scrub_redacts_bearer_string():
    cleaned = pa.scrub("prefix Bearer eyJhbGciOiJIUzI1NiJ9.abc.def suffix")
    assert "Bearer [REDACTED]" in cleaned


def test_scrub_redacts_jwt_like_blob():
    token = "aaaa.bbbb.cccc" + ("x" * 40)
    assert pa.scrub(token) == "[REDACTED]"


def test_normalise_route_uses_rule():
    assert pa.normalise_route("/users/<int:id>", "/users/1") == "/users/:id"
