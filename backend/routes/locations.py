from flask import Blueprint, request, jsonify
from geopy.geocoders import Nominatim
from timezonefinder import TimezoneFinder

locations_bp = Blueprint('locations', __name__)

@locations_bp.route('/geocode', methods=['GET'])
def geocode():
    place = request.args.get('place')
    if not place:
        return jsonify({'error': 'place required'}), 400
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
        'timezone': tz
    })
