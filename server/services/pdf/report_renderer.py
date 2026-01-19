from __future__ import annotations

import json
import logging
import zlib
from dataclasses import dataclass
from typing import Any

from .canvas import PDFCanvas, RGB, polar_point
from .interpretations import (
    dasha_bullets,
    placement_bullets,
    synthesis_line,
    traits_for_sign,
)
from .pdf_writer import PDFDocument
from .themes import ReportTheme, theme_for_report

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class ReportData:
    report_id: str
    report_type: str
    domain: str | None
    title: str
    generated_at: str | None
    birth: dict[str, Any] | None
    summary: str
    key_insights: list[str]
    zodiac: dict[str, Any] | None
    kundali: dict[str, Any] | None
    dashas: dict[str, Any] | None
    western_planets: dict[str, Any] | None
    vedic_planets: dict[str, Any] | None
    western_houses: dict[str, Any] | None
    vedic_houses: dict[str, Any] | None
    vedic_analysis: dict[str, Any] | None
    meta: dict[str, Any] | None


def _safe_str(value: Any, default: str = "") -> str:
    if isinstance(value, str):
        return value
    if value is None:
        return default
    return str(value)


def _parse_report_content(report: dict[str, Any] | None, report_id: str) -> ReportData:
    title = _safe_str((report or {}).get("title"), "Astrological Report")
    report_type = _safe_str((report or {}).get("type"), "birth_chart")
    generated_at = (report or {}).get("generated_at")

    summary = "Report content is not available."
    key_insights: list[str] = []
    zodiac: dict[str, Any] | None = None
    kundali: dict[str, Any] | None = None
    dashas: dict[str, Any] | None = None
    domain: str | None = None
    western_planets: dict[str, Any] | None = None
    vedic_planets: dict[str, Any] | None = None
    western_houses: dict[str, Any] | None = None
    vedic_houses: dict[str, Any] | None = None
    vedic_analysis: dict[str, Any] | None = None
    birth: dict[str, Any] | None = None
    meta: dict[str, Any] | None = None

    content_raw = (report or {}).get("content")
    if isinstance(content_raw, str) and content_raw.strip():
        try:
            parsed = json.loads(content_raw)
            if isinstance(parsed, dict):
                summary = _safe_str(parsed.get("summary"), summary)
                if isinstance(parsed.get("keyInsights"), list):
                    key_insights = [str(i) for i in parsed["keyInsights"] if isinstance(i, str) and i.strip()]
                zodiac = parsed.get("zodiac") if isinstance(parsed.get("zodiac"), dict) else None
                kundali = parsed.get("kundali") if isinstance(parsed.get("kundali"), dict) else None
                dashas = parsed.get("dashas") if isinstance(parsed.get("dashas"), dict) else None
                western_planets = parsed.get("westernPlanets") if isinstance(parsed.get("westernPlanets"), dict) else None
                vedic_planets = parsed.get("vedicPlanets") if isinstance(parsed.get("vedicPlanets"), dict) else None
                western_houses = parsed.get("westernHouses") if isinstance(parsed.get("westernHouses"), dict) else None
                vedic_houses = parsed.get("vedicHouses") if isinstance(parsed.get("vedicHouses"), dict) else None
                vedic_analysis = parsed.get("vedicAnalysis") if isinstance(parsed.get("vedicAnalysis"), dict) else None
                birth = parsed.get("birth") if isinstance(parsed.get("birth"), dict) else None
                meta = parsed.get("meta") if isinstance(parsed.get("meta"), dict) else None
                report_type = _safe_str(parsed.get("reportType"), report_type)
                title = _safe_str(parsed.get("title"), title)
                generated_at = _safe_str(parsed.get("generatedAt"), generated_at)
                if isinstance(parsed.get("domain"), str):
                    domain = parsed["domain"].strip().lower() or None
        except Exception:
            logger.exception("Failed to parse report content JSON report_id=%s", report_id)
            summary = _safe_str(content_raw, summary)

    if not key_insights:
        key_insights = [
            "Add full birth date, time, and location for a deeper reading.",
            "Use this report as a reflection tool, not a fixed prediction.",
        ]

    return ReportData(
        report_id=report_id,
        report_type=report_type,
        domain=domain,
        title=title,
        generated_at=_safe_str(generated_at, ""),
        birth=birth,
        summary=summary,
        key_insights=key_insights,
        zodiac=zodiac,
        kundali=kundali,
        dashas=dashas,
        western_planets=western_planets,
        vedic_planets=vedic_planets,
        western_houses=western_houses,
        vedic_houses=vedic_houses,
        vedic_analysis=vedic_analysis,
        meta=meta,
    )


WESTERN_SIGNS = [
    "Aries",
    "Taurus",
    "Gemini",
    "Cancer",
    "Leo",
    "Virgo",
    "Libra",
    "Scorpio",
    "Sagittarius",
    "Capricorn",
    "Aquarius",
    "Pisces",
]

VEDIC_SIGNS = [
    "Mesha",
    "Vrishabha",
    "Mithuna",
    "Karka",
    "Simha",
    "Kanya",
    "Tula",
    "Vrischika",
    "Dhanu",
    "Makara",
    "Kumbha",
    "Meena",
]

WESTERN_SIGN_LABELS = [
    "ARI",
    "TAU",
    "GEM",
    "CAN",
    "LEO",
    "VIR",
    "LIB",
    "SCO",
    "SAG",
    "CAP",
    "AQU",
    "PIS",
]

VEDIC_SIGN_LABELS = [
    "MES",
    "VRS",
    "MIT",
    "KAR",
    "SIM",
    "KAN",
    "TUL",
    "VRC",
    "DHA",
    "MAK",
    "KUM",
    "MEE",
]


def _parse_sign_degree(value: Any, *, vedic: bool) -> float | None:
    """Parse strings like 'Gemini 24.01°' into an absolute longitude (0..360)."""
    if not isinstance(value, str):
        return None
    text = value.strip()
    if not text:
        return None

    # Split on whitespace; first token is sign.
    parts = text.replace("°", "").split()
    if len(parts) < 2:
        return None

    sign = parts[0]
    try:
        degree = float(parts[1])
    except Exception:
        return None

    signs = VEDIC_SIGNS if vedic else WESTERN_SIGNS
    try:
        idx = signs.index(sign)
    except ValueError:
        return None
    return (idx * 30.0) + (degree % 30.0)


