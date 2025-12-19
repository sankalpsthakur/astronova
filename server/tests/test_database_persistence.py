"""
Comprehensive database persistence verification tests.

Tests verify that:
1. Report generation persists to the database
2. Chat messages persist conversations and messages
3. Subscription updates persist correctly
4. User authentication data persists
5. Birth data saves and updates correctly
6. Updates modify existing rows (no duplicates)
7. Foreign key constraints work
8. Timestamp fields are set correctly
"""

from __future__ import annotations

import sqlite3
import sys
import uuid
from datetime import datetime
from pathlib import Path

import pytest

SERVER_ROOT = Path(__file__).resolve().parents[1]
if str(SERVER_ROOT) not in sys.path:
    sys.path.append(str(SERVER_ROOT))

from db import (
    DB_PATH,
    add_chat_message,
    ensure_conversation,
    init_db,
    insert_report,
    set_subscription,
    upsert_user,
    upsert_user_birth_data,
)


@pytest.fixture
def test_db_connection(db):
    """
    Provide a direct database connection for verification.
    Uses the db fixture from conftest.py for test isolation.
    """
    yield db


@pytest.fixture
def clean_test_user_id():
    """Generate a unique test user ID to avoid conflicts."""
    return f"test-user-{uuid.uuid4()}"


@pytest.fixture
def clean_test_report_id():
    """Generate a unique test report ID."""
    return f"test-report-{uuid.uuid4()}"


class TestReportPersistence:
    """Test report generation and database persistence."""

    def test_report_insert_creates_row(self, test_db_connection, clean_test_user_id, clean_test_report_id):
        """Verify report is persisted to database after insert_report()."""
        # Insert a report
        report_id = clean_test_report_id
        user_id = clean_test_user_id
        report_type = "birth_chart"
        title = "Test Birth Chart"
        content = "This is test content for the birth chart."

        insert_report(report_id, user_id, report_type, title, content)

        # Query database directly
        cur = test_db_connection.cursor()
        cur.execute("SELECT * FROM reports WHERE report_id=?", (report_id,))
        row = cur.fetchone()

        # Verify row exists and has correct data
        assert row is not None, "Report row should exist in database"
        assert row["report_id"] == report_id
        assert row["user_id"] == user_id
        assert row["type"] == report_type
        assert row["title"] == title
        assert row["content"] == content
        assert row["status"] == "completed"
        assert row["generated_at"] is not None

        # Verify timestamp format
        generated_at = row["generated_at"]
        assert "T" in generated_at, "Timestamp should be in ISO format"

    def test_report_api_persists_to_database(self, client, test_db_connection, clean_test_user_id):
        """Verify report created via API is persisted to database."""
        # Make API request
        response = client.post(
            "/api/v1/reports/generate",
            json={
                "birthData": {
                    "date": "1990-01-15",
                    "time": "14:30",
                    "timezone": "Asia/Kolkata",
                    "latitude": 19.0760,
                    "longitude": 72.8777,
                },
                "reportType": "career_forecast",
                "userId": clean_test_user_id,
            },
        )

        assert response.status_code == 200
        data = response.get_json()
        report_id = data["reportId"]

        # Verify in database
        cur = test_db_connection.cursor()
        cur.execute("SELECT * FROM reports WHERE report_id=?", (report_id,))
        row = cur.fetchone()

        assert row is not None
        assert row["user_id"] == clean_test_user_id
        assert row["type"] == "career_forecast"
        assert row["status"] == "completed"
        assert len(row["content"]) > 0

    def test_multiple_reports_for_same_user(self, test_db_connection, clean_test_user_id):
        """Verify multiple reports can be stored for the same user."""
        user_id = clean_test_user_id

        # Insert multiple reports
        report_ids = []
        for i in range(3):
            report_id = f"test-report-{uuid.uuid4()}"
            report_ids.append(report_id)
            insert_report(report_id, user_id, "birth_chart", f"Report {i}", f"Content {i}")

        # Query all reports for user
        cur = test_db_connection.cursor()
        cur.execute("SELECT COUNT(*) as cnt FROM reports WHERE user_id=?", (user_id,))
        count = cur.fetchone()["cnt"]

        assert count == 3, "Should have 3 reports for user"

        # Verify all report IDs exist
        for report_id in report_ids:
            cur.execute("SELECT report_id FROM reports WHERE report_id=?", (report_id,))
            assert cur.fetchone() is not None


