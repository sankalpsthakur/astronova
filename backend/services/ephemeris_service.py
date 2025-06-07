import datetime

class EphemerisService:
    def get_current_positions(self):
        # Dummy planetary positions
        return {
            'sun': {'sign': 'Aries'},
            'moon': {'sign': 'Taurus'},
            'mercury': {'sign': 'Gemini'},
            'venus': {'sign': 'Cancer'},
            'mars': {'sign': 'Leo'}
        }

    def get_positions_for_date(self, date: datetime.date):
        return self.get_current_positions()
