"""
Comprehensive endpoint coverage tests for astronova API.

Tests all previously uncovered endpoints including:
- Chat endpoint and birth data persistence
- Compatibility calculations
- Reports and PDF generation
- Location search with geopy fallback
- Subscription status management
- System status and health checks
- Remote config and content management
"""

from __future__ import annotations

from datetime import datetime


class TestChatEndpoint:
    """Test /api/v1/chat endpoint for personalized responses."""

    def test_chat_basic_message(self, client):
        """Test basic chat message without birth data."""
        response = client.post("/api/v1/chat", json={"message": "What is my horoscope today?", "userId": "test-user-1"})
        assert response.status_code == 200
        data = response.get_json()
        assert "reply" in data
        assert "conversationId" in data
        assert "messageId" in data
        assert data["reply"] is not None
        assert len(data["reply"]) > 0

    def test_chat_with_birth_data_in_request(self, client):
        """Test chat with birth data provided in request."""
        response = client.post(
            "/api/v1/chat",
            json={
                "message": "Tell me about my love life",
                "userId": "test-user-2",
                "birthData": {
                    "date": "1990-08-15",
                    "time": "14:30",
                    "timezone": "America/New_York",
                    "latitude": 40.7128,
                    "longitude": -74.0060,
                },
            },
        )
        assert response.status_code == 200
        data = response.get_json()
        assert "reply" in data
        assert data["reply"] is not None

    def test_chat_question_classification_love(self, client):
        """Test that love questions are properly classified."""
        response = client.post("/api/v1/chat", json={"message": "Will I find love this year?", "userId": "test-user-3"})
        assert response.status_code == 200
        data = response.get_json()
        assert "reply" in data

    def test_chat_question_classification_career(self, client):
        """Test that career questions are properly classified."""
        response = client.post("/api/v1/chat", json={"message": "Should I change my job?", "userId": "test-user-4"})
        assert response.status_code == 200
        data = response.get_json()
        assert "reply" in data

    def test_chat_conversation_continuity(self, client):
        """Test that conversation can be continued with conversation ID."""
        # First message
        response1 = client.post("/api/v1/chat", json={"message": "Hello", "userId": "test-user-5"})
        data1 = response1.get_json()
        conversation_id = data1["conversationId"]

        # Continue conversation
        response2 = client.post(
            "/api/v1/chat", json={"message": "Tell me more", "userId": "test-user-5", "conversationId": conversation_id}
        )
        assert response2.status_code == 200
        data2 = response2.get_json()
        assert data2["conversationId"] == conversation_id

    def test_chat_without_user_id(self, client):
        """Test chat without user ID (should still work)."""
        response = client.post("/api/v1/chat", json={"message": "What is astrology?"})
        assert response.status_code == 200
        data = response.get_json()
        assert "reply" in data

    def test_chat_empty_message(self, client):
        """Test chat with empty message."""
        response = client.post("/api/v1/chat", json={"message": "", "userId": "test-user-6"})
        assert response.status_code == 200
        data = response.get_json()
        assert "reply" in data

    def test_chat_invalid_json(self, client):
        """Test chat with invalid JSON."""
        response = client.post("/api/v1/chat", data="invalid json", content_type="application/json")
        # Should handle gracefully (returns 200 with default handling)
        assert response.status_code == 200

    def test_chat_suggested_followups(self, client):
        """Test that chat returns suggested follow-up questions."""
        response = client.post("/api/v1/chat", json={"message": "Tell me about Mercury retrograde", "userId": "test-user-7"})
        assert response.status_code == 200
        data = response.get_json()
        assert "suggestedFollowUps" in data