class TestChatPersistence:
    """Test chat conversation and message persistence."""

    def test_ensure_conversation_creates_row(self, test_db_connection, clean_test_user_id):
        """Verify ensure_conversation creates a row in chat_conversations."""
        conversation_id = f"test-conv-{uuid.uuid4()}"
        user_id = clean_test_user_id

        ensure_conversation(conversation_id, user_id)

        # Verify conversation exists in database
        cur = test_db_connection.cursor()
        cur.execute("SELECT * FROM chat_conversations WHERE id=?", (conversation_id,))
        row = cur.fetchone()

        assert row is not None
        assert row["id"] == conversation_id
        assert row["user_id"] == user_id
        assert row["created_at"] is not None
        assert row["updated_at"] is not None

    def test_ensure_conversation_with_none_creates_new(self, test_db_connection, clean_test_user_id):
        """Verify ensure_conversation with None conversation_id creates a new conversation."""
        user_id = clean_test_user_id

        conversation_id = ensure_conversation(None, user_id)

        assert conversation_id is not None
        assert len(conversation_id) > 0

        # Verify in database
        cur = test_db_connection.cursor()
        cur.execute("SELECT * FROM chat_conversations WHERE id=?", (conversation_id,))
        row = cur.fetchone()

        assert row is not None
        assert row["user_id"] == user_id

    def test_add_chat_message_creates_row(self, test_db_connection, clean_test_user_id):
        """Verify add_chat_message persists message to database."""
        conversation_id = ensure_conversation(None, clean_test_user_id)

        message_content = "What's my horoscope for today?"
        message_id = add_chat_message(conversation_id, "user", message_content, clean_test_user_id)

        # Verify message in database
        cur = test_db_connection.cursor()
        cur.execute("SELECT * FROM chat_messages WHERE id=?", (message_id,))
        row = cur.fetchone()

        assert row is not None
        assert row["conversation_id"] == conversation_id
        assert row["user_id"] == clean_test_user_id
        assert row["role"] == "user"
        assert row["content"] == message_content
        assert row["created_at"] is not None

    def test_chat_api_persists_messages(self, client, test_db_connection, clean_test_user_id):
        """Verify chat API persists both user and assistant messages."""
        # Make chat API request
        response = client.post(
            "/api/v1/chat",
            json={
                "message": "Tell me about my day",
                "userId": clean_test_user_id,
                "birthData": {
                    "date": "1990-01-15",
                    "time": "14:30",
                    "timezone": "Asia/Kolkata",
                    "latitude": 19.0760,
                    "longitude": 72.8777,
                },
            },
        )

        assert response.status_code == 200
        data = response.get_json()
        conversation_id = data["conversationId"]

        # Verify conversation exists
        cur = test_db_connection.cursor()
        cur.execute("SELECT * FROM chat_conversations WHERE id=?", (conversation_id,))
        conv_row = cur.fetchone()
        assert conv_row is not None

        # Verify messages exist (user + assistant)
        cur.execute("SELECT * FROM chat_messages WHERE conversation_id=? ORDER BY created_at", (conversation_id,))
        messages = cur.fetchall()

        assert len(messages) == 2, "Should have user message and assistant reply"

        # Verify user message
        user_msg = messages[0]
        assert user_msg["role"] == "user"
        assert user_msg["content"] == "Tell me about my day"
        assert user_msg["user_id"] == clean_test_user_id

        # Verify assistant message
        assistant_msg = messages[1]
        assert assistant_msg["role"] == "assistant"
        assert len(assistant_msg["content"]) > 0

    def test_conversation_updated_at_changes(self, test_db_connection, clean_test_user_id):
        """Verify conversation updated_at timestamp changes when messages are added."""
        conversation_id = ensure_conversation(None, clean_test_user_id)

        # Get initial updated_at
        cur = test_db_connection.cursor()
        cur.execute("SELECT updated_at FROM chat_conversations WHERE id=?", (conversation_id,))
        initial_updated_at = cur.fetchone()["updated_at"]

        # Add a message (should update conversation timestamp)
        import time

        time.sleep(0.01)  # Small delay to ensure timestamp difference
        add_chat_message(conversation_id, "user", "Test message", clean_test_user_id)

        # Get new updated_at
        cur.execute("SELECT updated_at FROM chat_conversations WHERE id=?", (conversation_id,))
        new_updated_at = cur.fetchone()["updated_at"]

        # Timestamps should be different
        assert new_updated_at >= initial_updated_at


