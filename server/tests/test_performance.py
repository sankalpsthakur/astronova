"""
Comprehensive performance and regression tests for AstroNova server.

Benchmarks:
- Chart generation latency (target: <500ms)
- Dasha timeline calculation (target: <1s for 120 years)
- Compatibility scoring (target: <1s)
- Horoscope generation (target: <200ms)
- Database query performance (target: <50ms)
- Concurrent request handling (10+ simultaneous requests)
- Memory leak detection (repeated calls should not grow memory)
- Large payload handling
"""

from __future__ import annotations

import gc
import os
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timedelta

import pytest
from memory_profiler import memory_usage

try:  # pragma: no cover - optional dependency in some environments
    import swisseph as _swe  # noqa: F401
except Exception:  # pragma: no cover
    pytest.skip("pyswisseph not installed", allow_module_level=True)


def _make_auth_client(client):
    """Helper to add JWT auth to a test client."""
    import jwt as pyjwt

    secret = os.environ.get("JWT_SECRET", "astronova-dev-secret-change-in-production")
    payload = {
        "sub": "perf-test-user",
        "email": "perf@test.com",
        "iat": datetime.utcnow(),
        "exp": datetime.utcnow() + timedelta(days=1),
    }
    token = pyjwt.encode(payload, secret, algorithm="HS256")
    client.environ_base["HTTP_AUTHORIZATION"] = f"Bearer {token}"
    return client


class TestChartGenerationPerformance:
    """Test chart generation performance benchmarks."""

    @pytest.fixture
    def client(self):
        from app import create_app

        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    @pytest.fixture
    def authenticated_client(self, client):
        return _make_auth_client(client)

    @pytest.fixture
    def valid_chart_data(self):
        return {
            "birthData": {
                "date": "1990-01-15",
                "time": "14:30",
                "latitude": 19.0760,
                "longitude": 72.8777,
                "timezone": "Asia/Kolkata",
            }
        }

    def test_chart_generation_latency(self, authenticated_client, valid_chart_data, benchmark):
        """Benchmark chart generation (target: <500ms)."""

        def generate_chart():
            response = authenticated_client.post("/api/v1/chart/generate", json=valid_chart_data)
            assert response.status_code == 200
            return response.get_json()

        result = benchmark(generate_chart)
        assert result is not None
        assert "chartId" in result

        # Check benchmark stats
        stats = benchmark.stats.stats
        mean_time = stats.mean
        assert mean_time < 0.5, f"Chart generation too slow: {mean_time*1000:.2f}ms > 500ms"

    def test_chart_aspects_calculation_latency(self, authenticated_client, valid_chart_data, benchmark):
        """Benchmark chart aspects calculation (target: <500ms)."""

        def calculate_aspects():
            response = authenticated_client.post("/api/v1/chart/aspects", json=valid_chart_data)
            assert response.status_code == 200
            return response.get_json()

        result = benchmark(calculate_aspects)
        assert result is not None

        stats = benchmark.stats.stats
        mean_time = stats.mean
        assert mean_time < 0.5, f"Aspects calculation too slow: {mean_time*1000:.2f}ms > 500ms"

    def test_chart_generation_memory_stability(self, authenticated_client, valid_chart_data):
        """Test for memory leaks in repeated chart generation."""
        gc.collect()

        def generate_charts_repeatedly():
            for _ in range(50):
                response = authenticated_client.post("/api/v1/chart/generate", json=valid_chart_data)
                assert response.status_code == 200

        mem_usage = memory_usage(generate_charts_repeatedly, interval=0.1)

        # Memory should not grow significantly
        initial_mem = mem_usage[0]
        max_mem = max(mem_usage)
        mem_growth = max_mem - initial_mem

        # Allow up to 50MB growth for 50 requests (1MB per request is reasonable)
        assert mem_growth < 50, f"Memory leak detected: {mem_growth:.2f}MB growth"


