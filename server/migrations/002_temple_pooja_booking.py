"""
Migration 002: Temple Pooja Booking

Adds tables for pandits, poojas, and booking system.
- pandits: Enrolled pandit priests with verification status
- pooja_types: Different types of poojas offered
- pooja_bookings: User bookings with scheduling
- pooja_sessions: Video call sessions for poojas

Created: 2025-01-07
"""

from __future__ import annotations

import sqlite3

VERSION = 2
NAME = "temple_pooja_booking"


def up(conn: sqlite3.Connection) -> None:
    """Create tables for Temple Pooja booking system."""
    cur = conn.cursor()

    # =========================================================================
    # Pandits (Enrolled Priests)
    # =========================================================================

    cur.execute("""
        CREATE TABLE IF NOT EXISTS pandits (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT,
            phone TEXT,
            specializations TEXT,
            languages TEXT,
            experience_years INTEGER DEFAULT 0,
            rating REAL DEFAULT 5.0,
            review_count INTEGER DEFAULT 0,
            price_per_session INTEGER DEFAULT 500,
            avatar_url TEXT,
            bio TEXT,
            is_verified INTEGER DEFAULT 0,
            is_available INTEGER DEFAULT 1,
            verification_date TEXT,
            created_at TEXT,
            updated_at TEXT
        )
    """)

    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_pandits_available
        ON pandits(is_available, is_verified)
    """)

    # =========================================================================
    # Pooja Types (Catalog)
    # =========================================================================

    cur.execute("""
        CREATE TABLE IF NOT EXISTS pooja_types (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            deity TEXT,
            duration_minutes INTEGER DEFAULT 45,
            base_price INTEGER DEFAULT 1100,
            icon_name TEXT DEFAULT 'sparkles',
            benefits TEXT,
            ingredients TEXT,
            mantras TEXT,
            is_active INTEGER DEFAULT 1,
            sort_order INTEGER DEFAULT 0,
            created_at TEXT,
            updated_at TEXT
        )
    """)

    # =========================================================================
    # Pooja Bookings
    # =========================================================================

    cur.execute("""
        CREATE TABLE IF NOT EXISTS pooja_bookings (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            pooja_type_id TEXT NOT NULL,
            pandit_id TEXT,
            scheduled_date TEXT NOT NULL,
            scheduled_time TEXT NOT NULL,
            timezone TEXT DEFAULT 'Asia/Kolkata',
            status TEXT DEFAULT 'pending',
            sankalp_name TEXT,
            sankalp_gotra TEXT,
            sankalp_nakshatra TEXT,
            special_requests TEXT,
            amount_paid INTEGER DEFAULT 0,
            payment_status TEXT DEFAULT 'pending',
            session_link TEXT,
            session_id TEXT,
            user_joined_at TEXT,
            pandit_joined_at TEXT,
            completed_at TEXT,
            rating INTEGER,
            review TEXT,
            created_at TEXT,
            updated_at TEXT,
            FOREIGN KEY (pooja_type_id) REFERENCES pooja_types(id),
            FOREIGN KEY (pandit_id) REFERENCES pandits(id)
        )
    """)

    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_pooja_bookings_user
        ON pooja_bookings(user_id, status)
    """)

    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_pooja_bookings_pandit
        ON pooja_bookings(pandit_id, scheduled_date)
    """)

    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_pooja_bookings_date
        ON pooja_bookings(scheduled_date, status)
    """)

    # =========================================================================
    # Pooja Sessions (Video Call Tracking)
    # =========================================================================

    cur.execute("""
        CREATE TABLE IF NOT EXISTS pooja_sessions (
            id TEXT PRIMARY KEY,
            booking_id TEXT NOT NULL,
            provider TEXT DEFAULT 'internal',
            external_session_id TEXT,
            user_link TEXT,
            pandit_link TEXT,
            started_at TEXT,
            ended_at TEXT,
            duration_seconds INTEGER,
            recording_url TEXT,
            status TEXT DEFAULT 'scheduled',
            created_at TEXT,
            FOREIGN KEY (booking_id) REFERENCES pooja_bookings(id)
        )
    """)

    # =========================================================================
    # Pandit Availability Slots
    # =========================================================================

    cur.execute("""
        CREATE TABLE IF NOT EXISTS pandit_availability (
            id TEXT PRIMARY KEY,
            pandit_id TEXT NOT NULL,
            day_of_week INTEGER,
            start_time TEXT,
            end_time TEXT,
            is_active INTEGER DEFAULT 1,
            FOREIGN KEY (pandit_id) REFERENCES pandits(id)
        )
    """)

    # =========================================================================
    # Contact Attempt Logs (for monitoring private contact sharing)
    # =========================================================================

    cur.execute("""
        CREATE TABLE IF NOT EXISTS contact_filter_logs (
            id TEXT PRIMARY KEY,
            context_type TEXT NOT NULL,
            context_id TEXT NOT NULL,
            sender_type TEXT NOT NULL,
            sender_id TEXT NOT NULL,
            original_message TEXT,
            filtered_message TEXT,
            patterns_matched TEXT,
            action_taken TEXT,
            created_at TEXT
        )
    """)

    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_contact_filter_context
        ON contact_filter_logs(context_type, context_id)
    """)

    # =========================================================================
    # Seed Default Pooja Types
    # =========================================================================

    _seed_pooja_types(cur)

    conn.commit()


def _seed_pooja_types(cur: sqlite3.Cursor) -> None:
    """Seed default pooja types if table is empty."""
    import json
    from datetime import datetime

    cur.execute("SELECT COUNT(*) FROM pooja_types")
    if cur.fetchone()[0] > 0:
        return

    now = datetime.utcnow().isoformat()

    poojas = [
        {
            "id": "pooja_ganesh",
            "name": "Ganesh Puja",
            "description": "Remove obstacles and invite new beginnings with Lord Ganesha's blessings",
            "deity": "Lord Ganesha",
            "duration_minutes": 45,
            "base_price": 1100,
            "icon_name": "sparkles",
            "benefits": json.dumps(["Remove obstacles", "New beginnings", "Success", "Wisdom"]),
            "ingredients": json.dumps([
                "Modak (5 pieces)", "Red flowers (21)", "Durva grass (21 blades)",
                "Coconut (1)", "Vermillion", "Incense sticks"
            ]),
            "sort_order": 1,
        },
        {
            "id": "pooja_lakshmi",
            "name": "Lakshmi Puja",
            "description": "Invoke prosperity and abundance with Goddess Lakshmi's grace",
            "deity": "Goddess Lakshmi",
            "duration_minutes": 60,
            "base_price": 1500,
            "icon_name": "indianrupeesign.circle.fill",
            "benefits": json.dumps(["Wealth", "Prosperity", "Good fortune", "Abundance"]),
            "ingredients": json.dumps([
                "Lotus flowers (11)", "Gold/Silver coins", "Rice (250g)",
                "Turmeric powder", "Kumkum", "Ghee lamp"
            ]),
            "sort_order": 2,
        },
        {
            "id": "pooja_navagraha",
            "name": "Navagraha Shanti",
            "description": "Achieve planetary harmony and cosmic balance",
            "deity": "Nine Planets",
            "duration_minutes": 90,
            "base_price": 2100,
            "icon_name": "moon.stars.fill",
            "benefits": json.dumps(["Planetary balance", "Reduce malefic effects", "Peace", "Harmony"]),
            "ingredients": json.dumps([
                "9 types of grains (100g each)", "9 colored cloths",
                "9 types of flowers (11 each)", "Sesame oil", "Camphor", "Sandalwood paste"
            ]),
            "sort_order": 3,
        },
        {
            "id": "pooja_satyanarayan",
            "name": "Satyanarayan Katha",
            "description": "Fulfill wishes and seek divine blessings from Lord Vishnu",
            "deity": "Lord Vishnu",
            "duration_minutes": 120,
            "base_price": 2500,
            "icon_name": "sun.max.fill",
            "benefits": json.dumps(["Wish fulfillment", "Prosperity", "Peace", "Divine blessings"]),
            "ingredients": json.dumps([
                "Banana (2 dozens)", "Wheat flour (500g)", "Sugar (500g)",
                "Tulsi leaves (21)", "Panchamrit", "Mango leaves"
            ]),
            "sort_order": 4,
        },
        {
            "id": "pooja_rudrabhishek",
            "name": "Rudrabhishek",
            "description": "Powerful Shiva puja for protection and transformation",
            "deity": "Lord Shiva",
            "duration_minutes": 90,
            "base_price": 2100,
            "icon_name": "drop.fill",
            "benefits": json.dumps(["Protection", "Transformation", "Spiritual growth", "Peace of mind"]),
            "ingredients": json.dumps([
                "Milk (1L)", "Honey", "Ghee", "Curd", "Bilva leaves (108)",
                "Sandalwood paste", "Sacred ash"
            ]),
            "sort_order": 5,
        },
        {
            "id": "pooja_sundarkand",
            "name": "Sundarkand Path",
            "description": "Recitation from Ramayana for courage and protection",
            "deity": "Lord Hanuman",
            "duration_minutes": 150,
            "base_price": 1800,
            "icon_name": "book.fill",
            "benefits": json.dumps(["Courage", "Protection", "Overcome difficulties", "Family harmony"]),
            "ingredients": json.dumps([
                "Red cloth", "Sindoor", "Jasmine oil", "Betel leaves",
                "Fruits", "Prasad items"
            ]),
            "sort_order": 6,
        },
    ]

    for pooja in poojas:
        cur.execute("""
            INSERT INTO pooja_types
            (id, name, description, deity, duration_minutes, base_price, icon_name,
             benefits, ingredients, is_active, sort_order, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?)
        """, (
            pooja["id"], pooja["name"], pooja["description"], pooja["deity"],
            pooja["duration_minutes"], pooja["base_price"], pooja["icon_name"],
            pooja["benefits"], pooja["ingredients"], pooja["sort_order"], now, now
        ))


def down(conn: sqlite3.Connection) -> None:
    """Rollback migration (drop tables)."""
    cur = conn.cursor()

    tables = [
        "contact_filter_logs",
        "pandit_availability",
        "pooja_sessions",
        "pooja_bookings",
        "pooja_types",
        "pandits",
    ]

    for table in tables:
        cur.execute(f"DROP TABLE IF EXISTS {table}")

    conn.commit()
