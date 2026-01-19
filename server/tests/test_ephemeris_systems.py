from __future__ import annotations

import pytest

from services.ephemeris_service import EphemerisService


try:  # pragma: no cover - optional dependency in some environments
    import swisseph as _swe  # noqa: F401

    _SWE_OK = True
except Exception:  # pragma: no cover
    _SWE_OK = False

pytestmark = pytest.mark.ephemeris


def _planet_by_id(planets: list[dict], planet_id: str) -> dict:
    for planet in planets:
        if planet.get("id") == planet_id:
            return planet
    raise AssertionError(f"Planet with id={planet_id!r} not found")


def test_ephemeris_current_supports_western_and_vedic_systems(client):
    if not _SWE_OK:
        pytest.skip("pyswisseph not installed")
    lat, lon = 19.0760, 72.8777

    western_resp = client.get(f"/api/v1/ephemeris/current?system=western&lat={lat}&lon={lon}")
    assert western_resp.status_code == 200
    western = western_resp.get_json()

    vedic_resp = client.get(f"/api/v1/ephemeris/current?system=vedic&lat={lat}&lon={lon}")
    assert vedic_resp.status_code == 200
    vedic = vedic_resp.get_json()

    assert western["has_rising_sign"] is True
    assert vedic["has_rising_sign"] is True

    western_sun = _planet_by_id(western["planets"], "sun")
    vedic_sun = _planet_by_id(vedic["planets"], "sun")
    assert western_sun["sign"] in EphemerisService.ZODIAC_SIGNS
    assert vedic_sun["sign"] in EphemerisService.VEDIC_SIGNS

    western_asc = _planet_by_id(western["planets"], "ascendant")
    vedic_asc = _planet_by_id(vedic["planets"], "ascendant")
    assert western_asc["sign"] in EphemerisService.ZODIAC_SIGNS
    assert vedic_asc["sign"] in EphemerisService.VEDIC_SIGNS


def test_ephemeris_at_supports_vedic_system(client):
    if not _SWE_OK:
        pytest.skip("pyswisseph not installed")
    response = client.get("/api/v1/ephemeris/at?date=2025-01-01&system=vedic&lat=19.0760&lon=72.8777")
    assert response.status_code == 200
    data = response.get_json()

    sun = _planet_by_id(data["planets"], "sun")
    assert sun["sign"] in EphemerisService.VEDIC_SIGNS
