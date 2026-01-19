from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SERVER_ROOT = ROOT / "server"
if str(SERVER_ROOT) not in sys.path:
    sys.path.insert(0, str(SERVER_ROOT))


from errors import SwissEphemerisUnavailableError  # noqa: E402
from services.report_generation_service import ReportGenerationService  # noqa: E402


DEFAULT_TYPES = [
    "birth_chart",
    "love_forecast",
    "career_forecast",
    "money_forecast",
    "health_forecast",
    "family_forecast",
    "spiritual_forecast",
]


def main() -> int:
    parser = argparse.ArgumentParser(description="Regenerate Astronova report bundle JSON for a birth profile.")
    parser.add_argument("--date", required=True, help="Birth date YYYY-MM-DD")
    parser.add_argument("--time", required=True, help="Birth time HH:MM (local)")
    parser.add_argument("--timezone", required=True, help="IANA timezone (e.g. Asia/Kolkata)")
    parser.add_argument("--lat", type=float, required=True, help="Latitude")
    parser.add_argument("--lon", type=float, required=True, help="Longitude")
    parser.add_argument("--location", default=None, help="Location name (optional)")
    parser.add_argument(
        "--types",
        default=",".join(DEFAULT_TYPES),
        help=f"Comma-separated report types (default: {','.join(DEFAULT_TYPES)})",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=None,
        help="Output JSON path (default: reports/<date>_<time>_reports.json)",
    )
    args = parser.parse_args()

    out = args.out
    if out is None:
        safe_time = args.time.replace(":", "")
        out = ROOT / "reports" / f"{args.date}_{safe_time}_reports.json"

    birth_data: dict = {
        "date": args.date,
        "time": args.time,
        "timezone": args.timezone,
        "latitude": args.lat,
        "longitude": args.lon,
    }
    if args.location:
        birth_data["location_name"] = args.location

    service = ReportGenerationService()
    bundle: dict[str, object] = {}
    types = [t.strip() for t in str(args.types).split(",") if t.strip()]

    try:
        for report_type in types:
            generated = service.generate(report_type=report_type, birth_data=birth_data)
            try:
                bundle[report_type] = json.loads(generated.content)
            except Exception:
                bundle[report_type] = {"reportType": report_type, "content": generated.content}
    except SwissEphemerisUnavailableError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        print("Install Swiss Ephemeris with `pip install pyswisseph` and retry.", file=sys.stderr)
        return 2

    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

