"""
Migration 004: Backfill session URLs with correct production domain

This migration updates all session_link URLs in pooja_bookings and pooja_sessions
from the old placeholder domain (astronova.app) to the correct production domain
(astronova.onrender.com).

Background:
- The temple.py code previously hardcoded 'https://astronova.app' URLs
- This was fixed to use environment-aware URL generation
- Existing bookings in the database still have the old broken URLs
"""

import sqlite3

VERSION = 4
NAME = "backfill_session_urls"


def up(conn: sqlite3.Connection) -> None:
    """
    Update all session_link URLs from astronova.app to astronova.onrender.com
    """
    cur = conn.cursor()

    # Update pooja_bookings table
    cur.execute("""
        UPDATE pooja_bookings
        SET session_link = REPLACE(session_link,
            'https://astronova.app',
            'https://astronova.onrender.com')
        WHERE session_link LIKE 'https://astronova.app%'
    """)
    bookings_updated = cur.rowcount

    # Update pooja_sessions table (user_link and pandit_link)
    cur.execute("""
        UPDATE pooja_sessions
        SET user_link = REPLACE(user_link,
            'https://astronova.app',
            'https://astronova.onrender.com')
        WHERE user_link LIKE 'https://astronova.app%'
    """)
    user_links_updated = cur.rowcount

    cur.execute("""
        UPDATE pooja_sessions
        SET pandit_link = REPLACE(pandit_link,
            'https://astronova.app',
            'https://astronova.onrender.com')
        WHERE pandit_link LIKE 'https://astronova.app%'
    """)
    pandit_links_updated = cur.rowcount

    conn.commit()

    # Log results
    print(f"[Migration 004] Backfilled session URLs:")
    print(f"  - {bookings_updated} booking session_link(s) updated")
    print(f"  - {user_links_updated} user_link(s) updated")
    print(f"  - {pandit_links_updated} pandit_link(s) updated")


def down(conn: sqlite3.Connection) -> None:
    """
    Rollback: Revert URLs back to astronova.app (not recommended)
    """
    cur = conn.cursor()

    # Revert pooja_bookings
    cur.execute("""
        UPDATE pooja_bookings
        SET session_link = REPLACE(session_link,
            'https://astronova.onrender.com',
            'https://astronova.app')
        WHERE session_link LIKE 'https://astronova.onrender.com%'
    """)

    # Revert pooja_sessions
    cur.execute("""
        UPDATE pooja_sessions
        SET user_link = REPLACE(user_link,
            'https://astronova.onrender.com',
            'https://astronova.app')
        WHERE user_link LIKE 'https://astronova.onrender.com%'
    """)

    cur.execute("""
        UPDATE pooja_sessions
        SET pandit_link = REPLACE(pandit_link,
            'https://astronova.onrender.com',
            'https://astronova.app')
        WHERE pandit_link LIKE 'https://astronova.onrender.com%'
    """)

    conn.commit()
