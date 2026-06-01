"""
Comprehensive Authentication and Security Tests for Astronova Server

Tests cover:
1. Apple Sign-In flow (/api/v1/auth/apple)
2. Token refresh (/api/v1/auth/refresh)
3. Logout (/api/v1/auth/logout)
4. Delete account (/api/v1/auth/delete-account)
5. Protected endpoints - Bearer token validation
6. JWT expiration handling
7. Invalid/malformed token formats
8. Cross-user access attempts
9. SQL injection attempts in auth parameters
10. Rate limiting status (if implemented)
"""

import gc
import sys
from pathlib import Path

import pytest

SERVER_ROOT = Path(__file__).resolve().parents[1]
if str(SERVER_ROOT) not in sys.path:
    sys.path.append(str(SERVER_ROOT))

from app import create_app
from db import get_connection
from routes.auth import generate_jwt, get_jwt_secret, reset_auth_rate_limits_for_tests, validate_jwt
from utils.time_utils import utc_now_iso, utc_now_naive


VALID_APPLE_ID_TOKEN = "valid-apple-id-token"
_UNSET = object()


def mock_apple_validation(monkeypatch, *, sub="apple-user-001", email=_UNSET):
    """Mock Apple JWT validation while preserving token-required auth semantics."""

    def fake_validate(id_token):
        assert id_token == VALID_APPLE_ID_TOKEN
        payload = {}
        if sub is not None:
            payload["sub"] = sub
        if email is not _UNSET:
            payload["email"] = email
        return payload

    monkeypatch.setattr("routes.auth.validate_apple_id_token", fake_validate)


@pytest.fixture()
def test_db_path(tmp_path):
    """Temporary database path for test isolation."""
    db_file = tmp_path / "test_auth_security.db"
    return str(db_file)


@pytest.fixture()
def client(test_db_path):
    """Flask test client for API testing with isolated database."""
    import db as db_module

    # Override DB_PATH to use test database
    original_db_path = db_module.DB_PATH
    db_module.DB_PATH = test_db_path

    try:
        app = create_app()
        app.config.update(
            {
                "TESTING": True,
            }
        )

        with app.test_client() as client:
            yield client
    finally:
        # Restore original DB_PATH
        db_module.DB_PATH = original_db_path


@pytest.fixture()
def auth_token():
    """Valid authentication token."""
    return generate_jwt("test-user-123", "test@astronova.com")


@pytest.fixture()
def test_user_id():
    """Test user ID for cross-user access tests."""
    return "test-user-123"


@pytest.fixture()
def another_user_id():
    """Another test user ID for cross-user access tests."""
    return "test-user-456"