class TestDashaPerformance:
    """Test dasha calculation performance benchmarks."""

    @pytest.fixture
    def client(self):
        from app import create_app

        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    @pytest.fixture
    def authenticated_client(self, client):
        return _make_auth_client(client)

    @pytest.fixture
    def dasha_birth_data(self):
        return {"date": "1990-01-15", "time": "14:30", "timezone": "Asia/Kolkata", "latitude": 19.0760, "longitude": 72.8777}

    def test_dasha_timeline_120_years(self, authenticated_client, dasha_birth_data, benchmark):
        """Benchmark dasha timeline for 120 years (target: <1s)."""

        def calculate_full_timeline():
            response = authenticated_client.post(
                "/api/v1/astrology/dashas/complete",
                json={"birthData": dasha_birth_data, "targetDate": "2025-01-01", "includeTransitions": True},
            )
            assert response.status_code == 200
            return response.get_json()

        result = benchmark(calculate_full_timeline)
        assert result is not None

        stats = benchmark.stats.stats
        mean_time = stats.mean
        assert mean_time < 1.0, f"Dasha timeline too slow: {mean_time*1000:.2f}ms > 1000ms"

    def test_dasha_get_endpoint_latency(self, authenticated_client, benchmark):
        """Benchmark GET dasha endpoint (target: <500ms)."""

        def get_dasha():
            response = authenticated_client.get(
                "/api/v1/astrology/dashas",
                query_string={
                    "birth_date": "1990-01-15",
                    "birth_time": "14:30",
                    "timezone": "Asia/Kolkata",
                    "target_date": "2025-01-01",
                },
            )
            assert response.status_code == 200
            return response.get_json()

        result = benchmark(get_dasha)
        assert result is not None

        stats = benchmark.stats.stats
        mean_time = stats.mean
        assert mean_time < 0.5, f"Dasha GET too slow: {mean_time*1000:.2f}ms > 500ms"

    def test_dasha_with_boundaries_performance(self, authenticated_client, benchmark):
        """Benchmark dasha with antardasha boundaries (target: <1s)."""

        def get_dasha_boundaries():
            response = authenticated_client.get(
                "/api/v1/astrology/dashas",
                query_string={
                    "birth_date": "1990-01-15",
                    "birth_time": "14:30",
                    "timezone": "Asia/Kolkata",
                    "target_date": "2025-01-01",
                    "include_boundaries": "true",
                },
            )
            assert response.status_code == 200
            return response.get_json()

        result = benchmark(get_dasha_boundaries)
        assert result is not None

        stats = benchmark.stats.stats
        mean_time = stats.mean
        assert mean_time < 1.0, f"Dasha boundaries too slow: {mean_time*1000:.2f}ms > 1000ms"


class TestCompatibilityPerformance:
    """Test compatibility calculation performance benchmarks."""

    @pytest.fixture
    def client(self):
        from app import create_app

        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    @pytest.fixture
    def authenticated_client(self, client):
        return _make_auth_client(client)

    @pytest.fixture
    def compatibility_data(self):
        return {
            "person1": {
                "date": "1990-01-15",
                "time": "14:30",
                "latitude": 19.0760,
                "longitude": 72.8777,
                "timezone": "Asia/Kolkata",
            },
            "person2": {
                "date": "1992-06-20",
                "time": "10:00",
                "latitude": 28.6139,
                "longitude": 77.2090,
                "timezone": "Asia/Kolkata",
            },
        }

    def test_compatibility_scoring_latency(self, authenticated_client, compatibility_data, benchmark):
        """Benchmark compatibility scoring (target: <1s)."""

        def calculate_compatibility():
            response = authenticated_client.post("/api/v1/compatibility", json=compatibility_data)
            assert response.status_code == 200
            return response.get_json()

        result = benchmark(calculate_compatibility)
        assert result is not None

        stats = benchmark.stats.stats
        mean_time = stats.mean
        assert mean_time < 1.0, f"Compatibility scoring too slow: {mean_time*1000:.2f}ms > 1000ms"


class TestHoroscopePerformance:
    """Test horoscope generation performance benchmarks."""

    @pytest.fixture
    def client(self):
        from app import create_app

        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    @pytest.fixture
    def authenticated_client(self, client):
        return _make_auth_client(client)

    def test_horoscope_generation_latency(self, authenticated_client, benchmark):
        """Benchmark horoscope generation (target: <200ms)."""

        def generate_horoscope():
            response = authenticated_client.get("/api/v1/horoscope?sign=aries&type=daily")
            assert response.status_code == 200
            return response.get_json()

        result = benchmark(generate_horoscope)
        assert result is not None

        stats = benchmark.stats.stats
        mean_time = stats.mean
        assert mean_time < 0.2, f"Horoscope generation too slow: {mean_time*1000:.2f}ms > 200ms"

    @pytest.mark.parametrize(
        "sign",
        [
            "aries",
            "taurus",
            "gemini",
            "cancer",
            "leo",
            "virgo",
            "libra",
            "scorpio",
            "sagittarius",
            "capricorn",
            "aquarius",
            "pisces",
        ],
    )
    def test_all_signs_horoscope_performance(self, authenticated_client, sign, benchmark):
        """Benchmark horoscope for all zodiac signs (target: <200ms each)."""

        def generate_horoscope():
            response = authenticated_client.get(f"/api/v1/horoscope?sign={sign}&type=daily")
            assert response.status_code == 200
            return response.get_json()

        result = benchmark(generate_horoscope)
        assert result is not None
        assert result["sign"] == sign

        stats = benchmark.stats.stats
        mean_time = stats.mean
        assert mean_time < 0.2, f"Horoscope for {sign} too slow: {mean_time*1000:.2f}ms > 200ms"


