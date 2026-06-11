"""Shared birth data parsing utilities."""

from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

# Plausibility bounds for a real user's birth date. Dates outside this range are
# rejected with a clear error rather than fed into the ephemeris.
MIN_BIRTH_YEAR = 1900
# Small grace window so a user whose device clock is slightly ahead, or who was
# born "today", is not rejected at a timezone boundary.
_FUTURE_GRACE = timedelta(days=1)


class BirthDataError(ValueError):
    """Raised when birth data is invalid."""

    pass


def parse_birth_data(
    data: dict,
    key: str = "birthData",
    require_coords: bool = True,
    include_timezone: bool = False,
) -> tuple:
    """Parse birth data from a nested or flat dictionary structure.

    Args:
        data: Dictionary containing birth data (nested under `key` or flat)
        key: Key name for nested structure (default: "birthData")
        require_coords: If True, raises error when lat/lon missing; if False, returns None
        include_timezone: If True, returns (dt, lat, lon, tz); if False, returns (dt, lat, lon)

    Returns:
        If include_timezone=False: (datetime, latitude, longitude)
        If include_timezone=True: (datetime, latitude, longitude, timezone_str)

    Raises:
        BirthDataError: When required fields are missing or invalid
    """
    # Accept nested { birthData: { ... }} or flat structure
    bd = data.get(key, data) if key else data
    if not bd or not isinstance(bd, dict):
        if require_coords:
            raise BirthDataError(f"{key} is required" if key else "birth data is required")
        return (None, None, None, None) if include_timezone else (None, None, None)

    # Parse date (required)
    date = bd.get("date") or bd.get("birth_date")
    if not date:
        if require_coords:
            raise BirthDataError(f"date is required (format: YYYY-MM-DD)")
        return (None, None, None, None) if include_timezone else (None, None, None)

    # Parse coordinates
    lat = bd.get("latitude")
    lon = bd.get("longitude")

    if lat is None or lon is None:
        if require_coords:
            raise BirthDataError("latitude and longitude are required")
        lat_f, lon_f = None, None
    else:
        try:
            lat_f = float(lat)
            lon_f = float(lon)
        except (ValueError, TypeError) as e:
            if require_coords:
                raise BirthDataError(f"latitude and longitude must be valid numbers: {e}")
            lat_f, lon_f = None, None

        # Validate coordinate ranges
        if lat_f is not None and not (-90 <= lat_f <= 90):
            raise BirthDataError(f"latitude must be between -90 and 90, got {lat_f}")
        if lon_f is not None and not (-180 <= lon_f <= 180):
            raise BirthDataError(f"longitude must be between -180 and 180, got {lon_f}")

    # Parse time and timezone (with defaults)
    time = bd.get("time") or bd.get("birth_time") or "12:00"
    tz = bd.get("timezone") or "UTC"

    # Validate the timezone explicitly so callers get a clear message rather
    # than a generic "invalid date/time" for a bad IANA identifier.
    try:
        tzinfo = ZoneInfo(tz)
    except Exception:
        if require_coords:
            raise BirthDataError(f"Invalid timezone: {tz!r} (expected an IANA name like 'Asia/Kolkata')")
        return (None, None, None, None) if include_timezone else (None, None, None)

    # Parse the local datetime as entered.
    try:
        dt_local = datetime.fromisoformat(f"{date}T{time}")
    except Exception as e:
        if require_coords:
            raise BirthDataError(f"Invalid date/time format: {e}")
        return (None, None, None, None) if include_timezone else (None, None, None)

    # Reject implausible birth dates. A birth date cannot be in the future, and
    # dates before 1900 are not real users (and stress the ephemeris). This
    # turns garbage input into a clear 400 instead of meaningless results.
    if MIN_BIRTH_YEAR is not None and dt_local.year < MIN_BIRTH_YEAR:
        if require_coords:
            raise BirthDataError(f"Birth year must be {MIN_BIRTH_YEAR} or later, got {dt_local.year}")
        return (None, None, None, None) if include_timezone else (None, None, None)

    aware_local = dt_local.replace(tzinfo=tzinfo)
    if aware_local > datetime.now(tzinfo) + _FUTURE_GRACE:
        if require_coords:
            raise BirthDataError("Birth date/time cannot be in the future")
        return (None, None, None, None) if include_timezone else (None, None, None)

    # Convert to UTC for downstream astronomical calculations.
    dt = aware_local.astimezone(ZoneInfo("UTC")).replace(tzinfo=None)

    if include_timezone:
        return dt, lat_f, lon_f, tz
    return dt, lat_f, lon_f
