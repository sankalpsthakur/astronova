"""
Focused Temple auth regression tests for spoofable identity headers.
"""

from __future__ import annotations

import uuid

import pytest

from routes.auth import generate_jwt


SHASTRIJI_ID = "shastriji-001"


def auth_headers(user_id: str, **extra: str) -> dict[str, str]:
    headers = {"Authorization": f"Bearer {generate_jwt(user_id)}"}
    headers.update(extra)
    return headers


def first_pooja_type_id(db) -> str:
    cur = db.cursor()
    cur.execute("SELECT id FROM pooja_types WHERE is_active = 1 ORDER BY sort_order ASC, id ASC LIMIT 1")
    row = cur.fetchone()
    assert row is not None
    return row["id"]


def booking_payload(db) -> dict[str, str]:
    return {
        "poojaTypeId": first_pooja_type_id(db),
        "scheduledDate": "2026-06-01",
        "scheduledTime": "10:00",
        "timezone": "Asia/Kolkata",
        "sankalpName": "Security Test",
    }


def create_booking(client, db, user_id: str, **headers: str):
    return client.post(
        "/api/v1/temple/bookings",
        json=booking_payload(db),
        headers=auth_headers(user_id, **headers),
    )


def stored_booking_user_id(db, booking_id: str) -> str:
    cur = db.cursor()
    cur.execute("SELECT user_id FROM pooja_bookings WHERE id = ?", (booking_id,))
    row = cur.fetchone()
    assert row is not None
    return row["user_id"]


def test_booking_create_uses_jwt_subject_not_x_user_id(client, db):
    jwt_user = f"jwt-user-{uuid.uuid4().hex[:8]}"
    spoofed_user = f"spoof-user-{uuid.uuid4().hex[:8]}"

    response = create_booking(client, db, jwt_user, **{"X-User-Id": spoofed_user})

    assert response.status_code == 201
    assert stored_booking_user_id(db, response.get_json()["bookingId"]) == jwt_user


def test_booking_list_and_detail_ignore_spoofed_x_user_id(client, db):
    owner = f"owner-{uuid.uuid4().hex[:8]}"
    intruder = f"intruder-{uuid.uuid4().hex[:8]}"
    booking = create_booking(client, db, owner)
    assert booking.status_code == 201
    booking_id = booking.get_json()["bookingId"]

    list_response = client.get(
        "/api/v1/temple/bookings",
        headers=auth_headers(intruder, **{"X-User-Id": owner}),
    )
    detail_response = client.get(
        f"/api/v1/temple/bookings/{booking_id}",
        headers=auth_headers(intruder, **{"X-User-Id": owner}),
    )

    assert list_response.status_code == 200
    assert list_response.get_json()["bookings"] == []
    assert detail_response.status_code == 404


def test_booking_header_only_auth_is_rejected(client):
    response = client.get(
        "/api/v1/temple/bookings",
        headers={"X-User-Id": f"header-only-{uuid.uuid4().hex[:8]}"},
    )

    assert response.status_code == 401
    assert response.get_json()["code"] == "AUTH_REQUIRED"


def test_bell_ring_uses_jwt_subject_not_x_user_id(client, db):
    jwt_user = f"bell-jwt-{uuid.uuid4().hex[:8]}"
    spoofed_user = f"bell-spoof-{uuid.uuid4().hex[:8]}"

    response = client.post(
        "/api/v1/temple/bell/ring",
        json={"streak": 3, "totalRings": 9},
        headers=auth_headers(jwt_user, **{"X-User-Id": spoofed_user}),
    )

    assert response.status_code == 200
    cur = db.cursor()
    cur.execute("SELECT user_id FROM user_temple_activity WHERE activity_type = 'bell_ring'")
    row = cur.fetchone()
    assert row is not None
    assert row["user_id"] == jwt_user


def test_bell_ring_header_only_auth_is_rejected(client):
    response = client.post(
        "/api/v1/temple/bell/ring",
        json={"streak": 1, "totalRings": 1},
        headers={"X-User-Id": f"bell-header-only-{uuid.uuid4().hex[:8]}"},
    )

    assert response.status_code == 401
    assert response.get_json()["code"] == "AUTH_REQUIRED"


@pytest.mark.parametrize(
    ("method_name", "path"),
    [
        ("post", "/api/v1/temple/bookings/not-a-booking/accept"),
        ("get", "/api/v1/temple/pandit/bookings"),
        ("get", "/api/v1/temple/pandit/bookings/not-a-booking/join"),
    ],
)
def test_x_pandit_id_alone_cannot_access_pandit_routes(client, monkeypatch, method_name: str, path: str):
    monkeypatch.setenv("ADMIN_API_TOKEN", "expected-admin-token")

    response = getattr(client, method_name)(path, headers={"X-Pandit-Id": SHASTRIJI_ID})

    assert response.status_code == 401
    assert response.get_json()["code"] == "ADMIN_AUTH_REQUIRED"


def test_admin_token_can_access_pandit_booking_list(client, db, monkeypatch):
    monkeypatch.setenv("ADMIN_API_TOKEN", "expected-admin-token")
    owner = f"pandit-list-owner-{uuid.uuid4().hex[:8]}"
    booking = create_booking(client, db, owner)
    assert booking.status_code == 201
    booking_id = booking.get_json()["bookingId"]

    response = client.get(
        "/api/v1/temple/pandit/bookings",
        headers={
            "X-Admin-Token": "expected-admin-token",
            "X-Pandit-Id": SHASTRIJI_ID,
        },
    )

    assert response.status_code == 200
    booking_ids = {item["id"] for item in response.get_json()["bookings"]}
    assert booking_id in booking_ids
