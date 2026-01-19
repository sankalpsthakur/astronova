from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SERVER_ROOT = ROOT / "server"
if str(SERVER_ROOT) not in sys.path:
    sys.path.insert(0, str(SERVER_ROOT))


ENGLISH_TO_VEDIC = {
    "Aries": "Mesha",
    "Taurus": "Vrishabha",
    "Gemini": "Mithuna",
    "Cancer": "Karka",
    "Leo": "Simha",
    "Virgo": "Kanya",
    "Libra": "Tula",
    "Scorpio": "Vrischika",
    "Sagittarius": "Dhanu",
    "Capricorn": "Makara",
    "Aquarius": "Kumbha",
    "Pisces": "Meena",
}

VEDIC_TO_INDEX = {name: idx for idx, name in enumerate(ENGLISH_TO_VEDIC.values())}
ENGLISH_TO_INDEX = {name: idx for idx, name in enumerate(ENGLISH_TO_VEDIC.keys())}


REFERENCE_GUNA_24DEC1999 = {
    "birth": {
        "date": "1999-12-24",
        "time": "08:02",
        "timezone": "Asia/Kolkata",
        "latitude": 24.65,
        "longitude": 77.31,
    },
    # Source: user-provided Astrotalk report values.
    "placements": {
        "ascendant": ("Sagittarius", "21°20'"),
        "sun": ("Sagittarius", "7°57'"),
        "moon": ("Gemini", "27°26'"),
        "mercury": ("Scorpio", "25°9'"),
        "venus": ("Libra", "27°36'"),
        "mars": ("Capricorn", "27°36'"),
        "jupiter": ("Aries", "1°10'"),
        "saturn": ("Aries", "16°46'"),
        "rahu": ("Cancer", "11°37'"),
        "ketu": ("Capricorn", "11°37'"),
    },
    "dashas": {
        "starting_lord": "Jupiter",
        "current_mahadasha_lord": "Saturn",
        # In standard Vimshottari order (starting from the Mahadasha lord),
        # Saturn→Jupiter is the final Antardasha within Saturn Mahadasha.
        "current_antardasha_lord": "Jupiter",
    },
}


def _angular_diff_deg(a: float, b: float) -> float:
    return abs((a - b + 180.0) % 360.0 - 180.0)


def _parse_degree(value: str) -> float:
    """
    Parse strings like:
      - 7°57'
      - 25°9'
      - 21.33
    """
    raw = value.strip()
    if "°" not in raw:
        return float(raw)
    deg_part, rest = raw.split("°", 1)
    minutes = 0.0
    if "'" in rest:
        min_part = rest.split("'", 1)[0].strip()
        minutes = float(min_part) if min_part else 0.0
    return float(deg_part.strip()) + minutes / 60.0


def _abs_longitude(sign_name: str, deg_in_sign: float) -> float:
    if sign_name in ENGLISH_TO_INDEX:
        idx = ENGLISH_TO_INDEX[sign_name]
    elif sign_name in VEDIC_TO_INDEX:
        idx = VEDIC_TO_INDEX[sign_name]
    else:
        raise ValueError(f"Unknown sign: {sign_name}")
    return (idx * 30.0 + deg_in_sign) % 360.0


@dataclass(frozen=True)
class Placement:
    sign: str
    degree: float
    longitude: float


def _read_astronova_report(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or "birth_chart" not in data:
        raise ValueError("Expected a JSON object with top-level key 'birth_chart'")
    return data


def _extract_birth_chart(data: dict) -> tuple[dict, dict, dict]:
    birth_chart = data["birth_chart"]
    birth = birth_chart.get("birth", {}) if isinstance(birth_chart, dict) else {}
    vedic_planets = birth_chart.get("vedicPlanets", {}) if isinstance(birth_chart, dict) else {}
    dashas = birth_chart.get("dashas", {}) if isinstance(birth_chart, dict) else {}
    return birth, vedic_planets, dashas


def _parse_astronova_planet(vedic_planets: dict, name: str) -> Placement | None:
    info = vedic_planets.get(name)
    if not isinstance(info, dict):
        return None
    sign = str(info.get("sign") or "")
    try:
        degree = float(info.get("degree"))
        longitude = float(info.get("longitude"))
    except Exception:
        return None
    return Placement(sign=sign, degree=degree, longitude=longitude)


def _fmt_num(value: float | None) -> str:
    if value is None:
        return "—"
    return f"{value:.2f}"


def main() -> int:
    parser = argparse.ArgumentParser(description="Compare Astronova report JSON vs an Astrotalk reference baseline.")
    parser.add_argument(
        "--report",
        type=Path,
        default=ROOT / "reports" / "guna_24dec1999_reports.json",
        help="Path to Astronova aggregated report JSON (default: reports/guna_24dec1999_reports.json).",
    )
    args = parser.parse_args()

    data = _read_astronova_report(args.report)
    birth, vedic_planets, dashas = _extract_birth_chart(data)
    ref = REFERENCE_GUNA_24DEC1999

    print(f"Report: {args.report}")
    print(f"Birth (Astronova): {birth}")
    print()

    print("Placements (Vedic / Sidereal)")
    print("planet | reference (Astrotalk) | astronova | Δ° (abs longitude)")
    print("---|---|---|---")

    any_mismatch = False
    for planet, (ref_sign_en, ref_deg_str) in ref["placements"].items():
        astr = _parse_astronova_planet(vedic_planets, planet)
        ref_deg = _parse_degree(ref_deg_str)
        ref_sign_vedic = ENGLISH_TO_VEDIC.get(ref_sign_en, ref_sign_en)
        ref_lon = _abs_longitude(ref_sign_vedic, ref_deg)

        if astr is None:
            any_mismatch = True
            print(f"{planet} | {ref_sign_en} {ref_deg_str} | — | —")
            continue

        delta = _angular_diff_deg(float(astr.longitude), ref_lon)
        if delta > 1.0:
            any_mismatch = True
        print(
            f"{planet} | {ref_sign_en} {ref_deg_str} | {astr.sign} {astr.degree:.2f}° | {_fmt_num(delta)}"
        )

    print()
    print("Dashas")
    print("field | reference | astronova")
    print("---|---|---")
    starting = (dashas or {}).get("starting", {}) if isinstance(dashas, dict) else {}
    maha = (dashas or {}).get("mahadasha", {}) if isinstance(dashas, dict) else {}
    antar = (dashas or {}).get("antardasha", {}) if isinstance(dashas, dict) else {}

    astr_start_lord = starting.get("lord") if isinstance(starting, dict) else None
    astr_maha_lord = maha.get("lord") if isinstance(maha, dict) else None
    astr_antar_lord = antar.get("lord") if isinstance(antar, dict) else None

    for key, ref_value in ref["dashas"].items():
        if key == "starting_lord":
            astr_value = astr_start_lord
        elif key == "current_mahadasha_lord":
            astr_value = astr_maha_lord
        elif key == "current_antardasha_lord":
            astr_value = astr_antar_lord
        else:
            astr_value = None
        if ref_value != astr_value:
            any_mismatch = True
        print(f"{key} | {ref_value} | {astr_value}")

    print()
    if any_mismatch:
        print("Result: NOT inline (differences detected).")
        return 2
    print("Result: Inline.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
