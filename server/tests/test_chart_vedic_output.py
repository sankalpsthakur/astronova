from __future__ import annotations

import pytest

from services.ephemeris_service import EphemerisService


try:  # pragma: no cover - optional dependency in some environments
    import swisseph as _swe  # noqa: F401

    _SWE_OK = True
except Exception:  # pragma: no cover
    _SWE_OK = False

pytestmark = pytest.mark.ephemeris


def test_chart_generate_returns_western_chart_by_default(client):
    if not _SWE_OK:
        pytest.skip("pyswisseph not installed")
    response = client.post(
        "/api/v1/chart/generate",
        json={
            "birthData": {
                "date": "1990-01-15",
                "time": "14:30",
                "timezone": "UTC",
                "latitude": 19.0760,
                "longitude": 72.8777,
            },
            # iOS client currently sends "tropical" as the default system
            "systems": ["tropical"],
        },
    )

    assert response.status_code == 200
    data = response.get_json()
    assert isinstance(data, dict)

    assert "charts" in data
    assert "western" in data["charts"]
    assert data.get("westernChart") is not None

    western = data["westernChart"]
    assert "positions" in western
    assert "houses" in western
    assert "aspects" in western

    assert set(western["houses"].keys()) == {str(i) for i in range(1, 13)}
    assert western["positions"]["sun"]["sign"] in EphemerisService.ZODIAC_SIGNS
    assert western["positions"]["moon"]["sign"] in EphemerisService.ZODIAC_SIGNS
    assert isinstance(western["positions"]["sun"]["house"], int)


def test_chart_generate_can_return_full_vedic_chart_with_dashas(client):
    if not _SWE_OK:
        pytest.skip("pyswisseph not installed")
    response = client.post(
        "/api/v1/chart/generate",
        json={
            "birthData": {
                "date": "1990-01-15",
                "time": "14:30",
                "timezone": "UTC",
                "latitude": 19.0760,
                "longitude": 72.8777,
            },
            "systems": ["tropical", "vedic"],
        },
    )

    assert response.status_code == 200
    data = response.get_json()
    assert isinstance(data, dict)

    assert "western" in data["charts"]
    assert "vedic" in data["charts"]
    assert data.get("vedicChart") is not None

    vedic = data["vedicChart"]
    assert "positions" in vedic
    assert "houses" in vedic
    assert "dashas" in vedic

    # Lagna + whole-sign houses (1..12)
    assert set(vedic["houses"].keys()) == {str(i) for i in range(1, 13)}
    lagna_sign = vedic.get("lagna", {}).get("sign")
    assert lagna_sign in EphemerisService.VEDIC_SIGNS
    assert vedic["houses"]["1"]["sign"] == lagna_sign

    # Sidereal sign names should use the Vedic sign set (not Western names)
    assert vedic["positions"]["sun"]["sign"] in EphemerisService.VEDIC_SIGNS
    assert vedic["positions"]["moon"]["sign"] in EphemerisService.VEDIC_SIGNS

    # Mahadasha timeline payload (current + upcoming)
    dashas = vedic["dashas"]
    assert isinstance(dashas, list)
    assert len(dashas) >= 1
    assert isinstance(dashas[0].get("planet"), str)
    assert isinstance(dashas[0].get("startDate"), str)
    assert isinstance(dashas[0].get("endDate"), str)


def test_chart_aspects_post_returns_list(client):
    if not _SWE_OK:
        pytest.skip("pyswisseph not installed")
    response = client.post(
        "/api/v1/chart/aspects",
        json={
            "birthData": {
                "date": "1990-01-15",
                "time": "14:30",
                "timezone": "UTC",
                "latitude": 19.0760,
                "longitude": 72.8777,
            }
        },
    )

    assert response.status_code == 200
    data = response.get_json()
    assert isinstance(data, list)
    if data:
        assert "planet1" in data[0]
        assert "planet2" in data[0]
        assert "orb" in data[0]
        assert "type" in data[0] or "aspect" in data[0]


def test_chart_aspects_get_by_date_returns_list(client):
    if not _SWE_OK:
        pytest.skip("pyswisseph not installed")
    response = client.get("/api/v1/chart/aspects?date=2025-01-01")
    assert response.status_code == 200
    data = response.get_json()
    assert isinstance(data, list)
