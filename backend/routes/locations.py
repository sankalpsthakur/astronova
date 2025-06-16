from fastapi import APIRouter, HTTPException, Query
from slowapi import Limiter
from slowapi.util import get_remote_address
from geopy.geocoders import Nominatim
from timezonefinder import TimezoneFinder

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)

@router.get('/search')
@limiter.limit("100/hour")
async def search_locations(
    query: str = Query(..., description="Location query to search"),
    limit: int = Query(default=10, le=20, description="Maximum number of results")
):
    """Search for locations by name and return multiple results"""
    if not query:
        raise HTTPException(status_code=400, detail='query parameter required')
    
    try:
        geolocator = Nominatim(user_agent='astronova')
        tf = TimezoneFinder()
        
        # Search for multiple locations
        locations = geolocator.geocode(query, exactly_one=False, limit=limit)
        
        if not locations:
            return {'locations': []}
        
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
        
        return {'locations': results}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Location search failed: {str(e)}')


@router.get('/timezone')
@limiter.limit("100/hour")
async def get_timezone(
    lat: float = Query(..., description="Latitude"),
    lng: float = Query(..., description="Longitude")
):
    """Get timezone for coordinates"""
    try:
        tf = TimezoneFinder()
        tz = tf.timezone_at(lng=lng, lat=lat)
        
        if tz is None:
            tz = 'UTC'  # Default fallback
        
        return {'timezone': tz}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Timezone lookup failed: {str(e)}')