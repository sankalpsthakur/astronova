"""
Migration 007: Single Shastriji Practitioner

Converts the Temple consultation flow to a single practitioner model without
breaking existing booking/session data.
"""

from __future__ import annotations

import sqlite3

VERSION = 7
NAME = "single_shastriji"

SHASTRIJI_ID = "shastriji-001"
SLOT_DURATION_MINUTES = 30


def _is_active_booking_clause() -> str:
    return """
        pandit_id = ?
        AND status NOT IN ('cancelled', 'completed')
        AND COALESCE(call_state, 'idle') NOT IN ('ended', 'missed')
    """


def _ensure_queue_columns(cur: sqlite3.Cursor) -> None:
    for col_sql in [
        "ALTER TABLE pooja_bookings ADD COLUMN queue_position INTEGER DEFAULT 0",
        "ALTER TABLE pooja_bookings ADD COLUMN estimated_wait_minutes INTEGER DEFAULT 0",
        "ALTER TABLE pooja_bookings ADD COLUMN call_state TEXT DEFAULT 'idle'",
    ]:
        try:
            cur.execute(col_sql)
        except sqlite3.OperationalError:
            pass


def _upsert_shastriji(cur: sqlite3.Cursor) -> None:
    cur.execute(
        """
        INSERT OR IGNORE INTO pandits (
            id, name, email, phone, specializations, languages,
            experience_years, rating, review_count, price_per_session,
            avatar_url, bio, is_verified, is_available
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            SHASTRIJI_ID,
            "Shastriji",
            "shastriji@shastriji.app",
            "+91-0000000000",
            '["Vedic Astrology", "Kundli Analysis", "Muhurat", "Remedies", "Dasha Interpretation"]',
            '["Hindi", "English", "Sanskrit"]',
            25,
            4.9,
            1247,
            0,
            None,
            "Senior Vedic astrologer with 25 years of experience in Jyotish Shastra. Specializes in birth chart analysis, dasha interpretation, and personalized remedies.",
            1,
            1,
        ),
    )

    cur.execute(
        """
        UPDATE pandits
        SET name = ?,
            email = ?,
            phone = ?,
            specializations = ?,
            languages = ?,
            experience_years = ?,
            rating = ?,
            review_count = ?,
            price_per_session = ?,
            avatar_url = ?,
            bio = ?,
            is_verified = ?,
            is_available = ?
        WHERE id = ?
        """,
        (
            "Shastriji",
            "shastriji@shastriji.app",
            "+91-0000000000",
            '["Vedic Astrology", "Kundli Analysis", "Muhurat", "Remedies", "Dasha Interpretation"]',
            '["Hindi", "English", "Sanskrit"]',
            25,
            4.9,
            1247,
            0,
            None,
            "Senior Vedic astrologer with 25 years of experience in Jyotish Shastra. Specializes in birth chart analysis, dasha interpretation, and personalized remedies.",
            1,
            1,
            SHASTRIJI_ID,
        ),
    )


def _backfill_bookings(cur: sqlite3.Cursor) -> None:
    cur.execute(
        """
        UPDATE pooja_bookings
        SET pandit_id = ?
        WHERE pandit_id IS NULL OR pandit_id != ?
        """,
        (SHASTRIJI_ID, SHASTRIJI_ID),
    )

    cur.execute(
        """
        UPDATE pooja_bookings
        SET status = CASE
                WHEN status IN ('pending', 'assigned') THEN 'queued'
                ELSE status
            END,
            call_state = CASE
            WHEN status IN ('completed', 'cancelled') OR completed_at IS NOT NULL THEN 'ended'
            WHEN COALESCE(pandit_joined_at, user_joined_at) IS NOT NULL THEN 'connected'
            WHEN LOWER(COALESCE(call_state, '')) IN ('ringing', 'connected', 'ended', 'missed', 'requeued')
                THEN LOWER(call_state)
            WHEN session_link IS NOT NULL OR session_id IS NOT NULL OR status = 'confirmed' THEN 'queued'
            WHEN status IN ('queued', 'pending', 'assigned') THEN 'queued'
            ELSE COALESCE(call_state, 'idle')
        END
        WHERE pandit_id = ?
        """,
        (SHASTRIJI_ID,),
    )

    cur.execute(
        """
        UPDATE pooja_bookings
        SET queue_position = 0,
            estimated_wait_minutes = 0
        WHERE pandit_id = ?
        """,
        (SHASTRIJI_ID,),
    )

    cur.execute(
        """
        SELECT id
        FROM pooja_bookings
        WHERE """ + _is_active_booking_clause() + """
        ORDER BY scheduled_date ASC, scheduled_time ASC, created_at ASC, id ASC
        """,
        (SHASTRIJI_ID,),
    )
    active_booking_ids = [row[0] for row in cur.fetchall()]

    for index, booking_id in enumerate(active_booking_ids, start=1):
        cur.execute(
            """
            UPDATE pooja_bookings
            SET queue_position = ?,
                estimated_wait_minutes = ?
            WHERE id = ?
            """,
            (index, (index - 1) * SLOT_DURATION_MINUTES, booking_id),
        )


def _remove_extra_pandits(cur: sqlite3.Cursor) -> None:
    cur.execute("DELETE FROM pandits WHERE id != ?", (SHASTRIJI_ID,))


def up(conn: sqlite3.Connection) -> None:
    cur = conn.cursor()
    _ensure_queue_columns(cur)
    _upsert_shastriji(cur)
    _backfill_bookings(cur)
    _remove_extra_pandits(cur)
    conn.commit()


def down(conn: sqlite3.Connection) -> None:
    raise sqlite3.OperationalError(
        "Migration 007 is irreversible without a historical pandit backup."
    )