def _draw_cover(canvas: PDFCanvas, data: ReportData, theme: ReportTheme) -> None:
    bg = RGB(0.04, 0.06, 0.12)
    fg = RGB(0.92, 0.94, 0.98)
    muted = RGB(0.65, 0.70, 0.78)

    canvas.set_fill(bg)
    canvas.rect(0, 0, 612, 792, fill=True, stroke=False)
    # Avoid Python's randomized hash() for deterministic output across restarts.
    seed = zlib.crc32(data.report_id.encode("utf-8")) & 0xFFFFFFFF
    canvas.starfield(seed=seed, count=120)

    # Accent band
    canvas.set_fill(theme.accent_soft)
    canvas.rect(0, 720, 612, 72, fill=True, stroke=False)
    canvas.set_fill(theme.accent)
    canvas.rect(0, 716, 612, 4, fill=True, stroke=False)

    canvas.text(48, 740, "ASTRONOVA", font="F2", size=16, color=fg)
    canvas.text(48, 716, theme.label.upper() + " REPORT", font="F1", size=10, color=muted)
    canvas.text(48, 700, f"Focus: {theme.focus}", font="F1", size=10, color=muted)

    canvas.text(48, 648, data.title, font="F2", size=26, color=fg)
    canvas.wrapped_text(48, 612, data.summary, font="F1", size=12, color=muted, max_width=516)

    # Birth details section
    if data.birth:
        canvas.set_fill(RGB(0.08, 0.10, 0.16))
        canvas.rect(48, 420, 516, 120, fill=True, stroke=False)
        canvas.text(64, 520, "Birth Details", font="F2", size=12, color=fg)
        y_birth = 498
        if data.birth.get("date"):
            canvas.text(64, y_birth, f"Date: {data.birth['date']}", font="F1", size=11, color=muted)
            y_birth -= 18
        if data.birth.get("time"):
            canvas.text(64, y_birth, f"Time: {data.birth['time']}", font="F1", size=11, color=muted)
            y_birth -= 18
        if data.birth.get("location"):
            canvas.text(64, y_birth, f"Location: {data.birth['location']}", font="F1", size=11, color=muted)
            y_birth -= 18
        elif data.birth.get("coordinates"):
            canvas.text(64, y_birth, f"Coordinates: {data.birth['coordinates']}", font="F1", size=11, color=muted)
            y_birth -= 18
        if data.birth.get("timezone"):
            canvas.text(64, y_birth, f"Timezone: {data.birth['timezone']}", font="F1", size=11, color=muted)

    # Footer meta (keep stable and always include report ID for tests).
    canvas.set_fill(RGB(0.10, 0.12, 0.18))
    canvas.rect(48, 76, 516, 72, fill=True, stroke=False)
    canvas.text(64, 122, f"Report ID: {data.report_id}", font="F1", size=10, color=fg)
    if data.generated_at:
        canvas.text(64, 104, f"Generated: {data.generated_at}", font="F1", size=10, color=muted)
    canvas.text(64, 86, "Your cosmic blueprint \u2014 designed for clarity and action.", font="F1", size=10, color=muted)


def _draw_highlights(canvas: PDFCanvas, data: ReportData, theme: ReportTheme) -> None:
    bg = RGB(0.04, 0.06, 0.12)
    fg = RGB(0.92, 0.94, 0.98)
    muted = RGB(0.65, 0.70, 0.78)

    canvas.set_fill(bg)
    canvas.rect(0, 0, 612, 792, fill=True, stroke=False)
    seed = zlib.crc32(data.report_id.encode("utf-8")) & 0xFFFFFFFF
    canvas.starfield(seed=(seed + 1) & 0xFFFFFFFF, count=70)

    canvas.set_fill(theme.accent_soft)
    canvas.rect(0, 760, 612, 32, fill=True, stroke=False)
    canvas.text(48, 770, "Highlights", font="F2", size=16, color=fg)

    canvas.text(48, 722, "Summary", font="F2", size=12, color=fg)
    y = canvas.wrapped_text(48, 704, data.summary, font="F1", size=12, color=muted, max_width=516)

    canvas.text(48, y - 12, "Key Insights", font="F2", size=12, color=fg)
    y2 = canvas.bullets(56, y - 32, data.key_insights[:6], font="F1", size=12, color=muted, max_width=508)

    canvas.text(48, y2 - 14, "Reflection Prompts", font="F2", size=12, color=fg)
    canvas.bullets(56, y2 - 34, theme.prompts, font="F1", size=12, color=muted, max_width=508)


def _draw_vedic_details_page(canvas: PDFCanvas, *, data: ReportData, theme: ReportTheme, page_num: int, total_pages: int) -> None:
    bg = RGB(0.04, 0.06, 0.12)
    fg = RGB(0.92, 0.94, 0.98)
    muted = RGB(0.65, 0.70, 0.78)

    canvas.set_fill(bg)
    canvas.rect(0, 0, 612, 792, fill=True, stroke=False)
    seed = zlib.crc32((data.report_id + ":vedic").encode("utf-8")) & 0xFFFFFFFF
    canvas.starfield(seed=seed, count=80)

    canvas.set_fill(theme.accent_soft)
    canvas.rect(0, 760, 612, 32, fill=True, stroke=False)
    canvas.text(48, 770, "Kundali Essentials", font="F2", size=16, color=fg)

    va = data.vedic_analysis or {}
    ayanamsha = va.get("ayanamsha") or (data.meta or {}).get("ayanamsha")
    if isinstance(ayanamsha, (int, float)):
        canvas.text(48, 732, f"Ayanamsha (Lahiri): {ayanamsha:.6f}°", font="F1", size=10, color=muted)
    canvas.text(48, 714, _engine_label(data), font="F1", size=10, color=muted)

    lagna = va.get("lagna") if isinstance(va.get("lagna"), dict) else {}
    moon = (va.get("planets") or {}).get("moon") if isinstance(va.get("planets"), dict) else None
    moon_nak = (moon or {}).get("nakshatra") if isinstance(moon, dict) else None

    canvas.set_fill(RGB(0.08, 0.10, 0.16))
    canvas.rect(48, 560, 516, 132, fill=True, stroke=False)
    canvas.text(64, 676, "Your Anchors", font="F2", size=12, color=fg)
    canvas.text(
        64,
        650,
        f"Lagna: {_safe_str(lagna.get('sign'), '—')}  {_safe_str(lagna.get('degree'), '—')}°  (lord: {_safe_str(lagna.get('lord'), '—')})",
        font="F1",
        size=10,
        color=muted,
    )
    if isinstance(moon_nak, dict):
        canvas.text(
            64,
            632,
            f"Moon Nakshatra: {_safe_str(moon_nak.get('name'), '—')}  (lord: {_safe_str(moon_nak.get('lord'), '—')}, pada: {_safe_str(moon_nak.get('pada'), '—')})",
            font="F1",
            size=10,
            color=muted,
        )
    canvas.wrapped_text(
        64,
        610,
        "Lagna sets your house system (life areas). Moon Nakshatra sets your dasha timing. Both are foundational for Vedic readings.",
        font="F1",
        size=10,
        color=muted,
        max_width=488,
    )

    panchang = va.get("panchang") if isinstance(va.get("panchang"), dict) else {}
    tithi = panchang.get("tithi") if isinstance(panchang.get("tithi"), dict) else {}
    yoga = panchang.get("yoga") if isinstance(panchang.get("yoga"), dict) else {}
    karana = panchang.get("karana") if isinstance(panchang.get("karana"), dict) else {}

    canvas.set_fill(RGB(0.08, 0.10, 0.16))
    canvas.rect(48, 404, 516, 132, fill=True, stroke=False)
    canvas.text(64, 520, "Panchang (Birth Moment)", font="F2", size=12, color=fg)
    canvas.text(64, 494, f"Tithi: {_safe_str(tithi.get('name'), '—')}", font="F1", size=10, color=muted)
    canvas.text(64, 476, f"Karana: {_safe_str(karana.get('name'), '—')}", font="F1", size=10, color=muted)
    canvas.text(64, 458, f"Yoga: {_safe_str(yoga.get('name'), '—')}", font="F1", size=10, color=muted)
    canvas.wrapped_text(
        64,
        438,
        "These are traditional ‘time quality’ markers based on Sun–Moon geometry. They’re used for fine-grained timing and ritual calendars.",
        font="F1",
        size=10,
        color=muted,
        max_width=488,
    )

    avakhada = va.get("avakhada") if isinstance(va.get("avakhada"), dict) else {}
    canvas.set_fill(RGB(0.08, 0.10, 0.16))
    canvas.rect(48, 220, 516, 160, fill=True, stroke=False)
    canvas.text(64, 364, "Traditional Archetypes (Avakhada-style)", font="F2", size=12, color=fg)
    lines = [
        f"Varna: {_safe_str(avakhada.get('varna'), '—')}   Tatva: {_safe_str(avakhada.get('tatva'), '—')}",
        f"Vashya: {_safe_str(avakhada.get('vashya'), '—')}",
        f"Gana: {_safe_str(avakhada.get('gana'), '—')}   Nadi: {_safe_str(avakhada.get('nadi'), '—')}   Yoni: {_safe_str(avakhada.get('yoni'), '—')}",
    ]
    y = 338
    for line in lines:
        canvas.wrapped_text(64, y, line, font="F1", size=10, color=muted, max_width=488)
        y -= 18
    canvas.wrapped_text(
        64,
        280,
        "These labels are traditionally used in compatibility scoring. We show them as symbolic archetypes—not as deterministic judgments.",
        font="F1",
        size=10,
        color=muted,
        max_width=488,
    )

    _stamp_footer(canvas, data, color=muted, page_num=page_num, total_pages=total_pages)


