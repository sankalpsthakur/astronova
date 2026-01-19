from __future__ import annotations

import json
import logging
import time
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Optional

from services.dasha_service import DashaService
from services.ephemeris_service import EphemerisService
from services.vedic import VedicAnalysisService
from utils.birth_data import parse_birth_data

logger = logging.getLogger(__name__)


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
        start = time.perf_counter()
        report_type = (report_type or "birth_chart").strip()

        title = {
            "birth_chart": "Your Detailed Birth Chart Report",
            "love_forecast": "Your Love & Relationship Blueprint",
            "career_forecast": "Your Career & Professional Blueprint",
            "wealth_forecast": "Your Wealth & Abundance Blueprint",
            "health_forecast": "Your Health & Vitality Blueprint",
            "family_forecast": "Your Family & Home Blueprint",
            "spiritual_forecast": "Your Spiritual & Soul Purpose Blueprint",
            "year_ahead": "Your Year Ahead Overview",
        }.get(report_type, "Astrological Report")

        dt, lat, lon = self._parse_birth_data(birth_data)
        if not dt:
            logger.info(
                "Report generate fallback report_type=%s has_birth_data=%s",
                report_type,
                bool(birth_data),
            )
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
                "meta": {"ephemerisEngine": None},
            }
            return GeneratedReport(
                report_type=report_type,
                title=title,
                summary=summary,
                key_insights=key_insights,
                content=json.dumps(payload, ensure_ascii=False),
            )

        logger.info(
            "Report generate start report_type=%s has_coords=%s engine=%s",
            report_type,
            lat is not None and lon is not None,
            "swisseph",
        )

        western_positions = self._ephemeris.get_positions_for_date(dt, lat, lon, system="western")
        vedic_positions = self._ephemeris.get_positions_for_date(dt, lat, lon, system="vedic")

        western = western_positions.get("planets", {}) if isinstance(western_positions, dict) else {}
        vedic = vedic_positions.get("planets", {}) if isinstance(vedic_positions, dict) else {}
        ayanamsha = vedic_positions.get("ayanamsha") if isinstance(vedic_positions, dict) else None

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
            logger.exception("Report dasha calculation failed report_type=%s", report_type)
            dashas = None

        vedic_analysis = None
        if report_type == "birth_chart" and lat is not None and lon is not None:
            try:
                tz = str((birth_data or {}).get("timezone") or "UTC")
                vedic_analysis = VedicAnalysisService(ephemeris=self._ephemeris, dashas=self._dasha).analyze(
                    birth_dt_utc=dt,
                    latitude=float(lat),
                    longitude=float(lon),
                    timezone=tz,
                )
            except Exception:
                logger.exception("Report vedic analysis failed report_type=%s", report_type)
                vedic_analysis = None

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
            summary = (
                f"Your detailed blueprint blends Zodiac (tropical) and Kundali (sidereal). "
                f"Zodiac Sun: {zodiac['sun']}. Kundali Sun: {kundali['sun']}."
            )
            key_insights = [
                f"Zodiac Moon: {zodiac['moon']}",
                f"Kundali Moon: {kundali['moon']}",
                f"Current Mahadasha: {(dashas or {}).get('mahadasha', {}).get('lord', 'Unknown')}",
            ]

        # Build birth info for cover page
        birth_info: dict[str, Any] = {}
        if birth_data:
            if birth_data.get("date"):
                birth_info["date"] = birth_data["date"]
            if birth_data.get("time"):
                birth_info["time"] = birth_data["time"]
            if birth_data.get("location_name") or birth_data.get("locationName"):
                birth_info["location"] = birth_data.get("location_name") or birth_data.get("locationName")
            elif lat is not None and lon is not None:
                birth_info["coordinates"] = f"{lat:.2f}, {lon:.2f}"
                birth_info["latitude"] = round(float(lat), 6)
                birth_info["longitude"] = round(float(lon), 6)
            if birth_data.get("timezone"):
                birth_info["timezone"] = birth_data["timezone"]

        payload = {
            "reportType": report_type,
            "title": title,
            "generatedAt": datetime.utcnow().isoformat() + "Z",
            "summary": summary,
            "keyInsights": key_insights,
            "birth": birth_info if birth_info else None,
            "zodiac": zodiac,
            "kundali": kundali,
            "dashas": dashas,
            "westernPlanets": western,
            "vedicPlanets": vedic,
            "vedicAnalysis": vedic_analysis,
            "meta": {"ephemerisEngine": "swisseph", "ayanamsha": ayanamsha},
        }

        content = json.dumps(payload, ensure_ascii=False)
        elapsed_ms = (time.perf_counter() - start) * 1000
        logger.info(
            "Report generate complete report_type=%s duration_ms=%.2f content_bytes=%d",
            report_type,
            elapsed_ms,
            len(content.encode("utf-8")),
        )

        return GeneratedReport(
            report_type=report_type,
            title=title,
            summary=summary,
            key_insights=key_insights,
            content=content,
        )
