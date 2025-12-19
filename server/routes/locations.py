from __future__ import annotations

from typing import Dict, List

from flask import Blueprint, jsonify, request

try:
    from geopy.exc import GeocoderServiceError  # type: ignore
    from geopy.geocoders import Nominatim  # type: ignore
except ImportError:  # pragma: no cover
    Nominatim = None  # type: ignore
    GeocoderServiceError = Exception  # type: ignore

locations_bp = Blueprint("locations", __name__)


def _fallback_locations(q: str, limit: int) -> List[Dict[str, object]]:
    samples = [
        # United States
        {
            "name": "New York",
            "displayName": "New York, NY, USA",
            "latitude": 40.7128,
            "longitude": -74.0060,
            "state": "New York",
            "country": "USA",
            "timezone": "America/New_York",
        },
        {
            "name": "Los Angeles",
            "displayName": "Los Angeles, CA, USA",
            "latitude": 34.0522,
            "longitude": -118.2437,
            "state": "California",
            "country": "USA",
            "timezone": "America/Los_Angeles",
        },
        {
            "name": "Chicago",
            "displayName": "Chicago, IL, USA",
            "latitude": 41.8781,
            "longitude": -87.6298,
            "state": "Illinois",
            "country": "USA",
            "timezone": "America/Chicago",
        },
        {
            "name": "Houston",
            "displayName": "Houston, TX, USA",
            "latitude": 29.7604,
            "longitude": -95.3698,
            "state": "Texas",
            "country": "USA",
            "timezone": "America/Chicago",
        },
        {
            "name": "Phoenix",
            "displayName": "Phoenix, AZ, USA",
            "latitude": 33.4484,
            "longitude": -112.0740,
            "state": "Arizona",
            "country": "USA",
            "timezone": "America/Phoenix",
        },
        {
            "name": "San Francisco",
            "displayName": "San Francisco, CA, USA",
            "latitude": 37.7749,
            "longitude": -122.4194,
            "state": "California",
            "country": "USA",
            "timezone": "America/Los_Angeles",
        },
        {
            "name": "Seattle",
            "displayName": "Seattle, WA, USA",
            "latitude": 47.6062,
            "longitude": -122.3321,
            "state": "Washington",
            "country": "USA",
            "timezone": "America/Los_Angeles",
        },
        {
            "name": "Miami",
            "displayName": "Miami, FL, USA",
            "latitude": 25.7617,
            "longitude": -80.1918,
            "state": "Florida",
            "country": "USA",
            "timezone": "America/New_York",
        },
        {
            "name": "Boston",
            "displayName": "Boston, MA, USA",
            "latitude": 42.3601,
            "longitude": -71.0589,
            "state": "Massachusetts",
            "country": "USA",
            "timezone": "America/New_York",
        },
        {
            "name": "Denver",
            "displayName": "Denver, CO, USA",
            "latitude": 39.7392,
            "longitude": -104.9903,
            "state": "Colorado",
            "country": "USA",
            "timezone": "America/Denver",
        },
        # United Kingdom
        {
            "name": "London",
            "displayName": "London, UK",
            "latitude": 51.5074,
            "longitude": -0.1278,
            "state": None,
            "country": "UK",
            "timezone": "Europe/London",
        },
        {
            "name": "Manchester",
            "displayName": "Manchester, UK",
            "latitude": 53.4808,
            "longitude": -2.2426,
            "state": None,
            "country": "UK",
            "timezone": "Europe/London",
        },
        {
            "name": "Edinburgh",
            "displayName": "Edinburgh, Scotland, UK",
            "latitude": 55.9533,
            "longitude": -3.1883,
            "state": "Scotland",
            "country": "UK",
            "timezone": "Europe/London",
        },
        # India
        {
            "name": "Mumbai",
            "displayName": "Mumbai, Maharashtra, India",
            "latitude": 19.0760,
            "longitude": 72.8777,
            "state": "Maharashtra",
            "country": "India",
            "timezone": "Asia/Kolkata",
        },
        {
            "name": "Delhi",
            "displayName": "New Delhi, Delhi, India",
            "latitude": 28.6139,
            "longitude": 77.2090,
            "state": "Delhi",
            "country": "India",
            "timezone": "Asia/Kolkata",
        },
        {
            "name": "Bangalore",
            "displayName": "Bangalore, Karnataka, India",
            "latitude": 12.9716,
            "longitude": 77.5946,
            "state": "Karnataka",
            "country": "India",
            "timezone": "Asia/Kolkata",
        },
        {
            "name": "Chennai",
            "displayName": "Chennai, Tamil Nadu, India",
            "latitude": 13.0827,
            "longitude": 80.2707,
            "state": "Tamil Nadu",
            "country": "India",
            "timezone": "Asia/Kolkata",
        },
        # Europe
        {
            "name": "Paris",
            "displayName": "Paris, France",
            "latitude": 48.8566,
            "longitude": 2.3522,
            "state": None,
            "country": "France",
            "timezone": "Europe/Paris",
        },
        {
            "name": "Berlin",
            "displayName": "Berlin, Germany",
            "latitude": 52.5200,
            "longitude": 13.4050,
            "state": None,
            "country": "Germany",
            "timezone": "Europe/Berlin",
        },
        {
            "name": "Rome",
            "displayName": "Rome, Italy",
            "latitude": 41.9028,
            "longitude": 12.4964,
            "state": None,
            "country": "Italy",
            "timezone": "Europe/Rome",
        },
        {
            "name": "Madrid",
            "displayName": "Madrid, Spain",
            "latitude": 40.4168,
            "longitude": -3.7038,
            "state": None,
            "country": "Spain",
            "timezone": "Europe/Madrid",
        },
        {
            "name": "Amsterdam",
            "displayName": "Amsterdam, Netherlands",
            "latitude": 52.3676,
            "longitude": 4.9041,
            "state": None,
            "country": "Netherlands",
            "timezone": "Europe/Amsterdam",
        },
        # Asia-Pacific
        {
            "name": "Tokyo",
            "displayName": "Tokyo, Japan",
            "latitude": 35.6762,
            "longitude": 139.6503,
            "state": None,
            "country": "Japan",
            "timezone": "Asia/Tokyo",
        },
        {
            "name": "Singapore",
            "displayName": "Singapore",
            "latitude": 1.3521,
            "longitude": 103.8198,
            "state": None,
            "country": "Singapore",
            "timezone": "Asia/Singapore",
        },
        {
            "name": "Sydney",
            "displayName": "Sydney, NSW, Australia",
            "latitude": -33.8688,
            "longitude": 151.2093,
            "state": "New South Wales",
            "country": "Australia",
            "timezone": "Australia/Sydney",
        },
        {
            "name": "Melbourne",
            "displayName": "Melbourne, VIC, Australia",
            "latitude": -37.8136,
            "longitude": 144.9631,
            "state": "Victoria",
            "country": "Australia",
            "timezone": "Australia/Melbourne",
        },
        {
            "name": "Hong Kong",
            "displayName": "Hong Kong",
            "latitude": 22.3193,
            "longitude": 114.1694,
            "state": None,
            "country": "Hong Kong",
            "timezone": "Asia/Hong_Kong",
        },
        # Canada
        {
            "name": "Toronto",
            "displayName": "Toronto, ON, Canada",
            "latitude": 43.6532,
            "longitude": -79.3832,
            "state": "Ontario",
            "country": "Canada",
            "timezone": "America/Toronto",
        },
        {
            "name": "Vancouver",
            "displayName": "Vancouver, BC, Canada",
            "latitude": 49.2827,
            "longitude": -123.1207,
            "state": "British Columbia",
            "country": "Canada",
            "timezone": "America/Vancouver",
        },
        # Middle East
        {
            "name": "Dubai",
            "displayName": "Dubai, UAE",
            "latitude": 25.2048,
            "longitude": 55.2708,
            "state": None,
            "country": "UAE",
            "timezone": "Asia/Dubai",
        },
        # South America
        {
            "name": "São Paulo",
            "displayName": "São Paulo, Brazil",
            "latitude": -23.5505,
            "longitude": -46.6333,
            "state": "São Paulo",
            "country": "Brazil",
            "timezone": "America/Sao_Paulo",
        },
        {
            "name": "Mexico City",
            "displayName": "Mexico City, Mexico",
            "latitude": 19.4326,
            "longitude": -99.1332,
            "state": None,
            "country": "Mexico",
            "timezone": "America/Mexico_City",
        },
    ]
    if not q:
        return samples[:limit]
    q_lower = q.lower()
    # Search in name, displayName, state, and country for better matching
    matches = [
        s
        for s in samples
        if q_lower in s["displayName"].lower()
        or q_lower in s["name"].lower()
        or (s["state"] and q_lower in s["state"].lower())
        or (s["country"] and q_lower in s["country"].lower())
    ]
    return matches[:limit]