def _draw_dasha_timeline_page(canvas: PDFCanvas, *, data: ReportData, theme: ReportTheme, page_num: int, total_pages: int) -> None:
    bg = RGB(0.04, 0.06, 0.12)
    fg = RGB(0.92, 0.94, 0.98)
    muted = RGB(0.65, 0.70, 0.78)

    canvas.set_fill(bg)
    canvas.rect(0, 0, 612, 792, fill=True, stroke=False)
    seed = zlib.crc32((data.report_id + ":dasha").encode("utf-8")) & 0xFFFFFFFF
    canvas.starfield(seed=seed, count=70)

    canvas.set_fill(theme.accent_soft)
    canvas.rect(0, 760, 612, 32, fill=True, stroke=False)
    canvas.text(48, 770, "Vimshottari Dasha Timeline", font="F2", size=16, color=fg)

    va = data.vedic_analysis or {}
    dashas = va.get("dashas") if isinstance(va.get("dashas"), dict) else {}
    current = dashas.get("current") if isinstance(dashas.get("current"), dict) else {}
    maha = current.get("mahadasha") if isinstance(current.get("mahadasha"), dict) else {}
    antar = current.get("antardasha") if isinstance(current.get("antardasha"), dict) else {}

    canvas.text(
        48,
        732,
        f"Current: {_safe_str(maha.get('lord'), '—')} Mahadasha ({_safe_str(maha.get('start'), '—')} -> {_safe_str(maha.get('end'), '—')})",
        font="F1",
        size=10,
        color=muted,
    )
    canvas.text(
        48,
        714,
        f"Sub-period: {_safe_str(antar.get('lord'), '—')} Antardasha ({_safe_str(antar.get('start'), '—')} -> {_safe_str(antar.get('end'), '—')})",
        font="F1",
        size=10,
        color=muted,
    )
    canvas.wrapped_text(
        48,
        692,
        "Dashas are like long ‘chapters’ of life. Mahadasha is the main chapter, Antardasha is the sub-chapter. They’re used for timing themes.",
        font="F1",
        size=10,
        color=muted,
        max_width=516,
    )

    timeline = dashas.get("mahadashaTimeline") if isinstance(dashas.get("mahadashaTimeline"), list) else []
    canvas.text(48, 650, "Mahadasha Timeline (from birth)", font="F2", size=12, color=fg)
    y = 632
    for row in timeline[:9]:
        if not isinstance(row, dict):
            continue
        line = f"{_safe_str(row.get('lord'), '—')}: {_safe_str(row.get('start'), '—')} -> {_safe_str(row.get('end'), '—')}"
        canvas.text(64, y, line, font="F1", size=10, color=muted)
        y -= 16

    antars = dashas.get("currentAntardashas") if isinstance(dashas.get("currentAntardashas"), list) else []
    canvas.text(48, y - 10, "Antardashas (current Mahadasha)", font="F2", size=12, color=fg)
    y2 = y - 32
    for row in antars[:12]:
        if not isinstance(row, dict):
            continue
        line = f"{_safe_str(row.get('lord'), '—')}: {_safe_str(row.get('start'), '—')} -> {_safe_str(row.get('end'), '—')}"
        canvas.text(64, y2, line, font="F1", size=10, color=muted)
        y2 -= 16

    _stamp_footer(canvas, data, color=muted, page_num=page_num, total_pages=total_pages)


