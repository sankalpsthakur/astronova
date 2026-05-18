"""Tests for the natal_snapshot field on /astrology/dashas/complete.

The iOS Self tab uses this snapshot to render the active-house tint on the
chart wheel — lagna plus planet -> {sign, house} mapping for the natal chart.
"""

from __future__ import annotations

import pytest

try:  # pragma: no cover - optional dependency in some environments
    import swisseph as _swe  # noqa: F401

    _SWE_OK = True
except Exception:  # pragma: no cover
    _SWE_OK = False


VEDIC_SIGNS = {
    "Mesha", "Vrishabha", "Mithuna", "Karka", "Simha", "Kanya",
    "Tula", "Vrischika", "Dhanu", "Makara", "Kumbha", "Meena",
}


@pytest.fixture
def client():
    from app import create_app

    app = create_app()
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def _birth_payload(target: str = "2025-01-01") -> dict:
    return {
        "birthData": {
            "date": "1990-01-15",
            "time": "14:30",
            "timezone": "Asia/Kolkata",
            "latitude": 19.0760,
            "longitude": 72.8777,
        },
        "targetDate": target,
    }


def test_dashas_complete_emits_natal_snapshot(client):
    """The response must include natal_snapshot with lagna + planet placements."""
    if not _SWE_OK:
        pytest.skip("pyswisseph not installed")
    res = client.post("/api/v1/astrology/dashas/complete", json=_birth_payload())
    assert res.status_code == 200
    data = res.get_json()

    snapshot = data.get("natal_snapshot")
    assert snapshot is not None, "natal_snapshot missing from response"

    lagna = snapshot.get("lagna")
    assert lagna in VEDIC_SIGNS, f"lagna {lagna!r} is not a valid Vedic rashi"

    planets = snapshot.get("planets")
    assert isinstance(planets, dict) and planets, "planets dict missing or empty"

    # Every emitted planet must carry a sign + house, and house must be in 1..12.
    for name, info in planets.items():
        assert name == name.lower(), f"planet key {name!r} must be lowercase"
        assert name != "ascendant", "ascendant must not appear under planets (it's the lagna)"
        assert isinstance(info, dict)
        assert info.get("sign") in VEDIC_SIGNS, f"{name} sign {info.get('sign')!r} invalid"
        house = info.get("house")
        assert isinstance(house, int) and 1 <= house <= 12, f"{name} house {house!r} out of range"

    # Sanity: the major Vedic planets should all be present.
    expected = {"sun", "moon", "mars", "mercury", "jupiter", "venus", "saturn"}
    missing = expected - set(planets.keys())
    assert not missing, f"expected planets missing: {missing}"


def test_natal_snapshot_lagna_house_invariant(client):
    """House numbering is whole-sign: the planet in the same sign as the lagna sits in house 1."""
    if not _SWE_OK:
        pytest.skip("pyswisseph not installed")
    res = client.post("/api/v1/astrology/dashas/complete", json=_birth_payload())
    data = res.get_json()
    snapshot = data["natal_snapshot"]
    lagna = snapshot["lagna"]

    for name, info in snapshot["planets"].items():
        if info["sign"] == lagna:
            assert info["house"] == 1, (
                f"{name} shares lagna sign {lagna} but is in house {info['house']}"
            )
