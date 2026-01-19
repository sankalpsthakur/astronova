from datetime import date

import pytest


try:  # pragma: no cover - optional dependency in some environments
    import swisseph as _swe  # noqa: F401

    _SWE_OK = True
except Exception:  # pragma: no cover
    _SWE_OK = False


def _base_payload():
    return {
        "birthData": {
            "date": "1990-01-15",
            "time": "08:30",
            "timezone": "America/New_York",
            "latitude": 40.7128,
            "longitude": -74.0060,
        },
        "targetDate": date.today().strftime("%Y-%m-%d"),
        "includeTransitions": True,
        "includeEducation": True,
    }


def test_dashas_complete_success(client):
    response = client.post("/api/v1/astrology/dashas/complete", json=_base_payload())

    if not _SWE_OK:
        assert response.status_code == 503
        data = response.get_json()
        assert data["code"] == "SWISS_EPHEMERIS_UNAVAILABLE"
        return

    assert response.status_code == 200

    data = response.get_json()
    assert data is not None

    # Core sections should be present
    assert "current_period" in data
    assert "dasha" in data
    assert "impact_analysis" in data

    current = data["current_period"]
    dasha = data["dasha"]

    assert current["mahadasha"]["lord"]
    assert dasha["mahadasha"]["start"] <= dasha["mahadasha"]["end"]
    assert "combined_scores" in data["impact_analysis"]

    # Ensure optional sections are populated when requested
    education = data.get("education")
    transitions = data.get("transitions")

    assert education is not None
    assert transitions is not None

    assert education["mahadasha_guide"]["lord"]
    assert transitions["impact_comparison"]["current"]["dasha_lord"]


def test_dashas_complete_requires_birth_location(client):
    payload = _base_payload()
    payload["birthData"].pop("latitude")
    payload["birthData"].pop("longitude")

    response = client.post("/api/v1/astrology/dashas/complete", json=payload)

    assert response.status_code == 400
    data = response.get_json()
    assert data["error"] == "birthData with date, latitude, and longitude required"


def test_dashas_complete_rejects_bad_target_date(client):
    payload = _base_payload()
    payload["targetDate"] = "15-01-2024"

    response = client.post("/api/v1/astrology/dashas/complete", json=payload)

    assert response.status_code == 400
    data = response.get_json()
    assert data["error"] == "Invalid targetDate/targetTime format, use YYYY-MM-DD and optional HH:MM"