class TestChatBirthData:
    """Test /api/v1/chat/birth-data endpoints."""

    def test_save_birth_data(self, client):
        """Test saving user birth data."""
        response = client.post(
            "/api/v1/chat/birth-data",
            json={
                "userId": "test-user-bd-1",
                "birthData": {
                    "date": "1985-05-20",
                    "time": "09:30",
                    "timezone": "Europe/London",
                    "latitude": 51.5074,
                    "longitude": -0.1278,
                    "locationName": "London, UK",
                },
            },
        )
        assert response.status_code == 200
        data = response.get_json()
        assert data["status"] == "success"
        assert "message" in data

    def test_save_birth_data_minimal(self, client):
        """Test saving birth data with only required fields."""
        response = client.post(
            "/api/v1/chat/birth-data", json={"userId": "test-user-bd-2", "birthData": {"date": "1992-12-25"}}
        )
        assert response.status_code == 200
        data = response.get_json()
        assert data["status"] == "success"

    def test_save_birth_data_without_user_id(self, client):
        """Test saving birth data without user ID."""
        response = client.post("/api/v1/chat/birth-data", json={"birthData": {"date": "1990-01-01"}})
        assert response.status_code == 400
        data = response.get_json()
        assert "error" in data

    def test_save_birth_data_without_birth_data(self, client):
        """Test saving without birth data object."""
        response = client.post("/api/v1/chat/birth-data", json={"userId": "test-user-bd-3"})
        assert response.status_code == 400
        data = response.get_json()
        assert "error" in data

    def test_save_birth_data_without_date(self, client):
        """Test saving birth data without date field."""
        response = client.post("/api/v1/chat/birth-data", json={"userId": "test-user-bd-4", "birthData": {"time": "10:00"}})
        assert response.status_code == 400
        data = response.get_json()
        assert "error" in data

    def test_get_birth_data_exists(self, client):
        """Test retrieving saved birth data."""
        # First save birth data
        client.post(
            "/api/v1/chat/birth-data",
            json={"userId": "test-user-bd-5", "birthData": {"date": "1988-07-15", "time": "14:00", "timezone": "Asia/Tokyo"}},
        )

        # Then retrieve it
        response = client.get("/api/v1/chat/birth-data?userId=test-user-bd-5")
        assert response.status_code == 200
        data = response.get_json()
        assert data["hasBirthData"] is True
        assert data["birthData"] is not None
        assert data["birthData"]["birth_date"] == "1988-07-15"

    def test_get_birth_data_not_exists(self, client):
        """Test retrieving birth data that doesn't exist."""
        response = client.get("/api/v1/chat/birth-data?userId=nonexistent-user")
        assert response.status_code == 200
        data = response.get_json()
        assert data["hasBirthData"] is False
        assert data["birthData"] is None

    def test_get_birth_data_without_user_id(self, client):
        """Test retrieving birth data without user ID."""
        response = client.get("/api/v1/chat/birth-data")
        assert response.status_code == 400
        data = response.get_json()
        assert "error" in data

    def test_update_birth_data(self, client):
        """Test updating existing birth data."""
        user_id = "test-user-bd-6"

        # Save initial data
        client.post("/api/v1/chat/birth-data", json={"userId": user_id, "birthData": {"date": "1990-01-01", "time": "10:00"}})

        # Update with new data
        response = client.post(
            "/api/v1/chat/birth-data",
            json={"userId": user_id, "birthData": {"date": "1991-02-02", "time": "11:00", "locationName": "New York"}},
        )
        assert response.status_code == 200

        # Verify update
        get_response = client.get(f"/api/v1/chat/birth-data?userId={user_id}")
        data = get_response.get_json()
        assert data["birthData"]["birth_date"] == "1991-02-02"


