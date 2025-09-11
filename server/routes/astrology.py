from __future__ import annotations

from flask import Blueprint, jsonify
from flask import request
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from services.ephemeris_service import EphemerisService
try:
    # Access Swiss Ephemeris if available for sidereal Moon (nakshatra) calculations
    from services.ephemeris_service import SWE_AVAILABLE, swe as _swe
except Exception:  # pragma: no cover - defensive
    SWE_AVAILABLE = False
    _swe = None

astrology_bp = Blueprint('astrology', __name__)
_svc = EphemerisService()


@astrology_bp.route('/positions', methods=['GET'])
def positions():
    positions = _svc.get_positions_for_date(datetime.utcnow())
    result = {}
    for name, info in positions.get('planets', {}).items():
        key = name.title()
        result[key] = {
            'degree': float(info.get('degree', 0.0)),
            'sign': str(info.get('sign', 'Unknown'))
        }
    return jsonify(result)


def _vimshottari_sequence():
    # Order and durations in years
    return [
        ("Ketu", 7),
        ("Venus", 20),
        ("Sun", 6),
        ("Moon", 10),
        ("Mars", 7),
        ("Rahu", 18),
        ("Jupiter", 16),
        ("Saturn", 19),
        ("Mercury", 17),
    ]


def _lord_annotation(lord: str) -> str:
    notes = {
        "Sun": "Identity, authority, vitality; focus on purpose and leadership.",
        "Moon": "Emotions, home, nurturing; focus on intuition and care.",
        "Mars": "Action, courage, drive; focus on initiative and willpower.",
        "Mercury": "Intellect, communication; focus on learning and expression.",
        "Jupiter": "Growth, wisdom, fortune; focus on expansion and teaching.",
        "Venus": "Love, beauty, values; focus on harmony and relationships.",
        "Saturn": "Discipline, structure, lessons; focus on responsibility.",
        "Rahu": "Ambition, innovation, desires; unconventional progress.",
        "Ketu": "Detachment, insight, spirituality; inner refinement.",
    }
    return notes.get(lord, "Period of karmic development and learning.")