def _draw_vedic_advanced_page(canvas: PDFCanvas, *, data: ReportData, theme: ReportTheme, page_num: int, total_pages: int) -> None:
    bg = RGB(0.04, 0.06, 0.12)
    fg = RGB(0.92, 0.94, 0.98)
    muted = RGB(0.65, 0.70, 0.78)

    canvas.set_fill(bg)
    canvas.rect(0, 0, 612, 792, fill=True, stroke=False)
    seed = zlib.crc32((data.report_id + ":advanced").encode("utf-8")) & 0xFFFFFFFF
    canvas.starfield(seed=seed, count=70)

    canvas.set_fill(theme.accent_soft)
    canvas.rect(0, 760, 612, 32, fill=True, stroke=False)
    canvas.text(48, 770, "Vedic Deep Dive", font="F2", size=16, color=fg)

    va = data.vedic_analysis or {}
    divisional = va.get("divisionalCharts") if isinstance(va.get("divisionalCharts"), dict) else {}
    d9 = divisional.get("D9") if isinstance(divisional.get("D9"), dict) else {}
    d10 = divisional.get("D10") if isinstance(divisional.get("D10"), dict) else {}

    canvas.set_fill(RGB(0.08, 0.10, 0.16))
    canvas.rect(48, 560, 516, 180, fill=True, stroke=False)
    canvas.text(64, 724, "Divisional Charts (Vargas)", font="F2", size=12, color=fg)
    canvas.wrapped_text(
        64,
        706,
        "D9 (Navamsa) is often read for relationship patterns and inner strength. D10 (Dasamsa) is often read for career/public contribution.",
        font="F1",
        size=10,
        color=muted,
        max_width=488,
    )

    key_planets = ["sun", "moon", "mars", "mercury", "jupiter", "venus", "saturn", "rahu", "ketu"]
    y = 662
    for p in key_planets:
        d9s = _safe_str((d9.get(p) or {}).get("sign") if isinstance(d9.get(p), dict) else None, "—")
        d10s = _safe_str((d10.get(p) or {}).get("sign") if isinstance(d10.get(p), dict) else None, "—")
        canvas.text(64, y, f"{p.title():<8}  D9: {d9s:<10}  D10: {d10s}", font="F1", size=10, color=muted)
        y -= 16

    doshas = va.get("doshas") if isinstance(va.get("doshas"), dict) else {}
    manglik = doshas.get("manglik") if isinstance(doshas.get("manglik"), dict) else {}
    kalsarpa = doshas.get("kalsarpa") if isinstance(doshas.get("kalsarpa"), dict) else {}
    sadesati = va.get("sadesati") if isinstance(va.get("sadesati"), dict) else {}

    canvas.set_fill(RGB(0.08, 0.10, 0.16))
    canvas.rect(48, 340, 516, 196, fill=True, stroke=False)
    canvas.text(64, 520, "Yogas & Checks", font="F2", size=12, color=fg)

    yogas = va.get("yogas") if isinstance(va.get("yogas"), list) else []
    if yogas:
        canvas.text(64, 496, "Yogas detected:", font="F1", size=10, color=muted)
        y3 = 478
        for item in yogas[:6]:
            if not isinstance(item, dict):
                continue
            canvas.wrapped_text(
                76,
                y3,
                f"{_safe_str(item.get('name'), 'Yoga')}: {_safe_str(item.get('description'), '')}",
                font="F1",
                size=9,
                color=muted,
                max_width=476,
            )
            y3 -= 28
    else:
        canvas.wrapped_text(64, 496, "No major yogas detected in the current subset.", font="F1", size=10, color=muted, max_width=488)

    canvas.text(64, 420, f"Manglik: {_safe_str(manglik.get('label'), '—')}", font="F1", size=10, color=muted)
    canvas.text(
        64,
        402,
        f"Kalsarpa: {'Present' if bool(kalsarpa.get('present')) else 'Not present'}"
        + (f" ({_safe_str(kalsarpa.get('type'), '')})" if kalsarpa.get("type") else ""),
        font="F1",
        size=10,
        color=muted,
    )
    canvas.text(
        64,
        384,
        f"Sade Sati: {'Active' if bool(sadesati.get('active')) else 'Not active'}"
        + (f" ({_safe_str(sadesati.get('phase'), '')})" if sadesati.get("phase") else ""),
        font="F1",
        size=10,
        color=muted,
    )
    canvas.wrapped_text(
        64,
        360,
        "These checks are traditional pattern labels. Use them as prompts for reflection rather than strict verdicts.",
        font="F1",
        size=10,
        color=muted,
        max_width=488,
    )

    _stamp_footer(canvas, data, color=muted, page_num=page_num, total_pages=total_pages)


def _engine_label(data: ReportData) -> str:
    engine = (data.meta or {}).get("ephemerisEngine")
    if engine == "swisseph":
        return "Ephemeris: Swiss Ephemeris (high accuracy)"
    if engine:
        return f"Ephemeris: {engine}"
    return "Ephemeris: Unknown"


def _stamp_footer(canvas: PDFCanvas, data: ReportData, *, color: RGB, page_num: int, total_pages: int) -> None:
    canvas.text(48, 28, f"Report ID: {data.report_id}", font="F1", size=8, color=color)
    canvas.text(556, 28, f"{page_num}/{total_pages}", font="F1", size=8, color=color)


def _num(value: Any) -> float | None:
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        try:
            return float(value)
        except Exception:
            return None
    return None


def _planet_longitude(info: Any, *, signs: list[str], vedic: bool) -> float | None:
    if not isinstance(info, dict):
        return None
    lon = _num(info.get("longitude"))
    if lon is not None:
        return lon % 360.0

    # Fallback from sign + degree (or the legacy formatted string).
    sign = info.get("sign")
    deg = _num(info.get("degree"))
    if isinstance(sign, str) and deg is not None:
        try:
            idx = signs.index(sign)
        except ValueError:
            return None
        return (idx * 30.0) + (deg % 30.0)

    return _parse_sign_degree(_safe_str(info.get("value"), ""), vedic=vedic)


PLANET_ORDER: list[tuple[str, str]] = [
    ("ascendant", "AS"),
    ("sun", "SU"),
    ("moon", "MO"),
    ("mercury", "ME"),
    ("venus", "VE"),
    ("mars", "MA"),
    ("jupiter", "JU"),
    ("saturn", "SA"),
    ("rahu", "RA"),
    ("ketu", "KE"),
    ("uranus", "UR"),
    ("neptune", "NE"),
    ("pluto", "PL"),
]


ASPECT_SPECS: list[tuple[str, float, float, str]] = [
    ("Conjunction", 0.0, 8.0, "conj"),
    ("Sextile", 60.0, 4.0, "sex"),
    ("Square", 90.0, 6.0, "sqr"),
    ("Trine", 120.0, 6.0, "tri"),
    ("Opposition", 180.0, 8.0, "opp"),
]


def _compute_aspects(planets: dict[str, Any], *, signs: list[str], vedic: bool) -> list[dict[str, Any]]:
    keys = ["sun", "moon", "mercury", "venus", "mars", "jupiter", "saturn"]
    longs: dict[str, float] = {}
    for k in keys:
        lon = _planet_longitude(planets.get(k), signs=signs, vedic=vedic)
        if lon is not None:
            longs[k] = lon

    aspects: list[dict[str, Any]] = []
    for i, a in enumerate(keys):
        if a not in longs:
            continue
        for b in keys[i + 1 :]:
            if b not in longs:
                continue
            d = abs(longs[a] - longs[b]) % 360.0
            d = min(d, 360.0 - d)
            best = None
            for name, angle, orb_max, key in ASPECT_SPECS:
                orb = abs(d - angle)
                if orb <= orb_max:
                    candidate = (orb, name, angle, key)
                    if best is None or candidate < best:
                        best = candidate
            if best is None:
                continue
            orb, name, angle, key = best
            aspects.append(
                {
                    "a": a,
                    "b": b,
                    "name": name,
                    "key": key,
                    "angle": angle,
                    "orb": round(float(orb), 2),
                    "separation": round(float(d), 2),
                }
            )

    aspects.sort(key=lambda x: (x["orb"], x["key"], x["a"], x["b"]))
    return aspects


