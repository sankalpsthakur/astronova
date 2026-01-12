"""
Migration 005: Add preferred_language to users
"""

import sqlite3

VERSION = 5
NAME = "add_user_preferred_language"


def up(conn: sqlite3.Connection) -> None:
    cur = conn.cursor()
    cur.execute("PRAGMA table_info(users)")
    columns = [row[1] for row in cur.fetchall()]
    if "preferred_language" in columns:
        return

    cur.execute("ALTER TABLE users ADD COLUMN preferred_language TEXT DEFAULT 'en'")
    conn.commit()


def down(conn: sqlite3.Connection) -> None:
    # SQLite doesn't support DROP COLUMN without table rebuild.
    pass