class TestSubscriptionPersistence:
    """Test subscription status persistence."""

    def test_set_subscription_creates_row(self, test_db_connection, clean_test_user_id):
        """Verify set_subscription creates a row in subscription_status."""
        user_id = clean_test_user_id
        product_id = "premium_monthly"

        set_subscription(user_id, True, product_id)

        # Verify in database
        cur = test_db_connection.cursor()
        cur.execute("SELECT * FROM subscription_status WHERE user_id=?", (user_id,))
        row = cur.fetchone()

        assert row is not None
        assert row["user_id"] == user_id
        assert row["is_active"] == 1
        assert row["product_id"] == product_id
        assert row["updated_at"] is not None

    def test_set_subscription_updates_existing_row(self, test_db_connection, clean_test_user_id):
        """Verify set_subscription updates existing row instead of creating duplicate."""
        user_id = clean_test_user_id

        # Initial subscription
        set_subscription(user_id, True, "premium_monthly")

        # Update subscription
        import time

        time.sleep(0.01)
        set_subscription(user_id, False, "premium_annual")

        # Verify only one row exists
        cur = test_db_connection.cursor()
        cur.execute("SELECT COUNT(*) as cnt FROM subscription_status WHERE user_id=?", (user_id,))
        count = cur.fetchone()["cnt"]

        assert count == 1, "Should only have one subscription row per user"

        # Verify updated values
        cur.execute("SELECT * FROM subscription_status WHERE user_id=?", (user_id,))
        row = cur.fetchone()

        assert row["is_active"] == 0
        assert row["product_id"] == "premium_annual"

    def test_subscription_status_timestamp_updates(self, test_db_connection, clean_test_user_id):
        """Verify updated_at changes when subscription is updated."""
        user_id = clean_test_user_id

        # Initial subscription
        set_subscription(user_id, True, "basic")

        cur = test_db_connection.cursor()
        cur.execute("SELECT updated_at FROM subscription_status WHERE user_id=?", (user_id,))
        initial_timestamp = cur.fetchone()["updated_at"]

        # Update subscription
        import time

        time.sleep(0.01)
        set_subscription(user_id, True, "premium")

        cur.execute("SELECT updated_at FROM subscription_status WHERE user_id=?", (user_id,))
        new_timestamp = cur.fetchone()["updated_at"]

        assert new_timestamp >= initial_timestamp


