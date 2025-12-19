"""PDF report rendering (dependency-free).

This module intentionally avoids external PDF libraries to keep the server
deployment minimal and deterministic.
"""

from .report_renderer import render_report_pdf

__all__ = ["render_report_pdf"]

