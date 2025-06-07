import datetime
from services import ephemeris_service

class FakeHorizons:
    def __init__(self, id, location, epochs):
        pass
    def ephemerides(self):
        return {"RA": [0], "DEC": [0]}

def test_get_planetary_positions(monkeypatch):
    monkeypatch.setattr(ephemeris_service, 'Horizons', FakeHorizons)
    dt = datetime.datetime(2024, 1, 1)
    positions = ephemeris_service.get_planetary_positions(dt)
    assert set(positions.keys()) == set(ephemeris_service.PLANET_IDS.keys())
    for data in positions.values():
        assert data['sign'] == 'Aries'
        assert 0 <= data['degree'] < 1