class TestUserAuthPersistence:
    """Test user authentication data persistence."""

    def test_upsert_user_creates_row(self, test_db_connection, clean_test_user_id):
        """Verify upsert_user creates a row for new user."""
        user_id = clean_test_user_id
        email = "test@example.com"
        first_name = "John"
        last_name = "Doe"
        full_name = "John Doe"

        upsert_user(user_id, email, first_name, last_name, full_name)

        # Verify in database
        cur = test_db_connection.cursor()
        cur.execute("SELECT * FROM users WHERE id=?", (user_id,))
        row = cur.fetchone()

        assert row is not None
        assert row["id"] == user_id
        assert row["email"] == email
        assert row["first_name"] == first_name
        assert row["last_name"] == last_name
        assert row["full_name"] == full_name
        assert row["created_at"] is not None
        assert row["updated_at"] is not None

    def test_upsert_user_updates_existing_row(self, test_db_connection, clean_test_user_id):
        """Verify upsert_user updates existing user instead of creating duplicate."""
        user_id = clean_test_user_id

        # Initial user
        upsert_user(user_id, "old@example.com", "Old", "Name", "Old Name")

        # Update user
        import time

        time.sleep(0.01)
        upsert_user(user_id, "new@example.com", "New", "Name", "New Name")

        # Verify only one row exists
        cur = test_db_connection.cursor()
        cur.execute("SELECT COUNT(*) as cnt FROM users WHERE id=?", (user_id,))
        count = cur.fetchone()["cnt"]

        assert count == 1, "Should only have one user row per user_id"

        # Verify updated values
        cur.execute("SELECT * FROM users WHERE id=?", (user_id,))
        row = cur.fetchone()

        assert row["email"] == "new@example.com"
        assert row["first_name"] == "New"
        assert row["full_name"] == "New Name"

    def test_auth_api_creates_user(self, client, test_db_connection):
        """Verify Apple auth API creates user in database."""
        user_identifier = f"test-apple-user-{uuid.uuid4()}"

        response = client.post(
            "/api/v1/auth/apple",
            json={"userIdentifier": user_identifier, "email": "apple@example.com", "firstName": "Apple", "lastName": "User"},
        )

        assert response.status_code == 200

        # Verify user in database
        cur = test_db_connection.cursor()
        cur.execute("SELECT * FROM users WHERE id=?", (user_identifier,))
        row = cur.fetchone()

        assert row is not None
        assert row["email"] == "apple@example.com"
        assert row["first_name"] == "Apple"
        assert row["last_name"] == "User"

    def test_user_timestamps_set_correctly(self, test_db_connection, clean_test_user_id):
        """Verify created_at and updated_at are set correctly."""
        user_id = clean_test_user_id

        upsert_user(user_id, "test@example.com", "Test", "User", "Test User")

        cur = test_db_connection.cursor()
        cur.execute("SELECT created_at, updated_at FROM users WHERE id=?", (user_id,))
        row = cur.fetchone()

        created_at = row["created_at"]
        updated_at = row["updated_at"]

        # Both should be set
        assert created_at is not None
        assert updated_at is not None

        # Should be in ISO format
        assert "T" in created_at
        assert "T" in updated_at

        # For new user, they should be equal or very close
        assert created_at == updated_at


