"""
Migration 008: Report list index

Adds a composite index for the production report-library query:
recent reports for one authenticated user.
"""

from __future__ import annotations

import sqlite3

VERSION = 8
NAME = "report_list_index"


def up(conn: sqlite3.Connection) -> None:
    cur = conn.cursor()
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_reports_user_generated_at
        ON reports(user_id, generated_at DESC)
    """)
    conn.commit()


def down(conn: sqlite3.Connection) -> None:
    cur = conn.cursor()
    cur.execute("DROP INDEX IF EXISTS idx_reports_user_generated_at")
    conn.commit()
