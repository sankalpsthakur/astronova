"""Basic endpoint tests for the FastAPI application."""

from fastapi.testclient import TestClient

def test_health_endpoint(client: TestClient):
    res = client.get('/health')
    assert res.status_code == 200
    assert res.json()['status'] == 'ok'

def test_ephemeris_positions(client: TestClient):
    res = client.get('/api/v1/ephemeris/current')
    assert res.status_code == 200
    data = res.json()
    assert 'planets' in data


def test_location_missing_address(client: TestClient):
    res = client.get('/api/v1/locations/search')
    assert res.status_code == 422


def test_rate_limiting(client: TestClient):
    for _ in range(2):
        assert client.get('/api/v1/ephemeris/current').status_code == 200
    res = client.get('/api/v1/ephemeris/current')
    assert res.status_code == 429
