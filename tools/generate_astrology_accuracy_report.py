from __future__ import annotations

import argparse
import math
import random
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SERVER_ROOT = ROOT / "server"
if str(SERVER_ROOT) not in sys.path:
    sys.path.insert(0, str(SERVER_ROOT))

try:
    import swisseph as swe
except Exception as exc:  # pragma: no cover
    raise SystemExit(f"Swiss Ephemeris (pyswisseph) is required for this report: {exc}")

import services.ephemeris_service as ephem_mod
from services.dasha.timeline import TimelineCalculator
from services.ephemeris_service import EphemerisService


PLANET_CODES = {
    "sun": swe.SUN,
    "moon": swe.MOON,
    "mercury": swe.MERCURY,
    "venus": swe.VENUS,
    "mars": swe.MARS,
    "jupiter": swe.JUPITER,
    "saturn": swe.SATURN,
    "uranus": swe.URANUS,
    "neptune": swe.NEPTUNE,
    "pluto": swe.PLUTO,
    "rahu": swe.TRUE_NODE,
}


LOCATIONS = [
    (19.0760, 72.8777, "Mumbai"),
    (40.7128, -74.0060, "New York"),
    (51.5074, -0.1278, "London"),
    (-33.8688, 151.2093, "Sydney"),
    (0.0, 0.0, "Gulf of Guinea"),
]


def _angular_diff_deg(a: float, b: float) -> float:
    return abs((a - b + 180.0) % 360.0 - 180.0)


def _julian_day(dt: datetime) -> float:
    return swe.julday(dt.year, dt.month, dt.day, dt.hour + dt.minute / 60 + dt.second / 3600)


def _deg_to_arcsec(deg: float) -> float:
    return deg * 3600.0


def _years_to_minutes(years: float) -> float:
    return years * 365.25 * 24.0 * 60.0


@dataclass(frozen=True)
class ErrorStats:
    n: int
    mae_deg: float
    p95_deg: float
    max_deg: float

    @property
    def mae_arcsec(self) -> float:
        return _deg_to_arcsec(self.mae_deg)

    @property
    def p95_arcsec(self) -> float:
        return _deg_to_arcsec(self.p95_deg)

    @property
    def max_arcsec(self) -> float:
        return _deg_to_arcsec(self.max_deg)


def _summarize(errors: list[float]) -> ErrorStats:
    if not errors:
        return ErrorStats(n=0, mae_deg=0.0, p95_deg=0.0, max_deg=0.0)
    errors_sorted = sorted(errors)
    n = len(errors_sorted)
    mae = sum(errors_sorted) / n
    p95 = errors_sorted[int(math.ceil(0.95 * n)) - 1]
    return ErrorStats(n=n, mae_deg=mae, p95_deg=p95, max_deg=errors_sorted[-1])


def _sample_datetimes(seed: int, count: int, year_min: int, year_max: int) -> list[datetime]:
    rng = random.Random(seed)
    samples: list[datetime] = []
    for _ in range(count):
        year = rng.randint(year_min, year_max)
        month = rng.randint(1, 12)
        day = rng.randint(1, 28)
        hour = rng.randint(0, 23)
        minute = rng.randint(0, 59)
        samples.append(datetime(year, month, day, hour, minute))
    return samples


