"""
Migration 009: Server-authoritative payment verification

Extends subscription_status with the fields needed to make the *server* the
source of truth for App Store entitlements (verified via StoreKit2 signed
transactions and App Store Server Notifications), and adds the supporting
tables for transaction idempotency and a server-side chat-credit balance.

Before this migration, subscription_status could only be written by admin/test
endpoints, and chat credits lived only in the client's UserDefaults (spoofable
and lost on reinstall). These tables let purchases be recorded from a verified
Apple receipt and let credits be tracked and consumed on the server.
"""

from __future__ import annotations

import sqlite3

VERSION = 9
NAME = "payments_verification"


def _column_names(cur: sqlite3.Cursor, table: str) -> set[str]:
    cur.execute(f"PRAGMA table_info({table})")
    return {row[1] for row in cur.fetchall()}


def up(conn: sqlite3.Connection) -> None:
    cur = conn.cursor()

    # Extend subscription_status with App Store transaction metadata so we can
    # track expiry, renewals and revocations rather than just a boolean.
    existing = _column_names(cur, "subscription_status")
    new_columns = {
        "expires_at": "TEXT",
        "original_transaction_id": "TEXT",
        "latest_transaction_id": "TEXT",
        "environment": "TEXT",
        "auto_renew": "INTEGER DEFAULT 0",
    }
    for name, decl in new_columns.items():
        if name not in existing:
            cur.execute(f"ALTER TABLE subscription_status ADD COLUMN {name} {decl}")

    # Idempotency ledger: every verified App Store transaction is recorded once
    # so replays (re-sent receipts, redelivered notifications) are no-ops.
    cur.execute("""
        CREATE TABLE IF NOT EXISTS processed_transactions (
            transaction_id TEXT PRIMARY KEY,
            user_id TEXT,
            product_id TEXT,
            type TEXT,
            environment TEXT,
            processed_at TEXT NOT NULL
        )
    """)
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_processed_transactions_user
        ON processed_transactions(user_id)
    """)

    # Server-side chat-credit balance plus an append-only ledger for audit.
    cur.execute("""
        CREATE TABLE IF NOT EXISTS user_credits (
            user_id TEXT PRIMARY KEY,
            balance INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT
        )
    """)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS credit_ledger (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            delta INTEGER NOT NULL,
            reason TEXT,
            transaction_id TEXT,
            created_at TEXT NOT NULL
        )
    """)
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_credit_ledger_user
        ON credit_ledger(user_id)
    """)

    conn.commit()


def down(conn: sqlite3.Connection) -> None:
    cur = conn.cursor()
    cur.execute("DROP TABLE IF EXISTS credit_ledger")
    cur.execute("DROP TABLE IF EXISTS user_credits")
    cur.execute("DROP TABLE IF EXISTS processed_transactions")
    # Column drops are intentionally omitted: SQLite predating 3.35 cannot drop
    # columns, and leaving the extra subscription_status columns is harmless.
    conn.commit()