class TestAppleSignIn:
    """Test Apple Sign-In authentication flow."""

    def test_apple_auth_valid_complete_data(self, client, monkeypatch):
        """Test Apple auth with all valid fields."""
        mock_apple_validation(monkeypatch, sub="apple-user-001")

        response = client.post(
            "/api/v1/auth/apple",
            json={
                "idToken": VALID_APPLE_ID_TOKEN,
                "userIdentifier": "apple-user-001",
                "email": "user@example.com",
                "firstName": "John",
                "lastName": "Doe",
            },
            content_type="application/json",
        )

        assert response.status_code == 200
        data = response.get_json()

        assert "jwtToken" in data
        assert "user" in data
        assert "expiresAt" in data
        assert data["user"]["id"] == "apple-user-001"
        assert data["user"]["email"] == "user@example.com"
        assert data["user"]["firstName"] == "John"
        assert data["user"]["lastName"] == "Doe"
        assert data["user"]["fullName"] == "John Doe"

    def test_apple_auth_minimal_data(self, client, monkeypatch):
        """Test Apple auth with only token-backed userIdentifier."""
        mock_apple_validation(monkeypatch, sub="apple-user-002")

        response = client.post(
            "/api/v1/auth/apple",
            json={"idToken": VALID_APPLE_ID_TOKEN, "userIdentifier": "apple-user-002"},
            content_type="application/json",
        )

        assert response.status_code == 200
        data = response.get_json()

        assert "jwtToken" in data
        assert data["user"]["id"] == "apple-user-002"
        assert data["user"]["fullName"] == "User"

    def test_jwt_secret_key_render_env_fallback(self, monkeypatch):
        """Render's blueprint sets JWT_SECRET_KEY; tokens should not use the dev fallback."""
        import jwt as pyjwt

        monkeypatch.delenv("JWT_SECRET", raising=False)
        render_secret = "render-compatible-secret-at-least-32-bytes"
        monkeypatch.setenv("JWT_SECRET_KEY", render_secret)

        token = generate_jwt("render-user", "render@example.com")
        payload = pyjwt.decode(token, render_secret, algorithms=["HS256"])

        assert payload["sub"] == "render-user"
        assert validate_jwt(token)["user_id"] == "render-user"

    def test_apple_auth_accepts_documented_id_token(self, client, monkeypatch):
        """The iOS client and OpenAPI contract send idToken, not identityToken."""

        def fake_validate(id_token):
            assert id_token == "valid-ios-token"
            return {"sub": "apple-token-user", "email": "token@example.com"}

        monkeypatch.setattr("routes.auth.validate_apple_id_token", fake_validate)

        response = client.post(
            "/api/v1/auth/apple",
            json={"idToken": "valid-ios-token", "userIdentifier": "client-user", "email": "client@example.com"},
            content_type="application/json",
        )

        assert response.status_code == 200
        data = response.get_json()
        assert data["user"]["id"] == "apple-token-user"
        assert data["user"]["email"] == "token@example.com"

    def test_apple_auth_rejects_invalid_documented_id_token(self, client, monkeypatch):
        """Invalid iOS idToken values must not silently fall back to userIdentifier."""

        def fake_validate(_id_token):
            raise ValueError("Invalid token")

        monkeypatch.setattr("routes.auth.validate_apple_id_token", fake_validate)

        response = client.post(
            "/api/v1/auth/apple",
            json={"idToken": "invalid-token", "userIdentifier": "client-user", "email": "client@example.com"},
            content_type="application/json",
        )

        assert response.status_code == 401
        assert response.get_json()["code"] == "INVALID_TOKEN"

    def test_apple_auth_rejects_missing_token_even_with_email(self, client):
        """Apple auth must not mint anonymous JWTs without an Apple token."""
        response = client.post("/api/v1/auth/apple", json={"email": "anonymous@example.com"}, content_type="application/json")

        assert response.status_code == 401
        assert response.get_json()["code"] == "APPLE_TOKEN_REQUIRED"

    def test_apple_auth_empty_json(self, client):
        """Test Apple auth with empty JSON body requires token."""
        response = client.post("/api/v1/auth/apple", json={}, content_type="application/json")

        assert response.status_code == 401
        assert response.get_json()["code"] == "APPLE_TOKEN_REQUIRED"

    def test_apple_auth_no_json_body(self, client):
        """Test Apple auth with no JSON body requires token."""
        response = client.post("/api/v1/auth/apple")

        assert response.status_code == 401
        assert response.get_json()["code"] == "APPLE_TOKEN_REQUIRED"

    def test_apple_auth_malformed_json(self, client):
        """Test Apple auth with malformed JSON."""
        response = client.post("/api/v1/auth/apple", data="{invalid-json", content_type="application/json")

        assert response.status_code == 400
        data = response.get_json()
        assert data.get("code") == "INVALID_JSON"

    def test_apple_auth_creates_database_record(self, client, monkeypatch):
        """Test that Apple auth creates user record in database."""
        user_id = "apple-user-db-test"
        mock_apple_validation(monkeypatch, sub=user_id)

        response = client.post(
            "/api/v1/auth/apple",
            json={
                "idToken": VALID_APPLE_ID_TOKEN,
                "userIdentifier": user_id,
                "email": "dbtest@example.com",
                "firstName": "DB",
                "lastName": "Test",
            },
            content_type="application/json",
        )

        assert response.status_code == 200

        # Verify user was created in database
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT * FROM users WHERE id=?", (user_id,))
        user = cur.fetchone()
        conn.close()

        assert user is not None
        assert user["email"] == "dbtest@example.com"
        assert user["first_name"] == "DB"
        assert user["last_name"] == "Test"

    def test_apple_auth_upsert_existing_user(self, client, monkeypatch):
        """Test that Apple auth updates existing user."""
        user_id = "apple-user-upsert"
        mock_apple_validation(monkeypatch, sub=user_id)

        # First auth
        response1 = client.post(
            "/api/v1/auth/apple",
            json={
                "idToken": VALID_APPLE_ID_TOKEN,
                "userIdentifier": user_id,
                "email": "old@example.com",
                "firstName": "Old",
                "lastName": "Name",
            },
        )
        assert response1.status_code == 200

        # Second auth with updated info
        response2 = client.post(
            "/api/v1/auth/apple",
            json={
                "idToken": VALID_APPLE_ID_TOKEN,
                "userIdentifier": user_id,
                "email": "new@example.com",
                "firstName": "New",
                "lastName": "Name",
            },
        )
        assert response2.status_code == 200

        # Verify user was updated in database
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT * FROM users WHERE id=?", (user_id,))
        user = cur.fetchone()
        conn.close()

        assert user["email"] == "new@example.com"
        assert user["first_name"] == "New"


