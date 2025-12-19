"""
Migration 001: Initial schema baseline

This migration captures the existing Astronova database schema as the baseline.
For existing databases, tables already exist so we use CREATE TABLE IF NOT EXISTS.
For new databases, this creates all required tables.

Created: 2024-12-19
"""

from __future__ import annotations

import sqlite3

VERSION = 1
NAME = "initial_schema"


def up(conn: sqlite3.Connection) -> None:
    """Create all baseline tables and indexes."""
    cur = conn.cursor()

    # Enable WAL mode for better concurrency
    cur.execute("PRAGMA journal_mode=WAL")

    # =========================================================================
    # Core Tables
    # =========================================================================

    # Users table (Apple Sign-In accounts)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            email TEXT,
            first_name TEXT,
            last_name TEXT,
            full_name TEXT,
            created_at TEXT,
            updated_at TEXT
        )
    """)

    # User birth data for personalized astrology
    cur.execute("""
        CREATE TABLE IF NOT EXISTS user_birth_data (
            user_id TEXT PRIMARY KEY,
            birth_date TEXT,
            birth_time TEXT,
            timezone TEXT,
            latitude REAL,
            longitude REAL,
            location_name TEXT,
            created_at TEXT,
            updated_at TEXT
        )
    """)

    # =========================================================================
    # Reports
    # =========================================================================

    cur.execute("""
        CREATE TABLE IF NOT EXISTS reports (
            report_id TEXT PRIMARY KEY,
            user_id TEXT,
            type TEXT,
            title TEXT,
            content TEXT,
            generated_at TEXT,
            status TEXT
        )
    """)

    # Indexes for reports
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_reports_user_id
        ON reports(user_id)
    """)
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_reports_generated_at
        ON reports(generated_at DESC)
    """)

    # =========================================================================
    # Relationships (Compatibility Feature)
    # =========================================================================

    cur.execute("""
        CREATE TABLE IF NOT EXISTS relationships (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            partner_name TEXT NOT NULL,
            partner_birth_date TEXT NOT NULL,
            partner_birth_time TEXT,
            partner_timezone TEXT,
            partner_latitude REAL,
            partner_longitude REAL,
            partner_location_name TEXT,
            partner_avatar_url TEXT,
            is_favorite INTEGER DEFAULT 0,
            last_viewed_at TEXT,
            created_at TEXT,
            updated_at TEXT
        )
    """)

    # =========================================================================
    # Subscriptions
    # =========================================================================

    cur.execute("""
        CREATE TABLE IF NOT EXISTS subscription_status (
            user_id TEXT PRIMARY KEY,
            is_active INTEGER DEFAULT 0,
            product_id TEXT,
            updated_at TEXT
        )
    """)

    # =========================================================================
    # Chat (Oracle Feature)
    # =========================================================================

    cur.execute("""
        CREATE TABLE IF NOT EXISTS chat_conversations (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            created_at TEXT,
            updated_at TEXT
        )
    """)

    cur.execute("""
        CREATE TABLE IF NOT EXISTS chat_messages (
            id TEXT PRIMARY KEY,
            conversation_id TEXT,
            user_id TEXT,
            role TEXT,
            content TEXT,
            created_at TEXT
        )
    """)

    # Indexes for chat
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_chat_conversations_user_id
        ON chat_conversations(user_id)
    """)
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_chat_conversations_updated_at
        ON chat_conversations(updated_at DESC)
    """)
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation_id
        ON chat_messages(conversation_id)
    """)
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at
        ON chat_messages(created_at DESC)
    """)

    # =========================================================================
    # Content Management
    # =========================================================================

    cur.execute("""
        CREATE TABLE IF NOT EXISTS content_quick_questions (
            id TEXT PRIMARY KEY,
            text TEXT NOT NULL,
            category TEXT,
            order_index INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1
        )
    """)

    cur.execute("""
        CREATE TABLE IF NOT EXISTS content_insights (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            category TEXT,
            priority INTEGER DEFAULT 0,
            is_active INTEGER DEFAULT 1
        )
    """)

    # Indexes for content
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_content_quick_questions_active
        ON content_quick_questions(is_active, order_index)
    """)
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_content_insights_active
        ON content_insights(is_active, priority)
    """)

    conn.commit()


def down(conn: sqlite3.Connection) -> None:
    """
    Rollback migration (drop all tables).

    WARNING: This will delete all data! Only use in development.
    """
    cur = conn.cursor()

    # Drop tables in reverse dependency order
    tables = [
        "content_insights",
        "content_quick_questions",
        "chat_messages",
        "chat_conversations",
        "subscription_status",
        "relationships",
        "reports",
        "user_birth_data",
        "users",
    ]

    for table in tables:
        cur.execute(f"DROP TABLE IF EXISTS {table}")

    conn.commit()