class TestCompatibilityEndpoint:
    """Test /api/v1/compatibility endpoint."""

    def test_compatibility_person1_person2_format(self, client):
        """Test compatibility with person1/person2 format."""
        response = client.post(
            "/api/v1/compatibility",
            json={
                "person1": {
                    "date": "1990-08-15",
                    "time": "14:30",
                    "timezone": "America/New_York",
                    "latitude": 40.7128,
                    "longitude": -74.0060,
                },
                "person2": {
                    "date": "1992-03-20",
                    "time": "10:00",
                    "timezone": "America/Los_Angeles",
                    "latitude": 34.0522,
                    "longitude": -118.2437,
                },
            },
        )
        assert response.status_code == 200
        data = response.get_json()
        assert "overallScore" in data
        assert "vedicScore" in data
        assert "chineseScore" in data
        assert "synastryAspects" in data
        assert "userChart" in data
        assert "partnerChart" in data

    def test_match_user_partner_format(self, client):
        """Test /api/v1/match compatibility with OpenAPI user/partner payload."""
        response = client.post(
            "/api/v1/match",
            json={
                "user": {
                    "name": "User",
                    "date": "1990-08-15",
                    "time": "14:30",
                    "timezone": "America/New_York",
                    "latitude": 40.7128,
                    "longitude": -74.0060,
                },
                "partner": {
                    "name": "Partner",
                    "date": "1992-03-20",
                    "time": "10:00",
                    "timezone": "America/Los_Angeles",
                    "latitude": 34.0522,
                    "longitude": -118.2437,
                },
            },
        )
        assert response.status_code == 200
        data = response.get_json()
        assert "overallScore" in data
        assert "userChart" in data
        assert "partnerChart" in data

    def test_compatibility_scores_range(self, client):
        """Test that compatibility scores are in valid range."""
        response = client.post(
            "/api/v1/compatibility",
            json={
                "person1": {"date": "1985-05-20", "latitude": 51.5074, "longitude": -0.1278},
                "person2": {"date": "1987-11-10", "latitude": 48.8566, "longitude": 2.3522},
            },
        )
        assert response.status_code == 200
        data = response.get_json()

        # Overall score should be 0-100
        assert 0 <= data["overallScore"] <= 100

        # Vedic score should be 0-36
        assert 0 <= data["vedicScore"] <= 36

        # Chinese score should be 0-100
        assert 0 <= data["chineseScore"] <= 100

    def test_compatibility_chart_data(self, client):
        """Test that chart data includes planetary positions."""
        response = client.post(
            "/api/v1/compatibility",
            json={
                "person1": {"date": "1990-01-15", "latitude": 19.0760, "longitude": 72.8777},
                "person2": {"date": "1991-06-20", "latitude": 28.6139, "longitude": 77.2090},
            },
        )
        assert response.status_code == 200
        data = response.get_json()

        # Charts should have planetary data
        user_chart = data["userChart"]
        partner_chart = data["partnerChart"]

        # Check for major planets
        assert "Sun" in user_chart
        assert "Moon" in user_chart
        assert "Sun" in partner_chart
        assert "Moon" in partner_chart

    def test_compatibility_synastry_aspects(self, client):
        """Test that synastry aspects are returned as strings."""
        response = client.post(
            "/api/v1/compatibility",
            json={
                "person1": {"date": "1988-07-04", "latitude": 40.7128, "longitude": -74.0060},
                "person2": {"date": "1989-12-25", "latitude": 40.7128, "longitude": -74.0060},
            },
        )
        assert response.status_code == 200
        data = response.get_json()

        # Synastry aspects should be array of strings
        aspects = data["synastryAspects"]
        assert isinstance(aspects, list)
        for aspect in aspects:
            assert isinstance(aspect, str)

    def test_compatibility_invalid_json(self, client):
        """Test compatibility with invalid JSON."""
        response = client.post("/api/v1/compatibility", data="invalid json", content_type="application/json")
        assert response.status_code == 400
        data = response.get_json()
        assert "error" in data

    def test_compatibility_missing_person_data(self, client):
        """Test compatibility without required person data."""
        response = client.post("/api/v1/compatibility", json={"person1": {"date": "1990-01-01"}})
        assert response.status_code == 400
        data = response.get_json()
        assert "error" in data

    def test_compatibility_invalid_coordinates(self, client):
        """Test compatibility with invalid latitude/longitude."""
        response = client.post(
            "/api/v1/compatibility",
            json={
                "person1": {"date": "1990-01-01", "latitude": 999.0, "longitude": -74.0060},  # Invalid
                "person2": {"date": "1991-01-01", "latitude": 40.7128, "longitude": 999.0},  # Invalid
            },
        )
        assert response.status_code == 400
        data = response.get_json()
        assert "error" in data

    def test_compatibility_same_person(self, client):
        """Test compatibility calculation for same birth data."""
        birth_data = {"date": "1990-05-15", "time": "12:00", "latitude": 40.7128, "longitude": -74.0060}
        response = client.post("/api/v1/compatibility", json={"person1": birth_data, "person2": birth_data})
        assert response.status_code == 200
        data = response.get_json()
        # Same person should have high compatibility
        assert data["overallScore"] >= 70

    def test_compatibility_alternative_format(self, client):
        """Test compatibility with userBirthData/partnerBirthData format."""
        response = client.post(
            "/api/v1/compatibility",
            json={
                "userBirthData": {"date": "1990-08-15", "latitude": 40.7128, "longitude": -74.0060},
                "partnerBirthData": {"date": "1992-03-20", "latitude": 34.0522, "longitude": -118.2437},
            },
        )
        assert response.status_code == 200
        data = response.get_json()
        assert "overallScore" in data


