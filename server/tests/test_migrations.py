"""Tests for the lightweight migration framework's concurrency hardening.

Covers the concurrent-boot race: two instances starting at once may both apply
and try to record the same migration version. The ``version`` PRIMARY KEY makes
the loser's INSERT raise ``sqlite3.IntegrityError``; ``_record_migration`` must
tolerate that (migrations are idempotent) rather than crash the boot.
"""

from __future__ import annotations

import sqlite3

import pytest

import migrations


def _recorded_versions(conn: sqlite3.Connection) -> list[int]:
    cur = conn.execute("SELECT version FROM schema_migrations ORDER BY version")
    return [row[0] for row in cur.fetchall()]


def test_record_migration_tolerates_duplicate_version(db):
    """Recording the same version twice must not raise (concurrent-boot race)."""
    migrations._ensure_migrations_table(db)

    version = 99001
    name = "concurrent_boot_probe"

    # First record succeeds.
    migrations._record_migration(db, version, name)
    assert version in _recorded_versions(db)

    before = _recorded_versions(db)

    # Second record of the same version simulates the worker that lost the race.
    # It must be tolerated (no IntegrityError surfaced) and must not duplicate
    # or corrupt the recorded set.
    migrations._record_migration(db, version, name)

    after = _recorded_versions(db)
    assert after == before, "duplicate record must not add or drop versions"
    assert after.count(version) == 1, "version must appear exactly once"


def test_record_migration_duplicate_does_not_poison_connection(db):
    """After a tolerated duplicate, the connection must remain usable.

    A surfaced IntegrityError that wasn't rolled back would leave the SQLite
    connection in an aborted-transaction state and break the next write.
    """
    migrations._ensure_migrations_table(db)

    migrations._record_migration(db, 99002, "first")
    migrations._record_migration(db, 99002, "first")  # tolerated duplicate

    # A subsequent distinct record must still commit cleanly.
    migrations._record_migration(db, 99003, "second")

    versions = _recorded_versions(db)
    assert 99002 in versions
    assert 99003 in versions