def _draw_chart_wheel(
    canvas: PDFCanvas,
    *,
    cx: float,
    cy: float,
    r: float,
    theme: ReportTheme,
    signs: list[str],
    planets: dict[str, Any] | None,
    vedic: bool,
    include_aspects: bool,
) -> None:
    bg = RGB(0.04, 0.06, 0.12)
    fg = RGB(0.92, 0.94, 0.98)
    muted = RGB(0.65, 0.70, 0.78)
    ring = RGB(theme.accent.r * 0.9, theme.accent.g * 0.9, theme.accent.b * 0.9)

    # Outer rings
    canvas.set_stroke(ring)
    canvas.set_line_width(1.2)
    canvas.circle(cx, cy, r, fill=False, stroke=True)
    canvas.set_stroke(RGB(0.20, 0.24, 0.34))
    canvas.circle(cx, cy, r * 0.74, fill=False, stroke=True)
    canvas.set_stroke(RGB(0.16, 0.20, 0.30))
    canvas.circle(cx, cy, r * 0.42, fill=False, stroke=True)

    # Segments
    canvas.set_stroke(RGB(0.22, 0.26, 0.36))
    canvas.set_line_width(0.8)
    for i in range(12):
        angle = (i * 30.0) - 90.0
        x1, y1 = polar_point(cx, cy, r * 0.74, angle)
        x2, y2 = polar_point(cx, cy, r, angle)
        canvas.line(x1, y1, x2, y2)

    # Sign labels
    labels = None
    if signs == WESTERN_SIGNS:
        labels = WESTERN_SIGN_LABELS
    elif signs == VEDIC_SIGNS:
        labels = VEDIC_SIGN_LABELS

    for i, name in enumerate(signs):
        angle = (i * 30.0) - 75.0
        tx, ty = polar_point(cx, cy, r * 0.90, angle)
        label = (labels[i] if labels and i < len(labels) else name[:3].upper()).upper()
        canvas.text(tx - 11, ty - 3, label, font="F1", size=8, color=muted)

    # Aspect lines
    if include_aspects and planets:
        aspects = _compute_aspects(planets, signs=signs, vedic=vedic)[:10]
        style = {
            "conj": RGB(theme.accent.r, theme.accent.g, theme.accent.b),
            "opp": RGB(0.95, 0.35, 0.45),
            "sqr": RGB(0.95, 0.35, 0.45),
            "tri": RGB(0.35, 0.70, 1.00),
            "sex": RGB(0.45, 0.92, 0.85),
        }
        canvas.set_line_width(0.6)
        for a in aspects:
            a_key = a["a"]
            b_key = a["b"]
            lon_a = _planet_longitude(planets.get(a_key), signs=signs, vedic=vedic)
            lon_b = _planet_longitude(planets.get(b_key), signs=signs, vedic=vedic)
            if lon_a is None or lon_b is None:
                continue
            ax, ay = polar_point(cx, cy, r * 0.40, lon_a - 90.0)
            bx, by = polar_point(cx, cy, r * 0.40, lon_b - 90.0)
            canvas.set_stroke(style.get(a["key"], RGB(0.75, 0.78, 0.85)))
            canvas.line(ax, ay, bx, by)

    # Planet markers
    if not planets:
        return

    radii = {
        "ascendant": 0.68,
        "sun": 0.62,
        "moon": 0.62,
        "mercury": 0.56,
        "venus": 0.56,
        "mars": 0.56,
        "jupiter": 0.50,
        "saturn": 0.50,
        "uranus": 0.46,
        "neptune": 0.46,
        "pluto": 0.46,
        "rahu": 0.44,
        "ketu": 0.44,
    }

    canvas.set_fill(fg)
    for key, label in PLANET_ORDER:
        lon = _planet_longitude(planets.get(key), signs=signs, vedic=vedic)
        if lon is None:
            continue
        angle = lon - 90.0
        rr = r * radii.get(key, 0.54)
        px, py = polar_point(cx, cy, rr, angle)
        canvas.circle(px, py, 2.6, fill=True, stroke=False)
        canvas.text(px + 5, py - 3, label, font="F1", size=7, color=fg)


def _draw_chart_page(
    canvas: PDFCanvas,
    *,
    data: ReportData,
    theme: ReportTheme,
    title: str,
    planets: dict[str, Any] | None,
    signs: list[str],
    vedic: bool,
    include_aspects: bool,
    page_num: int,
    total_pages: int,
) -> None:
    bg = RGB(0.04, 0.06, 0.12)
    fg = RGB(0.92, 0.94, 0.98)
    muted = RGB(0.65, 0.70, 0.78)
    panel = RGB(0.08, 0.10, 0.16)

    canvas.set_fill(bg)
    canvas.rect(0, 0, 612, 792, fill=True, stroke=False)
    seed = zlib.crc32(data.report_id.encode("utf-8")) & 0xFFFFFFFF
    canvas.starfield(seed=(seed + page_num) & 0xFFFFFFFF, count=55)

    canvas.set_fill(theme.accent_soft)
    canvas.rect(0, 760, 612, 32, fill=True, stroke=False)
    canvas.text(48, 770, title, font="F2", size=16, color=fg)
    canvas.text(420, 770, _engine_label(data), font="F1", size=9, color=muted)

    # Panels
    canvas.set_fill(panel)
    canvas.rect(48, 120, 320, 620, fill=True, stroke=False)
    canvas.set_fill(panel)
    canvas.rect(384, 120, 180, 620, fill=True, stroke=False)

    # Wheel
    _draw_chart_wheel(
        canvas,
        cx=208,
        cy=430,
        r=146,
        theme=theme,
        signs=signs,
        planets=planets,
        vedic=vedic,
        include_aspects=include_aspects,
    )

    canvas.text(64, 132, "Wheel is plotted by ecliptic longitude.", font="F1", size=9, color=muted)

    # Table header
    canvas.text(396, 720, "Placements", font="F2", size=12, color=fg)
    canvas.text(396, 704, "Pl", font="F2", size=9, color=muted)
    canvas.text(420, 704, "Sign", font="F2", size=9, color=muted)
    canvas.text(510, 704, "Deg", font="F2", size=9, color=muted)
    canvas.text(548, 704, "R", font="F2", size=9, color=muted)

    y = 688
    row_h = 14
    for key, label in PLANET_ORDER:
        info = planets.get(key) if isinstance(planets, dict) else None
        sign = _safe_str((info or {}).get("sign"), "—")
        deg = _num((info or {}).get("degree"))
        deg_s = f"{deg:0.2f}°" if deg is not None else "—"
        retro = "R" if (info or {}).get("retrograde") else ""
        canvas.text(396, y, label, font="F1", size=9, color=fg)
        canvas.text(420, y, sign[:11], font="F1", size=9, color=fg)
        canvas.text(510, y, deg_s, font="F1", size=9, color=fg)
        canvas.text(548, y, retro, font="F1", size=9, color=fg)
        y -= row_h
        if y < 250:
            break

    if include_aspects and planets:
        canvas.text(396, 232, "Key Aspects", font="F2", size=11, color=fg)
        aspects = _compute_aspects(planets, signs=signs, vedic=vedic)[:8]
        y = 214
        for a in aspects:
            a_lbl = dict(PLANET_ORDER).get(a["a"], a["a"][:2].upper())
            b_lbl = dict(PLANET_ORDER).get(a["b"], a["b"][:2].upper())
            abbr = {"conj": "CONJ", "sex": "SEXT", "sqr": "SQR", "tri": "TRI", "opp": "OPP"}.get(a["key"], a["key"].upper())
            line = f"{a_lbl} {abbr} {b_lbl}  orb {a['orb']}°"
            canvas.text(396, y, line, font="F1", size=9, color=muted)
            y -= 14
    elif vedic:
        canvas.text(396, 232, "Dashas", font="F2", size=11, color=fg)
        maha = (data.dashas or {}).get("mahadasha") if isinstance((data.dashas or {}).get("mahadasha"), dict) else {}
        antar = (data.dashas or {}).get("antardasha") if isinstance((data.dashas or {}).get("antardasha"), dict) else {}
        start = (data.dashas or {}).get("starting") if isinstance((data.dashas or {}).get("starting"), dict) else {}

        lines = [
            f"Starting: {_safe_str(start.get('lord'), '—')}",
            f"Maha: {_safe_str(maha.get('lord'), '—')}  {_safe_str(maha.get('start'), '—')} \u2192 {_safe_str(maha.get('end'), '—')}",
            f"Antar: {_safe_str(antar.get('lord'), '—')}  {_safe_str(antar.get('start'), '—')} \u2192 {_safe_str(antar.get('end'), '—')}",
        ]
        y = 214
        for line in lines:
            canvas.wrapped_text(396, y, line, font="F1", size=9, color=muted, max_width=164)
            y -= 22

    _stamp_footer(canvas, data, color=muted, page_num=page_num, total_pages=total_pages)


