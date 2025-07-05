from __future__ import annotations

import datetime as _dt
from io import BytesIO
import logging

try:
    import swisseph as swe
    SWE_AVAILABLE = True
except ImportError:
    SWE_AVAILABLE = False
    swe = None

from fpdf import FPDF
from .gemini_ai import GeminiService

logger = logging.getLogger(__name__)


class ReportsService:
    """Service for generating personalized astrology reports."""

    def __init__(self, api_key: str = None):
        self._gemini = GeminiService(api_key)

    @staticmethod
    def _calculate_positions(
        birth_dt: _dt.datetime, latitude: float, longitude: float
    ) -> dict:
        """Calculate basic planetary positions using Swiss Ephemeris."""
        if SWE_AVAILABLE:
            swe.set_ephe_path(".")
            jd = swe.julday(
                birth_dt.year,
                birth_dt.month,
                birth_dt.day,
                birth_dt.hour + birth_dt.minute / 60,
            )
            sun_long = swe.calc_ut(jd, swe.SUN)[0]
            moon_long = swe.calc_ut(jd, swe.MOON)[0]
            return {"sun_longitude": sun_long, "moon_longitude": moon_long}
        else:
            # Fallback calculation
            day_of_year = birth_dt.timetuple().tm_yday
            sun_long = (day_of_year / 365.25 * 360) % 360
            moon_long = ((day_of_year * 13.2) + birth_dt.day * 13.2) % 360
            return {"sun_longitude": sun_long, "moon_longitude": moon_long}

    def _generate_text(self, profile: dict, astro_data: dict) -> str:
        """Generate report text using Gemini AI."""
        prompt = (
            "You are an expert astrologer. Generate a short personalized astrology report.\n"
            f"Name: {profile.get('full_name')}\n"
            f"Sun longitude: {astro_data['sun_longitude']:.2f} degrees\n"
            f"Moon longitude: {astro_data['moon_longitude']:.2f} degrees\n"
            "Provide insights about their personality, strengths, and cosmic guidance."
        )
        try:
            content = self._gemini.generate_content(prompt, max_tokens=400)
            return content
        except Exception as e:
            logger.error(f"Failed to generate report text: {e}")
            return "Your cosmic journey is unique and filled with potential. The alignment of celestial bodies at your birth creates a distinctive energy pattern that guides your path."

    def build_report(self, profile: dict) -> BytesIO:
        """Build PDF report for the given profile and return BytesIO."""
        birth_dt = profile["birth_datetime"]
        lat = profile.get("latitude", 0.0)
        lon = profile.get("longitude", 0.0)
        astro = self._calculate_positions(birth_dt, lat, lon)
        text = self._generate_text(profile, astro)

        pdf = FPDF()
        pdf.add_page()
        pdf.set_font("Helvetica", size=16)
        pdf.cell(0, 10, f"Report for {profile.get('full_name', 'User')}", ln=True)
        pdf.set_font("Helvetica", size=12)
        pdf.multi_cell(0, 10, text)

        buffer = BytesIO()
        pdf.output(buffer)
        buffer.seek(0)
        return buffer