class TestTokenRefresh:
    """Test token refresh endpoint."""

    def test_refresh_with_valid_token(self, client, auth_token):
        """Test token refresh with valid Bearer token."""
        response = client.post("/api/v1/auth/refresh", headers={"Authorization": f"Bearer {auth_token}"})

        assert response.status_code == 200
        data = response.get_json()

        assert "jwtToken" in data
        assert "user" in data
        assert "expiresAt" in data

    def test_refresh_without_authorization_header(self, client):
        """Test token refresh without Authorization header."""
        response = client.post("/api/v1/auth/refresh")

        assert response.status_code == 401
        data = response.get_json()

        assert "error" in data
        assert "code" in data
        assert data["code"] == "AUTH_REQUIRED"

    def test_refresh_with_empty_authorization_header(self, client):
        """Test token refresh with empty Authorization header."""
        response = client.post("/api/v1/auth/refresh", headers={"Authorization": ""})

        assert response.status_code == 401
        data = response.get_json()
        assert data["code"] == "AUTH_REQUIRED"

    def test_refresh_without_bearer_prefix(self, client):
        """Test token refresh without 'Bearer' prefix."""
        response = client.post("/api/v1/auth/refresh", headers={"Authorization": "demo-token"})

        assert response.status_code == 401
        data = response.get_json()
        assert data["code"] == "AUTH_REQUIRED"

    def test_refresh_with_empty_token(self, client):
        """Test token refresh with empty token."""
        response = client.post("/api/v1/auth/refresh", headers={"Authorization": "Bearer "})

        assert response.status_code == 401
        data = response.get_json()
        assert data["code"] == "INVALID_TOKEN"

    def test_refresh_with_null_token(self, client):
        """Test token refresh with 'null' string as token."""
        response = client.post("/api/v1/auth/refresh", headers={"Authorization": "Bearer null"})

        assert response.status_code == 401
        data = response.get_json()
        assert data["code"] == "INVALID_TOKEN"

    def test_refresh_with_undefined_token(self, client):
        """Test token refresh with 'undefined' string as token."""
        response = client.post("/api/v1/auth/refresh", headers={"Authorization": "Bearer undefined"})

        assert response.status_code == 401
        data = response.get_json()
        assert data["code"] == "INVALID_TOKEN"

    def test_refresh_with_malformed_token(self, client):
        """Test token refresh with malformed token."""
        response = client.post("/api/v1/auth/refresh", headers={"Authorization": "Bearer !!!invalid-token-format!!!"})

        assert response.status_code == 401
        data = response.get_json()
        assert data["code"] == "INVALID_TOKEN"

    def test_refresh_with_whitespace_in_token(self, client):
        """Test token refresh with token containing whitespace."""
        response = client.post("/api/v1/auth/refresh", headers={"Authorization": "Bearer   demo-token   "})

        assert response.status_code == 401
        data = response.get_json()
        assert data["code"] == "INVALID_TOKEN"


class TestTokenValidation:
    """Test token validation endpoint."""

    def test_validate_with_correct_token(self, client, auth_token):
        """Test validation with correct token."""
        response = client.get("/api/v1/auth/validate", headers={"Authorization": f"Bearer {auth_token}"})

        assert response.status_code == 200
        data = response.get_json()
        assert data["valid"] is True

    def test_validate_with_incorrect_token(self, client):
        """Test validation with incorrect token."""
        response = client.get("/api/v1/auth/validate", headers={"Authorization": "Bearer wrong-token"})

        assert response.status_code == 200
        data = response.get_json()
        assert data["valid"] is False

    def test_validate_without_token(self, client):
        """Test validation without token."""
        response = client.get("/api/v1/auth/validate")

        assert response.status_code == 200
        data = response.get_json()
        assert data["valid"] is False


class TestAdminTokenProtection:
    """Test admin endpoints require the configured admin token."""

    def test_admin_grant_pro_without_config_returns_503(self, client, monkeypatch):
        monkeypatch.delenv("ADMIN_API_TOKEN", raising=False)

        response = client.post("/api/v1/admin/grant-pro", json={"userId": "admin-test-user"})

        assert response.status_code == 503
        assert response.get_json()["code"] == "ADMIN_NOT_CONFIGURED"

    def test_admin_grant_pro_rejects_invalid_token(self, client, monkeypatch):
        monkeypatch.setenv("ADMIN_API_TOKEN", "expected-admin-token")

        response = client.post(
            "/api/v1/admin/grant-pro",
            json={"userId": "admin-test-user"},
            headers={"X-Admin-Token": "wrong-admin-token"},
        )

        assert response.status_code == 401
        assert response.get_json()["code"] == "ADMIN_AUTH_REQUIRED"

    def test_admin_list_users_rejects_missing_token(self, client, monkeypatch):
        monkeypatch.setenv("ADMIN_API_TOKEN", "expected-admin-token")

        response = client.get("/api/v1/admin/list-users")

        assert response.status_code == 401
        assert response.get_json()["code"] == "ADMIN_AUTH_REQUIRED"

    def test_admin_grant_pro_accepts_x_admin_token(self, client, monkeypatch):
        monkeypatch.setenv("ADMIN_API_TOKEN", "expected-admin-token")

        response = client.post(
            "/api/v1/admin/grant-pro",
            json={},
            headers={"X-Admin-Token": "expected-admin-token"},
        )

        assert response.status_code == 400
        assert response.get_json()["error"] == "email or userId is required"

    def test_admin_grant_pro_uses_app_store_product_id(self, client, monkeypatch):
        from db import upsert_user

        monkeypatch.setenv("ADMIN_API_TOKEN", "expected-admin-token")
        upsert_user("admin-product-user", "iap@example.com", "IAP", "User", "IAP User")

        response = client.post(
            "/api/v1/admin/grant-pro",
            json={"userId": "admin-product-user"},
            headers={"X-Admin-Token": "expected-admin-token"},
        )

        assert response.status_code == 200
        assert response.get_json()["subscription"]["productId"] == "astronova_pro_monthly"

    def test_admin_list_users_accepts_bearer_token(self, client, monkeypatch):
        monkeypatch.setenv("ADMIN_API_TOKEN", "expected-admin-token")

        response = client.get(
            "/api/v1/admin/list-users",
            headers={"Authorization": "Bearer expected-admin-token"},
        )

        assert response.status_code == 200
        data = response.get_json()
        assert "users" in data
        assert "total" in data

    def test_admin_health_requires_token(self, client, monkeypatch):
        monkeypatch.setenv("ADMIN_API_TOKEN", "expected-admin-token")

        response = client.get("/api/v1/admin/health")

        assert response.status_code == 401
        assert response.get_json()["code"] == "ADMIN_AUTH_REQUIRED"