@astrology_bp.route('/dashas', methods=['GET'])
def dashas():
    """
    Minimal Vimshottari-style dasha calculator (approximate).
    Query:
      - birth_date: YYYY-MM-DD (required)
      - birth_time: HH:MM (optional)
      - timezone: IANA tz (optional, defaults UTC)
      - target_date: YYYY-MM-DD (required)
    """
    birth_date = request.args.get('birth_date')
    birth_time = request.args.get('birth_time')  # optional HH:MM
    timezone = request.args.get('timezone', 'UTC')
    lat = request.args.get('lat', type=float)
    lon = request.args.get('lon', type=float)
    target_date = request.args.get('target_date')
    granularity = (request.args.get('granularity') or 'year').lower()
    include_boundaries = request.args.get('include_boundaries') in ('1', 'true', 'yes')
    if not birth_date or not target_date:
        return jsonify({'error': 'birth_date and target_date required'}), 400

    try:
        bd_local = datetime.strptime(birth_date + 'T' + (birth_time or '12:00'), '%Y-%m-%dT%H:%M')
        bd = bd_local.replace(tzinfo=ZoneInfo(timezone)).astimezone(ZoneInfo('UTC')).replace(tzinfo=None)
        td = datetime.strptime(target_date, '%Y-%m-%d')
    except Exception:
        return jsonify({'error': 'Invalid date/time/timezone'}), 400

    # Helpers for calendar-accurate additions (match common Vimshottari outputs)
    def _month_days(year: int, month: int) -> int:
        import calendar
        return calendar.monthrange(year, month)[1]

    def _add_years_months(dt: datetime, years: int = 0, months: int = 0) -> datetime:
        y = dt.year + years
        m0 = dt.month - 1 + months
        y += m0 // 12
        m = (m0 % 12) + 1
        d = min(dt.day, _month_days(y, m))
        return dt.replace(year=y, month=m, day=d)

    # Determine starting mahadasha
    seq = _vimshottari_sequence()
    lord_order = [x[0] for x in seq]
    dur_map = {lord: float(years) for lord, years in seq}

    # Optional overrides for calibration/testing
    override_start = (request.args.get('start_lord') or '').strip().title() or None
    override_balance_years = request.args.get('balance_years', type=float)
    override_balance_months = request.args.get('balance_months', type=float)

    if override_start and override_start not in lord_order:
        return jsonify({'error': f'Invalid start_lord {override_start}'}), 400

    if override_start is not None and (override_balance_years is not None or override_balance_months is not None):
        # Use explicit overrides
        start_lord = override_start
        years = override_balance_years or 0.0
        months = override_balance_months or 0.0
        start_balance_years = years + (months / 12.0)
    else:
        # Compute from Moon nakshatra at birth
        if SWE_AVAILABLE and _swe is not None:
            # Use sidereal longitude (Lahiri) for nakshatra correctness
            try:
                _swe.set_sid_mode(_swe.SIDM_LAHIRI, 0, 0)
                jd = _swe.julday(bd.year, bd.month, bd.day, bd.hour + bd.minute / 60 + bd.second / 3600)
                xx, _ = _swe.calc_ut(jd, _swe.MOON, _swe.FLG_SIDEREAL)
                moon_lon = float(xx[0])
            except Exception:
                positions = _svc.get_positions_for_date(bd, lat, lon)
                moon = positions.get('planets', {}).get('moon', {})
                moon_lon = float(moon.get('longitude', 0.0))
        else:
            positions = _svc.get_positions_for_date(bd, lat, lon)
            moon = positions.get('planets', {}).get('moon', {})
            moon_lon = float(moon.get('longitude', 0.0))
        # Each nakshatra spans 13°20' = 13.333... degrees
        nak_deg = 13.3333333333
        # Normalize longitude to [0, 360)
        norm_lon = moon_lon % 360.0
        # Identify birth nakshatra index (0..26)
        nak_index = int(norm_lon / nak_deg)
        start_lord = lord_order[nak_index % len(lord_order)] if not override_start else override_start
        # Balance remaining of first mahadasha at birth based on fraction of current nakshatra left
        deg_into_nak = norm_lon - (nak_deg * nak_index)
        fraction_elapsed = max(0.0, min(1.0, deg_into_nak / nak_deg))
        start_balance_years = dur_map[start_lord] * (1.0 - fraction_elapsed)

    # Build timeline across lords starting from start_lord (use calendar-year/month steps)
    def timeline(start_dt: datetime, first_lord: str):
        idx = lord_order.index(first_lord)
        cur = start_dt
        first = True
        while True:
            lord = lord_order[idx % len(lord_order)]
            years = dur_map[lord]
            # For first lord, use balance; then full durations
            span_years = start_balance_years if first else years
            whole_years = int(span_years)
            months = int(round((span_years - whole_years) * 12))
            end = _add_years_months(cur, whole_years, months)
            yield lord, cur, end, span_years
            cur = end
            idx += 1
            first = False

    # Find current Mahadasha at target_date
    maha_lord = start_lord
    maha_start = bd
    maha_end = bd
    maha_length_years = start_balance_years
    for lord, s, e, y in timeline(bd, start_lord):
        if s <= td < e:
            maha_lord, maha_start, maha_end, maha_length_years = lord, s, e, y
            break

    # Compute Antardasha within current Mahadasha
    # Use proportional months to keep calendar boundaries neat
    total_months = (maha_end.year - maha_start.year) * 12 + (maha_end.month - maha_start.month)
    if maha_end.day < maha_start.day:
        # If end day is earlier in the month than start, treat as one less full month
        total_months -= 1
    total_months = max(total_months, 1)
    antars = []
    accum = maha_start
    start_idx = lord_order.index(maha_lord)
    antar_order = lord_order[start_idx:] + lord_order[:start_idx]
    # Compute raw shares then round while preserving total via largest remainder method
    shares = [dur_map[l] / 120.0 for l in antar_order]
    raw_months = [s * total_months for s in shares]
    floor_months = [int(m) for m in raw_months]
    allocated = sum(floor_months)
    remainder = total_months - allocated
    # Distribute remaining months to largest fractional parts
    order_by_frac = sorted(range(len(raw_months)), key=lambda i: (raw_months[i] - floor_months[i]), reverse=True)
    months_alloc = floor_months[:]
    for i in range(remainder):
        months_alloc[order_by_frac[i]] += 1
    # Build antardasha segments
    for i, sub_lord in enumerate(antar_order):
        months = months_alloc[i]
        next_accum = _add_years_months(accum, 0, months)
        antars.append((sub_lord, accum, next_accum))
        accum = next_accum
    # Ensure last ends at maha_end
    if antars:
        antars[-1] = (antars[-1][0], antars[-1][1], maha_end)
    antar_lord = antars[0][0] if antars else maha_lord
    antar_start = maha_start
    antar_end = maha_end
    for lord, s, e in antars:
        if s <= td < e:
            antar_lord = lord
            antar_start = s
            antar_end = e
            break

    resp = {
        'mahadasha': {
            'lord': maha_lord,
            'start': maha_start.date().isoformat(),
            'end': maha_end.date().isoformat(),
            'annotation': _lord_annotation(maha_lord)
        },
        'antardasha': {
            'lord': antar_lord,
            'start': antar_start.date().isoformat(),
            'end': antar_end.date().isoformat(),
            'annotation': _lord_annotation(antar_lord)
        }
    }

    # Optionally include boundaries for snapping / month-level UI
    if include_boundaries or granularity == 'month':
        antar_list = [
            {
                'lord': lord,
                'start': s.date().isoformat(),
                'end': e.date().isoformat(),
                'annotation': _lord_annotation(lord)
            }
            for (lord, s, e) in antars
        ]
        resp['boundaries'] = {
            'mahadasha': {
                'lord': maha_lord,
                'start': maha_start.date().isoformat(),
                'end': maha_end.date().isoformat()
            },
            'antardasha': antar_list,
            'breakpoints': [item['start'] for item in antar_list]
        }

    # Optional debug details to aid verification
    if request.args.get('debug') in ('1', 'true', 'yes'):
        resp['debug'] = {
            'start_lord': start_lord,
            'start_balance_years': round(start_balance_years, 6),
            'start_balance_years_int': int(start_balance_years),
            'start_balance_months_approx': int(round((start_balance_years - int(start_balance_years)) * 12)),
            'mahadasha_order': lord_order,
        }

    return jsonify(resp)
