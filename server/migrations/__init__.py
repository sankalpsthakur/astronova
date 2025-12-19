"""
Lightweight database migration framework for Astronova.

This module provides a simple, Python-native migration system that:
- Tracks schema versions in a `schema_migrations` table
- Discovers and runs migration files in order
- Supports idempotent migrations for existing databases
- Logs migration progress and errors

Usage:
    from migrations import run_migrations
    run_migrations()  # Called automatically at app startup
"""

from __future__ import annotations

import importlib.util
import logging
import os
import re
import sqlite3
from datetime import datetime
from pathlib import Path
from typing import Callable, Optional

logger = logging.getLogger(__name__)

# Migration file pattern: NNN_name.py (e.g., 001_initial_schema.py)
MIGRATION_PATTERN = re.compile(r"^(\d{3})_(.+)\.py$")


class MigrationError(Exception):
    """Raised when a migration fails."""

    pass


class Migration:
    """Represents a single migration."""

    def __init__(
        self,
        version: int,
        name: str,
        up_fn: Callable[[sqlite3.Connection], None],
        down_fn: Optional[Callable[[sqlite3.Connection], None]] = None,
    ):
        self.version = version
        self.name = name
        self.up_fn = up_fn
        self.down_fn = down_fn

    def __repr__(self) -> str:
        return f"Migration({self.version:03d}_{self.name})"


def _ensure_migrations_table(conn: sqlite3.Connection) -> None:
    """Create the schema_migrations table if it doesn't exist."""
    conn.execute("""
        CREATE TABLE IF NOT EXISTS schema_migrations (
            version INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            applied_at TEXT NOT NULL
        )
    """)
    conn.commit()


def _get_applied_versions(conn: sqlite3.Connection) -> set[int]:
    """Get set of already-applied migration versions."""
    cur = conn.execute("SELECT version FROM schema_migrations ORDER BY version")
    return {row[0] for row in cur.fetchall()}


def _record_migration(conn: sqlite3.Connection, version: int, name: str) -> None:
    """Record a successfully applied migration."""
    now = datetime.utcnow().isoformat()
    conn.execute(
        "INSERT INTO schema_migrations (version, name, applied_at) VALUES (?, ?, ?)",
        (version, name, now),
    )
    conn.commit()


def _discover_migrations(migrations_dir: Path) -> list[Migration]:
    """
    Discover all migration files in the migrations directory.

    Migration files must:
    - Match pattern NNN_name.py (e.g., 001_initial_schema.py)
    - Define VERSION (int) and NAME (str) constants
    - Define an up(conn) function
    - Optionally define a down(conn) function
    """
    migrations = []

    if not migrations_dir.exists():
        logger.warning(f"Migrations directory not found: {migrations_dir}")
        return migrations

    for filename in sorted(os.listdir(migrations_dir)):
        match = MIGRATION_PATTERN.match(filename)
        if not match:
            continue

        file_version = int(match.group(1))
        file_path = migrations_dir / filename

        try:
            # Import the migration module
            spec = importlib.util.spec_from_file_location(
                f"migration_{file_version}", file_path
            )
            if spec is None or spec.loader is None:
                logger.warning(f"Could not load migration: {filename}")
                continue

            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)

            # Validate required attributes
            if not hasattr(module, "VERSION"):
                logger.warning(f"Migration {filename} missing VERSION constant")
                continue
            if not hasattr(module, "NAME"):
                logger.warning(f"Migration {filename} missing NAME constant")
                continue
            if not hasattr(module, "up"):
                logger.warning(f"Migration {filename} missing up() function")
                continue

            # Verify VERSION matches filename
            if module.VERSION != file_version:
                logger.warning(
                    f"Migration {filename} VERSION ({module.VERSION}) "
                    f"doesn't match filename ({file_version})"
                )
                continue

            migration = Migration(
                version=module.VERSION,
                name=module.NAME,
                up_fn=module.up,
                down_fn=getattr(module, "down", None),
            )
            migrations.append(migration)

        except Exception as e:
            logger.error(f"Failed to load migration {filename}: {e}")
            continue

    return sorted(migrations, key=lambda m: m.version)


def run_migrations(conn: sqlite3.Connection, migrations_dir: Optional[Path] = None) -> int:
    """
    Run all pending migrations.

    Args:
        conn: SQLite database connection
        migrations_dir: Path to migrations directory (default: ./migrations)

    Returns:
        Number of migrations applied

    Raises:
        MigrationError: If a migration fails
    """
    if migrations_dir is None:
        migrations_dir = Path(__file__).parent

    # Ensure migrations table exists
    _ensure_migrations_table(conn)

    # Get already applied versions
    applied = _get_applied_versions(conn)
    logger.info(f"Schema at version {max(applied) if applied else 0}")

    # Discover all migrations
    all_migrations = _discover_migrations(migrations_dir)
    if not all_migrations:
        logger.info("No migrations found")
        return 0

    # Filter to pending migrations
    pending = [m for m in all_migrations if m.version not in applied]
    if not pending:
        logger.info("No pending migrations")
        return 0

    logger.info(f"Found {len(pending)} pending migration(s)")

    # Apply each migration in order
    applied_count = 0
    for migration in pending:
        logger.info(f"Applying migration {migration.version:03d}_{migration.name}...")

        try:
            # Run the migration
            migration.up_fn(conn)

            # Record success
            _record_migration(conn, migration.version, migration.name)
            applied_count += 1

            logger.info(f"Migration {migration.version:03d}_{migration.name} applied successfully")

        except Exception as e:
            # Rollback any uncommitted changes
            conn.rollback()
            error_msg = f"Migration {migration.version:03d}_{migration.name} failed: {e}"
            logger.error(error_msg)
            raise MigrationError(error_msg) from e

    logger.info(f"Applied {applied_count} migration(s)")
    return applied_count


def get_current_version(conn: sqlite3.Connection) -> int:
    """Get the current schema version."""
    _ensure_migrations_table(conn)
    cur = conn.execute("SELECT MAX(version) FROM schema_migrations")
    row = cur.fetchone()
    return row[0] if row and row[0] else 0


def get_migration_history(conn: sqlite3.Connection) -> list[dict]:
    """Get the migration history."""
    _ensure_migrations_table(conn)
    cur = conn.execute(
        "SELECT version, name, applied_at FROM schema_migrations ORDER BY version"
    )
    return [
        {"version": row[0], "name": row[1], "applied_at": row[2]}
        for row in cur.fetchall()
    ]