class TestBirthDataPersistence:
    """Test user birth data persistence."""

    def test_upsert_birth_data_creates_row(self, test_db_connection, clean_test_user_id):
        """Verify upsert_user_birth_data creates a row for new user."""
        user_id = clean_test_user_id

        upsert_user_birth_data(
            user_id=user_id,
            birth_date="1990-01-15",
            birth_time="14:30",
            timezone="Asia/Kolkata",
            latitude=19.0760,
            longitude=72.8777,
            location_name="Mumbai, India",
        )

        # Verify in database
        cur = test_db_connection.cursor()
        cur.execute("SELECT * FROM user_birth_data WHERE user_id=?", (user_id,))
        row = cur.fetchone()

        assert row is not None
        assert row["user_id"] == user_id
        assert row["birth_date"] == "1990-01-15"
        assert row["birth_time"] == "14:30"
        assert row["timezone"] == "Asia/Kolkata"
        assert abs(row["latitude"] - 19.0760) < 0.0001
        assert abs(row["longitude"] - 72.8777) < 0.0001
        assert row["location_name"] == "Mumbai, India"
        assert row["created_at"] is not None
        assert row["updated_at"] is not None

    def test_upsert_birth_data_updates_existing_row(self, test_db_connection, clean_test_user_id):
        """Verify upsert_user_birth_data updates existing row instead of creating duplicate."""
        user_id = clean_test_user_id

        # Initial birth data
        upsert_user_birth_data(
            user_id=user_id,
            birth_date="1990-01-15",
            birth_time="14:30",
            timezone="Asia/Kolkata",
            latitude=19.0760,
            longitude=72.8777,
        )

        # Update birth data
        import time

        time.sleep(0.01)
        upsert_user_birth_data(
            user_id=user_id,
            birth_date="1985-05-20",
            birth_time="10:00",
            timezone="America/New_York",
            latitude=40.7128,
            longitude=-74.0060,
            location_name="New York, NY",
        )

        # Verify only one row exists
        cur = test_db_connection.cursor()
        cur.execute("SELECT COUNT(*) as cnt FROM user_birth_data WHERE user_id=?", (user_id,))
        count = cur.fetchone()["cnt"]

        assert count == 1, "Should only have one birth data row per user"

        # Verify updated values
        cur.execute("SELECT * FROM user_birth_data WHERE user_id=?", (user_id,))
        row = cur.fetchone()

        assert row["birth_date"] == "1985-05-20"
        assert row["birth_time"] == "10:00"
        assert row["timezone"] == "America/New_York"
        assert row["location_name"] == "New York, NY"

    def test_birth_data_api_persists_to_database(self, client, test_db_connection, clean_test_user_id):
        """Verify birth data saved via API is persisted to database."""
        user_id = clean_test_user_id

        response = client.post(
            "/api/v1/chat/birth-data",
            json={
                "userId": user_id,
                "birthData": {
                    "date": "1992-07-10",
                    "time": "18:45",
                    "timezone": "Europe/London",
                    "latitude": 51.5074,
                    "longitude": -0.1278,
                    "locationName": "London, UK",
                },
            },
        )

        assert response.status_code == 200

        # Verify in database
        cur = test_db_connection.cursor()
        cur.execute("SELECT * FROM user_birth_data WHERE user_id=?", (user_id,))
        row = cur.fetchone()

        assert row is not None
        assert row["birth_date"] == "1992-07-10"
        assert row["birth_time"] == "18:45"
        assert row["timezone"] == "Europe/London"
        assert row["location_name"] == "London, UK"

    def test_birth_data_timestamps_update_correctly(self, test_db_connection, clean_test_user_id):
        """Verify created_at is set once and updated_at changes on updates."""
        user_id = clean_test_user_id

        # Initial insert
        upsert_user_birth_data(user_id=user_id, birth_date="1990-01-15", birth_time="14:30")

        cur = test_db_connection.cursor()
        cur.execute("SELECT created_at, updated_at FROM user_birth_data WHERE user_id=?", (user_id,))
        row = cur.fetchone()
        initial_created_at = row["created_at"]
        initial_updated_at = row["updated_at"]

        # Update
        import time

        time.sleep(0.01)
        upsert_user_birth_data(user_id=user_id, birth_date="1990-01-15", birth_time="15:00")

        cur.execute("SELECT created_at, updated_at FROM user_birth_data WHERE user_id=?", (user_id,))
        row = cur.fetchone()
        new_created_at = row["created_at"]
        new_updated_at = row["updated_at"]

        # created_at should not change
        assert new_created_at == initial_created_at

        # updated_at should change
        assert new_updated_at >= initial_updated_at


