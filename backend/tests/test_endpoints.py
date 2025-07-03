import pytest
import requests
import json

BASE_URL = "http://localhost:5000"

def test_health_endpoint():
    """Test health endpoint - should work and bypass rate limiting"""
    res = requests.get(f"{BASE_URL}/health")
    assert res.status_code == 200
    assert res.json()['status'] == 'ok'

def test_ephemeris_positions():
    """Test ephemeris current positions"""
    res = requests.get(f"{BASE_URL}/api/v1/ephemeris/current")
    assert res.status_code == 200
    data = res.json()
    assert 'planets' in data
    assert len(data['planets']) > 0

def test_system_status_shows_correct_configs():
    """Test system status shows correct API configurations"""
    res = requests.get(f"{BASE_URL}/api/v1/misc/system-status")
    assert res.status_code == 200
    data = res.json()
    assert 'environment' in data
    # Should show correct configs
    assert 'gemini_api_configured' in data['environment']
    assert 'secret_key_configured' in data['environment']
    # Should NOT show deprecated configs
    assert 'google_places_configured' not in data['environment']
    assert 'redis_configured' not in data['environment']

def test_location_services_removed():
    """Test location services are completely removed"""
    res = requests.get(f"{BASE_URL}/api/v1/locations/search?query=New York")
    assert res.status_code == 404

def test_chart_generation_fixed_validation():
    """Test chart generation accepts flat structure"""
    data = {
        "birth_date": "1990-01-01",
        "birth_time": "12:00",
        "latitude": 40.7128,
        "longitude": -74.0060,
        "timezone": "America/New_York",
        "system": "western",
        "chart_type": "natal"
    }
    res = requests.post(f"{BASE_URL}/api/v1/chart/generate", json=data)
    assert res.status_code == 200
    result = res.json()
    assert 'chartId' in result
    assert 'charts' in result
    assert 'western' in result['charts']

def test_match_analysis_fixed_validation():
    """Test match analysis accepts person1/person2 structure"""
    data = {
        "person1": {
            "birth_date": "1990-01-01",
            "birth_time": "12:00",
            "latitude": 40.7128,
            "longitude": -74.0060,
            "timezone": "America/New_York"
        },
        "person2": {
            "birth_date": "1992-06-15",
            "birth_time": "14:30",
            "latitude": 34.0522,
            "longitude": -118.2437,
            "timezone": "America/Los_Angeles"
        },
        "systems": ["western"],
        "match_type": "compatibility"
    }
    res = requests.post(f"{BASE_URL}/api/v1/match", json=data)
    assert res.status_code == 200
    result = res.json()
    assert 'overallScore' in result
    assert 'userChart' in result
    assert 'partnerChart' in result

def test_service_info_excludes_location_services():
    """Test service info no longer includes location services"""
    res = requests.get(f"{BASE_URL}/api/v1/misc/info")
    assert res.status_code == 200
    data = res.json()
    assert 'endpoints' in data
    # Should NOT include locations
    assert 'locations' not in data['endpoints']
    # Should include other services
    assert 'chat' in data['endpoints']
    assert 'chart' in data['endpoints']
    assert 'ephemeris' in data['endpoints']
