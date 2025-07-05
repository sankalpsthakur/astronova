import logging
from datetime import datetime, date
from typing import List, Dict, Optional
from .cloudkit_web_client import CloudKitWebClient

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Required fields for each record type
REQUIRED_FIELDS = {
    'UserProfile': ['fullName', 'birthDate', 'birthLocation', 'birthTime'],
    'ChatMessage': ['userProfileId', 'conversationId', 'content', 'isUser'],
    'Horoscope': ['userProfileId', 'date', 'type', 'content', 'sign'],
    'KundaliMatch': ['userProfileId', 'partnerName', 'partnerBirthDate', 'compatibilityScore'],
    'BirthChart': ['userProfileId', 'chartType', 'systems'],
    'BookmarkedReading': ['userProfileId', 'readingType', 'title', 'content', 'originalDate']
}

class CloudKitService:
    """CloudKit service for managing user data across iOS app and backend"""
    
    def __init__(self):
        self.container_id = "iCloud.com.sankalp.AstronovaApp"
        self.web_client = CloudKitWebClient()
        self.enabled = self.web_client.enabled
        
        if not self.enabled:
            logger.warning("CloudKit Web Services not configured - running in offline mode. Some features may be limited.")
        else:
            logger.info("CloudKit Web Services configured and ready.")
    
    def _check_enabled(self, operation_name: str = "operation") -> bool:
        """Check if CloudKit is enabled and log if not"""
        if not self.enabled:
            logger.debug(f"CloudKit not enabled - skipping {operation_name}")
            return False
        return True
    
    def _validate_required_fields(self, record_type: str, data: Dict) -> None:
        """Validate that all required fields are present"""
        if record_type not in REQUIRED_FIELDS:
            return
            
        missing_fields = []
        for field in REQUIRED_FIELDS[record_type]:
            if field not in data or data[field] is None or data[field] == '':
                missing_fields.append(field)
                
        if missing_fields:
            raise ValueError(f"Missing required fields for {record_type}: {', '.join(missing_fields)}")
    
    def _format_location(self, latitude: float, longitude: float) -> Dict:
        """Format latitude/longitude as CloudKit Location type"""
        return {
            'latitude': latitude,
            'longitude': longitude
        }
            
    # MARK: - UserProfile Operations
    
    def get_user_profile(self, user_id: str) -> Optional[Dict]:
        """Get user profile by ID"""
        if not self._check_enabled("get_user_profile"):
            return None
            
        try:
            records = self.web_client.query_user_records('UserProfile', user_id, limit=1)
            return records[0] if records else None
        except Exception as e:
            logger.error(f"Error fetching user profile {user_id}: {e}")
            # Don't raise, just return None
            return None
            
    def save_user_profile(self, user_id: str, profile_data: Dict) -> bool:
        """Save or update user profile"""
        if not self._check_enabled("save_user_profile"):
            return False
            
        try:
            profile_data['id'] = user_id
            result = self.web_client.save_user_record('UserProfile', user_id, profile_data)
            logger.info(f"Saved user profile for {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error saving user profile {user_id}: {e}")
            return False
    
    def update_user_profile(self, user_id: str, updated_data: Dict) -> bool:
        """Update specific fields in a user profile"""
        try:
            # Get existing profile first
            existing_profile = self.get_user_profile(user_id)
            if not existing_profile:
                logger.error(f"User profile not found for {user_id}")
                return False
            
            # Merge existing data with updates
            profile_data = existing_profile.copy()
            profile_data.update(updated_data)
            
            # Save updated profile
            return self.save_user_profile(user_id, profile_data)
        except Exception as e:
            logger.error(f"Error updating user profile {user_id}: {e}")
            return False
    
    def delete_user_profile(self, user_id: str) -> bool:
        """Delete a user profile"""
        try:
            success = self.web_client.delete_record('UserProfile', user_id)
            if success:
                logger.info(f"Deleted user profile: {user_id}")
            return success
        except Exception as e:
            logger.error(f"Error deleting user profile {user_id}: {e}")
            return False
            
    # MARK: - ChatMessage Operations
    
    def get_conversation_history(self, user_id: str, conv_id: str, limit: int = 10) -> List[Dict]:
        """Get conversation history for user"""
        if not self._check_enabled("get_conversation_history"):
            return []
            
        try:
            records = self.web_client.query_user_records('ChatMessage', user_id, limit=limit)
            
            # Filter by conversation ID if provided
            if conv_id:
                records = [msg for msg in records if msg.get('conversationId') == conv_id]
            
            return records
        except Exception as e:
            logger.error(f"Error fetching conversation history for {user_id}: {e}")
            return []

    def save_chat_message(self, data: Dict) -> bool:
        """Save chat message to CloudKit"""
        if not self._check_enabled("save_chat_message"):
            return False
            
        try:
            user_id = data.get('userProfileId')
            if not user_id:
                logger.error("No userProfileId provided for chat message")
                return False
            
            message_data = {
                'id': data.get('id', f"msg_{datetime.now().timestamp()}"),
                'userProfileId': user_id,
                'conversationId': data.get('conversationId', 'default'),
                'content': data.get('content', ''),
                'isUser': 1 if data.get('isUser', True) else 0,
                'timestamp': data.get('timestamp', datetime.now()),
                'messageType': data.get('messageType', 'text')
            }
            
            # Validate required fields
            self._validate_required_fields('ChatMessage', message_data)
            
            self.web_client.save_user_record('ChatMessage', user_id, message_data)
            logger.info(f"Saved chat message for user {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error saving chat message: {e}")
            return False
    
    def update_chat_message(self, user_id: str, message_id: str, updated_data: Dict) -> bool:
        """Update a chat message"""
        try:
            # For CloudKit, we need to get the record name first by querying
            messages = self.web_client.query_user_records('ChatMessage', user_id, limit=100)
            message_record = None
            
            for msg in messages:
                if msg.get('id') == message_id:
                    message_record = msg
                    break
            
            if not message_record:
                logger.error(f"Chat message {message_id} not found for user {user_id}")
                return False
            
            # Merge existing data with updates
            message_data = message_record.copy()
            message_data.update(updated_data)
            
            # Save updated message using record name
            record_name = message_record.get('recordName', message_id)
            result = self.web_client.save_record('ChatMessage', message_data, record_name)
            logger.info(f"Updated chat message {message_id} for user {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error updating chat message {message_id}: {e}")
            return False
    
    def delete_chat_message(self, user_id: str, message_id: str) -> bool:
        """Delete a chat message"""
        try:
            # For CloudKit, we need to get the record name first by querying
            messages = self.web_client.query_user_records('ChatMessage', user_id, limit=100)
            
            for msg in messages:
                if msg.get('id') == message_id:
                    record_name = msg.get('recordName', message_id)
                    success = self.web_client.delete_record('ChatMessage', record_name)
                    if success:
                        logger.info(f"Deleted chat message {message_id} for user {user_id}")
                    return success
            
            logger.error(f"Chat message {message_id} not found for user {user_id}")
            return False
        except Exception as e:
            logger.error(f"Error deleting chat message {message_id}: {e}")
            return False
            
    # MARK: - Horoscope Operations
    
    def get_horoscope(self, user_id: str, sign: str, date: str, type_: str) -> Optional[Dict]:
        """Get cached horoscope for user"""
        if not self._check_enabled("get_horoscope"):
            return None
            
        try:
            records = self.web_client.query_user_records('Horoscope', user_id, limit=50)
            
            # Find matching horoscope
            for horoscope in records:
                if (horoscope.get('sign') == sign and 
                    str(horoscope.get('date')) == date and 
                    horoscope.get('type') == type_):
                    return horoscope
            return None
        except Exception as e:
            logger.error(f"Error fetching horoscope for {user_id}: {e}")
            return None

    def save_horoscope(self, data: Dict) -> bool:
        """Save horoscope to CloudKit"""
        if not self._check_enabled("save_horoscope"):
            return False
            
        try:
            user_id = data.get('userProfileId')
            if not user_id:
                # For public horoscopes, use sign as identifier
                user_id = f"public_{data.get('sign', 'unknown')}"
            
            # Handle date conversion properly
            date_value = data.get('date')
            if isinstance(date_value, str):
                parsed_date = datetime.strptime(date_value, '%Y-%m-%d')
            elif isinstance(date_value, date):
                parsed_date = datetime.combine(date_value, datetime.min.time())
            elif isinstance(date_value, datetime):
                parsed_date = date_value
            else:
                parsed_date = datetime.combine(date.today(), datetime.min.time())
            
            horoscope_data = {
                'id': data.get('id', f"horoscope_{int(datetime.now().timestamp())}"),
                'date': parsed_date,
                'type': data.get('type', 'daily'),
                'content': data.get('content', ''),
                'sign': data.get('sign', ''),
                'luckyElements': data.get('luckyElements', {})
            }
            
            self.web_client.save_user_record('Horoscope', user_id, horoscope_data)
            logger.info(f"Saved horoscope for {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error saving horoscope: {e}")
            return False
    
    def update_horoscope(self, user_id: str, horoscope_id: str, updated_data: Dict) -> bool:
        """Update a horoscope"""
        try:
            # Find the horoscope record
            horoscopes = self.web_client.query_user_records('Horoscope', user_id, limit=50)
            horoscope_record = None
            
            for horoscope in horoscopes:
                if horoscope.get('id') == horoscope_id:
                    horoscope_record = horoscope
                    break
            
            if not horoscope_record:
                logger.error(f"Horoscope {horoscope_id} not found for user {user_id}")
                return False
            
            # Merge existing data with updates
            horoscope_data = horoscope_record.copy()
            horoscope_data.update(updated_data)
            
            # Save updated horoscope using record name
            record_name = horoscope_record.get('recordName', horoscope_id)
            result = self.web_client.save_record('Horoscope', horoscope_data, record_name)
            logger.info(f"Updated horoscope {horoscope_id} for user {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error updating horoscope {horoscope_id}: {e}")
            return False
    
    def delete_horoscope(self, user_id: str, horoscope_id: str) -> bool:
        """Delete a horoscope"""
        try:
            # Find the horoscope record
            horoscopes = self.web_client.query_user_records('Horoscope', user_id, limit=50)
            
            for horoscope in horoscopes:
                if horoscope.get('id') == horoscope_id:
                    record_name = horoscope.get('recordName', horoscope_id)
                    success = self.web_client.delete_record('Horoscope', record_name)
                    if success:
                        logger.info(f"Deleted horoscope {horoscope_id} for user {user_id}")
                    return success
            
            logger.error(f"Horoscope {horoscope_id} not found for user {user_id}")
            return False
        except Exception as e:
            logger.error(f"Error deleting horoscope {horoscope_id}: {e}")
            return False
            
    # MARK: - KundaliMatch Operations
    
    def save_match(self, data: Dict) -> bool:
        """Save compatibility match results"""
        try:
            user_id = data.get('userProfileId')
            if not user_id:
                logger.error("No userProfileId provided for match")
                return False
            
            # Handle partner birth date conversion properly
            partner_birth_date = data.get('partnerBirthDate')
            if isinstance(partner_birth_date, str):
                parsed_birth_date = datetime.strptime(partner_birth_date, '%Y-%m-%d')
            elif isinstance(partner_birth_date, date):
                parsed_birth_date = datetime.combine(partner_birth_date, datetime.min.time())
            elif isinstance(partner_birth_date, datetime):
                parsed_birth_date = partner_birth_date
            else:
                parsed_birth_date = datetime.now()
            
            match_data = {
                'id': data.get('id', f"match_{int(datetime.now().timestamp())}"),
                'partnerName': data.get('partnerName', ''),
                'partnerBirthDate': parsed_birth_date,
                'partnerLocation': data.get('partnerLocation', ''),
                'compatibilityScore': data.get('compatibilityScore', 0),
                'detailedAnalysis': data.get('detailedAnalysis', {})
            }
            
            self.web_client.save_user_record('KundaliMatch', user_id, match_data)
            logger.info(f"Saved compatibility match for {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error saving match: {e}")
            return False
            
    def get_user_matches(self, user_id: str) -> List[Dict]:
        """Get user's compatibility matches"""
        try:
            matches = self.web_client.query_user_records('KundaliMatch', user_id, limit=50)
            return matches
        except Exception as e:
            logger.error(f"Error fetching matches for {user_id}: {e}")
            return []
    
    def update_match(self, user_id: str, match_id: str, updated_data: Dict) -> bool:
        """Update a compatibility match"""
        try:
            # Find the match record
            matches = self.web_client.query_user_records('KundaliMatch', user_id, limit=50)
            match_record = None
            
            for match in matches:
                if match.get('id') == match_id:
                    match_record = match
                    break
            
            if not match_record:
                logger.error(f"Match {match_id} not found for user {user_id}")
                return False
            
            # Merge existing data with updates
            match_data = match_record.copy()
            match_data.update(updated_data)
            
            # Save updated match using record name
            record_name = match_record.get('recordName', match_id)
            result = self.web_client.save_record('KundaliMatch', match_data, record_name)
            logger.info(f"Updated match {match_id} for user {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error updating match {match_id}: {e}")
            return False
    
    def delete_match(self, user_id: str, match_id: str) -> bool:
        """Delete a compatibility match"""
        try:
            # Find the match record
            matches = self.web_client.query_user_records('KundaliMatch', user_id, limit=50)
            
            for match in matches:
                if match.get('id') == match_id:
                    record_name = match.get('recordName', match_id)
                    success = self.web_client.delete_record('KundaliMatch', record_name)
                    if success:
                        logger.info(f"Deleted match {match_id} for user {user_id}")
                    return success
            
            logger.error(f"Match {match_id} not found for user {user_id}")
            return False
        except Exception as e:
            logger.error(f"Error deleting match {match_id}: {e}")
            return False
            
    # MARK: - Birth Chart Operations
    
    def save_birth_chart(self, data: Dict) -> bool:
        """Save birth chart data"""
        if not self._check_enabled("save_birth_chart"):
            return False
            
        try:
            user_id = data.get('userProfileId')
            if not user_id:
                logger.error("No userProfileId provided for birth chart")
                return False
                
            chart_data = {
                'id': data.get('id', f"chart_{datetime.now().timestamp()}"),
                'chartType': data.get('chartType', 'natal'),
                'systems': data.get('systems', ['western']),
                'planetaryPositions': data.get('planetaryPositions', []),
                'chartSVG': data.get('chartSVG', ''),
                'birthData': data.get('birthData', {})
            }
            
            self.web_client.save_user_record('BirthChart', user_id, chart_data)
            logger.info(f"Saved birth chart for {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error saving birth chart: {e}")
            return False
            
    def get_birth_chart(self, user_id: str, chart_type: str = 'natal') -> Optional[Dict]:
        """Get user's birth chart"""
        try:
            charts = self.web_client.query_user_records('BirthChart', user_id, limit=20)
            
            # Find chart of specified type
            for chart in charts:
                if chart.get('chartType') == chart_type:
                    return chart
            return None
        except Exception as e:
            logger.error(f"Error fetching birth chart for {user_id}: {e}")
            return None
    
    def update_birth_chart(self, user_id: str, chart_id: str, updated_data: Dict) -> bool:
        """Update a birth chart"""
        try:
            # Find the chart record
            charts = self.web_client.query_user_records('BirthChart', user_id, limit=20)
            chart_record = None
            
            for chart in charts:
                if chart.get('id') == chart_id:
                    chart_record = chart
                    break
            
            if not chart_record:
                logger.error(f"Birth chart {chart_id} not found for user {user_id}")
                return False
            
            # Merge existing data with updates
            chart_data = chart_record.copy()
            chart_data.update(updated_data)
            
            # Save updated chart using record name
            record_name = chart_record.get('recordName', chart_id)
            result = self.web_client.save_record('BirthChart', chart_data, record_name)
            logger.info(f"Updated birth chart {chart_id} for user {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error updating birth chart {chart_id}: {e}")
            return False
    
    def delete_birth_chart(self, user_id: str, chart_id: str) -> bool:
        """Delete a birth chart"""
        try:
            # Find the chart record
            charts = self.web_client.query_user_records('BirthChart', user_id, limit=20)
            
            for chart in charts:
                if chart.get('id') == chart_id:
                    record_name = chart.get('recordName', chart_id)
                    success = self.web_client.delete_record('BirthChart', record_name)
                    if success:
                        logger.info(f"Deleted birth chart {chart_id} for user {user_id}")
                    return success
            
            logger.error(f"Birth chart {chart_id} not found for user {user_id}")
            return False
        except Exception as e:
            logger.error(f"Error deleting birth chart {chart_id}: {e}")
            return False
            
    # MARK: - BookmarkedReading Operations
    
    def save_bookmarked_reading(self, data: Dict) -> bool:
        """Save bookmarked reading"""
        try:
            user_id = data.get('userProfileId')
            if not user_id:
                logger.error("No userProfileId provided for bookmarked reading")
                return False
            
            # Handle original date conversion properly
            original_date = data.get('originalDate')
            if isinstance(original_date, str):
                parsed_original_date = datetime.strptime(original_date, '%Y-%m-%d')
            elif isinstance(original_date, date):
                parsed_original_date = datetime.combine(original_date, datetime.min.time())
            elif isinstance(original_date, datetime):
                parsed_original_date = original_date
            else:
                parsed_original_date = datetime.combine(date.today(), datetime.min.time())
            
            # Handle bookmarked at date
            bookmarked_at = data.get('bookmarkedAt')
            if isinstance(bookmarked_at, datetime):
                parsed_bookmarked_at = bookmarked_at
            else:
                parsed_bookmarked_at = datetime.now()
            
            bookmark_data = {
                'id': data.get('id', f"bookmark_{int(datetime.now().timestamp())}"),
                'readingType': data.get('readingType', 'horoscope'),
                'title': data.get('title', ''),
                'content': data.get('content', ''),
                'originalDate': parsed_original_date,
                'bookmarkedAt': parsed_bookmarked_at
            }
            
            self.web_client.save_user_record('BookmarkedReading', user_id, bookmark_data)
            logger.info(f"Saved bookmarked reading for {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error saving bookmarked reading: {e}")
            return False
            
    def get_bookmarked_readings(self, user_id: str) -> List[Dict]:
        """Get user's bookmarked readings"""
        try:
            bookmarks = self.web_client.query_user_records('BookmarkedReading', user_id, limit=100)
            return bookmarks
        except Exception as e:
            logger.error(f"Error fetching bookmarked readings for {user_id}: {e}")
            return []
    
    def update_bookmarked_reading(self, user_id: str, bookmark_id: str, updated_data: Dict) -> bool:
        """Update a bookmarked reading"""
        try:
            # Find the bookmark record
            bookmarks = self.web_client.query_user_records('BookmarkedReading', user_id, limit=100)
            bookmark_record = None
            
            for bookmark in bookmarks:
                if bookmark.get('id') == bookmark_id:
                    bookmark_record = bookmark
                    break
            
            if not bookmark_record:
                logger.error(f"Bookmarked reading {bookmark_id} not found for user {user_id}")
                return False
            
            # Merge existing data with updates
            bookmark_data = bookmark_record.copy()
            bookmark_data.update(updated_data)
            
            # Save updated bookmark using record name
            record_name = bookmark_record.get('recordName', bookmark_id)
            result = self.web_client.save_record('BookmarkedReading', bookmark_data, record_name)
            logger.info(f"Updated bookmarked reading {bookmark_id} for user {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error updating bookmarked reading {bookmark_id}: {e}")
            return False
            
    def remove_bookmarked_reading(self, user_id: str, bookmark_id: str) -> bool:
        """Remove a bookmarked reading"""
        try:
            # In CloudKit Web Services, we'd use the delete_record method
            success = self.web_client.delete_record('BookmarkedReading', bookmark_id)
            if success:
                logger.info(f"Removed bookmarked reading {bookmark_id} for {user_id}")
                return True
            
            logger.warning(f"Bookmark {bookmark_id} not found for user {user_id}")
            return False
        except Exception as e:
            logger.error(f"Error removing bookmarked reading: {e}")
            return False
