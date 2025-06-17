import os
import json
import logging
from datetime import datetime, date
from typing import List, Dict, Optional, Any
from .cloudkit_web_client import CloudKitWebClient

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class CloudKitService:
    """CloudKit service for managing user data across iOS app and backend"""
    
    def __init__(self):
        self.container_id = "iCloud.com.sankalp.AstronovaApp"
        self.web_client = CloudKitWebClient()
        
        if not self.web_client.enabled:
            raise Exception("CloudKit Web Services must be configured. Set CLOUDKIT_KEY_ID, CLOUDKIT_TEAM_ID, and CLOUDKIT_PRIVATE_KEY_PATH environment variables.")
        
        logger.info("CloudKit Web Services configured and ready.")
        
            
    # MARK: - UserProfile Operations
    
    def get_user_profile(self, user_id: str) -> Optional[Dict]:
        """Get user profile by ID"""
        try:
            records = self.web_client.query_user_records('UserProfile', user_id, limit=1)
            return records[0] if records else None
        except Exception as e:
            logger.error(f"Error fetching user profile {user_id}: {e}")
            return None
            
    def save_user_profile(self, user_id: str, profile_data: Dict) -> bool:
        """Save or update user profile"""
        try:
            profile_data['id'] = user_id
            result = self.web_client.save_user_record('UserProfile', user_id, profile_data)
            logger.info(f"Saved user profile for {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error saving user profile {user_id}: {e}")
            return False
            
    # MARK: - ChatMessage Operations
    
    def get_conversation_history(self, user_id: str, conv_id: str, limit: int = 10) -> List[Dict]:
        """Get conversation history for user"""
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
        try:
            user_id = data.get('userProfileId')
            if not user_id:
                logger.error("No userProfileId provided for chat message")
                return False
            
            message_data = {
                'id': data.get('id', f"msg_{datetime.now().timestamp()}"),
                'conversationId': data.get('conversationId', 'default'),
                'content': data.get('content', ''),
                'isUser': data.get('isUser', True),
                'timestamp': data.get('timestamp', datetime.now()),
                'messageType': data.get('messageType', 'text')
            }
            
            self.web_client.save_user_record('ChatMessage', user_id, message_data)
            logger.info(f"Saved chat message for user {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error saving chat message: {e}")
            return False
            
    # MARK: - Horoscope Operations
    
    def get_horoscope(self, user_id: str, sign: str, date: str, type_: str) -> Optional[Dict]:
        """Get cached horoscope for user"""
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
        try:
            user_id = data.get('userProfileId')
            if not user_id:
                # For public horoscopes, use sign as identifier
                user_id = f"public_{data.get('sign', 'unknown')}"
            
            horoscope_data = {
                'id': data.get('id', f"horoscope_{datetime.now().timestamp()}"),
                'date': datetime.strptime(data.get('date', date.today().isoformat()), '%Y-%m-%d'),
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
            
    # MARK: - KundaliMatch Operations
    
    def save_match(self, data: Dict) -> bool:
        """Save compatibility match results"""
        try:
            user_id = data.get('userProfileId')
            if not user_id:
                logger.error("No userProfileId provided for match")
                return False
            
            match_data = {
                'id': data.get('id', f"match_{datetime.now().timestamp()}"),
                'partnerName': data.get('partnerName', ''),
                'partnerBirthDate': datetime.strptime(data.get('partnerBirthDate', ''), '%Y-%m-%d') if data.get('partnerBirthDate') else datetime.now(),
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
            
    # MARK: - Birth Chart Operations
    
    def save_birth_chart(self, data: Dict) -> bool:
        """Save birth chart data"""
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
            
    # MARK: - BookmarkedReading Operations
    
    def save_bookmarked_reading(self, data: Dict) -> bool:
        """Save bookmarked reading"""
        try:
            user_id = data.get('userProfileId')
            if not user_id:
                logger.error("No userProfileId provided for bookmarked reading")
                return False
            
            bookmark_data = {
                'id': data.get('id', f"bookmark_{datetime.now().timestamp()}"),
                'readingType': data.get('readingType', 'horoscope'),
                'title': data.get('title', ''),
                'content': data.get('content', ''),
                'originalDate': datetime.strptime(data.get('originalDate', date.today().isoformat()), '%Y-%m-%d'),
                'bookmarkedAt': datetime.now()
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
            
    def remove_bookmarked_reading(self, user_id: str, bookmark_id: str) -> bool:
        """Remove a bookmarked reading"""
        try:
            # In CloudKit Web Services, we'd use the delete_record method
            success = self.web_client.delete_record(bookmark_id)
            if success:
                logger.info(f"Removed bookmarked reading {bookmark_id} for {user_id}")
                return True
            else:
                logger.warning(f"Bookmark {bookmark_id} not found for user {user_id}")
                return False
        except Exception as e:
            logger.error(f"Error removing bookmarked reading: {e}")
            return False
