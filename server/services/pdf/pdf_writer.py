from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class PDFFontRef:
    """A font resource reference (e.g., /F1)."""

    resource_name: str
    object_number: int


class PDFDocument:
    """Minimal, deterministic PDF writer (no compression, no external deps)."""

    def __init__(self) -> None:
        # Object numbers:
        #   1 = Catalog
        #   2 = Pages
        #   3..N = objects stored in _objects
        self._objects: list[bytes] = []
        self._page_object_numbers: list[int] = []
        self._fonts: dict[str, PDFFontRef] = {}

        # Built-in base fonts (Type1). Keep to standard 14 fonts to avoid embedding.
        self.add_base_font("F1", "Helvetica")
        self.add_base_font("F2", "Helvetica-Bold")

    def add_base_font(self, resource_name: str, base_font: str) -> PDFFontRef:
        if resource_name in self._fonts:
            return self._fonts[resource_name]

        obj_num = self._add_object(
            b"<< /Type /Font /Subtype /Type1 /BaseFont /" + base_font.encode("ascii") + b" >>"
        )
        ref = PDFFontRef(resource_name=resource_name, object_number=obj_num)
        self._fonts[resource_name] = ref
        return ref

    def add_page(self, content_stream: bytes, media_box: tuple[int, int, int, int] = (0, 0, 612, 792)) -> int:
        contents_obj = self._add_stream(content_stream)

        # Resources: expose the font objects as /F1, /F2, ...
        font_entries = []
        for name in sorted(self._fonts.keys()):
            font_entries.append(f"/{name} {self._fonts[name].object_number} 0 R".encode("ascii"))
        fonts_dict = b"<< " + b" ".join(font_entries) + b" >>"

        page_dict = (
            b"<< /Type /Page /Parent 2 0 R "
            + b"/MediaBox ["
            + b" ".join(str(v).encode("ascii") for v in media_box)
            + b"] "
            + b"/Contents "
            + str(contents_obj).encode("ascii")
            + b" 0 R "
            + b"/Resources << /Font "
            + fonts_dict
            + b" >> >>"
        )
        page_obj = self._add_object(page_dict)
        self._page_object_numbers.append(page_obj)
        return page_obj

    def build(self) -> bytes:
        # Build catalog/pages objects now that we know all pages.
        kids = b" ".join(f"{n} 0 R".encode("ascii") for n in self._page_object_numbers)
        pages_obj = b"<< /Type /Pages /Kids [" + kids + b"] /Count " + str(len(self._page_object_numbers)).encode("ascii") + b" >>"
        catalog_obj = b"<< /Type /Catalog /Pages 2 0 R >>"

        objects: list[bytes] = []
        objects.append(b"1 0 obj\n" + catalog_obj + b"\nendobj\n")
        objects.append(b"2 0 obj\n" + pages_obj + b"\nendobj\n")

        # Append all stored objects (3..N) with their object numbers.
        for idx, obj_body in enumerate(self._objects, start=3):
            objects.append(f"{idx} 0 obj\n".encode("ascii") + obj_body + b"\nendobj\n")

        header = b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n"
        body = b"".join(objects)

        # Compute xref offsets.
        offsets: list[int] = [0]  # object 0
        cursor = len(header)
        for obj in objects:
            offsets.append(cursor)
            cursor += len(obj)

        xref_start = len(header) + len(body)
        xref_lines = [f"xref\n0 {len(offsets)}\n".encode("ascii"), b"0000000000 65535 f \n"]
        for off in offsets[1:]:
            xref_lines.append(f"{off:010d} 00000 n \n".encode("ascii"))

        trailer = (
            b"trailer\n<< /Size "
            + str(len(offsets)).encode("ascii")
            + b" /Root 1 0 R >>\nstartxref\n"
            + str(xref_start).encode("ascii")
            + b"\n%%EOF\n"
        )

        return header + body + b"".join(xref_lines) + trailer

    def _add_object(self, obj_body: bytes) -> int:
        self._objects.append(obj_body)
        # Objects start at 3 (because 1=Catalog, 2=Pages).
        return len(self._objects) + 2

    def _add_stream(self, stream_data: bytes) -> int:
        obj_body = (
            b"<< /Length "
            + str(len(stream_data)).encode("ascii")
            + b" >>\nstream\n"
            + stream_data
            + b"\nendstream"
        )
        return self._add_object(obj_body)

