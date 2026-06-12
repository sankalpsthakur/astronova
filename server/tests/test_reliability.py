"""Reliability tests: stuck-report recovery and bounded report generation."""

from __future__ import annotations

import json
from datetime import datetime, timedelta

import db as db_module


def test_fail_stuck_reports_marks_old_processing_as_failed(clean_db, sample_user):
    # A report stuck 'processing' from 30 minutes ago (older than the 15m cutoff).
    old = (datetime.utcnow() - timedelta(minutes=30)).isoformat()
    conn = db_module.get_connection()
    conn.execute(
        "INSERT INTO reports (report_id, user_id, type, title, content, generated_at, status) VALUES (?,?,?,?,?,?,?)",
        ("stuck-1", sample_user["id"], "birth_chart", "Pending", "{}", old, "processing"),
    )
    # A fresh one (1 minute ago) must NOT be touched.
    recent = (datetime.utcnow() - timedelta(minutes=1)).isoformat()
    conn.execute(
        "INSERT INTO reports (report_id, user_id, type, title, content, generated_at, status) VALUES (?,?,?,?,?,?,?)",
        ("fresh-1", sample_user["id"], "birth_chart", "Pending", "{}", recent, "processing"),
    )
    conn.commit()
    conn.close()

    updated = db_module.fail_stuck_reports(older_than_minutes=15)
    assert updated == 1

    stuck = db_module.get_report("stuck-1")
    assert stuck["status"] == "failed"
    # The stored content must be a generic message, never a raw exception/stack.
    payload = json.loads(stuck["content"])
    assert payload["code"] == "REPORT_GENERATION_INTERRUPTED"

    fresh = db_module.get_report("fresh-1")
    assert fresh["status"] == "processing"


def test_completed_reports_are_not_affected(clean_db, sample_user):
    old = (datetime.utcnow() - timedelta(hours=2)).isoformat()
    conn = db_module.get_connection()
    conn.execute(
        "INSERT INTO reports (report_id, user_id, type, title, content, generated_at, status) VALUES (?,?,?,?,?,?,?)",
        ("done-1", sample_user["id"], "birth_chart", "Done", "{}", old, "completed"),
    )
    conn.commit()
    conn.close()

    db_module.fail_stuck_reports(older_than_minutes=15)
    assert db_module.get_report("done-1")["status"] == "completed"


def test_upsert_user_is_atomic_and_idempotent(clean_db):
    db_module.upsert_user("upsert-user-1", "a@example.com", "A", "One", "A One")
    db_module.upsert_user("upsert-user-1", "b@example.com", "B", "Two", "B Two")

    conn = db_module.get_connection()
    rows = conn.execute(
        "SELECT email, full_name FROM users WHERE id=?", ("upsert-user-1",)
    ).fetchall()
    conn.close()

    assert len(rows) == 1
    assert rows[0]["email"] == "b@example.com"
    assert rows[0]["full_name"] == "B Two"


def test_oversized_request_body_is_rejected_with_413(client):
    # Bodies past MAX_CONTENT_LENGTH must be refused, not buffered into memory.
    huge = "x" * (2 * 1024 * 1024)
    response = client.post(
        "/api/v1/auth/apple",
        json={"idToken": huge},
    )
    assert response.status_code == 413