@locations_bp.route("/search", methods=["GET"])
def search():
    q = (request.args.get("q") or "").strip()
    try:
        limit = int(request.args.get("limit", 10))
    except (TypeError, ValueError):
        limit = 10
    limit = max(1, min(limit, 50))

    fallback = _fallback_locations(q, limit)
    if fallback:
        return jsonify({"locations": fallback})

    if Nominatim and q:
        try:
            geolocator = Nominatim(user_agent="astronova-geocoder", timeout=5)
            results = geolocator.geocode(q, exactly_one=False, limit=limit)
            locations: List[Dict[str, object]] = []
            for result in results or []:
                address = getattr(result, "raw", {}).get("address", {})
                name = (
                    address.get("city")
                    or address.get("town")
                    or address.get("village")
                    or address.get("state")
                    or result.address
                )
                locations.append(
                    {
                        "name": name,
                        "displayName": result.address,
                        "latitude": result.latitude,
                        "longitude": result.longitude,
                        "state": address.get("state"),
                        "country": address.get("country"),
                        "timezone": "Etc/UTC",
                    }
                )
            if locations:
                return jsonify({"locations": locations[:limit]})
        except (GeocoderServiceError, Exception):
            # Fall back to static data when geocoder is unavailable
            pass

    return jsonify({"locations": fallback})