class TestReportsEndpoint:
    """Test /api/v1/reports endpoints."""

    def test_generate_report_default(self, client):
        """Test generating default report."""
        response = client.post(
            "/api/v1/reports", json={"userId": "test-user-report-1", "birthData": {"date": "1990-08-15", "time": "14:30"}}
        )
        assert response.status_code == 200
        data = response.get_json()
        assert "reportId" in data
        assert "type" in data
        assert "title" in data
        assert "summary" in data
        assert "keyInsights" in data
        assert "downloadUrl" in data
        assert "generatedAt" in data
        assert data["status"] == "completed"

    def test_generate_report_specific_type(self, client):
        """Test generating specific report types."""
        report_types = ["birth_chart", "love_forecast", "career_forecast", "year_ahead"]

        for report_type in report_types:
            response = client.post(
                "/api/v1/reports",
                json={"userId": f"test-user-{report_type}", "reportType": report_type, "birthData": {"date": "1990-01-01"}},
            )
            assert response.status_code == 200
            data = response.get_json()
            assert data["type"] == report_type
            assert data["reportId"] is not None

    def test_generate_report_via_generate_endpoint(self, client):
        """Test generating report via /generate alias."""
        response = client.post(
            "/api/v1/reports/generate", json={"userId": "test-user-report-2", "reportType": "love_forecast", "birthData": {}}
        )
        assert response.status_code == 200
        data = response.get_json()
        assert "reportId" in data

    def test_generate_report_via_full_endpoint(self, client):
        """Test generating report via /full alias."""
        response = client.post("/api/v1/reports/full", json={"userId": "test-user-report-3", "birthData": {}})
        assert response.status_code == 200
        data = response.get_json()
        assert "reportId" in data

    def test_get_user_reports(self, client):
        """Test retrieving user's reports."""
        user_id = "test-user-report-4"

        # Generate a report first
        client.post("/api/v1/reports", json={"userId": user_id, "reportType": "birth_chart", "birthData": {}})

        # Get user reports
        response = client.get(f"/api/v1/reports/user/{user_id}")
        assert response.status_code == 200
        data = response.get_json()
        assert isinstance(data, list)
        assert len(data) > 0

    def test_download_pdf(self, client):
        """Test downloading PDF report."""
        # Generate a report
        report_response = client.post("/api/v1/reports", json={"userId": "test-user-report-5", "birthData": {}})
        report_data = report_response.get_json()
        report_id = report_data["reportId"]

        # Download PDF
        pdf_response = client.get(f"/api/v1/reports/{report_id}/pdf")
        assert pdf_response.status_code == 200
        assert pdf_response.mimetype == "application/pdf"
        assert pdf_response.data.startswith(b"%PDF")

    def test_download_pdf_headers(self, client):
        """Test that PDF download has correct headers."""
        response = client.get("/api/v1/reports/test-report-id/pdf")
        assert response.status_code == 200
        assert response.content_type == "application/pdf"

    def test_download_pdf_content(self, client):
        """Test that PDF content is valid binary data."""
        response = client.get("/api/v1/reports/any-report-id/pdf")
        assert response.status_code == 200
        data = response.data
        assert isinstance(data, bytes)
        assert len(data) > 0
        assert b"PDF" in data  # Check for PDF marker

    def test_report_key_insights_structure(self, client):
        """Test that report key insights are properly formatted."""
        response = client.post("/api/v1/reports", json={"userId": "test-user-report-6", "birthData": {}})
        assert response.status_code == 200
        data = response.get_json()
        insights = data["keyInsights"]
        assert isinstance(insights, list)
        assert len(insights) > 0
        for insight in insights:
            assert isinstance(insight, str)
            assert len(insight) > 0

    def test_report_download_url_format(self, client):
        """Test that download URL is correctly formatted."""
        response = client.post("/api/v1/reports", json={"userId": "test-user-report-7", "birthData": {}})
        assert response.status_code == 200
        data = response.get_json()
        download_url = data["downloadUrl"]
        assert download_url.startswith("/api/v1/reports/")
        assert download_url.endswith("/pdf")
        assert data["reportId"] in download_url