def _draw_action_page(canvas: PDFCanvas, *, data: ReportData, theme: ReportTheme, page_num: int, total_pages: int) -> None:
    bg = RGB(0.04, 0.06, 0.12)
    fg = RGB(0.92, 0.94, 0.98)
    muted = RGB(0.65, 0.70, 0.78)
    panel = RGB(0.08, 0.10, 0.16)

    canvas.set_fill(bg)
    canvas.rect(0, 0, 612, 792, fill=True, stroke=False)
    seed = zlib.crc32(data.report_id.encode("utf-8")) & 0xFFFFFFFF
    canvas.starfield(seed=(seed + 10 + page_num) & 0xFFFFFFFF, count=60)

    canvas.set_fill(theme.accent_soft)
    canvas.rect(0, 760, 612, 32, fill=True, stroke=False)
    canvas.text(48, 770, "Action Plan", font="F2", size=16, color=fg)
    canvas.text(420, 770, _engine_label(data), font="F1", size=9, color=muted)

    canvas.text(48, 726, "Do next (7 days)", font="F2", size=12, color=fg)
    canvas.set_fill(panel)
    canvas.rect(48, 520, 516, 190, fill=True, stroke=False)
    y = 684
    for item in theme.actions:
        canvas.set_stroke(theme.accent)
        canvas.set_line_width(1.0)
        canvas.rect(64, y - 3, 10, 10, fill=False, stroke=True)
        canvas.wrapped_text(82, y + 6, item, font="F1", size=11, color=muted, max_width=470)
        y -= 44

    canvas.text(48, 486, "Watch for", font="F2", size=12, color=fg)
    canvas.set_fill(panel)
    canvas.rect(48, 300, 516, 170, fill=True, stroke=False)
    y = 450
    canvas.bullets(64, y, theme.watch_fors, font="F1", size=11, color=muted, max_width=496)

    canvas.text(48, 260, "Notes", font="F2", size=12, color=fg)
    canvas.set_fill(panel)
    canvas.rect(48, 92, 516, 156, fill=True, stroke=False)
    canvas.wrapped_text(
        64,
        224,
        "Astrology offers patterns and timing - not guarantees. Use this report for reflection and choice. "
        "If you purchased this report, ensure high-accuracy ephemeris is enabled in production.",
        font="F1",
        size=10,
        color=muted,
        max_width=488,
    )

    _stamp_footer(canvas, data, color=muted, page_num=page_num, total_pages=total_pages)


# Domain-specific planet focus for deep dive page
DOMAIN_PLANETS: dict[str, list[tuple[str, str, str]]] = {
    "love": [
        ("venus", "Venus", "Your love language, attraction style, and what you value in partnership."),
        ("moon", "Moon", "Emotional needs, how you nurture and want to be nurtured."),
        ("mars", "Mars", "Passion, desire, and how you pursue what you want in love."),
    ],
    "career": [
        ("saturn", "Saturn", "Your discipline, ambition, and long-term career structure."),
        ("jupiter", "Jupiter", "Growth opportunities, mentors, and professional expansion."),
        ("mercury", "Mercury", "Communication style, networking, and intellectual strengths."),
    ],
    "money": [
        ("jupiter", "Jupiter", "Abundance mindset, opportunities, and wealth expansion."),
        ("venus", "Venus", "What you value, spending patterns, and money magnetism."),
        ("saturn", "Saturn", "Financial discipline, savings, and long-term wealth building."),
    ],
    "health": [
        ("sun", "Sun", "Vitality, constitution, and core life force energy."),
        ("mars", "Mars", "Physical energy, drive, and how you handle stress."),
        ("moon", "Moon", "Emotional health, sleep patterns, and recovery needs."),
    ],
    "family": [
        ("moon", "Moon", "Home, belonging, emotional patterns, and maternal influences."),
        ("saturn", "Saturn", "Responsibilities, boundaries, and paternal influences."),
        ("venus", "Venus", "Harmony at home, aesthetics, and family values."),
    ],
    "spiritual": [
        ("jupiter", "Jupiter", "Wisdom, higher learning, and spiritual teachers."),
        ("ketu", "Ketu", "Past life patterns, detachment, and moksha (liberation)."),
        ("neptune", "Neptune", "Intuition, transcendence, and connection to the divine."),
    ],
    "general": [
        ("sun", "Sun", "Core identity, ego, and life purpose."),
        ("moon", "Moon", "Emotions, instincts, and inner needs."),
        ("ascendant", "Ascendant", "How you present yourself and meet the world."),
    ],
}


