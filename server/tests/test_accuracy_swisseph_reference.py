from __future__ import annotations

from datetime import datetime
from zoneinfo import ZoneInfo

import pytest

from services.dasha.timeline import TimelineCalculator
from services.ephemeris_service import EphemerisService


try:  # pragma: no cover - optional dependency
    import swisseph as swe

    SWE_OK = True
except Exception:  # pragma: no cover - optional dependency
    swe = None  # type: ignore[assignment]
    SWE_OK = False


def _jd(dt_utc: datetime) -> float:
    return swe.julday(dt_utc.year, dt_utc.month, dt_utc.day, dt_utc.hour + dt_utc.minute / 60 + dt_utc.second / 3600)


def _sign_and_degree(longitude: float, sign_names: list[str]) -> tuple[str, float]:
    sign_index = int(longitude // 30) % 12
    return sign_names[sign_index], longitude % 30


@pytest.mark.external
def test_ephemeris_service_matches_swisseph_tropical_and_sidereal():
    if not SWE_OK:
        pytest.skip("pyswisseph not installed")

    service = EphemerisService()

    dt = datetime(2025, 1, 1, 0, 0)  # UTC
    lat, lon = 19.0760, 72.8777

    jd = _jd(dt)

    # --- Tropical (Western) -------------------------------------------------------------
    xx_sun, _ = swe.calc_ut(jd, swe.SUN)
    expected_sun_lon = float(xx_sun[0])
    expected_sun_sign, expected_sun_deg = _sign_and_degree(expected_sun_lon, list(EphemerisService.ZODIAC_SIGNS))

    cusps, ascmc = swe.houses_ex(jd, lat, lon, b"P", 0)
    expected_asc_lon = float(ascmc[0])
    expected_asc_sign, expected_asc_deg = _sign_and_degree(expected_asc_lon, list(EphemerisService.ZODIAC_SIGNS))

    western = service.get_positions_for_date(dt, lat, lon, system="western")["planets"]
    assert western["sun"]["sign"] == expected_sun_sign
    assert western["sun"]["longitude"] == round(expected_sun_lon, 2)
    assert western["sun"]["degree"] == round(expected_sun_deg, 2)
    assert western["ascendant"]["sign"] == expected_asc_sign
    assert western["ascendant"]["longitude"] == round(expected_asc_lon, 2)
    assert western["ascendant"]["degree"] == round(expected_asc_deg, 2)

    xx_rahu, _ = swe.calc_ut(jd, swe.TRUE_NODE)
    expected_rahu_lon = float(xx_rahu[0])
    expected_rahu_sign, expected_rahu_deg = _sign_and_degree(expected_rahu_lon, list(EphemerisService.ZODIAC_SIGNS))
    expected_ketu_lon = (expected_rahu_lon + 180.0) % 360.0
    expected_ketu_sign, expected_ketu_deg = _sign_and_degree(expected_ketu_lon, list(EphemerisService.ZODIAC_SIGNS))

    assert western["rahu"]["sign"] == expected_rahu_sign
    assert western["rahu"]["longitude"] == round(expected_rahu_lon, 2)
    assert western["rahu"]["degree"] == round(expected_rahu_deg, 2)
    assert western["ketu"]["sign"] == expected_ketu_sign
    assert western["ketu"]["longitude"] == round(expected_ketu_lon, 2)
    assert western["ketu"]["degree"] == round(expected_ketu_deg, 2)

    # --- Sidereal (Vedic/Kundali, Lahiri) ----------------------------------------------
    swe.set_sid_mode(swe.SIDM_LAHIRI, 0, 0)
    xx_sun_sid, _ = swe.calc_ut(jd, swe.SUN, swe.FLG_SIDEREAL)
    expected_sun_sid_lon = float(xx_sun_sid[0])
    expected_sun_sid_sign, expected_sun_sid_deg = _sign_and_degree(expected_sun_sid_lon, list(EphemerisService.VEDIC_SIGNS))

    cusps_sid, ascmc_sid = swe.houses_ex(jd, lat, lon, b"P", swe.FLG_SIDEREAL)
    expected_asc_sid_lon = float(ascmc_sid[0])
    expected_asc_sid_sign, expected_asc_sid_deg = _sign_and_degree(expected_asc_sid_lon, list(EphemerisService.VEDIC_SIGNS))

    vedic = service.get_positions_for_date(dt, lat, lon, system="vedic")["planets"]
    assert vedic["sun"]["sign"] == expected_sun_sid_sign
    assert vedic["sun"]["longitude"] == round(expected_sun_sid_lon, 2)
    assert vedic["sun"]["degree"] == round(expected_sun_sid_deg, 2)
    assert vedic["ascendant"]["sign"] == expected_asc_sid_sign
    assert vedic["ascendant"]["longitude"] == round(expected_asc_sid_lon, 2)
    assert vedic["ascendant"]["degree"] == round(expected_asc_sid_deg, 2)

    xx_rahu_sid, _ = swe.calc_ut(jd, swe.TRUE_NODE, swe.FLG_SIDEREAL)
    expected_rahu_sid_lon = float(xx_rahu_sid[0])
    expected_rahu_sid_sign, expected_rahu_sid_deg = _sign_and_degree(
        expected_rahu_sid_lon, list(EphemerisService.VEDIC_SIGNS)
    )
    expected_ketu_sid_lon = (expected_rahu_sid_lon + 180.0) % 360.0
    expected_ketu_sid_sign, expected_ketu_sid_deg = _sign_and_degree(
        expected_ketu_sid_lon, list(EphemerisService.VEDIC_SIGNS)
    )

    assert vedic["rahu"]["sign"] == expected_rahu_sid_sign
    assert vedic["rahu"]["longitude"] == round(expected_rahu_sid_lon, 2)
    assert vedic["rahu"]["degree"] == round(expected_rahu_sid_deg, 2)
    assert vedic["ketu"]["sign"] == expected_ketu_sid_sign
    assert vedic["ketu"]["longitude"] == round(expected_ketu_sid_lon, 2)
    assert vedic["ketu"]["degree"] == round(expected_ketu_sid_deg, 2)


@pytest.mark.external
def test_chart_generate_vedic_lagna_matches_swisseph(client):
    if not SWE_OK:
        pytest.skip("pyswisseph not installed")

    payload = {
        "birthData": {
            "date": "2025-01-01",
            "time": "00:00",
            "timezone": "UTC",
            "latitude": 19.0760,
            "longitude": 72.8777,
        },
        "systems": ["vedic"],
    }

    response = client.post("/api/v1/chart/generate", json=payload)
    assert response.status_code == 200
    data = response.get_json()
    assert data["vedicChart"] is not None

    vedic_chart = data["vedicChart"]
    lagna = vedic_chart["lagna"]

    dt = datetime(2025, 1, 1, 0, 0)
    jd = _jd(dt)
    lat, lon = 19.0760, 72.8777

    swe.set_sid_mode(swe.SIDM_LAHIRI, 0, 0)
    _cusps, ascmc = swe.houses_ex(jd, lat, lon, b"P", swe.FLG_SIDEREAL)
    expected_asc_sid_lon = float(ascmc[0])
    expected_sign, expected_deg = _sign_and_degree(expected_asc_sid_lon, list(EphemerisService.VEDIC_SIGNS))

    assert lagna["sign"] == expected_sign
    assert lagna["longitude"] == round(expected_asc_sid_lon, 2)
    assert lagna["degree"] == round(expected_deg, 2)
    assert vedic_chart["houses"]["1"]["sign"] == expected_sign


@pytest.mark.external
def test_dashas_complete_starting_dasha_matches_swisseph_moon(client):
    if not SWE_OK:
        pytest.skip("pyswisseph not installed")

    # Use a non-UTC timezone to validate conversion behavior.
    birth_date = "1990-01-15"
    birth_time = "14:30"
    timezone = "Asia/Kolkata"
    lat, lon = 19.0760, 72.8777

    payload = {
        "birthData": {
            "date": birth_date,
            "time": birth_time,
            "timezone": timezone,
            "latitude": lat,
            "longitude": lon,
        },
        "targetDate": "2025-01-01",
        "includeTransitions": False,
        "includeEducation": False,
    }

    response = client.post("/api/v1/astrology/dashas/complete", json=payload)
    assert response.status_code == 200
    data = response.get_json()

    bd_local = datetime.strptime(f"{birth_date}T{birth_time}", "%Y-%m-%dT%H:%M")
    bd_utc = bd_local.replace(tzinfo=ZoneInfo(timezone)).astimezone(ZoneInfo("UTC")).replace(tzinfo=None)
    jd = _jd(bd_utc)

    swe.set_sid_mode(swe.SIDM_LAHIRI, 0, 0)
    xx_moon_sid, _ = swe.calc_ut(jd, swe.MOON, swe.FLG_SIDEREAL)
    moon_sid_lon = float(xx_moon_sid[0])

    expected_lord, expected_balance_years = TimelineCalculator().calculate_starting_dasha(moon_sid_lon)

    starting = data["dasha"]["starting_dasha"]
    assert starting["lord"] == expected_lord
    assert starting["balance_years"] == round(expected_balance_years, 4)