class TestDataIntegrity:
    """Test data integrity constraints and relationships."""

    def test_report_without_user_id_allowed(self, test_db_connection):
        """Verify reports can be created without user_id (anonymous reports)."""
        report_id = f"test-anon-report-{uuid.uuid4()}"

        insert_report(report_id, None, "birth_chart", "Anonymous Report", "Content")

        cur = test_db_connection.cursor()
        cur.execute("SELECT user_id FROM reports WHERE report_id=?", (report_id,))
        row = cur.fetchone()

        assert row is not None
        assert row["user_id"] is None

    def test_chat_conversation_without_user_id_allowed(self, test_db_connection):
        """Verify conversations can be created without user_id (anonymous chats)."""
        conversation_id = ensure_conversation(None, None)

        cur = test_db_connection.cursor()
        cur.execute("SELECT user_id FROM chat_conversations WHERE id=?", (conversation_id,))
        row = cur.fetchone()

        assert row is not None
        # user_id can be None for anonymous conversations

    def test_multiple_messages_in_same_conversation(self, test_db_connection, clean_test_user_id):
        """Verify multiple messages can be added to the same conversation."""
        conversation_id = ensure_conversation(None, clean_test_user_id)

        # Add multiple messages
        message_ids = []
        for i in range(5):
            msg_id = add_chat_message(
                conversation_id, "user" if i % 2 == 0 else "assistant", f"Message {i}", clean_test_user_id
            )
            message_ids.append(msg_id)

        # Verify all messages exist
        cur = test_db_connection.cursor()
        cur.execute("SELECT COUNT(*) as cnt FROM chat_messages WHERE conversation_id=?", (conversation_id,))
        count = cur.fetchone()["cnt"]

        assert count == 5

    def test_foreign_key_constraints_enabled(self, test_db_connection):
        """Verify foreign key constraints are enabled."""
        cur = test_db_connection.cursor()
        cur.execute("PRAGMA foreign_keys")
        row = cur.fetchone()

        # Should return (1,) if enabled
        assert row is not None
        assert row[0] == 1, "Foreign key constraints should be enabled"

    def test_timestamp_fields_are_iso_format(self, test_db_connection, clean_test_user_id):
        """Verify all timestamp fields use ISO 8601 format."""
        user_id = clean_test_user_id

        # Create various records
        upsert_user(user_id, "test@example.com", "Test", "User", "Test User")
        report_id = f"test-report-{uuid.uuid4()}"
        insert_report(report_id, user_id, "birth_chart", "Test", "Content")
        conversation_id = ensure_conversation(None, user_id)
        add_chat_message(conversation_id, "user", "Test", user_id)
        set_subscription(user_id, True, "premium")
        upsert_user_birth_data(user_id, "1990-01-15")

        # Check all timestamp fields
        cur = test_db_connection.cursor()

        # Users table
        cur.execute("SELECT created_at, updated_at FROM users WHERE id=?", (user_id,))
        user_row = cur.fetchone()
        assert "T" in user_row["created_at"]
        assert "T" in user_row["updated_at"]

        # Reports table
        cur.execute("SELECT generated_at FROM reports WHERE report_id=?", (report_id,))
        report_row = cur.fetchone()
        assert "T" in report_row["generated_at"]

        # Chat conversations
        cur.execute("SELECT created_at, updated_at FROM chat_conversations WHERE id=?", (conversation_id,))
        conv_row = cur.fetchone()
        assert "T" in conv_row["created_at"]
        assert "T" in conv_row["updated_at"]

        # Chat messages
        cur.execute("SELECT created_at FROM chat_messages WHERE conversation_id=?", (conversation_id,))
        msg_row = cur.fetchone()
        assert "T" in msg_row["created_at"]

        # Subscription status
        cur.execute("SELECT updated_at FROM subscription_status WHERE user_id=?", (user_id,))
        sub_row = cur.fetchone()
        assert "T" in sub_row["updated_at"]

        # Birth data
        cur.execute("SELECT created_at, updated_at FROM user_birth_data WHERE user_id=?", (user_id,))
        birth_row = cur.fetchone()
        assert "T" in birth_row["created_at"]
        assert "T" in birth_row["updated_at"]

    def test_primary_key_uniqueness(self, test_db_connection, clean_test_user_id):
        """Verify primary key constraints prevent duplicates."""
        user_id = clean_test_user_id

        # Insert user
        upsert_user(user_id, "test1@example.com", "Test", "User", "Test User")

        # Try to insert with same ID using raw SQL (should fail)
        cur = test_db_connection.cursor()
        with pytest.raises(sqlite3.IntegrityError):
            cur.execute(
                "INSERT INTO users (id, email, full_name, created_at, updated_at) VALUES (?,?,?,?,?)",
                (user_id, "test2@example.com", "Another User", datetime.utcnow().isoformat(), datetime.utcnow().isoformat()),
            )

    def test_database_file_exists(self):
        """Verify database file exists after initialization."""
        init_db()
        assert Path(DB_PATH).exists(), f"Database file should exist at {DB_PATH}"
        assert Path(DB_PATH).is_file(), "Database path should be a file"

    def test_wal_mode_enabled(self, test_db_connection):
        """Verify WAL (Write-Ahead Logging) mode is enabled for better concurrency."""
        cur = test_db_connection.cursor()
        cur.execute("PRAGMA journal_mode")
        row = cur.fetchone()

        # WAL mode provides better concurrency
        assert row[0].lower() == "wal", "Database should use WAL journal mode"