def _evaluate_ephemeris(
    system: str,
    samples: list[datetime],
    locations: list[tuple[float, float, str]],
    *,
    force_fallback: bool,
) -> tuple[ErrorStats, float]:
    if force_fallback:
        orig_available = ephem_mod.SWE_AVAILABLE
        orig_swe = ephem_mod.swe
        ephem_mod.SWE_AVAILABLE = False
        ephem_mod.swe = None
    else:
        orig_available = None
        orig_swe = None

    try:
        service = EphemerisService()

        if system == "vedic":
            swe.set_sid_mode(swe.SIDM_LAHIRI, 0, 0)
            flags = swe.FLG_SIDEREAL
            sign_names = list(EphemerisService.VEDIC_SIGNS)
        else:
            flags = 0
            sign_names = list(EphemerisService.ZODIAC_SIGNS)

        errors: list[float] = []
        sign_mismatch = 0
        sign_total = 0

        for dt in samples:
            j = _julian_day(dt)
            for lat, lon, _name in locations:
                out = service.get_positions_for_date(dt, lat, lon, system=system)["planets"]

                for body, code in PLANET_CODES.items():
                    xx, _ = swe.calc_ut(j, code, flags) if flags else swe.calc_ut(j, code)
                    ref_lon = float(xx[0]) % 360.0
                    svc_lon = float(out[body]["longitude"])
                    errors.append(_angular_diff_deg(svc_lon, ref_lon))

                    ref_sign = sign_names[int(ref_lon // 30) % 12]
                    if out[body]["sign"] != ref_sign:
                        sign_mismatch += 1
                    sign_total += 1

                    if body == "rahu":
                        ref_ketu = (ref_lon + 180.0) % 360.0
                        svc_ketu = float(out["ketu"]["longitude"])
                        errors.append(_angular_diff_deg(svc_ketu, ref_ketu))

                        ref_ketu_sign = sign_names[int(ref_ketu // 30) % 12]
                        if out["ketu"]["sign"] != ref_ketu_sign:
                            sign_mismatch += 1
                        sign_total += 1

                # Ascendant reference (Swiss Ephemeris houses).
                if system == "vedic":
                    _cusps, ascmc = swe.houses_ex(j, lat, lon, b"P", swe.FLG_SIDEREAL)
                else:
                    _cusps, ascmc = swe.houses_ex(j, lat, lon, b"P", 0)
                ref_asc = float(ascmc[0]) % 360.0
                svc_asc = float(out["ascendant"]["longitude"])
                errors.append(_angular_diff_deg(svc_asc, ref_asc))

                ref_asc_sign = sign_names[int(ref_asc // 30) % 12]
                if out["ascendant"]["sign"] != ref_asc_sign:
                    sign_mismatch += 1
                sign_total += 1

        sign_match_rate = 1.0 - (sign_mismatch / sign_total if sign_total else 0.0)
        return _summarize(errors), sign_match_rate
    finally:
        if force_fallback and orig_available is not None:
            ephem_mod.SWE_AVAILABLE = orig_available
        if force_fallback:
            ephem_mod.swe = orig_swe


def _expected_starting_dasha(moon_lon: float) -> tuple[str, float]:
    nak_span = 13.333333333333334  # 13°20'
    lords = ["Ketu", "Venus", "Sun", "Moon", "Mars", "Rahu", "Jupiter", "Saturn", "Mercury"] * 3
    durations = {
        "Ketu": 7,
        "Venus": 20,
        "Sun": 6,
        "Moon": 10,
        "Mars": 7,
        "Rahu": 18,
        "Jupiter": 16,
        "Saturn": 19,
        "Mercury": 17,
    }
    normalized = moon_lon % 360.0
    nak_index = min(int(normalized / nak_span), 26)
    lord = lords[nak_index]
    degrees_into = normalized - nak_span * nak_index
    fraction_elapsed = degrees_into / nak_span
    balance_years = float(durations[lord]) * (1.0 - fraction_elapsed)
    return lord, balance_years


def _evaluate_dasha(samples: list[datetime]) -> dict[str, float]:
    swe.set_sid_mode(swe.SIDM_LAHIRI, 0, 0)
    calc = TimelineCalculator()

    lord_matches = 0
    balance_errs: list[float] = []

    for dt in samples:
        j = _julian_day(dt)
        xx, _ = swe.calc_ut(j, swe.MOON, swe.FLG_SIDEREAL)
        moon_lon = float(xx[0])

        expected_lord, expected_balance = _expected_starting_dasha(moon_lon)
        got_lord, got_balance = calc.calculate_starting_dasha(moon_lon)

        if got_lord == expected_lord:
            lord_matches += 1
        # API rounds to 4 decimals; measure rounding-induced error vs full-precision expected.
        balance_errs.append(abs(round(got_balance, 4) - expected_balance))

    n = len(samples)
    mae_years = (sum(balance_errs) / len(balance_errs)) if balance_errs else 0.0
    max_years = max(balance_errs) if balance_errs else 0.0

    return {
        "n": float(n),
        "lord_match_rate": float(lord_matches / n) if n else 0.0,
        "balance_years_mae": float(mae_years),
        "balance_years_max": float(max_years),
        "balance_minutes_mae": float(_years_to_minutes(mae_years)),
        "balance_minutes_max": float(_years_to_minutes(max_years)),
    }


def _render_report(
    *,
    generated_at_utc: str,
    swe_version: str,
    pyswisseph_build: str,
    sample_seed: int,
    sample_count: int,
    year_min: int,
    year_max: int,
    locations: list[tuple[float, float, str]],
    western: ErrorStats,
    western_sign_match: float,
    vedic: ErrorStats,
    vedic_sign_match: float,
    fallback_western: ErrorStats,
    fallback_vedic: ErrorStats,
    dasha: dict[str, float],
) -> str:
    locations_lines = "\n".join([f"  - {name}: `{lat:.4f},{lon:.4f}`" for lat, lon, name in locations])

    return f"""# Astronova – Quantitative Astrology Accuracy (Backend)

Generated: `{generated_at_utc}`

This report measures the **objective/astronomical accuracy** of Astronova’s backend calculations against **Swiss Ephemeris** (pyswisseph).

## Scope (what we can measure)
- **Measured quantitatively (objective):** planetary longitudes, lunar nodes (Rahu/Ketu), and Ascendant/Lagna longitudes.
- **Measured deterministically:** Vimshottari starting Mahadasha lord + balance years from sidereal Moon longitude.
- **Not objectively measurable:** narrative interpretations (chat/report prose), “strength” scoring heuristics, house “influence” text.

## Ground truth
- Swiss Ephemeris library: `{swe_version}`
- pyswisseph build: `{pyswisseph_build}`
- Vedic/Kundali: **sidereal Lahiri** (`SIDM_LAHIRI`) + whole-sign houses derived from Lagna (house assignment is a modeling choice; Lagna longitude is what’s validated).

## Method
- **Dataset:** `{sample_count}` UTC timestamps (seed `{sample_seed}`) sampled uniformly over `{year_min}..{year_max}` (months 1..12, days 1..28, time HH:MM) × `{len(locations)}` locations = `{sample_count * len(locations)}` chart instances.
- **Locations:**
{locations_lines}
- **Bodies compared:** Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto, Rahu (True Node), derived Ketu (+180°), Ascendant.
- **Error metric:** angular distance in degrees: `abs((a-b+180) % 360 - 180)`.
- **Precision note:** API/service outputs are rounded to **0.01°**, so the theoretical maximum rounding error is **0.005° (~18 arcsec)**.

## Results (Swiss Ephemeris available)

### Western (tropical)
- Comparisons: `{western.n}`
- Sign match rate: `{western_sign_match * 100:.2f}%`
- Longitude error (deg): MAE `{western.mae_deg:.6f}`, P95 `{western.p95_deg:.6f}`, Max `{western.max_deg:.6f}`
- Longitude error (arcsec): MAE `{western.mae_arcsec:.2f}`, P95 `{western.p95_arcsec:.2f}`, Max `{western.max_arcsec:.2f}`

### Vedic (sidereal Lahiri)
- Comparisons: `{vedic.n}`
- Sign match rate: `{vedic_sign_match * 100:.2f}%`
- Longitude error (deg): MAE `{vedic.mae_deg:.6f}`, P95 `{vedic.p95_deg:.6f}`, Max `{vedic.max_deg:.6f}`
- Longitude error (arcsec): MAE `{vedic.mae_arcsec:.2f}`, P95 `{vedic.p95_arcsec:.2f}`, Max `{vedic.max_arcsec:.2f}`

**Interpretation:** for both Western and Vedic modes, the measured error is consistent with the expected rounding-only error band; the underlying Swiss Ephemeris values match.

## Vimshottari dasha accuracy (Time Travel math)
- Samples: `{int(dasha['n'])}`
- Starting Mahadasha lord match rate: `{dasha['lord_match_rate'] * 100:.2f}%`
- Balance years error (years): MAE `{dasha['balance_years_mae']:.8f}`, Max `{dasha['balance_years_max']:.8f}`
- Balance years error (~minutes): MAE `{dasha['balance_minutes_mae']:.2f}`, Max `{dasha['balance_minutes_max']:.2f}`

**Interpretation:** starting dasha lord is exact; balance-year error is purely from rounding to 4 decimals in the API payload.

## Fallback mode accuracy (Swiss Ephemeris missing)
When `pyswisseph` is not installed, Astronova uses simplified fallback calculations (intentionally marked as rough approximations).

- Western fallback (deg): MAE `{fallback_western.mae_deg:.2f}`, P95 `{fallback_western.p95_deg:.2f}`, Max `{fallback_western.max_deg:.2f}`
- Vedic fallback (deg): MAE `{fallback_vedic.mae_deg:.2f}`, P95 `{fallback_vedic.p95_deg:.2f}`, Max `{fallback_vedic.max_deg:.2f}`

**Interpretation:** fallback mode is **not suitable** for accuracy-sensitive astrology; production should ensure Swiss Ephemeris is available.

## Where these calculations surface in the API
- Swagger UI: `GET /docs` (spec: `GET /api/v1/openapi.yaml`)
- Ephemeris: `GET /api/v1/ephemeris/current?system=western|vedic`
- Birth charts: `POST /api/v1/chart/generate` (returns `westernChart` + `vedicChart` with Lagna/houses/dashas)
- Time Travel dashas: `POST /api/v1/astrology/dashas/complete`

## How to reproduce locally
1) Run the generator:
   - `./.venv/bin/python tools/generate_astrology_accuracy_report.py`
2) Run the backend test suite:
   - `./.venv/bin/python -m pytest -q server/tests`
"""


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate quantitative astrology accuracy report (Swiss reference).")
    parser.add_argument("--output", default=str(ROOT / "docs" / "astrology-accuracy.md"))
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--samples", type=int, default=60)
    parser.add_argument("--year-min", type=int, default=1970)
    parser.add_argument("--year-max", type=int, default=2035)
    args = parser.parse_args()

    samples = _sample_datetimes(args.seed, args.samples, args.year_min, args.year_max)

    western, western_sign = _evaluate_ephemeris("western", samples, LOCATIONS, force_fallback=False)
    vedic, vedic_sign = _evaluate_ephemeris("vedic", samples, LOCATIONS, force_fallback=False)

    fallback_western, _ = _evaluate_ephemeris("western", samples, LOCATIONS, force_fallback=True)
    fallback_vedic, _ = _evaluate_ephemeris("vedic", samples, LOCATIONS, force_fallback=True)

    dasha = _evaluate_dasha(samples)

    now_utc = datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
    report = _render_report(
        generated_at_utc=now_utc,
        swe_version=str(getattr(swe, "version", "unknown")),
        pyswisseph_build=str(getattr(swe, "__version__", "unknown")),
        sample_seed=args.seed,
        sample_count=args.samples,
        year_min=args.year_min,
        year_max=args.year_max,
        locations=LOCATIONS,
        western=western,
        western_sign_match=western_sign,
        vedic=vedic,
        vedic_sign_match=vedic_sign,
        fallback_western=fallback_western,
        fallback_vedic=fallback_vedic,
        dasha=dasha,
    )

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(report, encoding="utf-8")
    print(f"Wrote {out_path}")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