class TestDatabasePerformance:
    """Test database query performance benchmarks."""

    @pytest.fixture
    def client(self):
        from app import create_app

        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    @pytest.fixture
    def authenticated_client(self, client):
        return _make_auth_client(client)

    def test_user_reports_query_latency(self, authenticated_client, benchmark):
        """Benchmark user reports query (target: <50ms)."""
        # First create some reports
        report_data = {
            "birthData": {
                "date": "1990-01-15",
                "time": "14:30",
                "latitude": 19.0760,
                "longitude": 72.8777,
                "timezone": "Asia/Kolkata",
            },
            "reportType": "birth_chart",
            "userId": "perf-test-user",
        }

        # Create a report
        authenticated_client.post("/api/v1/reports", json=report_data)

        def query_user_reports():
            response = authenticated_client.get("/api/v1/reports/user/perf-test-user")
            assert response.status_code == 200
            return response.get_json()

        result = benchmark(query_user_reports)
        assert result is not None

        stats = benchmark.stats.stats
        mean_time = stats.mean
        assert mean_time < 0.05, f"DB query too slow: {mean_time*1000:.2f}ms > 50ms"

    def test_subscription_status_query_latency(self, authenticated_client, benchmark):
        """Benchmark subscription status query (target: <50ms)."""

        def query_subscription():
            response = authenticated_client.get("/api/v1/subscription/status?userId=perf-test-user")
            assert response.status_code == 200
            return response.get_json()

        result = benchmark(query_subscription)
        assert result is not None

        stats = benchmark.stats.stats
        mean_time = stats.mean
        assert mean_time < 0.05, f"Subscription query too slow: {mean_time*1000:.2f}ms > 50ms"


class TestConcurrentRequestHandling:
    """Test concurrent request handling performance."""

    def test_concurrent_horoscope_requests(self, authenticated_client):
        """Test handling 10 simultaneous horoscope requests."""
        signs = ["aries", "taurus", "gemini", "cancer", "leo", "virgo", "libra", "scorpio", "sagittarius", "capricorn"]

        def fetch_horoscope(sign):
            response = authenticated_client.get(f"/api/v1/horoscope?sign={sign}&type=daily")
            return response.status_code, response.get_json()

        start_time = datetime.now()

        with ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(fetch_horoscope, sign) for sign in signs]
            results = [future.result() for future in as_completed(futures)]

        elapsed_time = (datetime.now() - start_time).total_seconds()

        # All should succeed
        assert all(status == 200 for status, _ in results)

        # Should complete in reasonable time (10 concurrent requests < 2 seconds)
        assert elapsed_time < 2.0, f"Concurrent requests too slow: {elapsed_time:.2f}s > 2s"

    def test_concurrent_chart_generation(self, authenticated_client):
        """Test handling 10 simultaneous chart generation requests."""
        chart_data = {
            "birthData": {
                "date": "1990-01-15",
                "time": "14:30",
                "latitude": 19.0760,
                "longitude": 72.8777,
                "timezone": "Asia/Kolkata",
            }
        }

        def generate_chart(index):
            response = authenticated_client.post("/api/v1/chart/generate", json=chart_data)
            return response.status_code, response.get_json()

        start_time = datetime.now()

        with ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(generate_chart, i) for i in range(10)]
            results = [future.result() for future in as_completed(futures)]

        elapsed_time = (datetime.now() - start_time).total_seconds()

        # All should succeed
        assert all(status == 200 for status, _ in results)

        # Should complete in reasonable time
        assert elapsed_time < 5.0, f"Concurrent chart generation too slow: {elapsed_time:.2f}s > 5s"

    def test_concurrent_dasha_calculations(self, authenticated_client):
        """Test handling 10 simultaneous dasha calculations."""

        def calculate_dasha(index):
            response = authenticated_client.get(
                "/api/v1/astrology/dashas",
                query_string={
                    "birth_date": "1990-01-15",
                    "birth_time": "14:30",
                    "timezone": "Asia/Kolkata",
                    "target_date": "2025-01-01",
                },
            )
            return response.status_code, response.get_json()

        start_time = datetime.now()

        with ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(calculate_dasha, i) for i in range(10)]
            results = [future.result() for future in as_completed(futures)]

        elapsed_time = (datetime.now() - start_time).total_seconds()

        # All should succeed
        assert all(status == 200 for status, _ in results)

        # Should complete in reasonable time
        assert elapsed_time < 5.0, f"Concurrent dasha calculations too slow: {elapsed_time:.2f}s > 5s"


