"""Shared server exception types.

These error types are used to return consistent API responses without silently
falling back to inaccurate calculations.
"""


class ServiceDependencyError(RuntimeError):
    """Raised when a required optional dependency is unavailable."""


class SwissEphemerisUnavailableError(ServiceDependencyError):
    """Raised when Swiss Ephemeris (pyswisseph) is required but not available."""

