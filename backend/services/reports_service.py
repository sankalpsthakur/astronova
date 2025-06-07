from __future__ import annotations

import datetime as _dt
from io import BytesIO

import swisseph as swe
from anthropic import Anthropic
from fpdf import FPDF


class ReportsService:
    """Service for generating personalized astrology reports."""

    def __init__(self, anthropic_api_key: str):
        self._anthropic = Anthropic(api_key=anthropic_api_key)

    @staticmethod
    def _calculate_positions(
        birth_dt: _dt.datetime, latitude: float, longitude: float
    ) -> dict:
        """Calculate basic planetary positions using Swiss Ephemeris."""
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

    def _generate_text(self, profile: dict, astro_data: dict) -> str:
        """Generate report text using Claude AI."""
        prompt = (
            "Generate a short personalized astrology report.\n"
            f"Name: {profile.get('full_name')}\n"
            f"Sun longitude: {astro_data['sun_longitude']:.2f}\n"
            f"Moon longitude: {astro_data['moon_longitude']:.2f}\n"
        )
        msg = self._anthropic.messages.create(
            model="claude-3-sonnet-20240229",
            max_tokens=400,
            temperature=0.6,
            system="You are an expert astrologer.",
            messages=[{"role": "user", "content": prompt}],
        )
        return msg.content[0].text if msg.content else ""

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
