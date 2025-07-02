import datetime
from unittest.mock import patch, MagicMock
from services import ephemeris_service

def test_get_planetary_positions():
    """Test getting planetary positions with Swiss Ephemeris"""
    dt = datetime.datetime(2024, 1, 1)
    
    # Mock the Swiss Ephemeris calc_ut function
    with patch('services.ephemeris_service.swe.calc_ut') as mock_calc:
        # Mock return value: (longitude, latitude, distance, speed, ...)
        mock_calc.return_value = ([45.5, 1.2, 1.0, 0.5], 0)
        
        positions = ephemeris_service.get_planetary_positions(dt)
        
        # Check that all planets are present
        assert set(positions.keys()) == set(ephemeris_service.PLANETS.keys())
        
        # Check the data structure for each planet
        for planet_name, data in positions.items():
            assert 'sign' in data
            assert 'degree' in data
            assert 'longitude' in data
            assert 'retrograde' in data
            assert data['sign'] == 'Taurus'  # 45.5 degrees = Taurus
            assert abs(data['degree'] - 15.5) < 0.1  # 45.5 % 30 = 15.5
            assert data['retrograde'] is False  # positive speed

def test_get_current_positions_with_rising_sign():
    """Test getting positions with rising sign calculation"""
    service = ephemeris_service.EphemerisService()
    
    with patch('services.ephemeris_service.swe.calc_ut') as mock_calc:
        with patch('services.ephemeris_service.swe.houses') as mock_houses:
            # Mock planetary positions
            mock_calc.return_value = ([120.0, 1.2, 1.0, -0.5], 0)  # Retrograde with negative speed
            # Mock houses return: (house_cusps, (asc, mc, armc, vertex, ...))
            mock_houses.return_value = ([0]*12, [95.0, 180.0, 0, 0])  # Ascendant at 95 degrees
            
            result = service.get_current_positions(lat=40.7, lon=-74.0)
            
            assert 'planets' in result
            planets = result['planets']
            
            # Check ascendant was calculated
            assert 'ascendant' in planets
            assert planets['ascendant']['sign'] == 'Cancer'  # 95 degrees = Cancer
            assert abs(planets['ascendant']['degree'] - 5.0) < 0.1  # 95 % 30 = 5
            
            # Check retrograde detection
            for planet_name, data in planets.items():
                if planet_name != 'ascendant':
                    assert data['retrograde'] is True  # negative speed means retrograde