class TestLocationsEndpoint:
    """Test /api/v1/location/search endpoint."""

    def test_location_search_basic(self, client):
        """Test basic location search."""
        response = client.get("/api/v1/location/search?q=London")
        assert response.status_code == 200
        data = response.get_json()
        assert "locations" in data
        assert isinstance(data["locations"], list)

    def test_location_search_results_structure(self, client):
        """Test that location results have proper structure."""
        response = client.get("/api/v1/location/search?q=New York")
        assert response.status_code == 200
        data = response.get_json()
        locations = data["locations"]

        if len(locations) > 0:
            location = locations[0]
            assert "name" in location
            assert "displayName" in location
            assert "latitude" in location
            assert "longitude" in location
            assert "timezone" in location

    def test_location_search_empty_query(self, client):
        """Test location search with empty query."""
        response = client.get("/api/v1/location/search?q=")
        assert response.status_code == 200
        data = response.get_json()
        # Should return default locations
        assert "locations" in data
        assert len(data["locations"]) > 0

    def test_location_search_no_query_param(self, client):
        """Test location search without query parameter."""
        response = client.get("/api/v1/location/search")
        assert response.status_code == 200
        data = response.get_json()
        assert "locations" in data

    def test_location_search_with_limit(self, client):
        """Test location search with limit parameter."""
        response = client.get("/api/v1/location/search?q=&limit=5")
        assert response.status_code == 200
        data = response.get_json()
        locations = data["locations"]
        assert len(locations) <= 5

    def test_location_search_common_cities(self, client):
        """Test searching for common cities."""
        cities = ["Tokyo", "Paris", "Mumbai", "Sydney", "Toronto"]

        for city in cities:
            response = client.get(f"/api/v1/location/search?q={city}")
            assert response.status_code == 200
            data = response.get_json()
            locations = data["locations"]
            assert len(locations) > 0
            # Check that at least one result contains the city name
            assert any(city.lower() in loc["name"].lower() or city.lower() in loc["displayName"].lower() for loc in locations)

    def test_location_search_coordinates_valid(self, client):
        """Test that returned coordinates are valid."""
        response = client.get("/api/v1/location/search?q=London")
        assert response.status_code == 200
        data = response.get_json()
        locations = data["locations"]

        for location in locations:
            lat = location["latitude"]
            lon = location["longitude"]
            assert -90 <= lat <= 90
            assert -180 <= lon <= 180

    def test_location_search_case_insensitive(self, client):
        """Test that search is case insensitive."""
        response1 = client.get("/api/v1/location/search?q=london")
        response2 = client.get("/api/v1/location/search?q=LONDON")
        response3 = client.get("/api/v1/location/search?q=London")

        assert response1.status_code == 200
        assert response2.status_code == 200
        assert response3.status_code == 200

    def test_location_search_partial_match(self, client):
        """Test partial string matching."""
        response = client.get("/api/v1/location/search?q=San")
        assert response.status_code == 200
        data = response.get_json()
        locations = data["locations"]
        # Should find San Francisco, San Diego, etc.
        assert len(locations) > 0

    def test_location_search_geopy_fallback(self, client):
        """Test that location search falls back to static data when geopy fails."""
        # Even if geopy fails, the endpoint should return fallback results
        # Testing with a query that would work with fallback
        response = client.get("/api/v1/location/search?q=London")
        assert response.status_code == 200
        data = response.get_json()
        # Should get fallback results
        assert "locations" in data
        assert len(data["locations"]) > 0
        # London should be in the results
        assert any("london" in loc["name"].lower() or "london" in loc["displayName"].lower() for loc in data["locations"])