def _draw_domain_deep_dive(
    canvas: PDFCanvas,
    *,
    data: ReportData,
    theme: ReportTheme,
    page_num: int,
    total_pages: int,
) -> None:
    """Draw domain-specific planet focus page."""
    bg = RGB(0.04, 0.06, 0.12)
    fg = RGB(0.92, 0.94, 0.98)
    muted = RGB(0.65, 0.70, 0.78)
    panel = RGB(0.08, 0.10, 0.16)

    canvas.set_fill(bg)
    canvas.rect(0, 0, 612, 792, fill=True, stroke=False)
    seed = zlib.crc32(data.report_id.encode("utf-8")) & 0xFFFFFFFF
    canvas.starfield(seed=(seed + 200 + page_num) & 0xFFFFFFFF, count=55)

    canvas.set_fill(theme.accent_soft)
    canvas.rect(0, 760, 612, 32, fill=True, stroke=False)
    domain_label = (data.domain or "general").title()
    canvas.text(48, 770, f"{domain_label} Deep Dive", font="F2", size=16, color=fg)
    canvas.text(48, 742, f"Key planets shaping your {domain_label.lower()} experience", font="F1", size=10, color=muted)

    domain = data.domain or "general"
    planets_focus = DOMAIN_PLANETS.get(domain, DOMAIN_PLANETS["general"])

    y = 700
    for planet_key, planet_name, planet_desc in planets_focus:
        # Get position from western planets
        info = (data.western_planets or {}).get(planet_key, {})
        sign = info.get("sign", "\u2014")
        deg = _num(info.get("degree"))
        deg_str = f"{deg:.1f}\u00b0" if deg is not None else ""
        retro = " (R)" if info.get("retrograde") else ""

        # Panel for this planet
        canvas.set_fill(panel)
        canvas.rect(48, y - 80, 516, 100, fill=True, stroke=False)

        # Planet header
        canvas.text(64, y, f"{planet_name} in {sign} {deg_str}{retro}", font="F2", size=14, color=theme.accent)
        canvas.wrapped_text(64, y - 20, planet_desc, font="F1", size=11, color=muted, max_width=480)

        # Get vedic position for comparison
        vedic_info = (data.vedic_planets or {}).get(planet_key, {})
        vedic_sign = vedic_info.get("sign")
        if vedic_sign and vedic_sign != sign:
            canvas.text(64, y - 50, f"Vedic (Sidereal): {vedic_sign}", font="F1", size=9, color=muted)

        y -= 130

    # Bottom guidance
    canvas.set_fill(panel)
    canvas.rect(48, 92, 516, 80, fill=True, stroke=False)
    canvas.wrapped_text(
        64,
        152,
        f"These planets are especially significant for {domain_label.lower()} matters. "
        "Understanding their sign placements helps you work with your natural tendencies.",
        font="F1",
        size=10,
        color=muted,
        max_width=488,
    )

    _stamp_footer(canvas, data, color=muted, page_num=page_num, total_pages=total_pages)


def _placement_sign_deg(planets: dict[str, Any] | None, key: str) -> tuple[str | None, float | None]:
    if not isinstance(planets, dict):
        return None, None
    info = planets.get(key)
    if not isinstance(info, dict):
        return None, None
    sign = info.get("sign") if isinstance(info.get("sign"), str) else None
    deg = _num(info.get("degree"))
    return sign, deg


def _draw_placement_block(
    canvas: PDFCanvas,
    *,
    x: float,
    y: float,
    heading: str,
    placement_kind: str,
    planets: dict[str, Any] | None,
    sign_names: list[str],
    theme: ReportTheme,
    fg: RGB,
    muted: RGB,
    max_width: float,
    domain: str | None = None,
) -> float:
    sign, deg = _placement_sign_deg(planets, placement_kind)
    if sign and deg is not None:
        head = f"{heading}: {sign} {deg:0.2f}°"
    elif sign:
        head = f"{heading}: {sign}"
    else:
        head = f"{heading}: —"

    canvas.text(x, y, head, font="F2", size=10, color=fg)
    yy = y - 14

    traits = traits_for_sign(sign, sign_names=sign_names)
    if traits:
        bullets = placement_bullets(placement_kind, traits, theme=theme, domain=domain)
        yy = canvas.bullets(x, yy, bullets, font="F1", size=9, color=muted, max_width=max_width)
        return yy - 10

    # Fallback guidance (common when ascendant is missing due to no coordinates).
    if placement_kind in {"ascendant"}:
        return canvas.wrapped_text(
            x,
            yy,
            "Ascendant requires birth time and location. Add coordinates for a complete reading.",
            font="F1",
            size=9,
            color=muted,
            max_width=max_width,
        ) - 10

    return canvas.wrapped_text(
        x,
        yy,
        "Interpretation is unavailable for this placement.",
        font="F1",
        size=9,
        color=muted,
        max_width=max_width,
    ) - 10


