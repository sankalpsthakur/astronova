"""
Focused integration coverage for the Shastriji single-practitioner flow.
"""

from __future__ import annotations

import importlib.util
import json
import sqlite3
import uuid
from datetime import datetime
from pathlib import Path

import pytest

from migrations import _discover_migrations, _ensure_migrations_table, _record_migration
from routes.auth import generate_jwt


SERVER_ROOT = Path(__file__).resolve().parents[1]
MIGRATIONS_DIR = SERVER_ROOT / "migrations"
SHASTRIJI_ID = "shastriji-001"


def auth_headers(user_id: str) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {generate_jwt(user_id)}",
        "Content-Type": "application/json",
    }


def migration_007_module():
    migration_path = MIGRATIONS_DIR / "007_single_shastriji.py"
    spec = importlib.util.spec_from_file_location("migration_007_single_shastriji", migration_path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def initialize_schema_through_v6(conn: sqlite3.Connection) -> None:
    _ensure_migrations_table(conn)
    migrations = [migration for migration in _discover_migrations(MIGRATIONS_DIR) if migration.version < 7]
    for migration in migrations:
        migration.up_fn(conn)
        _record_migration(conn, migration.version, migration.name)


def first_active_pooja_type(conn: sqlite3.Connection) -> str:
    cur = conn.cursor()
    cur.execute("SELECT id FROM pooja_types WHERE is_active = 1 ORDER BY sort_order ASC, id ASC LIMIT 1")
    row = cur.fetchone()
    assert row is not None
    return row["id"]


def create_booking(client, user_id: str, payload: dict | None = None):
    return client.post(
        "/api/v1/temple/shastriji/book",
        headers=auth_headers(user_id),
        data=json.dumps(payload or {}),
    )


def fetch_booking(conn: sqlite3.Connection, booking_id: str):
    cur = conn.cursor()
    cur.execute(
        """
        SELECT id, pandit_id, status, call_state, queue_position, estimated_wait_minutes,
               scheduled_date, scheduled_time, completed_at, session_link, session_id
        FROM pooja_bookings
        WHERE id = ?
        """,
        (booking_id,),
    )
    return cur.fetchone()


@pytest.mark.integration
class TestShastrijiMigration:
    def test_migration_preserves_existing_bookings_sessions_and_foreign_keys(self, tmp_path):
        db_path = tmp_path / "pre_007.sqlite3"
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON")

        try:
            initialize_schema_through_v6(conn)
            pooja_type_id = first_active_pooja_type(conn)
            cur = conn.cursor()
            now = "2026-03-15T10:00:00"

            cur.execute(
                """
                INSERT INTO pandits (
                    id, name, email, phone, specializations, languages,
                    experience_years, rating, review_count, price_per_session,
                    avatar_url, bio, is_verified, is_available
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    "legacy-pandit-001",
                    "Legacy Pandit",
                    "legacy@example.com",
                    "+91-1111111111",
                    json.dumps(["Legacy Consultation"]),
                    json.dumps(["Hindi"]),
                    12,
                    4.3,
                    18,
                    900,
                    None,
                    "Legacy practitioner",
                    1,
                    1,
                ),
            )

            booking_id = str(uuid.uuid4())
            cur.execute(
                """
                INSERT INTO pooja_bookings (
                    id, user_id, pooja_type_id, pandit_id, scheduled_date, scheduled_time,
                    timezone, status, amount_paid, payment_status, session_link, session_id,
                    created_at, updated_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    booking_id,
                    "legacy-user",
                    pooja_type_id,
                    "legacy-pandit-001",
                    "2026-03-16",
                    "09:00",
                    "Asia/Kolkata",
                    "assigned",
                    0,
                    "not_required",
                    "https://example.com/session/legacy",
                    "legacy-session",
                    now,
                    now,
                ),
            )
            cur.execute(
                """
                INSERT INTO pooja_sessions (
                    id, booking_id, provider, user_link, pandit_link, status, created_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    "legacy-session",
                    booking_id,
                    "twilio",
                    "https://example.com/session/legacy",
                    "https://example.com/session/legacy",
                    "scheduled",
                    now,
                ),
            )
            conn.commit()

            migration_007_module().up(conn)

            booking = fetch_booking(conn, booking_id)
            assert booking["pandit_id"] == SHASTRIJI_ID
            assert booking["status"] == "queued"
            assert booking["call_state"] == "queued"
            assert booking["queue_position"] == 1
            assert booking["estimated_wait_minutes"] == 0

            cur.execute("SELECT COUNT(*) AS count FROM pandits WHERE id = ?", (SHASTRIJI_ID,))
            assert cur.fetchone()["count"] == 1
            cur.execute("SELECT COUNT(*) AS count FROM pandits WHERE id != ?", (SHASTRIJI_ID,))
            assert cur.fetchone()["count"] == 0

            cur.execute("SELECT booking_id FROM pooja_sessions WHERE id = ?", ("legacy-session",))
            assert cur.fetchone()["booking_id"] == booking_id

            assert conn.execute("PRAGMA foreign_key_check").fetchall() == []
        finally:
            conn.close()


@pytest.mark.integration
class TestShastrijiStatusAndBooking:
    def test_status_endpoint_is_public_and_returns_profile(self, client):
        response = client.get("/api/v1/temple/shastriji/status")
        assert response.status_code == 200
        data = response.get_json()
        assert data["shastriji"]["name"] == "Shastriji"
        assert "nextSlotTime" in data
        assert "estimatedWaitMinutes" in data

    def test_booking_requires_bearer_auth(self, client):
        response = client.post(
            "/api/v1/temple/shastriji/book",
            headers={"Content-Type": "application/json"},
            data=json.dumps({}),
        )
        assert response.status_code == 401

    def test_booking_auto_assigns_shastriji_and_persists_queue_data(self, client, db):
        user_id = f"book-user-{uuid.uuid4().hex[:8]}"
        response = create_booking(client, user_id)
        assert response.status_code == 201

        data = response.get_json()
        booking = fetch_booking(db, data["bookingId"])
        assert booking["pandit_id"] == SHASTRIJI_ID
        assert booking["status"] == "queued"
        assert booking["call_state"] == "queued"
        assert booking["queue_position"] == data["queuePosition"]
        assert booking["estimated_wait_minutes"] == data["estimatedWaitMinutes"]
        assert booking["scheduled_date"] == data["scheduledDate"]
        assert booking["scheduled_time"] == data["scheduledTime"]

    def test_duplicate_active_booking_returns_conflict(self, client):
        user_id = f"dup-user-{uuid.uuid4().hex[:8]}"
        assert create_booking(client, user_id).status_code == 201
        second = create_booking(client, user_id)
        assert second.status_code == 409

    def test_status_reflects_queue_growth_and_next_available_slot(self, client, freeze_time):
        with freeze_time("2026-03-15 10:00:00"):
            first = create_booking(client, f"status-user-{uuid.uuid4().hex[:8]}")
            second = create_booking(client, f"status-user-{uuid.uuid4().hex[:8]}")
            assert first.status_code == 201
            assert second.status_code == 201

            response = client.get("/api/v1/temple/shastriji/status")
            data = response.get_json()
            assert data["currentQueueLength"] == 2
            assert data["estimatedWaitMinutes"] == 60

            next_slot = datetime.fromisoformat(data["nextSlotTime"])
            second_scheduled = datetime.fromisoformat(
                f"{second.get_json()['scheduledDate']}T{second.get_json()['scheduledTime']}:00"
            )
            assert next_slot > second_scheduled


@pytest.mark.integration
class TestShastrijiQueue:
    def test_queue_returns_real_position_and_wait(self, client):
        first_user = f"queue-user-{uuid.uuid4().hex[:8]}"
        second_user = f"queue-user-{uuid.uuid4().hex[:8]}"
        assert create_booking(client, first_user).status_code == 201
        assert create_booking(client, second_user).status_code == 201

        response = client.get("/api/v1/temple/shastriji/queue", headers=auth_headers(second_user))
        assert response.status_code == 200
        data = response.get_json()
        assert data["queuePosition"] == 2
        assert data["estimatedWaitMinutes"] == 30
        assert data["callState"] == "queued"

    def test_queue_improves_after_cancel(self, client):
        first_user = f"cancel-user-{uuid.uuid4().hex[:8]}"
        second_user = f"cancel-user-{uuid.uuid4().hex[:8]}"
        first = create_booking(client, first_user)
        second = create_booking(client, second_user)
        assert first.status_code == 201
        assert second.status_code == 201

        cancel = client.post(
            f"/api/v1/temple/bookings/{first.get_json()['bookingId']}/cancel",
            headers=auth_headers(first_user),
        )
        assert cancel.status_code == 200

        response = client.get("/api/v1/temple/shastriji/queue", headers=auth_headers(second_user))
        assert response.status_code == 200
        data = response.get_json()
        assert data["queuePosition"] == 1
        assert data["estimatedWaitMinutes"] == 0

    def test_queue_requires_bearer_auth(self, client):
        response = client.get("/api/v1/temple/shastriji/queue")
        assert response.status_code == 401


@pytest.mark.integration
class TestCallStateMachine:
    def test_call_state_requires_owner_or_pandit(self, client):
        owner_id = f"owner-{uuid.uuid4().hex[:8]}"
        booking = create_booking(client, owner_id)
        booking_id = booking.get_json()["bookingId"]

        response = client.patch(
            f"/api/v1/temple/bookings/{booking_id}/call-state",
            headers=auth_headers(f"other-{uuid.uuid4().hex[:8]}"),
            data=json.dumps({"callState": "ringing"}),
        )
        assert response.status_code == 403

    def test_full_call_lifecycle_persists_duration(self, client, db, freeze_time):
        user_id = f"caller-{uuid.uuid4().hex[:8]}"
        booking = create_booking(client, user_id)
        booking_id = booking.get_json()["bookingId"]

        session = client.post(
            f"/api/v1/temple/bookings/{booking_id}/session",
            headers=auth_headers(user_id),
        )
        assert session.status_code == 200

        with freeze_time("2026-03-15 10:00:00"):
            ringing = client.patch(
                f"/api/v1/temple/bookings/{booking_id}/call-state",
                headers=auth_headers(user_id),
                data=json.dumps({"callState": "ringing"}),
            )
            assert ringing.status_code == 200

        with freeze_time("2026-03-15 10:02:00"):
            connected = client.patch(
                f"/api/v1/temple/bookings/{booking_id}/call-state",
                headers=auth_headers(SHASTRIJI_ID),
                data=json.dumps({"callState": "connected"}),
            )
            assert connected.status_code == 200

        with freeze_time("2026-03-15 10:09:00"):
            ended = client.patch(
                f"/api/v1/temple/bookings/{booking_id}/call-state",
                headers=auth_headers(user_id),
                data=json.dumps({"callState": "ended"}),
            )
            assert ended.status_code == 200

        booking_row = fetch_booking(db, booking_id)
        assert booking_row["status"] == "completed"
        assert booking_row["call_state"] == "ended"
        assert booking_row["completed_at"] is not None

        cur = db.cursor()
        cur.execute("SELECT status, ended_at, duration_seconds FROM pooja_sessions WHERE booking_id = ?", (booking_id,))
        session_row = cur.fetchone()
        assert session_row["status"] == "completed"
        assert session_row["ended_at"] is not None
        assert session_row["duration_seconds"] == 420

    def test_missed_call_can_be_requeued_and_rescheduled(self, client, db, freeze_time):
        user_id = f"retry-{uuid.uuid4().hex[:8]}"
        with freeze_time("2026-03-15 10:00:00"):
            booking = create_booking(client, user_id)
        booking_id = booking.get_json()["bookingId"]
        original_slot = f"{booking.get_json()['scheduledDate']} {booking.get_json()['scheduledTime']}"

        assert client.patch(
            f"/api/v1/temple/bookings/{booking_id}/call-state",
            headers=auth_headers(user_id),
            data=json.dumps({"callState": "ringing"}),
        ).status_code == 200

        missed = client.patch(
            f"/api/v1/temple/bookings/{booking_id}/call-state",
            headers=auth_headers(user_id),
            data=json.dumps({"callState": "missed"}),
        )
        assert missed.status_code == 200

        with freeze_time("2026-03-15 10:40:00"):
            requeued = client.patch(
                f"/api/v1/temple/bookings/{booking_id}/call-state",
                headers=auth_headers(user_id),
                data=json.dumps({"callState": "requeued"}),
            )
        assert requeued.status_code == 200
        # The handler auto-transitions requeued -> queued so the client
        # polling loop picks it up immediately (no stuck 'requeued' state).
        assert requeued.get_json()["callState"] == "queued"

        row = fetch_booking(db, booking_id)
        assert row["status"] == "queued"
        assert row["call_state"] == "queued"
        assert row["queue_position"] == 1
        assert row["estimated_wait_minutes"] == 0
        assert f"{row['scheduled_date']} {row['scheduled_time']}" != original_slot

    def test_invalid_transition_is_rejected(self, client):
        user_id = f"invalid-{uuid.uuid4().hex[:8]}"
        booking = create_booking(client, user_id)
        booking_id = booking.get_json()["bookingId"]

        response = client.patch(
            f"/api/v1/temple/bookings/{booking_id}/call-state",
            headers=auth_headers(user_id),
            data=json.dumps({"callState": "ended"}),
        )
        assert response.status_code == 400


@pytest.mark.integration
class TestSessionGeneration:
    def test_session_link_generation_confirms_booking(self, client, db):
        user_id = f"session-{uuid.uuid4().hex[:8]}"
        booking = create_booking(client, user_id)
        booking_id = booking.get_json()["bookingId"]

        response = client.post(
            f"/api/v1/temple/bookings/{booking_id}/session",
            headers=auth_headers(user_id),
        )
        assert response.status_code == 200
        data = response.get_json()
        assert data["sessionLink"].endswith(data["sessionId"])
        assert data["status"] == "confirmed"

        booking_row = fetch_booking(db, booking_id)
        assert booking_row["status"] == "confirmed"
        assert booking_row["session_link"] == data["sessionLink"]
        assert booking_row["session_id"] == data["sessionId"]

    def test_session_generation_rejects_wrong_owner(self, client):
        owner_id = f"session-owner-{uuid.uuid4().hex[:8]}"
        booking = create_booking(client, owner_id)
        booking_id = booking.get_json()["bookingId"]

        response = client.post(
            f"/api/v1/temple/bookings/{booking_id}/session",
            headers=auth_headers(f"session-other-{uuid.uuid4().hex[:8]}"),
        )
        assert response.status_code == 404