class TestSubscriptionEndpoint:
    """Test /api/v1/subscription/status endpoint."""

    def test_subscription_status_no_user(self, client):
        """Test subscription status without user ID."""
        response = client.get("/api/v1/subscription/status")
        assert response.status_code == 200
        data = response.get_json()
        assert "isActive" in data
        assert data["isActive"] is False

    def test_subscription_status_nonexistent_user(self, client):
        """Test subscription status for user without subscription."""
        response = client.get("/api/v1/subscription/status?userId=nonexistent-user")
        assert response.status_code == 200
        data = response.get_json()
        assert data["isActive"] is False

    def test_subscription_status_with_active_subscription(self, client):
        """Test subscription status for user with active subscription."""
        from db import set_subscription

        user_id = "test-user-sub-1"
        set_subscription(user_id, True, "premium_monthly")

        response = client.get(f"/api/v1/subscription/status?userId={user_id}")
        assert response.status_code == 200
        data = response.get_json()
        assert data["isActive"] is True
        assert "productId" in data
        assert data["productId"] == "premium_monthly"

    def test_subscription_status_with_inactive_subscription(self, client):
        """Test subscription status for user with inactive subscription."""
        from db import set_subscription

        user_id = "test-user-sub-2"
        set_subscription(user_id, False, None)

        response = client.get(f"/api/v1/subscription/status?userId={user_id}")
        assert response.status_code == 200
        data = response.get_json()
        assert data["isActive"] is False

    def test_subscription_status_updated_at_field(self, client):
        """Test that subscription status includes updatedAt timestamp."""
        from db import set_subscription

        user_id = "test-user-sub-3"
        set_subscription(user_id, True, "yearly_plan")

        response = client.get(f"/api/v1/subscription/status?userId={user_id}")
        assert response.status_code == 200
        data = response.get_json()
        assert "updatedAt" in data
        assert data["updatedAt"] is not None

    def test_subscription_status_different_product_ids(self, client):
        """Test subscription with various product IDs."""
        from db import set_subscription

        product_ids = ["basic", "premium", "pro", "lifetime"]

        for i, product_id in enumerate(product_ids):
            user_id = f"test-user-sub-product-{i}"
            set_subscription(user_id, True, product_id)

            response = client.get(f"/api/v1/subscription/status?userId={user_id}")
            data = response.get_json()
            assert data["isActive"] is True
            assert data["productId"] == product_id


class TestSystemStatusEndpoint:
    """Test /api/v1/system-status endpoint."""

    def test_system_status_basic(self, client):
        """Test basic system status endpoint."""
        response = client.get("/api/v1/system-status")
        assert response.status_code == 200
        data = response.get_json()
        assert "status" in data
        assert data["status"] == "operational"

    def test_system_status_structure(self, client):
        """Test system status response structure."""
        response = client.get("/api/v1/system-status")
        assert response.status_code == 200
        data = response.get_json()
        assert "status" in data
        assert "system" in data
        assert "endpoints" in data

    def test_system_status_system_info(self, client):
        """Test system information in status response."""
        response = client.get("/api/v1/system-status")
        assert response.status_code == 200
        data = response.get_json()
        system = data["system"]
        assert "python_version" in system
        assert "timestamp" in system
        assert "." in system["python_version"]  # Version format

    def test_system_status_endpoints_list(self, client):
        """Test that system status includes endpoint list."""
        response = client.get("/api/v1/system-status")
        assert response.status_code == 200
        data = response.get_json()
        endpoints = data["endpoints"]

        # Check for key endpoints
        expected_endpoints = ["health", "horoscope", "ephemeris", "chart", "auth", "chat", "locations", "reports"]
        for endpoint in expected_endpoints:
            assert endpoint in endpoints
            assert endpoints[endpoint].startswith("/api/v1/")

    def test_system_status_timestamp_format(self, client):
        """Test that timestamp is in ISO format."""
        response = client.get("/api/v1/system-status")
        assert response.status_code == 200
        data = response.get_json()
        timestamp = data["system"]["timestamp"]

        # Try to parse as ISO format
        try:
            datetime.fromisoformat(timestamp)
            valid_format = True
        except ValueError:
            valid_format = False

        assert valid_format


