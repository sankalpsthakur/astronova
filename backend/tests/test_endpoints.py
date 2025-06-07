from flask import url_for

def test_health_endpoint(client):
    res = client.get('/health')
    assert res.status_code == 200
    assert res.get_json()['status'] == 'ok'

def test_ephemeris_positions(client):
    res = client.get('/api/v1/ephemeris/positions')
    assert res.status_code == 200
    data = res.get_json()
    assert 'sun' in data


def test_location_missing_address(client):
    res = client.get('/api/v1/misc/location')
    assert res.status_code == 400


def test_rate_limiting(client):
    for _ in range(2):
        assert client.get('/api/v1/ephemeris/positions').status_code == 200
    res = client.get('/api/v1/ephemeris/positions')
    assert res.status_code == 429
