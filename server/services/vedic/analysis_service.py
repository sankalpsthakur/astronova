"""Orchestrates detailed Vedic analysis for reports."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Any, Optional
from zoneinfo import ZoneInfo

from services.dasha.timeline import TimelineCalculator
from services.dasha_service import DashaService
from services.ephemeris_service import EphemerisService

from .divisional_charts_service import compute_d9_d10
from .dosha_service import kalsarpa_status, manglik_status
from .houses_service import build_whole_sign_houses, house_number_for_sign
from .nakshatra_service import nakshatra_from_longitude
from .panchang_service import calculate_panchang
from .sadesati_service import sade_sati_status
from .sunrise_service import sunrise_sunset_for_date
from .constants import (
    NAKSHATRA_GANA,
    NAKSHATRA_NADI,
    NAKSHATRA_YONI,
    SIGN_ELEMENT,
    VASHYA_BY_MOON_SIGN,
    VARNA_BY_MOON_SIGN,
    VEDIC_SIGN_RULERS,
)


@dataclass
class VedicAnalysisService:
    ephemeris: EphemerisService
    dashas: DashaService

    def __init__(self, ephemeris: Optional[EphemerisService] = None, dashas: Optional[DashaService] = None) -> None:
        self.ephemeris = ephemeris or EphemerisService()
        self.dashas = dashas or DashaService()

    def analyze(
        self,
        *,
        birth_dt_utc: datetime,
        latitude: float,
        longitude: float,
        timezone: str,
    ) -> dict[str, Any]:
        positions = self.ephemeris.get_positions_for_date(birth_dt_utc, latitude, longitude, system="vedic")
        ayanamsha = positions.get("ayanamsha") if isinstance(positions, dict) else None
        planets = positions.get("planets", {}) if isinstance(positions, dict) else {}

        lagna = planets.get("ascendant") if isinstance(planets.get("ascendant"), dict) else {}
        lagna_sign = str(lagna.get("sign") or "")
        if lagna_sign:
            lagna_lord = VEDIC_SIGN_RULERS.get(lagna_sign)
            lagna = {**lagna, "lord": lagna_lord}

        # Enrich planet dict with houses + nakshatras.
        enriched: dict[str, dict[str, Any]] = {}
        longitudes: dict[str, float] = {}

        for name, info in planets.items():
            if not isinstance(info, dict):
                continue
            sign = str(info.get("sign") or "")
            lon = info.get("longitude")
            deg = info.get("degree")
            if isinstance(lon, (int, float)):
                longitudes[str(name).lower()] = float(lon) % 360.0

            payload: dict[str, Any] = dict(info)
            if lagna_sign and sign:
                house = house_number_for_sign(lagna_sign=lagna_sign, planet_sign=sign)
                if house:
                    payload["house"] = house
            if isinstance(lon, (int, float)):
                nak = nakshatra_from_longitude(float(lon))
                payload["nakshatra"] = nak.__dict__
            if isinstance(deg, (int, float)):
                payload["degree"] = round(float(deg), 2)
            if isinstance(lon, (int, float)):
                payload["longitude"] = round(float(lon) % 360.0, 4)
            enriched[str(name).lower()] = payload

        houses = build_whole_sign_houses(lagna_sign=lagna_sign, planets_by_name=enriched) if lagna_sign else {}

        # Panchang (based on Sun/Moon longitudes at birth moment)
        sun_lon = float(enriched.get("sun", {}).get("longitude", 0.0))
        moon_lon = float(enriched.get("moon", {}).get("longitude", 0.0))
        panchang = calculate_panchang(sun_longitude=sun_lon, moon_longitude=moon_lon)

        # Avakhada-like attributes derived from Moon nakshatra/sign (single-person view).
        moon_sign = str(enriched.get("moon", {}).get("sign") or "")
        moon_nak = (enriched.get("moon", {}).get("nakshatra") or {}) if isinstance(enriched.get("moon", {}), dict) else {}
        moon_nak_name = str(moon_nak.get("name") or "")

        # Add Moon nakshatra + sunrise/sunset to Panchang.
        if isinstance(moon_nak, dict) and moon_nak.get("name"):
            panchang["nakshatra"] = {
                "name": moon_nak.get("name"),
                "lord": moon_nak.get("lord"),
                "pada": moon_nak.get("pada"),
            }
        try:
            dt_local = birth_dt_utc.replace(tzinfo=ZoneInfo("UTC")).astimezone(ZoneInfo(timezone))
            panchang["sunriseSunset"] = sunrise_sunset_for_date(
                local_date=dt_local.date(),
                timezone=timezone,
                latitude=float(latitude),
                longitude=float(longitude),
            )
        except Exception:
            panchang["sunriseSunset"] = None

        avakhada = {
            "moonSign": moon_sign or None,
            "moonNakshatra": moon_nak_name or None,
            "varna": VARNA_BY_MOON_SIGN.get(moon_sign),
            "vashya": VASHYA_BY_MOON_SIGN.get(moon_sign),
            "tatva": SIGN_ELEMENT.get(moon_sign),
            "gana": NAKSHATRA_GANA.get(moon_nak_name),
            "nadi": NAKSHATRA_NADI.get(moon_nak_name),
            "yoni": NAKSHATRA_YONI.get(moon_nak_name),
            "explainLikeImFive": {
                "varna": "A traditional archetype label based on your Moon sign (often used in matchmaking).",
                "vashya": "A traditional ‘influence’ category for your Moon sign (often used in matchmaking).",
                "gana": "A temperament grouping for your Moon nakshatra (Deva/Manushya/Rakshasa).",
                "nadi": "A classical grouping used in compatibility checks; not a medical diagnosis.",
                "yoni": "An animal archetype used in compatibility scoring; symbolic, not literal.",
            },
        }

        # Vimshottari Dashas (current timing + report timeline).
        dasha_payload: dict[str, Any] | None = None
        try:
            dasha_info = self.dashas.calculate_complete_dasha(
                birth_date=birth_dt_utc,
                moon_longitude=moon_lon,
                target_date=datetime.utcnow(),
                include_future=True,
                num_future_periods=9,
            )
            dasha_payload = dasha_info
        except Exception:
            dasha_payload = None

        # Dasha timelines
        mahadasha_timeline: list[dict[str, Any]] = []
        dasha_timeline_120y: list[dict[str, Any]] = []
        if dasha_payload and isinstance(dasha_payload.get("starting_dasha"), dict):
            starting = dasha_payload["starting_dasha"]
            try:
                start_lord = str(starting.get("lord") or "")
                balance_years = float(starting.get("balance_years") or 0.0)
                calc = TimelineCalculator()
                timeline = calc.generate_mahadasha_timeline(birth_dt_utc, start_lord, balance_years, num_periods=9)
                mahadasha_timeline = [
                    {"lord": t["lord"], "start": t["start"].date().isoformat(), "end": t["end"].date().isoformat()}
                    for t in timeline
                ]

                horizon_end = calc._add_years_months(birth_dt_utc, years=120)
                extended = calc.generate_mahadasha_timeline(birth_dt_utc, start_lord, balance_years, num_periods=30)
                for period in extended:
                    start_dt = period["start"]
                    end_dt = period["end"]
                    if start_dt >= horizon_end:
                        break
                    clipped_end = end_dt if end_dt <= horizon_end else horizon_end
                    antars = calc.calculate_antardasha(period["lord"], start_dt, clipped_end)
                    dasha_timeline_120y.append(
                        {
                            "lord": period["lord"],
                            "start": start_dt.date().isoformat(),
                            "end": clipped_end.date().isoformat(),
                            "antardashas": [
                                {"lord": a["lord"], "start": a["start"].date().isoformat(), "end": a["end"].date().isoformat()}
                                for a in antars
                            ],
                        }
                    )
            except Exception:
                mahadasha_timeline = []
                dasha_timeline_120y = []

        # Divisional charts
        divisional = compute_d9_d10(planets_by_name=enriched)

        # Yogas (subset)
        from .yoga_service import detect_yogas

        yogas = detect_yogas(lagna_sign=lagna_sign, planets=enriched) if lagna_sign else []

        # Doshas (subset)
        venus_sign = str(enriched.get("venus", {}).get("sign") or "")
        mars_sign = str(enriched.get("mars", {}).get("sign") or "")
        doshas: dict[str, Any] = {}
        if lagna_sign and moon_sign and venus_sign and mars_sign:
            doshas["manglik"] = manglik_status(
                lagna_sign=lagna_sign,
                moon_sign=moon_sign,
                venus_sign=venus_sign,
                mars_sign=mars_sign,
            )
        doshas["kalsarpa"] = kalsarpa_status(longitudes=longitudes, lagna_sign=lagna_sign or None)

        # Sade Sati (current transit status only)
        current_saturn = self.ephemeris.get_positions_for_date(datetime.utcnow(), None, None, system="vedic")
        saturn_sign_now = (
            str(((current_saturn.get("planets") or {}).get("saturn") or {}).get("sign") or "")
            if isinstance(current_saturn, dict)
            else ""
        )
        sadesati = (
            sade_sati_status(natal_moon_sign=moon_sign, current_saturn_sign=saturn_sign_now)
            if moon_sign and saturn_sign_now
            else None
        )

        return {
            "timezone": timezone,
            "ayanamsha": ayanamsha,
            "lagna": lagna if lagna else None,
            "houses": houses,
            "planets": enriched,
            "panchang": panchang,
            "avakhada": avakhada,
            "dashas": {
                "current": {
                    "starting": (dasha_payload or {}).get("starting_dasha") if isinstance(dasha_payload, dict) else None,
                    "mahadasha": (dasha_payload or {}).get("mahadasha") if isinstance(dasha_payload, dict) else None,
                    "antardasha": (dasha_payload or {}).get("antardasha") if isinstance(dasha_payload, dict) else None,
                },
                "mahadashaTimeline": mahadasha_timeline,
                "dashaTimeline120Years": dasha_timeline_120y,
                "currentAntardashas": (dasha_payload or {}).get("all_antardashas") if isinstance(dasha_payload, dict) else None,
            },
            "divisionalCharts": divisional,
            "yogas": yogas,
            "doshas": doshas,
            "sadesati": sadesati,
            "glossary": [
                {"term": "Lagna (Ascendant)", "meaning": "The rising sign at birth; sets the starting point for houses."},
                {"term": "House", "meaning": "A life area. In Vedic reports we often use whole-sign houses."},
                {"term": "Nakshatra", "meaning": "A 27-part lunar constellation segment used for timing and dashas."},
                {"term": "Vimshottari Dasha", "meaning": "A 120-year timing cycle used in Vedic astrology."},
            ],
        }
