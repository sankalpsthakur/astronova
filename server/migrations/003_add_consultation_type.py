"""
Migration 003: Add Consultation Type to Pooja Types

Adds the 'pooja_consultation' type for astrology consultations.
"""

import sqlite3
import json
from datetime import datetime

VERSION = 3
NAME = "add_consultation_type"


def up(conn: sqlite3.Connection) -> None:
    """Add consultation pooja type."""
    cur = conn.cursor()

    # Check if consultation type already exists
    cur.execute("SELECT COUNT(*) FROM pooja_types WHERE id = 'pooja_consultation'")
    if cur.fetchone()[0] > 0:
        print("Consultation type already exists, skipping...")
        return

    now = datetime.utcnow().isoformat()

    consultation = {
        "id": "pooja_consultation",
        "name": "Astrology Consultation",
        "description": "One-on-one video consultation with expert Vedic astrologer",
        "deity": "Expert Guidance",
        "duration_minutes": 30,
        "base_price": 750,
        "icon_name": "video.fill",
        "benefits": json.dumps([
            "Personalized astrological guidance",
            "Birth chart analysis",
            "Life path insights",
            "Remedies and recommendations"
        ]),
        "ingredients": json.dumps([
            "Your birth details (date, time, place)",
            "Specific questions or topics to discuss"
        ]),
        "sort_order": 7,
    }

    cur.execute("""
        INSERT INTO pooja_types
        (id, name, description, deity, duration_minutes, base_price, icon_name,
         benefits, ingredients, is_active, sort_order, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?)
    """, (
        consultation["id"],
        consultation["name"],
        consultation["description"],
        consultation["deity"],
        consultation["duration_minutes"],
        consultation["base_price"],
        consultation["icon_name"],
        consultation["benefits"],
        consultation["ingredients"],
        consultation["sort_order"],
        now,
        now
    ))

    conn.commit()
    print(f"✅ Added consultation type: {consultation['name']}")


def down(conn: sqlite3.Connection) -> None:
    """Remove consultation pooja type."""
    cur = conn.cursor()
    cur.execute("DELETE FROM pooja_types WHERE id = 'pooja_consultation'")
    conn.commit()
    print("✅ Removed consultation type")