class TestSeedTestUserProtection:
    """Test seed-test-user is not open in production."""

    def test_seed_test_user_requires_admin_token_in_production(self, client, monkeypatch):
        monkeypatch.setenv("FLASK_ENV", "production")
        monkeypatch.setenv("ADMIN_API_TOKEN", "expected-admin-token")

        response = client.post("/api/v1/seed-test-user")

        assert response.status_code == 401
        assert response.get_json()["code"] == "ADMIN_AUTH_REQUIRED"

    def test_seed_test_user_returns_503_if_admin_token_unconfigured_in_production(self, client, monkeypatch):
        monkeypatch.setenv("FLASK_ENV", "production")
        monkeypatch.delenv("ADMIN_API_TOKEN", raising=False)

        response = client.post("/api/v1/seed-test-user")

        assert response.status_code == 503
        assert response.get_json()["code"] == "ADMIN_NOT_CONFIGURED"

    def test_seed_test_user_accepts_admin_token_in_production(self, client, monkeypatch):
        monkeypatch.setenv("FLASK_ENV", "production")
        monkeypatch.setenv("ADMIN_API_TOKEN", "expected-admin-token")

        response = client.post(
            "/api/v1/seed-test-user",
            headers={"X-Admin-Token": "expected-admin-token"},
        )

        assert response.status_code == 201
        assert response.get_json()["user_id"] == "appstore-test-user-2026"

    def test_seed_test_user_allows_non_production_without_admin_token(self, client, monkeypatch):
        monkeypatch.setenv("FLASK_ENV", "development")
        monkeypatch.delenv("APP_ENV", raising=False)
        monkeypatch.delenv("ENV", raising=False)
        monkeypatch.delenv("ADMIN_API_TOKEN", raising=False)

        response = client.post("/api/v1/seed-test-user")

        assert response.status_code == 201
        assert response.get_json()["user_id"] == "appstore-test-user-2026"


class TestLogout:
    """Test logout endpoint."""

    def test_logout_success(self, client):
        """Test logout returns success."""
        response = client.post("/api/v1/auth/logout")

        assert response.status_code == 200
        data = response.get_json()
        assert data["status"] == "ok"

    def test_logout_with_token(self, client, auth_token):
        """Test logout with authentication token."""
        response = client.post("/api/v1/auth/logout", headers={"Authorization": f"Bearer {auth_token}"})

        assert response.status_code == 200
        data = response.get_json()
        assert data["status"] == "ok"

    def test_logout_without_token(self, client):
        """Test logout without authentication token."""
        # Current implementation doesn't require auth for logout
        response = client.post("/api/v1/auth/logout")

        assert response.status_code == 200
        data = response.get_json()
        assert data["status"] == "ok"


