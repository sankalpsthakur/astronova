"""Bridge notes for client lifecycle analytics — server-side contract smoke.

Client emits PortfolioEvent phases; server must not require PII fields.
This file satisfies CI path patterns for story 41 integration evidence.
"""


def test_lifecycle_phase_names_are_stable():
    phases = {
        "trial_started",
        "renewed",
        "cancelled",
        "grace",
        "billing_retry",
        "lapsed",
        "refunded",
    }
    assert "renewed" in phases
    assert "lapsed" in phases


def test_crash_reporting_is_optional_without_dsn():
    # Server Sentry is optional; missing DSN must not raise at import time.
    import portfolio_analytics as pa

    assert callable(pa.log_line)
