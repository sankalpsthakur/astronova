import os
from typing import Dict

import requests
from timezonefinder import TimezoneFinder

from .cache_service import cache


GEOCODE_URL = "https://maps.googleapis.com/maps/api/geocode/json"
CACHE_TTL = 60 * 60 * 24  # 24 hours


def get_location(address: str) -> Dict[str, str]:
    """Resolve an address to coordinates and timezone."""
    cache_key = f"geocode:{address}"
    cached = cache.get(cache_key)
    if cached:
        return cached

    api_key = os.getenv("GEOCODING_API_KEY")
    if not api_key:
        raise RuntimeError("GEOCODING_API_KEY environment variable is not set")

    response = requests.get(GEOCODE_URL, params={"address": address, "key": api_key}, timeout=10)
    response.raise_for_status()
    data = response.json()

    if data.get("status") != "OK":
        raise RuntimeError(f"Geocoding failed: {data.get('status')}")

    result = data["results"][0]
    location = result["geometry"]["location"]
    lat = location["lat"]
    lng = location["lng"]

    tf = TimezoneFinder()
    timezone = tf.timezone_at(lng=lng, lat=lat)

    info = {
        "latitude": lat,
        "longitude": lng,
        "timezone": timezone,
        "formatted_address": result.get("formatted_address"),
    }

    cache.set(cache_key, info, timeout=CACHE_TTL)
    return info
