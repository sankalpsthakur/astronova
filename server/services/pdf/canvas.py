from __future__ import annotations

import math
import textwrap
from dataclasses import dataclass
from typing import Iterable


def _pdf_escape(text: str) -> str:
    return text.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")


def _sanitize_text(text: str) -> str:
    # Normalize line endings and replace common Unicode punctuation with ASCII so
    # we don't end up with "?" from latin-1 replacement.
    cleaned = text.replace("\r\n", "\n").replace("\r", "\n")
    replacements = {
        "\u00a0": " ",  # nbsp
        "\u2010": "-",  # hyphen
        "\u2011": "-",  # non-breaking hyphen
        "\u2012": "-",  # figure dash
        "\u2013": "-",  # en dash
        "\u2014": "-",  # em dash
        "\u2212": "-",  # minus
        "\u2192": "->",  # right arrow
        "\u2026": "...",  # ellipsis
        "\u2018": "'",  # left single quote
        "\u2019": "'",  # right single quote
        "\u201c": '"',  # left double quote
        "\u201d": '"',  # right double quote
    }
    for src, dst in replacements.items():
        cleaned = cleaned.replace(src, dst)
    return cleaned


@dataclass(frozen=True)
class RGB:
    r: float
    g: float
    b: float

    def clamp(self) -> "RGB":
        return RGB(
            r=min(1.0, max(0.0, self.r)),
            g=min(1.0, max(0.0, self.g)),
            b=min(1.0, max(0.0, self.b)),
        )

    def fill(self) -> str:
        c = self.clamp()
        return f"{c.r:.3f} {c.g:.3f} {c.b:.3f} rg"

    def stroke(self) -> str:
        c = self.clamp()
        return f"{c.r:.3f} {c.g:.3f} {c.b:.3f} RG"


class PDFCanvas:
    """Builds a single page content stream."""

    def __init__(self) -> None:
        self._cmd: list[str] = []

    def raw(self, *lines: str) -> None:
        self._cmd.extend(lines)

    def set_fill(self, color: RGB) -> None:
        self._cmd.append(color.fill())

    def set_stroke(self, color: RGB) -> None:
        self._cmd.append(color.stroke())

    def set_line_width(self, width: float) -> None:
        self._cmd.append(f"{width:.3f} w")

    def rect(self, x: float, y: float, w: float, h: float, *, fill: bool = True, stroke: bool = False) -> None:
        self._cmd.append(f"{x:.2f} {y:.2f} {w:.2f} {h:.2f} re")
        if fill and stroke:
            self._cmd.append("B")
        elif fill:
            self._cmd.append("f")
        elif stroke:
            self._cmd.append("S")

    def line(self, x1: float, y1: float, x2: float, y2: float) -> None:
        self._cmd.append(f"{x1:.2f} {y1:.2f} m {x2:.2f} {y2:.2f} l S")

    def circle(self, cx: float, cy: float, r: float, *, fill: bool = False, stroke: bool = True) -> None:
        # 4-segment cubic Bezier approximation.
        k = 0.5522847498307936
        ox = r * k
        oy = r * k

        self._cmd.append(f"{cx + r:.2f} {cy:.2f} m")
        self._cmd.append(f"{cx + r:.2f} {cy + oy:.2f} {cx + ox:.2f} {cy + r:.2f} {cx:.2f} {cy + r:.2f} c")
        self._cmd.append(f"{cx - ox:.2f} {cy + r:.2f} {cx - r:.2f} {cy + oy:.2f} {cx - r:.2f} {cy:.2f} c")
        self._cmd.append(f"{cx - r:.2f} {cy - oy:.2f} {cx - ox:.2f} {cy - r:.2f} {cx:.2f} {cy - r:.2f} c")
        self._cmd.append(f"{cx + ox:.2f} {cy - r:.2f} {cx + r:.2f} {cy - oy:.2f} {cx + r:.2f} {cy:.2f} c")
        self._cmd.append("h")
        if fill and stroke:
            self._cmd.append("B")
        elif fill:
            self._cmd.append("f")
        elif stroke:
            self._cmd.append("S")

    def text(self, x: float, y: float, text: str, *, font: str = "F1", size: int = 12, color: RGB | None = None) -> None:
        safe = _pdf_escape(_sanitize_text(text))
        if color is not None:
            self._cmd.append(color.fill())
        self._cmd.append(f"BT /{font} {size} Tf {x:.2f} {y:.2f} Td ({safe}) Tj ET")

    def wrapped_text(
        self,
        x: float,
        y: float,
        text: str,
        *,
        font: str = "F1",
        size: int = 12,
        color: RGB | None = None,
        max_width: float = 468.0,
        line_height: float | None = None,
    ) -> float:
        """Draw wrapped text block. Returns the y position after drawing."""
        line_height = line_height or (size * 1.35)

        # Conservative approximation to avoid overflow.
        approx_char_width = size * 0.52
        max_chars = max(10, int(max_width / approx_char_width))
        lines = textwrap.wrap(_sanitize_text(text), width=max_chars, break_long_words=True, replace_whitespace=False)
        yy = y
        for line in lines:
            self.text(x, yy, line, font=font, size=size, color=color)
            yy -= line_height
        return yy

    def bullets(
        self,
        x: float,
        y: float,
        items: Iterable[str],
        *,
        font: str = "F1",
        size: int = 12,
        color: RGB | None = None,
        max_width: float = 468.0,
        bullet_gap: float = 10.0,
    ) -> float:
        yy = y
        for item in items:
            start_y = yy
            yy = self.wrapped_text(
                x + bullet_gap,
                start_y,
                str(item),
                font=font,
                size=size,
                color=color,
                max_width=max_width - bullet_gap,
                line_height=size * 1.35,
            )
            # Draw a simple bullet as a filled circle.
            if color is not None:
                self.set_fill(color)
            self.circle(x + 3, start_y + (size * 0.30), 1.6, fill=True, stroke=False)
            yy -= size * 0.25
        return yy

    def starfield(self, *, seed: int, count: int = 80, bounds: tuple[float, float, float, float] = (0, 0, 612, 792)) -> None:
        """Draw a deterministic starfield using tiny filled squares."""
        x0, y0, x1, y1 = bounds
        w = x1 - x0
        h = y1 - y0

        # Simple LCG for determinism across Python versions.
        state = seed & 0xFFFFFFFF

        def rnd() -> float:
            nonlocal state
            state = (1664525 * state + 1013904223) & 0xFFFFFFFF
            return state / 4294967296.0

        self.set_fill(RGB(0.95, 0.95, 1.0))
        for _ in range(count):
            sx = x0 + rnd() * w
            sy = y0 + rnd() * h
            size = 0.8 + rnd() * 1.6
            alpha = 0.15 + rnd() * 0.55
            # Simulate alpha by blending toward background; caller should set bg first.
            self.set_fill(RGB(0.8 * alpha + 0.08, 0.9 * alpha + 0.10, 1.0 * alpha + 0.15))
            self.rect(sx, sy, size, size, fill=True, stroke=False)

    def build(self) -> bytes:
        # Use latin-1 to preserve degree sign; replace unsupported glyphs deterministically.
        content = "\n".join(self._cmd) + "\n"
        return content.encode("latin-1", errors="replace")


def polar_point(cx: float, cy: float, r: float, deg: float) -> tuple[float, float]:
    rad = math.radians(deg)
    return cx + r * math.cos(rad), cy + r * math.sin(rad)
