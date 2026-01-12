from __future__ import annotations

from datetime import date, datetime, time

from babel.dates import format_date, format_datetime, format_time
from babel.numbers import format_currency, format_decimal, format_percent


class LocaleFormatter:
    """Locale-aware formatting helpers for API responses."""

    def __init__(self, locale: str = "en") -> None:
        self.locale = locale or "en"

    def format_date(self, value: date | datetime, format_type: str = "medium") -> str:
        """Format a date according to locale (short/medium/long/full)."""
        return format_date(value, format=format_type, locale=self.locale)

    def format_time(self, value: time | datetime, format_type: str = "short") -> str:
        """Format a time according to locale (12-hour vs 24-hour)."""
        return format_time(value, format=format_type, locale=self.locale)

    def format_datetime(self, value: datetime, format_type: str = "medium") -> str:
        """Format a datetime according to locale."""
        return format_datetime(value, format=format_type, locale=self.locale)

    def format_number(self, value: float) -> str:
        """Format a number with locale grouping."""
        return format_decimal(value, locale=self.locale)

    def format_currency(self, amount: float, currency: str = "INR") -> str:
        """Format currency according to locale."""
        return format_currency(amount, currency, locale=self.locale)

    def format_percent(self, value: float) -> str:
        """Format a percentage according to locale."""
        return format_percent(value, locale=self.locale)
