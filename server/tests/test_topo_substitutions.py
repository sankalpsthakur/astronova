"""Tests for the /api/v1/ephemeris/topo-substitutions endpoint.

The endpoint replaces the iOS-side `TerrainComputer.substitute` pseudo-random
stubs with Swiss-Ephemeris-derived values. These tests assert the response
shape and basic value sanity so accidental regressions are caught fast.
"""
from __future__ import annotations

import re
from datetime import datetime, timedelta, timezone

import pytest
from utils.time_utils import utc_now_naive

try:  # pragma: no cover - optional dep
    import swisseph as _swe  # noqa: F401
except Exception:  # pragma: no cover
    pytest.skip("pyswisseph not installed", allow_module_level=True)


_ASPECT_TYPES = {"", "conjunction", "sextile", "square", "trine", "opposition"}
_ASPECT_ANGLES = {"", "0°", "60°", "90°", "120°", "180°"}


def test_endpoint_returns_200_with_complete_schema(client):
    """Response carries every documented key with the right type."""
    resp = client.get("/api/v1/ephemeris/topo-substitutions")
    assert resp.status_code == 200, resp.get_data(as_text=True)
    data = resp.get_json()
    for key in (
        "void_end_time_iso",
        "void_end_time",
        "aspect_partner",
        "aspect_type",
        "aspect_angle",
        "aspect_orb_degrees",
        "eclipse_distance_days",
        "computed_at_iso",
    ):
        assert key in data, f"missing key {key!r}"
    assert isinstance(data["aspect_orb_degrees"], (int, float))
    assert isinstance(data["eclipse_distance_days"], int)


def test_void_end_time_is_in_the_future(client):
    """The void-of-course end time must always project forward — that was the
    whole point of replacing the iOS pseudo-random stub (which sometimes put
    the time in the user's past)."""
    resp = client.get("/api/v1/ephemeris/topo-substitutions")
    data = resp.get_json()
    iso = data["void_end_time_iso"].rstrip("Z")
    void_dt = datetime.fromisoformat(iso)
    now = utc_now_naive()
    # Must be in the future, capped at moon's max sign-residence (~2.5 days).
    assert void_dt > now
    assert void_dt - now < timedelta(hours=72)


def test_void_end_time_clock_matches_iso(client):
    """The pre-formatted "h:mm AM/PM" clock must agree with the ISO."""
    resp = client.get("/api/v1/ephemeris/topo-substitutions")
    data = resp.get_json()
    clock = data["void_end_time"]
    iso = data["void_end_time_iso"].rstrip("Z")
    void_dt = datetime.fromisoformat(iso)
    expected_hour = void_dt.hour % 12 or 12
    expected_period = "PM" if void_dt.hour >= 12 else "AM"
    expected = f"{expected_hour}:{void_dt.minute:02d} {expected_period}"
    assert clock == expected, f"clock {clock!r} disagrees with iso {iso!r}"


def test_aspect_fields_are_well_formed_or_empty(client):
    """When Moon makes a major aspect within orb, all aspect fields are
    populated; when it doesn't, they're all empty strings together."""
    resp = client.get("/api/v1/ephemeris/topo-substitutions")
    data = resp.get_json()
    assert data["aspect_type"] in _ASPECT_TYPES
    assert data["aspect_angle"] in _ASPECT_ANGLES

    populated = bool(data["aspect_type"])
    if populated:
        # Partner is a planet name when populated.
        assert data["aspect_partner"] in {
            "Sun", "Mercury", "Venus", "Mars", "Jupiter", "Saturn",
        }
        # Orb is non-negative and within the major-aspect tolerance.
        assert 0.0 <= data["aspect_orb_degrees"] <= 8.0
    else:
        assert data["aspect_partner"] == ""
        assert data["aspect_angle"] == ""


def test_eclipse_distance_is_plausible(client):
    """Solar eclipses occur every ~6 months globally. The next one is
    therefore at most ~180 days out, and never negative."""
    resp = client.get("/api/v1/ephemeris/topo-substitutions")
    data = resp.get_json()
    assert data["eclipse_distance_days"] >= 0
    assert data["eclipse_distance_days"] <= 200


def test_computed_at_is_recent(client):
    """The server stamps each response — make sure it's within a few seconds."""
    resp = client.get("/api/v1/ephemeris/topo-substitutions")
    data = resp.get_json()
    stamped = datetime.fromisoformat(data["computed_at_iso"].rstrip("Z"))
    now = utc_now_naive()
    delta = abs((now - stamped).total_seconds())
    assert delta < 5, f"computed_at_iso drifted {delta}s from server clock"


def test_response_pattern_is_iso_with_z_suffix(client):
    """Both timestamp fields are ISO 8601 in UTC, with a trailing `Z`."""
    resp = client.get("/api/v1/ephemeris/topo-substitutions")
    data = resp.get_json()
    iso_pattern = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")
    assert iso_pattern.match(data["void_end_time_iso"])
    assert iso_pattern.match(data["computed_at_iso"])


def test_subsequent_requests_within_same_utc_day_are_cached(client):
    """The endpoint must serve from the per-UTC-day cache on the second hit
    so cold-path Swiss-Ephemeris cost is only paid once per day."""
    import time
    # Warm the cache (first hit pays the full Swiss-Ephemeris cost).
    t0 = time.perf_counter()
    _ = client.get("/api/v1/ephemeris/topo-substitutions")
    cold_ms = (time.perf_counter() - t0) * 1000

    # Hit it again — should be served from the dict-keyed cache.
    t1 = time.perf_counter()
    resp = client.get("/api/v1/ephemeris/topo-substitutions")
    warm_ms = (time.perf_counter() - t1) * 1000

    assert resp.status_code == 200
    # Warm path should be at least an order of magnitude faster than cold.
    # We use a loose 5x bound to avoid flakiness on slow CI runners.
    assert warm_ms * 5 < cold_ms or warm_ms < 5, (
        f"warm path ({warm_ms:.2f}ms) should be much faster than cold "
        f"({cold_ms:.2f}ms) — cache may not be wired"
    )


def test_cached_payload_is_identical_across_requests(client):
    """Two reads on the same UTC day must return byte-identical payloads."""
    r1 = client.get("/api/v1/ephemeris/topo-substitutions").get_json()
    r2 = client.get("/api/v1/ephemeris/topo-substitutions").get_json()
    assert r1 == r2
