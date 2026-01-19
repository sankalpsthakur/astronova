"""Sunrise/sunset calculations using Swiss Ephemeris."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date as Date, datetime, timedelta
from zoneinfo import ZoneInfo

import swisseph as swe


@dataclass(frozen=True)
class RiseSetTimes:
    sunrise_local: str
    sunset_local: str
    sunrise_utc: str
    sunset_utc: str
    day_length_hours: float


def _jd_ut(dt_utc_naive: datetime) -> float:
    """Julian day for a naive UTC datetime."""
    return float(
        swe.julday(
            dt_utc_naive.year,
            dt_utc_naive.month,
            dt_utc_naive.day,
            dt_utc_naive.hour + dt_utc_naive.minute / 60 + dt_utc_naive.second / 3600,
        )
    )


def _datetime_from_jd_ut(jd_ut: float) -> datetime:
    year, month, day, hour = swe.revjul(float(jd_ut))
    hours = int(hour)
    minutes_float = (hour - hours) * 60.0
    minutes = int(minutes_float)
    seconds = int(round((minutes_float - minutes) * 60.0))
    if seconds >= 60:
        seconds -= 60
        minutes += 1
    if minutes >= 60:
        minutes -= 60
        hours += 1
    return datetime(int(year), int(month), int(day), int(hours), int(minutes), int(seconds))


def sunrise_sunset_for_date(
    *,
    local_date: Date,
    timezone: str,
    latitude: float,
    longitude: float,
    altitude_m: float = 0.0,
) -> dict[str, object]:
    """Compute sunrise/sunset times for a local calendar date at a location."""
    tz = ZoneInfo(timezone)
    start_local = datetime(local_date.year, local_date.month, local_date.day, 0, 0, 0, tzinfo=tz)
    start_utc = start_local.astimezone(ZoneInfo("UTC")).replace(tzinfo=None)

    geopos = (float(longitude), float(latitude), float(altitude_m))
    flags = int(getattr(swe, "FLG_SWIEPH", 0))

    res_rise, tret_rise = swe.rise_trans(_jd_ut(start_utc), swe.SUN, swe.CALC_RISE, geopos, 0.0, 0.0, flags)
    if res_rise != 0:
        raise ValueError("Sunrise not found for this location/date (circumpolar).")

    res_set, tret_set = swe.rise_trans(_jd_ut(start_utc), swe.SUN, swe.CALC_SET, geopos, 0.0, 0.0, flags)
    if res_set != 0:
        raise ValueError("Sunset not found for this location/date (circumpolar).")

    sunrise_utc = _datetime_from_jd_ut(float(tret_rise[0]))
    sunset_utc = _datetime_from_jd_ut(float(tret_set[0]))

    sunrise_local = sunrise_utc.replace(tzinfo=ZoneInfo("UTC")).astimezone(tz)
    sunset_local = sunset_utc.replace(tzinfo=ZoneInfo("UTC")).astimezone(tz)

    length_seconds = max((sunset_utc - sunrise_utc).total_seconds(), 0.0)
    if length_seconds == 0.0 and sunset_utc < sunrise_utc:
        length_seconds = (sunset_utc + timedelta(days=1) - sunrise_utc).total_seconds()

    return RiseSetTimes(
        sunrise_local=sunrise_local.isoformat(timespec="minutes"),
        sunset_local=sunset_local.isoformat(timespec="minutes"),
        sunrise_utc=sunrise_utc.isoformat(timespec="minutes") + "Z",
        sunset_utc=sunset_utc.isoformat(timespec="minutes") + "Z",
        day_length_hours=round(length_seconds / 3600.0, 2),
    ).__dict__

