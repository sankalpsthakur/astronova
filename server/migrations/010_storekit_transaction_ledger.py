"""Migration 010: durable StoreKit transaction and Oracle credit ledgers."""

from __future__ import annotations

import sqlite3

VERSION = 10
NAME = "storekit_transaction_ledger"


def up(conn: sqlite3.Connection) -> None:
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS storekit_transaction_ledger (
            transaction_id TEXT PRIMARY KEY,
            original_transaction_id TEXT,
            user_id TEXT,
            product_id TEXT NOT NULL,
            purchase_kind TEXT NOT NULL,
            units INTEGER NOT NULL DEFAULT 0,
            environment TEXT,
            created_at TEXT NOT NULL,
            tombstoned_at TEXT
        )
    """)
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_storekit_transaction_ledger_user
        ON storekit_transaction_ledger(user_id, purchase_kind, created_at)
    """)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS oracle_credit_balances (
            user_id TEXT PRIMARY KEY,
            balance INTEGER NOT NULL DEFAULT 0 CHECK(balance >= 0),
            updated_at TEXT NOT NULL
        )
    """)

    # Preserve replay ownership for report transactions recorded before this
    # shared ledger existed.
    cur.execute("""
        INSERT OR IGNORE INTO storekit_transaction_ledger
            (transaction_id, original_transaction_id, user_id, product_id,
             purchase_kind, units, environment, created_at)
        SELECT transaction_id, original_transaction_id, user_id, product_id,
               'report', 1, environment, created_at
        FROM report_purchase_entitlements
    """)
    conn.commit()


def down(conn: sqlite3.Connection) -> None:
    cur = conn.cursor()
    cur.execute("DROP INDEX IF EXISTS idx_storekit_transaction_ledger_user")
    cur.execute("DROP TABLE IF EXISTS oracle_credit_balances")
    cur.execute("DROP TABLE IF EXISTS storekit_transaction_ledger")
    conn.commit()