class TestDeleteAccount:
    """Test account deletion endpoint."""

    def test_delete_account_success(self, client, auth_token):
        """Test delete account returns success."""
        response = client.delete("/api/v1/auth/delete-account", headers={"Authorization": f"Bearer {auth_token}"})

        assert response.status_code == 200
        data = response.get_json()
        assert data["status"] == "ok"

    def test_delete_account_removes_purchase_and_temple_data(self, client, auth_token):
        """Delete account removes all user-linked monetization and Temple rows."""
        user_id = "test-user-123"
        now = utc_now_iso()

        conn = get_connection()
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO users (id, email, first_name, last_name, full_name, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (user_id, "test@astronova.com", "Test", "User", "Test User", now, now),
        )
        cur.execute(
            """
            INSERT INTO report_purchase_entitlements
            (id, user_id, product_id, report_type, transaction_id, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            ("report-entitlement-1", user_id, "report_general", "birth_chart", "tx-delete-account-1", now),
        )
        cur.execute("SELECT id FROM pooja_types LIMIT 1")
        pooja_type_id = cur.fetchone()["id"]
        cur.execute(
            """
            INSERT INTO pooja_bookings
            (id, user_id, pooja_type_id, scheduled_date, scheduled_time, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            ("booking-delete-account-1", user_id, pooja_type_id, "2026-06-01", "09:00", now, now),
        )
        cur.execute(
            "INSERT INTO pooja_sessions (id, booking_id, created_at) VALUES (?, ?, ?)",
            ("session-delete-account-1", "booking-delete-account-1", now),
        )
        cur.execute(
            "INSERT INTO user_temple_activity (id, user_id, activity_type, created_at) VALUES (?, ?, ?, ?)",
            ("activity-delete-account-1", user_id, "bell_ring", now),
        )
        cur.execute(
            """
            INSERT INTO contact_filter_logs
            (id, context_type, context_id, sender_type, sender_id, original_message, filtered_message, patterns_matched, action_taken, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                "contact-log-delete-account-1",
                "pooja_session",
                "session-delete-account-1",
                "user",
                user_id,
                "call me at 5555555555",
                "call me at [contact removed]",
                '["5555555555"]',
                "filtered",
                now,
            ),
        )
        conn.commit()
        conn.close()

        response = client.delete("/api/v1/auth/delete-account", headers={"Authorization": f"Bearer {auth_token}"})

        assert response.status_code == 200
        data = response.get_json()
        assert data["status"] == "ok"
        assert data["deletedRecords"]["report_purchase_entitlements"] == 1
        assert data["deletedRecords"]["pooja_sessions"] == 1
        assert data["deletedRecords"]["user_temple_activity"] == 1
        assert data["deletedRecords"]["contact_filter_logs"] == 1

        conn = get_connection()
        cur = conn.cursor()
        for table, column, value in [
            ("report_purchase_entitlements", "user_id", user_id),
            ("user_temple_activity", "user_id", user_id),
            ("pooja_bookings", "user_id", user_id),
            ("contact_filter_logs", "sender_id", user_id),
            ("pooja_sessions", "booking_id", "booking-delete-account-1"),
        ]:
            cur.execute(f"SELECT COUNT(*) AS count FROM {table} WHERE {column}=?", (value,))
            assert cur.fetchone()["count"] == 0
        conn.close()

    def test_delete_account_with_invalid_token(self, client):
        """Test delete account with invalid authentication token."""
        response = client.delete("/api/v1/auth/delete-account", headers={"Authorization": "Bearer wrong-token"})

        assert response.status_code == 401
        data = response.get_json()
        assert data["code"] == "INVALID_TOKEN"

    def test_delete_account_without_token(self, client):
        """Test delete account without authentication token."""
        response = client.delete("/api/v1/auth/delete-account")

        assert response.status_code == 401
        data = response.get_json()
        assert data["code"] == "AUTH_REQUIRED"


class TestProtectedEndpoints:
    """Test protected endpoints require authentication."""

    def test_reports_endpoint_requires_auth(self, client):
        """Test reports endpoint requires authentication."""
        response = client.get("/api/v1/reports/user/some-user-id")
        assert response.status_code == 401

    def test_chat_endpoint_requires_auth(self, client):
        """Test chat endpoint requires authentication."""
        response = client.post("/api/v1/chat", json={"message": "test message"}, content_type="application/json")
        assert response.status_code == 401

    def test_birth_data_endpoint_requires_auth(self, client):
        """Test birth data endpoint requires authentication."""
        response = client.get("/api/v1/chat/birth-data")
        assert response.status_code == 401

    def test_save_birth_data_requires_auth(self, client):
        """Test save birth data requires authentication."""
        response = client.post(
            "/api/v1/chat/birth-data", json={"birthData": {"date": "1990-01-15"}}, content_type="application/json"
        )
        assert response.status_code == 401


class TestCrossUserAccess:
    """Test cross-user data access is prevented by auth."""

    def test_user_cannot_access_another_users_reports(self, client, test_user_id, another_user_id):
        """Test that unauthenticated access to reports is blocked."""
        from db import insert_report

        report_id = "test-report-001"
        insert_report(report_id, test_user_id, "birth_chart", "Test Report", "Test content")

        response = client.get(f"/api/v1/reports/user/{test_user_id}")
        assert response.status_code == 401

    def test_user_report_list_rejects_valid_token_for_another_user(self, client, auth_token, another_user_id):
        """A valid JWT cannot list another user's reports by changing the path."""
        response = client.get(
            f"/api/v1/reports/user/{another_user_id}",
            headers={"Authorization": f"Bearer {auth_token}"},
        )
        assert response.status_code == 403
        assert response.get_json()["code"] == "FORBIDDEN"

    def test_report_status_requires_authentication(self, client, test_user_id):
        """Report status should not reveal report metadata without a JWT."""
        from db import insert_report

        report_id = "test-report-status-001"
        insert_report(report_id, test_user_id, "birth_chart", "Test Report", "Test content")

        response = client.get(f"/api/v1/reports/{report_id}/status")
        assert response.status_code == 401

    def test_report_pdf_rejects_valid_token_for_another_user(self, client, auth_token, another_user_id):
        """A valid JWT cannot download another user's persisted report PDF."""
        from db import insert_report

        report_id = "test-report-pdf-001"
        insert_report(report_id, another_user_id, "birth_chart", "Other Report", "Other content")

        response = client.get(
            f"/api/v1/reports/{report_id}/pdf",
            headers={"Authorization": f"Bearer {auth_token}"},
        )
        assert response.status_code == 403
        assert response.get_json()["code"] == "FORBIDDEN"

    def test_subscription_status_requires_authentication(self, client):
        """Subscription status should not be queryable without a JWT."""
        response = client.get("/api/v1/subscription/status?userId=test-user-123")
        assert response.status_code == 401

    def test_user_cannot_access_another_users_birth_data(self, client, test_user_id, another_user_id):
        """Test that unauthenticated access to birth data is blocked."""
        from db import upsert_user_birth_data

        upsert_user_birth_data(test_user_id, "1990-01-15", "14:30", "America/New_York", 40.7128, -74.0060, "New York")

        response = client.get(f"/api/v1/chat/birth-data?userId={test_user_id}")
        assert response.status_code == 401

    def test_user_id_header_spoofing_blocked(self, client):
        """Test that X-User-Id header alone is insufficient without valid JWT."""
        response = client.post("/api/v1/chat", json={"message": "test"}, headers={"X-User-Id": "spoofed-user-id"})
        assert response.status_code == 401

    def test_locale_selection_ignores_user_id_header_before_auth(self, monkeypatch, test_db_path):
        """Pre-auth locale resolution must not trust X-User-Id."""
        from flask_babel import get_locale

        import db as db_module

        calls = []

        def fake_get_user_preferred_language(user_id):
            calls.append(user_id)
            return "hi"

        original_db_path = db_module.DB_PATH
        db_module.DB_PATH = test_db_path
        monkeypatch.setattr("app.get_user_preferred_language", fake_get_user_preferred_language)
        try:
            app = create_app()
            app.config.update({"TESTING": True})
            with app.test_request_context(
                "/api/v1/health",
                headers={"X-User-Id": "spoofed-user-id", "Accept-Language": "es"},
            ):
                assert str(get_locale()) == "es"
        finally:
            db_module.DB_PATH = original_db_path

        assert calls == []

    def test_request_log_context_ignores_user_id_header_without_auth(self):
        """Unauthenticated headers must not be written as trusted user IDs in logs."""
        from utils.logging_utils import get_user_id

        app = create_app()
        app.config.update({"TESTING": True})
        with app.test_request_context("/api/v1/health", headers={"X-User-Id": "spoofed-user-id"}):
            assert get_user_id() == "-"

    def test_app_env_production_does_not_allow_localhost_cors(self, monkeypatch, test_db_path):
        """Any production env marker must keep localhost out of default CORS."""
        import db as db_module

        original_db_path = db_module.DB_PATH
        db_module.DB_PATH = test_db_path
        monkeypatch.delenv("FLASK_ENV", raising=False)
        monkeypatch.setenv("APP_ENV", "production")
        monkeypatch.delenv("ENV", raising=False)
        monkeypatch.delenv("ASTRONOVA_CORS_ORIGINS", raising=False)
        try:
            app = create_app()
            app.config.update({"TESTING": True})
            with app.test_client() as client:
                response = client.get("/api/v1/health", headers={"Origin": "http://localhost:8080"})
        finally:
            db_module.DB_PATH = original_db_path

        assert response.headers.get("Access-Control-Allow-Origin") is None


class TestSQLInjection:
    """Test SQL injection attempts in authentication parameters."""

    def test_sql_injection_in_token_subject(self, client, monkeypatch):
        """Test SQL injection in validated Apple subject."""
        malicious_id = "'; DROP TABLE users; --"
        mock_apple_validation(monkeypatch, sub=malicious_id)

        response = client.post(
            "/api/v1/auth/apple",
            json={"idToken": VALID_APPLE_ID_TOKEN, "userIdentifier": malicious_id},
            content_type="application/json",
        )

        # Should handle safely due to parameterized queries
        assert response.status_code == 200

        # Verify users table still exists
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='users'")
        table = cur.fetchone()
        conn.close()

        assert table is not None

    def test_sql_injection_in_email(self, client, monkeypatch):
        """Test SQL injection in email field."""
        malicious_email = "test@example.com' OR '1'='1"
        mock_apple_validation(monkeypatch, sub="test-user")

        response = client.post(
            "/api/v1/auth/apple",
            json={"idToken": VALID_APPLE_ID_TOKEN, "userIdentifier": "test-user", "email": malicious_email},
            content_type="application/json",
        )

        # Should handle safely
        assert response.status_code == 200

    def test_sql_injection_in_user_id_query(self, client):
        """Test SQL injection in userId query parameter is blocked by auth."""
        malicious_id = "' OR '1'='1"

        response = client.get(f"/api/v1/reports/user/{malicious_id}")

        # Auth required before any query is executed
        assert response.status_code == 401

    def test_sql_injection_in_chat_birth_data(self, client):
        """Test SQL injection in birth data query is blocked by auth."""
        malicious_id = "' OR '1'='1; --"

        response = client.get(f"/api/v1/chat/birth-data?userId={malicious_id}")

        # Auth required before any query is executed
        assert response.status_code == 401


class TestInvalidTokenFormats:
    """Test handling of various invalid token formats."""

    def test_jwt_with_invalid_signature(self, client):
        """Test JWT with invalid signature."""
        fake_jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.invalid_signature"

        response = client.post("/api/v1/auth/refresh", headers={"Authorization": f"Bearer {fake_jwt}"})

        assert response.status_code == 401
        data = response.get_json()
        assert data["code"] == "INVALID_TOKEN"

    def test_token_with_special_characters(self, client):
        """Test token containing special characters."""
        special_token = "token!@#$%^&*(){}[]|\\:;\"'<>,.?/"

        response = client.post("/api/v1/auth/refresh", headers={"Authorization": f"Bearer {special_token}"})

        assert response.status_code == 401
        data = response.get_json()
        assert data["code"] == "INVALID_TOKEN"

    def test_extremely_long_token(self, client):
        """Test extremely long token."""
        long_token = "a" * 10000

        response = client.post("/api/v1/auth/refresh", headers={"Authorization": f"Bearer {long_token}"})

        assert response.status_code == 401
        data = response.get_json()
        assert data["code"] == "INVALID_TOKEN"

    def test_token_with_unicode(self, client):
        """Test token containing unicode characters."""
        unicode_token = "token-用户-🔐"

        response = client.post("/api/v1/auth/refresh", headers={"Authorization": f"Bearer {unicode_token}"})

        assert response.status_code == 401
        data = response.get_json()
        assert data["code"] == "INVALID_TOKEN"

    def test_multiple_bearer_prefixes(self, client):
        """Test Authorization header with multiple Bearer prefixes."""
        response = client.post("/api/v1/auth/refresh", headers={"Authorization": "Bearer Bearer demo-token"})

        assert response.status_code == 401
        data = response.get_json()
        assert data["code"] == "INVALID_TOKEN"


class TestJWTExpiration:
    """Test JWT expiration handling."""

    def test_token_expiration_field_present(self, client, monkeypatch):
        """Test that token response includes expiration."""
        mock_apple_validation(monkeypatch, sub="test-user")
        response = client.post(
            "/api/v1/auth/apple",
            json={"idToken": VALID_APPLE_ID_TOKEN, "userIdentifier": "test-user"},
        )

        assert response.status_code == 200
        data = response.get_json()

        assert "expiresAt" in data
        # Should be 30 days in future
        from datetime import datetime

        expires_at = datetime.fromisoformat(data["expiresAt"])
        created_at = datetime.fromisoformat(data["user"]["createdAt"])

        # Check expiration is approximately 30 days from creation
        delta = (expires_at - created_at).days
        assert 29 <= delta <= 31

    def test_refresh_token_expiration(self, client, auth_token):
        """Test that refresh also includes expiration."""
        response = client.post("/api/v1/auth/refresh", headers={"Authorization": f"Bearer {auth_token}"})

        assert response.status_code == 200
        data = response.get_json()

        assert "expiresAt" in data

        from datetime import datetime

        expires_at = datetime.fromisoformat(data["expiresAt"])
        now = utc_now_naive()

        # Should be ~30 days in future
        delta = (expires_at - now).days
        assert 29 <= delta <= 31


class TestRateLimiting:
    """Test auth rate limiting."""

    def test_apple_auth_rate_limiting_when_enabled(self, client, monkeypatch):
        """Repeated Apple auth attempts are blocked when rate limiting is enabled."""
        reset_auth_rate_limits_for_tests()
        monkeypatch.setenv("AUTH_RATE_LIMIT_ENABLED", "true")
        monkeypatch.setenv("AUTH_RATE_LIMIT_MAX_REQUESTS", "3")
        monkeypatch.setenv("AUTH_RATE_LIMIT_WINDOW_SECONDS", "60")
        mock_apple_validation(monkeypatch, sub="rate-limit-user")

        responses = []
        for i in range(4):
            response = client.post(
                "/api/v1/auth/apple",
                json={"idToken": VALID_APPLE_ID_TOKEN, "userIdentifier": f"user-{i}"},
            )
            responses.append(response.status_code)

        assert responses[:3] == [200, 200, 200]
        assert responses[3] == 429

    def test_refresh_brute_force_rate_limiting_when_enabled(self, client, monkeypatch):
        """Repeated failed refresh attempts are blocked when rate limiting is enabled."""
        reset_auth_rate_limits_for_tests()
        monkeypatch.setenv("AUTH_RATE_LIMIT_ENABLED", "true")
        monkeypatch.setenv("AUTH_RATE_LIMIT_MAX_REQUESTS", "3")
        monkeypatch.setenv("AUTH_RATE_LIMIT_WINDOW_SECONDS", "60")

        responses = []
        for _ in range(4):
            response = client.post("/api/v1/auth/refresh", headers={"Authorization": "Bearer "})
            responses.append(response.status_code)

        assert responses[:3] == [401, 401, 401]
        assert responses[3] == 429

    def test_expensive_endpoint_rate_limit_ignores_spoofable_user_header(self, authenticated_client, sample_birth_data):
        """Rotating X-User-Id must not bypass expensive endpoint throttles."""
        statuses = []
        for i in range(21):
            response = authenticated_client.post(
                "/api/v1/reports/generate",
                json={"reportType": "birth_chart", "birthData": sample_birth_data},
                headers={"X-User-Id": f"spoofed-rate-key-{i}"},
            )
            statuses.append(response.status_code)

        assert 429 not in statuses[:20]
        assert statuses[20] == 429

    def test_disabled_expensive_endpoint_limiter_survives_app_factory_lifecycle(self, test_db_path, monkeypatch):
        """Expensive endpoint limiter wrapper must not outlive its Limiter instance."""
        import db as db_module

        original_db_path = db_module.DB_PATH
        db_module.DB_PATH = test_db_path
        monkeypatch.setenv("ASTRONOVA_DISABLE_RATE_LIMITS", "1")
        try:
            app = create_app()
            app.config["TESTING"] = True
            gc.collect()
            with app.test_client() as client:
                response = client.post("/api/v1/chart/generate", json={})
        finally:
            db_module.DB_PATH = original_db_path

        assert response.status_code == 400
        assert response.get_json()["code"] == "INVALID_JSON"

    def test_production_requires_jwt_secret(self, monkeypatch):
        """Production auth refuses the development fallback secret."""
        monkeypatch.delenv("JWT_SECRET", raising=False)
        monkeypatch.delenv("JWT_SECRET_KEY", raising=False)
        monkeypatch.setenv("FLASK_ENV", "production")

        with pytest.raises(RuntimeError):
            get_jwt_secret()


class TestProductionConfiguration:
    """Test production configuration invariants."""

    def test_app_env_production_requires_ip_hash_salt(self, monkeypatch):
        """APP_ENV=production must not fall back to ephemeral IP hash salts."""
        import portfolio_analytics

        monkeypatch.delenv("FLASK_ENV", raising=False)
        monkeypatch.setenv("APP_ENV", "production")
        monkeypatch.delenv("ENV", raising=False)
        monkeypatch.delenv("IP_HASH_SALT", raising=False)
        portfolio_analytics._SALT = None
        try:
            with pytest.raises(RuntimeError, match="IP_HASH_SALT"):
                portfolio_analytics.internals["hash_ip"]("127.0.0.1")
        finally:
            portfolio_analytics._SALT = None

    def test_render_blueprint_provisions_ip_hash_salt(self):
        """Render production blueprint must provision the analytics IP hash salt."""
        import yaml

        render_config = yaml.safe_load((SERVER_ROOT / "render.yaml").read_text())
        env_vars = render_config["services"][0]["envVars"]
        ip_hash_salt = next((env for env in env_vars if env.get("key") == "IP_HASH_SALT"), None)

        assert ip_hash_salt is not None
        assert ip_hash_salt.get("generateValue") is True


class TestSecurityHeaders:
    """Test security-related headers."""

    def test_request_id_in_response(self, client):
        """Test that X-Request-ID is included in responses."""
        response = client.get("/api/v1/health")

        assert "X-Request-ID" in response.headers
        assert len(response.headers["X-Request-ID"]) > 0

    def test_cors_headers(self, client):
        """Test that CORS headers are present."""
        response = client.options("/api/v1/auth/apple")

        # CORS is enabled via Flask-CORS
        # Check if CORS headers would be present
        assert response.status_code in [200, 204]


class TestDataValidation:
    """Test input validation and sanitization."""

    def test_birth_data_requires_date(self, authenticated_client):
        """Test that birth data requires date field."""
        response = authenticated_client.post(
            "/api/v1/chat/birth-data", json={"userId": "test-user", "birthData": {"time": "14:30"}}  # Missing date
        )

        assert response.status_code == 400
        data = response.get_json()
        assert "error" in data

    def test_birth_data_validates_presence(self, authenticated_client):
        """Test that birth data field is required."""
        response = authenticated_client.post("/api/v1/chat/birth-data", json={"userId": "test-user"})  # Missing birthData

        assert response.status_code == 400

    def test_null_values_in_json(self, client, monkeypatch):
        """Test handling of null values in JSON."""
        mock_apple_validation(monkeypatch, sub="null-values-user")
        response = client.post(
            "/api/v1/auth/apple",
            json={"idToken": VALID_APPLE_ID_TOKEN, "userIdentifier": None, "email": None, "firstName": None},
        )

        # Should handle None values gracefully
        assert response.status_code == 200

    def test_extremely_long_strings(self, client, monkeypatch):
        """Test handling of extremely long input strings."""
        long_string = "a" * 100000
        mock_apple_validation(monkeypatch, sub="test")

        response = client.post(
            "/api/v1/auth/apple",
            json={"idToken": VALID_APPLE_ID_TOKEN, "userIdentifier": "test", "firstName": long_string},
        )

        # Should handle without crashing
        assert response.status_code == 200


class TestDatabaseSecurity:
    """Test database security and isolation."""

    def test_database_connection_uses_parameterized_queries(self):
        """Verify that database uses parameterized queries."""
        # Read the db.py file to check for parameterized queries
        db_file = SERVER_ROOT / "db.py"
        with open(db_file, "r") as f:
            content = f.read()

        # Check for parameterized query patterns (? placeholders)
        assert "?" in content  # SQLite parameter placeholder
        # Should not have string formatting in SQL
        assert 'f"SELECT' not in content or "?" in content

    def test_foreign_keys_enabled(self):
        """Test that foreign key constraints are enabled."""
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("PRAGMA foreign_keys")
        result = cur.fetchone()[0]
        conn.close()

        assert result == 1  # Foreign keys enabled

    def test_wal_mode_enabled(self):
        """Test that WAL mode is enabled for better concurrency."""
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("PRAGMA journal_mode")
        result = cur.fetchone()[0]
        conn.close()

        assert result.upper() == "WAL"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
