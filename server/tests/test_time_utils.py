"""UTC helpers must import and run on the Python 3.10 CI matrix."""

from datetime import datetime

from utils.time_utils import utc_now_iso, utc_now_naive


def test_utc_now_naive_is_naive_datetime():
    now = utc_now_naive()
    assert isinstance(now, datetime)
    assert now.tzinfo is None


def test_utc_now_iso_is_parseable_naive_iso():
    parsed = datetime.fromisoformat(utc_now_iso())
    assert parsed.tzinfo is None