class TestLargePayloadHandling:
    """Test handling of large payloads and edge cases."""

    @pytest.fixture
    def client(self):
        from app import create_app

        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    @pytest.fixture
    def authenticated_client(self, client):
        return _make_auth_client(client)

    def test_max_birth_data_size(self, authenticated_client):
        """Test maximum reasonable birth data payload."""
        large_birth_data = {
            "birthData": {
                "date": "1990-01-15",
                "time": "14:30",
                "latitude": 19.0760,
                "longitude": 72.8777,
                "timezone": "Asia/Kolkata",
                # Add extra fields that might be sent
                "name": "A" * 1000,  # Large name
                "notes": "B" * 5000,  # Large notes
                "extra_data": "C" * 10000,  # Extra data
            }
        }

        response = authenticated_client.post("/api/v1/chart/generate", json=large_birth_data)

        # Should handle gracefully (either succeed or return proper error)
        assert response.status_code in [200, 400, 413]

    def test_many_concurrent_reports_query(self, authenticated_client):
        """Test querying reports for user with many reports."""
        # Create 50 reports for a user
        for i in range(50):
            report_data = {
                "birthData": {
                    "date": "1990-01-15",
                    "time": "14:30",
                    "latitude": 19.0760,
                    "longitude": 72.8777,
                    "timezone": "Asia/Kolkata",
                },
                "reportType": "birth_chart",
                "userId": "heavy-user",
            }
            response = authenticated_client.post("/api/v1/reports", json=report_data)
            assert response.status_code == 200

        # Query all reports
        start_time = datetime.now()
        response = authenticated_client.get("/api/v1/reports/user/heavy-user")
        elapsed_time = (datetime.now() - start_time).total_seconds()

        assert response.status_code == 200
        data = response.get_json()

        # Should return all reports
        assert len(data) >= 50

        # Should complete in reasonable time
        assert elapsed_time < 0.5, f"Large report query too slow: {elapsed_time*1000:.2f}ms > 500ms"


class TestMemoryLeakDetection:
    """Test for memory leaks in repeated operations."""

    @pytest.fixture
    def client(self):
        from app import create_app

        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    @pytest.fixture
    def authenticated_client(self, client):
        return _make_auth_client(client)

    def test_repeated_horoscope_calls_no_leak(self, authenticated_client):
        """Test that repeated horoscope calls don't leak memory."""
        gc.collect()

        def generate_horoscopes():
            for i in range(100):
                response = authenticated_client.get("/api/v1/horoscope?sign=aries&type=daily")
                assert response.status_code == 200

        mem_usage = memory_usage(generate_horoscopes, interval=0.1)

        initial_mem = mem_usage[0]
        max_mem = max(mem_usage)
        mem_growth = max_mem - initial_mem

        # Allow up to 30MB growth for 100 requests
        assert mem_growth < 30, f"Memory leak in horoscope: {mem_growth:.2f}MB growth"

    def test_repeated_dasha_calls_no_leak(self, authenticated_client):
        """Test that repeated dasha calls don't leak memory."""
        gc.collect()

        def calculate_dashas():
            for i in range(50):
                response = authenticated_client.get(
                    "/api/v1/astrology/dashas",
                    query_string={
                        "birth_date": "1990-01-15",
                        "birth_time": "14:30",
                        "timezone": "Asia/Kolkata",
                        "target_date": "2025-01-01",
                    },
                )
                assert response.status_code == 200

        mem_usage = memory_usage(calculate_dashas, interval=0.1)

        initial_mem = mem_usage[0]
        max_mem = max(mem_usage)
        mem_growth = max_mem - initial_mem

        # Allow up to 40MB growth for 50 dasha calculations
        assert mem_growth < 40, f"Memory leak in dasha: {mem_growth:.2f}MB growth"