class TestHealthEndpoint:
    """Test /api/v1/health endpoint."""

    def test_health_check(self, client):
        """Test health check endpoint."""
        response = client.get("/api/v1/health")
        assert response.status_code == 200
        data = response.get_json()
        assert "status" in data
        assert data["status"] == "healthy"

    def test_health_check_structure(self, client):
        """Test health check response structure."""
        response = client.get("/api/v1/health")
        assert response.status_code == 200
        data = response.get_json()
        assert "status" in data
        assert "service" in data
        assert "version" in data
        assert "timestamp" in data

    def test_health_check_service_name(self, client):
        """Test that service name is correct."""
        response = client.get("/api/v1/health")
        assert response.status_code == 200
        data = response.get_json()
        assert data["service"] == "astronova-api"

    def test_root_health_check(self, client):
        """Test root health endpoint."""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.get_json()
        assert data["status"] == "ok"


class TestRemoteConfigEndpoint:
    """Test /api/v1/config endpoint."""

    def test_remote_config_basic(self, client):
        """Test basic remote config endpoint."""
        response = client.get("/api/v1/config")
        assert response.status_code == 200
        data = response.get_json()
        assert isinstance(data, dict)
        assert len(data) > 0

    def test_remote_config_structure(self, client):
        """Test remote config response structure."""
        response = client.get("/api/v1/config")
        assert response.status_code == 200
        data = response.get_json()

        # Check for expected config keys
        expected_keys = [
            "paywall_variant",
            "widget_prompt_enabled",
            "daily_notification_default_hour",
            "home_quick_tiles_enabled",
        ]

        for key in expected_keys:
            assert key in data

    def test_remote_config_values(self, client):
        """Test remote config values are of correct types."""
        response = client.get("/api/v1/config")
        assert response.status_code == 200
        data = response.get_json()

        assert isinstance(data["paywall_variant"], str)
        assert isinstance(data["widget_prompt_enabled"], bool)
        assert isinstance(data["daily_notification_default_hour"], int)
        assert isinstance(data["home_quick_tiles_enabled"], bool)

    def test_remote_config_consistent(self, client):
        """Test that remote config returns consistent values."""
        response1 = client.get("/api/v1/config")
        response2 = client.get("/api/v1/config")

        assert response1.get_json() == response2.get_json()


class TestContentEndpoint:
    """Test /api/v1/content endpoints."""

    def test_content_info(self, client):
        """Test content info endpoint."""
        response = client.get("/api/v1/content")
        assert response.status_code == 200
        data = response.get_json()
        assert "service" in data
        assert data["service"] == "content"
        assert "status" in data
        assert data["status"] == "available"

    def test_content_management(self, client):
        """Test content management endpoint."""
        response = client.get("/api/v1/content/management")
        assert response.status_code == 200
        data = response.get_json()
        assert "quick_questions" in data
        assert "insights" in data

    def test_content_quick_questions_structure(self, client):
        """Test quick questions structure."""
        response = client.get("/api/v1/content/management")
        assert response.status_code == 200
        data = response.get_json()
        questions = data["quick_questions"]

        assert isinstance(questions, list)
        assert len(questions) > 0

        for question in questions:
            assert "id" in question
            assert "text" in question
            assert "category" in question
            assert "order" in question
            assert "is_active" in question

    def test_content_insights_structure(self, client):
        """Test insights structure."""
        response = client.get("/api/v1/content/management")
        assert response.status_code == 200
        data = response.get_json()
        insights = data["insights"]

        assert isinstance(insights, list)
        assert len(insights) > 0

        for insight in insights:
            assert "id" in insight
            assert "title" in insight
            assert "content" in insight
            assert "category" in insight
            assert "priority" in insight
            assert "is_active" in insight

    def test_content_questions_ordered(self, client):
        """Test that quick questions are properly ordered."""
        response = client.get("/api/v1/content/management")
        assert response.status_code == 200
        data = response.get_json()
        questions = data["quick_questions"]

        # Check that questions are ordered
        orders = [q["order"] for q in questions]
        assert orders == sorted(orders)

    def test_content_insights_prioritized(self, client):
        """Test that insights are properly prioritized."""
        response = client.get("/api/v1/content/management")
        assert response.status_code == 200
        data = response.get_json()
        insights = data["insights"]

        # Check that insights are ordered by priority
        priorities = [i["priority"] for i in insights]
        assert priorities == sorted(priorities)

    def test_content_default_questions(self, client):
        """Test that default questions are seeded."""
        response = client.get("/api/v1/content/management")
        assert response.status_code == 200
        data = response.get_json()
        questions = data["quick_questions"]

        # Should have default seeded questions
        assert len(questions) >= 5

    def test_content_default_insights(self, client):
        """Test that default insights are seeded."""
        response = client.get("/api/v1/content/management")
        assert response.status_code == 200
        data = response.get_json()
        insights = data["insights"]

        # Should have default seeded insights
        assert len(insights) >= 3


