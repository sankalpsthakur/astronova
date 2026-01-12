"""
Migration 003: Add Consultation Pooja Type

Adds a consultation entry to pooja_types so client can book consultations
through the existing booking endpoint.
"""

from __future__ import annotations

import sqlite3
from datetime import datetime

VERSION = 3
NAME = "add_consultation_pooja_type"


def up(conn: sqlite3.Connection) -> None:
    cur = conn.cursor()
    cur.execute("SELECT 1 FROM pooja_types WHERE id = ?", ("pooja_consultation",))
    if cur.fetchone():
        return

    now = datetime.utcnow().isoformat()
    cur.execute(
        """
        INSERT INTO pooja_types (
            id, name, description, deity, duration_minutes, base_price, icon_name,
            benefits, ingredients, mantras, is_active, sort_order, created_at, updated_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            "pooja_consultation",
            "Astrologer Consultation",
            "Personal guidance session with a verified pandit",
            "Astrologer",
            30,
            1200,
            "phone.fill",
            "[]",
            "[]",
            None,
            1,
            10,
            now,
            now,
        ),
    )
    conn.commit()


def down(conn: sqlite3.Connection) -> None:
    cur = conn.cursor()
    cur.execute("DELETE FROM pooja_types WHERE id = ?", ("pooja_consultation",))
    conn.commit()