class TestEphemerisPerformance:
    """Test ephemeris and planetary position calculation performance."""

    @pytest.fixture
    def client(self):
        from app import create_app

        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    @pytest.fixture
    def authenticated_client(self, client):
        return _make_auth_client(client)

    def test_current_positions_latency(self, authenticated_client, benchmark):
        """Benchmark current planetary positions (target: <100ms)."""

        def get_positions():
            response = authenticated_client.get("/api/v1/ephemeris/current")
            assert response.status_code == 200
            return response.get_json()

        result = benchmark(get_positions)
        assert result is not None

        stats = benchmark.stats.stats
        mean_time = stats.mean
        assert mean_time < 0.1, f"Ephemeris too slow: {mean_time*1000:.2f}ms > 100ms"

    def test_positions_at_date_latency(self, authenticated_client, benchmark):
        """Benchmark planetary positions at specific date (target: <100ms)."""

        def get_positions_at_date():
            response = authenticated_client.get("/api/v1/ephemeris/at?date=2025-01-01")
            assert response.status_code == 200
            return response.get_json()

        result = benchmark(get_positions_at_date)
        assert result is not None

        stats = benchmark.stats.stats
        mean_time = stats.mean
        assert mean_time < 0.1, f"Ephemeris at date too slow: {mean_time*1000:.2f}ms > 100ms"


class TestReportGenerationPerformance:
    """Test report generation performance benchmarks."""

    @pytest.fixture
    def client(self):
        from app import create_app

        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    @pytest.fixture
    def authenticated_client(self, client):
        return _make_auth_client(client)

    @pytest.fixture
    def report_data(self):
        return {
            "birthData": {
                "date": "1990-01-15",
                "time": "14:30",
                "latitude": 19.0760,
                "longitude": 72.8777,
                "timezone": "Asia/Kolkata",
            },
            "reportType": "birth_chart",
            "userId": "report-perf-test",
        }

    def test_report_generation_latency(self, authenticated_client, report_data, benchmark):
        """Benchmark report generation (target: <1s)."""

        def generate_report():
            response = authenticated_client.post("/api/v1/reports", json=report_data)
            assert response.status_code == 200
            return response.get_json()

        result = benchmark(generate_report)
        assert result is not None
        assert "reportId" in result

        stats = benchmark.stats.stats
        mean_time = stats.mean
        assert mean_time < 1.0, f"Report generation too slow: {mean_time*1000:.2f}ms > 1000ms"


class TestAuthenticationPerformance:
    """Test authentication endpoint performance."""

    @pytest.fixture
    def client(self):
        from app import create_app

        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    @pytest.fixture
    def authenticated_client(self, client):
        return _make_auth_client(client)

    def test_apple_auth_latency(self, authenticated_client, benchmark):
        """Benchmark Apple authentication (target: <200ms)."""

        def authenticate():
            response = authenticated_client.post("/api/v1/auth/apple", json={"userIdentifier": "perf-test-user", "email": "perf@test.com"})
            assert response.status_code == 200
            return response.get_json()

        result = benchmark(authenticate)
        assert result is not None

        stats = benchmark.stats.stats
        mean_time = stats.mean
        assert mean_time < 0.2, f"Auth too slow: {mean_time*1000:.2f}ms > 200ms"

    def test_token_validation_latency(self, authenticated_client, benchmark):
        """Benchmark token validation (target: <50ms)."""

        def validate_token():
            response = authenticated_client.get("/api/v1/auth/validate")
            assert response.status_code == 200
            return response.get_json()

        result = benchmark(validate_token)
        assert result is not None

        stats = benchmark.stats.stats
        mean_time = stats.mean
        assert mean_time < 0.05, f"Token validation too slow: {mean_time*1000:.2f}ms > 50ms"


class TestLocationSearchPerformance:
    """Test location search performance benchmarks."""

    @pytest.fixture
    def client(self):
        from app import create_app

        app = create_app()
        app.config["TESTING"] = True
        with app.test_client() as client:
            yield client

    @pytest.fixture
    def authenticated_client(self, client):
        return _make_auth_client(client)

    def test_location_search_latency(self, authenticated_client, benchmark):
        """Benchmark location search (target: <500ms)."""

        def search_location():
            response = authenticated_client.get("/api/v1/location/search?q=Mumbai&limit=5")
            assert response.status_code == 200
            return response.get_json()

        result = benchmark(search_location)
        assert result is not None

        stats = benchmark.stats.stats
        mean_time = stats.mean
        # Location search may be slower due to external API
        assert mean_time < 2.0, f"Location search too slow: {mean_time*1000:.2f}ms > 2000ms"
