from flask import Blueprint, request, jsonify
from geopy.geocoders import Nominatim
from timezonefinder import TimezoneFinder

locations_bp = Blueprint('locations', __name__)

@locations_bp.route('/search', methods=['GET'])
def search_locations():
    """Search for locations by name and return multiple results"""
    query = request.args.get('query')
    limit = request.args.get('limit', 10, type=int)
    
    if not query:
        return jsonify({'error': 'query parameter required'}), 400
    
    if limit > 20:
        limit = 20  # Cap at 20 results
    
    try:
        geolocator = Nominatim(user_agent='astronova')
        tf = TimezoneFinder()
        
        # Search for multiple locations
        locations = geolocator.geocode(query, exactly_one=False, limit=limit)
        
        if not locations:
            return jsonify({'locations': []})
        
        results = []
        for loc in locations:
            try:
                # Get timezone for this location
                tz = tf.timezone_at(lng=loc.longitude, lat=loc.latitude)
                if tz is None:
                    tz = 'UTC'  # Default fallback
                
                # Parse the address components
                address_parts = loc.address.split(', ')
                
                # Extract meaningful components
                name = address_parts[0] if address_parts else str(loc)
                
                # Try to extract state/country info
                country = address_parts[-1] if len(address_parts) > 0 else 'Unknown'
                state = None
                
                if len(address_parts) >= 3:
                    state = address_parts[-2]  # Second to last is usually state/region
                
                result = {
                    'name': name,
                    'displayName': loc.address,
                    'latitude': loc.latitude,
                    'longitude': loc.longitude,
                    'country': country,
                    'state': state,
                    'timezone': tz
                }
                results.append(result)
                
            except Exception as e:
                # Skip this location if there's an error processing it
                continue
        
        return jsonify({'locations': results})
        
    except Exception as e:
        return jsonify({'error': f'Location search failed: {str(e)}'}), 500

@locations_bp.route('/geocode', methods=['GET'])
def geocode():
    """Geocode a single location (legacy endpoint)"""
    place = request.args.get('place')
    if not place:
        return jsonify({'error': 'place required'}), 400
    
    try:
        geolocator = Nominatim(user_agent='astronova')
        loc = geolocator.geocode(place)
        if not loc:
            return jsonify({'error': 'not found'}), 404
        
        tf = TimezoneFinder()
        tz = tf.timezone_at(lng=loc.longitude, lat=loc.latitude)
        if tz is None:
            tz = 'UTC'  # Default fallback
        
        return jsonify({
            'latitude': loc.latitude,
            'longitude': loc.longitude,
            'timezone': tz,
            'address': loc.address
        })
        
    except Exception as e:
        return jsonify({'error': f'Geocoding failed: {str(e)}'}), 500

@locations_bp.route('/timezone', methods=['GET'])
def get_timezone():
    """Get timezone for coordinates"""
    try:
        lat = request.args.get('lat', type=float)
        lng = request.args.get('lng', type=float)
        
        if lat is None or lng is None:
            return jsonify({'error': 'lat and lng parameters required'}), 400
        
        tf = TimezoneFinder()
        tz = tf.timezone_at(lng=lng, lat=lat)
        
        if tz is None:
            tz = 'UTC'  # Default fallback
        
        return jsonify({'timezone': tz})
        
    except Exception as e:
        return jsonify({'error': f'Timezone lookup failed: {str(e)}'}), 500