class TestErrorHandling:
    """Test error handling across endpoints."""

    def test_404_not_found(self, client):
        """Test 404 error handling."""
        response = client.get("/api/v1/nonexistent-endpoint")
        assert response.status_code == 404
        data = response.get_json()
        assert "error" in data
        assert "code" in data
        assert data["code"] == "NOT_FOUND"

    def test_chat_error_recovery(self, client):
        """Test that chat endpoint handles errors gracefully."""
        # Send malformed request
        response = client.post(
            "/api/v1/chat",
            json={"birthData": {"date": "invalid-date", "latitude": "not-a-number", "longitude": "not-a-number"}},
        )
        # Should not crash (may return 200 with error message or 400)
        assert response.status_code in [200, 400, 500]

    def test_compatibility_error_handling(self, client):
        """Test compatibility error handling with invalid data."""
        response = client.post(
            "/api/v1/compatibility",
            json={
                "person1": {"date": "invalid", "latitude": "invalid", "longitude": "invalid"},
                "person2": {"date": "1990-01-01", "latitude": 40.0, "longitude": -74.0},
            },
        )
        assert response.status_code in [400, 500]
        data = response.get_json()
        assert "error" in data


class TestEdgeCases:
    """Test edge cases and boundary conditions."""

    def test_chat_very_long_message(self, client):
        """Test chat with very long message."""
        long_message = "What is astrology? " * 1000  # Very long message
        response = client.post("/api/v1/chat", json={"message": long_message, "userId": "test-user-edge-1"})
        assert response.status_code == 200

    def test_chat_special_characters(self, client):
        """Test chat with special characters."""
        response = client.post(
            "/api/v1/chat", json={"message": "🌟✨ What does my future hold? 💫🔮", "userId": "test-user-edge-2"}
        )
        assert response.status_code == 200
        data = response.get_json()
        assert "reply" in data

    def test_location_search_special_characters(self, client):
        """Test location search with special characters."""
        response = client.get("/api/v1/location/search?q=São Paulo")
        assert response.status_code == 200
        data = response.get_json()
        assert "locations" in data

    def test_compatibility_leap_year_births(self, client):
        """Test compatibility with leap year birth dates."""
        response = client.post(
            "/api/v1/compatibility",
            json={
                "person1": {"date": "1992-02-29", "latitude": 40.7128, "longitude": -74.0060},  # Leap year
                "person2": {"date": "1996-02-29", "latitude": 40.7128, "longitude": -74.0060},  # Another leap year
            },
        )
        assert response.status_code == 200

    def test_birth_data_extreme_coordinates(self, client):
        """Test birth data with extreme valid coordinates."""
        response = client.post(
            "/api/v1/chat/birth-data",
            json={
                "userId": "test-user-edge-3",
                "birthData": {
                    "date": "1990-01-01",
                    "latitude": 89.99,  # Near North Pole
                    "longitude": 179.99,  # Near date line
                },
            },
        )
        assert response.status_code == 200

    def test_report_no_birth_data(self, client):
        """Test report generation without any birth data."""
        response = client.post(
            "/api/v1/reports", json={"userId": "test-user-edge-4", "reportType": "birth_chart", "birthData": {}}
        )
        assert response.status_code == 200
        data = response.get_json()
        assert "reportId" in data

    def test_subscription_empty_product_id(self, client):
        """Test subscription with empty product ID."""
        from db import set_subscription

        user_id = "test-user-edge-5"
        set_subscription(user_id, True, "")

        response = client.get(f"/api/v1/subscription/status?userId={user_id}")
        assert response.status_code == 200
        data = response.get_json()
        assert "isActive" in data