def _draw_interpretations_page(
    canvas: PDFCanvas,
    *,
    data: ReportData,
    theme: ReportTheme,
    page_num: int,
    total_pages: int,
) -> None:
    bg = RGB(0.04, 0.06, 0.12)
    fg = RGB(0.92, 0.94, 0.98)
    muted = RGB(0.65, 0.70, 0.78)
    panel = RGB(0.08, 0.10, 0.16)

    canvas.set_fill(bg)
    canvas.rect(0, 0, 612, 792, fill=True, stroke=False)
    seed = zlib.crc32(data.report_id.encode("utf-8")) & 0xFFFFFFFF
    canvas.starfield(seed=(seed + 100 + page_num) & 0xFFFFFFFF, count=65)

    canvas.set_fill(theme.accent_soft)
    canvas.rect(0, 760, 612, 32, fill=True, stroke=False)
    canvas.text(48, 770, "Core Interpretations", font="F2", size=16, color=fg)
    canvas.text(48, 742, f"Focus: {theme.focus}", font="F1", size=10, color=muted)

    # Two-column panels (Western + Vedic).
    canvas.set_fill(panel)
    canvas.rect(48, 332, 252, 394, fill=True, stroke=False)
    canvas.set_fill(panel)
    canvas.rect(312, 332, 252, 394, fill=True, stroke=False)

    canvas.text(64, 710, "Western Big Three", font="F2", size=12, color=fg)
    y = 690
    y = _draw_placement_block(
        canvas,
        x=64,
        y=y,
        heading="Sun",
        placement_kind="sun",
        planets=data.western_planets,
        sign_names=WESTERN_SIGNS,
        theme=theme,
        fg=fg,
        muted=muted,
        max_width=224,
        domain=data.domain,
    )
    y = _draw_placement_block(
        canvas,
        x=64,
        y=y,
        heading="Moon",
        placement_kind="moon",
        planets=data.western_planets,
        sign_names=WESTERN_SIGNS,
        theme=theme,
        fg=fg,
        muted=muted,
        max_width=224,
        domain=data.domain,
    )
    _draw_placement_block(
        canvas,
        x=64,
        y=y,
        heading="Ascendant",
        placement_kind="ascendant",
        planets=data.western_planets,
        sign_names=WESTERN_SIGNS,
        theme=theme,
        fg=fg,
        muted=muted,
        max_width=224,
        domain=data.domain,
    )

    canvas.text(328, 710, "Kundali Focus", font="F2", size=12, color=fg)
    y = 690
    y = _draw_placement_block(
        canvas,
        x=328,
        y=y,
        heading="Sun",
        placement_kind="sun",
        planets=data.vedic_planets,
        sign_names=VEDIC_SIGNS,
        theme=theme,
        fg=fg,
        muted=muted,
        max_width=224,
        domain=data.domain,
    )
    y = _draw_placement_block(
        canvas,
        x=328,
        y=y,
        heading="Moon",
        placement_kind="moon",
        planets=data.vedic_planets,
        sign_names=VEDIC_SIGNS,
        theme=theme,
        fg=fg,
        muted=muted,
        max_width=224,
        domain=data.domain,
    )
    _draw_placement_block(
        canvas,
        x=328,
        y=y,
        heading="Lagna",
        placement_kind="ascendant",
        planets=data.vedic_planets,
        sign_names=VEDIC_SIGNS,
        theme=theme,
        fg=fg,
        muted=muted,
        max_width=224,
        domain=data.domain,
    )

    # Synthesis + Timing panel
    canvas.set_fill(panel)
    canvas.rect(48, 92, 516, 220, fill=True, stroke=False)
    canvas.text(64, 292, "Synthesis", font="F2", size=12, color=fg)

    western_sun_traits = traits_for_sign(_placement_sign_deg(data.western_planets, "sun")[0], sign_names=WESTERN_SIGNS)
    western_moon_traits = traits_for_sign(_placement_sign_deg(data.western_planets, "moon")[0], sign_names=WESTERN_SIGNS)
    canvas.wrapped_text(
        64,
        272,
        synthesis_line(western_sun_traits, western_moon_traits, theme=theme),
        font="F1",
        size=10,
        color=muted,
        max_width=488,
    )

    canvas.text(64, 232, "Current Timing (Vimshottari)", font="F2", size=11, color=fg)
    maha = (data.dashas or {}).get("mahadasha") if isinstance((data.dashas or {}).get("mahadasha"), dict) else {}
    antar = (data.dashas or {}).get("antardasha") if isinstance((data.dashas or {}).get("antardasha"), dict) else {}
    maha_lord = maha.get("lord")
    antar_lord = antar.get("lord")

    timing_lines: list[str] = []
    if isinstance(maha_lord, str) and maha_lord.strip():
        timing_lines.append(
            f"Mahadasha: {maha_lord}  {_safe_str(maha.get('start'), '—')} \u2192 {_safe_str(maha.get('end'), '—')}"
        )
    if isinstance(antar_lord, str) and antar_lord.strip():
        timing_lines.append(
            f"Antardasha: {antar_lord}  {_safe_str(antar.get('start'), '—')} \u2192 {_safe_str(antar.get('end'), '—')}"
        )
    if not timing_lines:
        timing_lines.append("Timing data is unavailable for this report.")

    y = 214
    for line in timing_lines:
        canvas.wrapped_text(64, y, line, font="F1", size=9, color=muted, max_width=488)
        y -= 18

    bullets = dasha_bullets(maha_lord if isinstance(maha_lord, str) else None)
    if bullets:
        canvas.bullets(64, 166, bullets, font="F1", size=9, color=muted, max_width=488)

    _stamp_footer(canvas, data, color=muted, page_num=page_num, total_pages=total_pages)


def render_report_pdf(report_id: str, report: dict[str, Any] | None, *, domain: str | None = None) -> bytes:
    """Render a deterministic, multi-page PDF for a stored report."""
    data = _parse_report_content(report, report_id)
    theme = theme_for_report(data.report_type, domain=(domain or data.domain))

    doc = PDFDocument()
    include_vedic_extras = data.report_type == "birth_chart" and isinstance(data.vedic_analysis, dict)
    total_pages = 10 if include_vedic_extras else 7

    cover = PDFCanvas()
    _draw_cover(cover, data, theme)
    _stamp_footer(cover, data, color=RGB(0.65, 0.70, 0.78), page_num=1, total_pages=total_pages)
    doc.add_page(cover.build())

    highlights = PDFCanvas()
    _draw_highlights(highlights, data, theme)
    _stamp_footer(highlights, data, color=RGB(0.65, 0.70, 0.78), page_num=2, total_pages=total_pages)
    doc.add_page(highlights.build())

    interpretations = PDFCanvas()
    _draw_interpretations_page(interpretations, data=data, theme=theme, page_num=3, total_pages=total_pages)
    doc.add_page(interpretations.build())

    # Domain Deep Dive page (domain-specific planet focus)
    deep_dive = PDFCanvas()
    _draw_domain_deep_dive(deep_dive, data=data, theme=theme, page_num=4, total_pages=total_pages)
    doc.add_page(deep_dive.build())

    page_offset = 0
    if include_vedic_extras:
        vedic_details = PDFCanvas()
        _draw_vedic_details_page(vedic_details, data=data, theme=theme, page_num=5, total_pages=total_pages)
        doc.add_page(vedic_details.build())

        dasha_timeline = PDFCanvas()
        _draw_dasha_timeline_page(dasha_timeline, data=data, theme=theme, page_num=6, total_pages=total_pages)
        doc.add_page(dasha_timeline.build())

        vedic_advanced = PDFCanvas()
        _draw_vedic_advanced_page(vedic_advanced, data=data, theme=theme, page_num=7, total_pages=total_pages)
        doc.add_page(vedic_advanced.build())
        page_offset = 3

    western = PDFCanvas()
    _draw_chart_page(
        western,
        data=data,
        theme=theme,
        title="Western (Tropical) Chart",
        planets=data.western_planets,
        signs=WESTERN_SIGNS,
        vedic=False,
        include_aspects=True,
        page_num=5 + page_offset,
        total_pages=total_pages,
    )
    doc.add_page(western.build())

    vedic_page = PDFCanvas()
    _draw_chart_page(
        vedic_page,
        data=data,
        theme=theme,
        title="Vedic (Sidereal) Chart",
        planets=data.vedic_planets,
        signs=VEDIC_SIGNS,
        vedic=True,
        include_aspects=False,
        page_num=6 + page_offset,
        total_pages=total_pages,
    )
    doc.add_page(vedic_page.build())

    action = PDFCanvas()
    _draw_action_page(action, data=data, theme=theme, page_num=7 + page_offset, total_pages=total_pages)
    doc.add_page(action.build())

    return doc.build()
