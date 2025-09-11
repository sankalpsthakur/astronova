from __future__ import annotations

from flask import Blueprint, jsonify, request

locations_bp = Blueprint('locations', __name__)


def _fallback_locations(q: str, limit: int) -> list[dict]:
    samples = [
        {
            'name': 'New York',
            'displayName': 'New York, USA',
            'latitude': 40.7128,
            'longitude': -74.0060,
            'state': 'New York',
            'country': 'USA',
            'timezone': 'America/New_York'
        },
        {
            'name': 'Los Angeles',
            'displayName': 'Los Angeles, USA',
            'latitude': 34.0522,
            'longitude': -118.2437,
            'state': 'California',
            'country': 'USA',
            'timezone': 'America/Los_Angeles'
        },
        {
            'name': 'London',
            'displayName': 'London, UK',
            'latitude': 51.5074,
            'longitude': -0.1278,
            'state': None,
            'country': 'UK',
            'timezone': 'Europe/London'
        }
    ]
    if not q:
        return samples[:limit]
    return [s for s in samples if q in s['displayName'].lower() or q in s['name'].lower()][:limit]


@locations_bp.route('/search', methods=['GET'])
def search():
    q = (request.args.get('q') or '').strip()
    limit = int(request.args.get('limit', 10))

    # Try geopy if available
    try:
        from geopy.geocoders import Nominatim  # type: ignore
        geolocator = Nominatim(user_agent="astronova-geocoder")
        results = geolocator.geocode(q, exactly_one=False, limit=limit) if q else []
        locations = []
        for r in results or []:
            addr = getattr(r, 'raw', {}).get('address', {})
            name = addr.get('city') or addr.get('town') or addr.get('village') or addr.get('state') or r.address
            country = addr.get('country')
            state = addr.get('state')
            locations.append({
                'name': name,
                'displayName': r.address,
                'latitude': r.latitude,
                'longitude': r.longitude,
                'state': state,
                'country': country,
                'timezone': 'Etc/UTC'  # Fallback; clients can refine locally
            })
        if locations:
            return jsonify({'locations': locations})
        # Fall through if no results
    except Exception:
        pass

    # Fallback static results
    return jsonify({'locations': _fallback_locations(q.lower(), limit)})
