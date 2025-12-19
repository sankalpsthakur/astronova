from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Optional

from services.dasha_service import DashaService
from services.ephemeris_service import EphemerisService
from services.ephemeris_service import SWE_AVAILABLE
from utils.birth_data import parse_birth_data


@dataclass
class GeneratedReport:
    report_type: str
    title: str
    summary: str
    key_insights: list[str]
    content: str


class ReportGenerationService:
    """Generate report payloads and stored content using existing astrology services."""

    def __init__(self, ephemeris: Optional[EphemerisService] = None, dasha: Optional[DashaService] = None) -> None:
        self._ephemeris = ephemeris or EphemerisService()
        self._dasha = dasha or DashaService()

    def _parse_birth_data(self, birth_data: Optional[dict[str, Any]]) -> tuple[Optional[datetime], Optional[float], Optional[float]]:
        """Parse birth data using shared utility (lenient mode for reports)."""
        if not isinstance(birth_data, dict):
            return None, None, None
        return parse_birth_data(birth_data, key=None, require_coords=False, include_timezone=False)

    def generate(self, report_type: str, birth_data: Optional[dict[str, Any]] = None) -> GeneratedReport:
        report_type = (report_type or "birth_chart").strip()

        title = {
            "birth_chart": "Complete Birth Chart Reading",
            "love_forecast": "Love Forecast",
            "career_forecast": "Career Forecast",
            "year_ahead": "Year Ahead Overview",
        }.get(report_type, "Astrological Report")

        dt, lat, lon = self._parse_birth_data(birth_data)
        if not dt:
            summary = f"Personalized {report_type.replace('_', ' ')} based on provided details."
            key_insights = [
                "Add full birth date, time, and location for a detailed reading",
                "Kundali (sidereal) and Zodiac (tropical) insights can differ",
            ]
            payload = {
                "reportType": report_type,
                "title": title,
                "generatedAt": datetime.utcnow().isoformat() + "Z",
                "summary": summary,
                "keyInsights": key_insights,
                "zodiac": None,
                "kundali": None,
                "dashas": None,
                "westernPlanets": None,
                "vedicPlanets": None,
                "meta": {"ephemerisEngine": "swisseph" if SWE_AVAILABLE else "fallback"},
            }
            return GeneratedReport(
                report_type=report_type,
                title=title,
                summary=summary,
                key_insights=key_insights,
                content=json.dumps(payload, ensure_ascii=False),
            )

        western = self._ephemeris.get_positions_for_date(dt, lat, lon, system="western").get("planets", {})
        vedic = self._ephemeris.get_positions_for_date(dt, lat, lon, system="vedic").get("planets", {})

        def fmt_position(info: dict[str, Any]) -> str:
            sign = info.get("sign", "Unknown")
            degree = info.get("degree", 0.0)
            return f"{sign} {degree:.2f}°" if isinstance(degree, (int, float)) else str(sign)

        zodiac = {
            "sun": fmt_position(western.get("sun", {})),
            "moon": fmt_position(western.get("moon", {})),
            "ascendant": fmt_position(western.get("ascendant", {})) if lat is not None and lon is not None else None,
        }
        kundali = {
            "sun": fmt_position(vedic.get("sun", {})),
            "moon": fmt_position(vedic.get("moon", {})),
            "lagna": fmt_position(vedic.get("ascendant", {})) if lat is not None and lon is not None else None,
            "rahu": fmt_position(vedic.get("rahu", {})),
            "ketu": fmt_position(vedic.get("ketu", {})),
        }

        dashas: dict[str, Any] | None = None
        try:
            moon_lon = float(vedic.get("moon", {}).get("longitude", 0.0))
            dasha_info = self._dasha.calculate_complete_dasha(
                birth_date=dt,
                moon_longitude=moon_lon,
                target_date=datetime.utcnow(),
                include_future=True,
                num_future_periods=3,
            )
            if dasha_info:
                dashas = {
                    "starting": dasha_info.get("starting_dasha"),
                    "mahadasha": dasha_info.get("mahadasha"),
                    "antardasha": dasha_info.get("antardasha"),
                }
        except Exception:
            dashas = None

        if report_type == "love_forecast":
            summary = f"Love themes are highlighted through Venus and the current dasha influences. Zodiac: {zodiac['sun']}. Kundali: {kundali['sun']}."
            key_insights = [
                "Look for relationship lessons during your current dasha period",
                f"Kundali Moon: {kundali['moon']}",
            ]
        elif report_type == "career_forecast":
            summary = f"Career timing is influenced by Saturn themes and your current dasha. Zodiac: {zodiac['sun']}. Kundali: {kundali['sun']}."
            key_insights = [
                "Career growth tends to accelerate in Jupiter/Saturn-linked periods",
                f"Current Mahadasha: {(dashas or {}).get('mahadasha', {}).get('lord', 'Unknown')}",
            ]
        elif report_type == "year_ahead":
            summary = f"Your year-ahead overview blends tropical transits with kundali dashas for timing. Zodiac: {zodiac['sun']}. Kundali: {kundali['sun']}."
            key_insights = [
                "Use dashas for timing and transits for day-to-day tone",
                f"Lagna (kundali): {kundali.get('lagna')}",
            ]
        else:
            summary = f"Your core blueprint blends Zodiac (tropical) and Kundali (sidereal). Zodiac Sun: {zodiac['sun']}. Kundali Sun: {kundali['sun']}."
            key_insights = [
                f"Zodiac Moon: {zodiac['moon']}",
                f"Kundali Moon: {kundali['moon']}",
                f"Current Mahadasha: {(dashas or {}).get('mahadasha', {}).get('lord', 'Unknown')}",
            ]

        payload = {
            "reportType": report_type,
            "title": title,
            "generatedAt": datetime.utcnow().isoformat() + "Z",
            "summary": summary,
            "keyInsights": key_insights,
            "zodiac": zodiac,
            "kundali": kundali,
            "dashas": dashas,
            "westernPlanets": western,
            "vedicPlanets": vedic,
            "meta": {"ephemerisEngine": "swisseph" if SWE_AVAILABLE else "fallback"},
        }

        return GeneratedReport(
            report_type=report_type,
            title=title,
            summary=summary,
            key_insights=key_insights,
            content=json.dumps(payload, ensure_ascii=False),
        )
