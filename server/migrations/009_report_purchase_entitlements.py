"""
Migration 009: Report purchase entitlements

Tracks individual non-consumable report purchases separately from Pro
subscriptions so a single report purchase can unlock exactly one matching
server-side report generation.
"""

from __future__ import annotations

import sqlite3

VERSION = 9
NAME = "report_purchase_entitlements"


def up(conn: sqlite3.Connection) -> None:
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS report_purchase_entitlements (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            product_id TEXT NOT NULL,
            report_type TEXT NOT NULL,
            transaction_id TEXT NOT NULL UNIQUE,
            original_transaction_id TEXT,
            environment TEXT,
            consumed_report_id TEXT,
            created_at TEXT NOT NULL,
            consumed_at TEXT
        )
    """)
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_report_purchase_entitlements_user_type
        ON report_purchase_entitlements(user_id, report_type, consumed_at)
    """)
    conn.commit()


def down(conn: sqlite3.Connection) -> None:
    cur = conn.cursor()
    cur.execute("DROP INDEX IF EXISTS idx_report_purchase_entitlements_user_type")
    cur.execute("DROP TABLE IF EXISTS report_purchase_entitlements")
    conn.commit()