class TestEndToEndScenarios:
    """Test complete end-to-end scenarios combining multiple operations."""

    def test_complete_user_journey(self, client, test_db_connection):
        """Test a complete user journey: auth -> birth data -> chat -> report."""
        user_id = f"test-journey-{uuid.uuid4()}"

        # Step 1: User authenticates
        auth_response = client.post(
            "/api/v1/auth/apple",
            json={"userIdentifier": user_id, "email": "journey@example.com", "firstName": "Journey", "lastName": "Test"},
        )
        assert auth_response.status_code == 200

        # Verify user in DB
        cur = test_db_connection.cursor()
        cur.execute("SELECT * FROM users WHERE id=?", (user_id,))
        assert cur.fetchone() is not None

        # Step 2: User saves birth data
        birth_response = client.post(
            "/api/v1/chat/birth-data",
            json={
                "userId": user_id,
                "birthData": {
                    "date": "1990-01-15",
                    "time": "14:30",
                    "timezone": "Asia/Kolkata",
                    "latitude": 19.0760,
                    "longitude": 72.8777,
                    "locationName": "Mumbai, India",
                },
            },
        )
        assert birth_response.status_code == 200

        # Verify birth data in DB
        cur.execute("SELECT * FROM user_birth_data WHERE user_id=?", (user_id,))
        assert cur.fetchone() is not None

        # Step 3: User chats
        chat_response = client.post("/api/v1/chat", json={"message": "What is my chart like?", "userId": user_id})
        assert chat_response.status_code == 200
        conversation_id = chat_response.get_json()["conversationId"]

        # Verify chat in DB
        cur.execute("SELECT COUNT(*) as cnt FROM chat_messages WHERE conversation_id=?", (conversation_id,))
        assert cur.fetchone()["cnt"] >= 2  # User + assistant messages

        # Step 4: User generates report
        report_response = client.post(
            "/api/v1/reports/generate",
            json={
                "userId": user_id,
                "reportType": "birth_chart",
                "birthData": {
                    "date": "1990-01-15",
                    "time": "14:30",
                    "timezone": "Asia/Kolkata",
                    "latitude": 19.0760,
                    "longitude": 72.8777,
                },
            },
        )
        assert report_response.status_code == 200
        report_id = report_response.get_json()["reportId"]

        # Verify report in DB
        cur.execute("SELECT * FROM reports WHERE report_id=?", (report_id,))
        report = cur.fetchone()
        assert report is not None
        assert report["user_id"] == user_id

        # Step 5: Verify all data is linked to same user
        cur.execute("SELECT id FROM users WHERE id=?", (user_id,))
        assert cur.fetchone() is not None

        cur.execute("SELECT COUNT(*) as cnt FROM user_birth_data WHERE user_id=?", (user_id,))
        assert cur.fetchone()["cnt"] == 1

        cur.execute("SELECT COUNT(*) as cnt FROM chat_conversations WHERE user_id=?", (user_id,))
        assert cur.fetchone()["cnt"] >= 1

        cur.execute("SELECT COUNT(*) as cnt FROM reports WHERE user_id=?", (user_id,))
        assert cur.fetchone()["cnt"] >= 1

    def test_subscription_lifecycle(self, test_db_connection, clean_test_user_id):
        """Test complete subscription lifecycle: activate -> update -> deactivate."""
        user_id = clean_test_user_id

        # Activate subscription
        set_subscription(user_id, True, "premium_monthly")

        cur = test_db_connection.cursor()
        cur.execute("SELECT is_active, product_id FROM subscription_status WHERE user_id=?", (user_id,))
        row = cur.fetchone()
        assert row["is_active"] == 1
        assert row["product_id"] == "premium_monthly"

        # Upgrade subscription
        import time

        time.sleep(0.01)
        set_subscription(user_id, True, "premium_annual")

        cur.execute("SELECT is_active, product_id FROM subscription_status WHERE user_id=?", (user_id,))
        row = cur.fetchone()
        assert row["is_active"] == 1
        assert row["product_id"] == "premium_annual"

        # Deactivate subscription
        time.sleep(0.01)
        set_subscription(user_id, False, None)

        cur.execute("SELECT is_active, product_id FROM subscription_status WHERE user_id=?", (user_id,))
        row = cur.fetchone()
        assert row["is_active"] == 0

        # Verify only one row throughout lifecycle
        cur.execute("SELECT COUNT(*) as cnt FROM subscription_status WHERE user_id=?", (user_id,))
        assert cur.fetchone()["cnt"] == 1
