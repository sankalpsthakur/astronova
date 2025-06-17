import os
import json
import logging
from datetime import datetime, date
from typing import List, Dict, Optional, Any
from dataclasses import dataclass, asdict
from enum import Enum

# CloudKit imports (would use actual CloudKit SDK in production)
# For now, we'll simulate CloudKit operations with a file-based approach
# In production, you'd use: from cloudkit import CloudKitClient

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class CloudKitService:
    """CloudKit service for managing user data across iOS app and backend"""
    
    def __init__(self):
        self.container_id = "iCloud.com.sankalp.AstronovaApp"
        # In production, initialize CloudKit client:
        # self.client = CloudKitClient(container_id=self.container_id)
        
        # For development, use local storage simulation
        self.data_dir = os.path.join(os.path.dirname(__file__), '..', 'cloudkit_data')
        os.makedirs(self.data_dir, exist_ok=True)
        
    def _get_user_data_file(self, user_id: str, record_type: str) -> str:
        """Get file path for user's data of specific record type"""
        return os.path.join(self.data_dir, f"{user_id}_{record_type}.json")
        
    def _load_user_data(self, user_id: str, record_type: str) -> List[Dict]:
        """Load user data from file"""
        file_path = self._get_user_data_file(user_id, record_type)
        if os.path.exists(file_path):
            try:
                with open(file_path, 'r') as f:
                    return json.load(f)
            except (json.JSONDecodeError, IOError) as e:
                logger.error(f"Error loading {record_type} data for user {user_id}: {e}")
        return []
        
    def _save_user_data(self, user_id: str, record_type: str, data: List[Dict]):
        """Save user data to file"""
        file_path = self._get_user_data_file(user_id, record_type)
        try:
            with open(file_path, 'w') as f:
                json.dump(data, f, indent=2, default=str)
        except IOError as e:
            logger.error(f"Error saving {record_type} data for user {user_id}: {e}")
            
    # MARK: - UserProfile Operations
    
    def get_user_profile(self, user_id: str) -> Optional[Dict]:
        """Get user profile by ID"""
        try:
            profiles = self._load_user_data(user_id, "UserProfile")
            if profiles:
                return profiles[0]  # Return the first (and should be only) profile
            return None
        except Exception as e:
            logger.error(f"Error fetching user profile {user_id}: {e}")
            return None
            
    def save_user_profile(self, user_id: str, profile_data: Dict) -> bool:
        """Save or update user profile"""
        try:
            profile_data.update({
                'id': user_id,
                'updatedAt': datetime.now().isoformat()
            })
            
            if 'createdAt' not in profile_data:
                profile_data['createdAt'] = datetime.now().isoformat()
                
            self._save_user_data(user_id, "UserProfile", [profile_data])
            logger.info(f"Saved user profile for {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error saving user profile {user_id}: {e}")
            return False
            
    # MARK: - ChatMessage Operations
    
    def get_conversation_history(self, user_id: str, conv_id: str, limit: int = 10) -> List[Dict]:
        """Get conversation history for user"""
        try:
            messages = self._load_user_data(user_id, "ChatMessage")
            
            # Filter by conversation ID if provided
            if conv_id:
                messages = [msg for msg in messages if msg.get('conversationId') == conv_id]
            
            # Sort by timestamp descending and limit
            messages.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
            return messages[:limit]
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
                
            # Load existing messages
            messages = self._load_user_data(user_id, "ChatMessage")
            
            # Add new message with timestamp and ID
            message_data = {
                'id': data.get('id', f"msg_{datetime.now().timestamp()}"),
                'userProfileId': user_id,
                'conversationId': data.get('conversationId', 'default'),
                'content': data.get('content', ''),
                'isUser': data.get('isUser', True),
                'timestamp': data.get('timestamp', datetime.now().isoformat()),
                'messageType': data.get('messageType', 'text')
            }
            
            messages.append(message_data)
            
            # Keep only last 100 messages per user to manage storage
            messages = messages[-100:]
            
            self._save_user_data(user_id, "ChatMessage", messages)
            logger.info(f"Saved chat message for user {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error saving chat message: {e}")
            return False
            
    # MARK: - Horoscope Operations
    
    def get_horoscope(self, user_id: str, sign: str, date: str, type_: str) -> Optional[Dict]:
        """Get cached horoscope for user"""
        try:
            horoscopes = self._load_user_data(user_id, "Horoscope")
            
            # Find matching horoscope
            for horoscope in horoscopes:
                if (horoscope.get('sign') == sign and 
                    horoscope.get('date') == date and 
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
                
            horoscopes = self._load_user_data(user_id, "Horoscope")
            
            horoscope_data = {
                'id': data.get('id', f"horoscope_{datetime.now().timestamp()}"),
                'userProfileId': user_id,
                'date': data.get('date', date.today().isoformat()),
                'type': data.get('type', 'daily'),
                'content': data.get('content', ''),
                'sign': data.get('sign', ''),
                'luckyElements': data.get('luckyElements', {}),
                'createdAt': datetime.now().isoformat()
            }
            
            # Remove old horoscope of same type/date/sign if exists
            horoscopes = [h for h in horoscopes if not (
                h.get('sign') == horoscope_data['sign'] and
                h.get('date') == horoscope_data['date'] and
                h.get('type') == horoscope_data['type']
            )]
            
            horoscopes.append(horoscope_data)
            
            # Keep only last 30 horoscopes to manage storage
            horoscopes = horoscopes[-30:]
            
            self._save_user_data(user_id, "Horoscope", horoscopes)
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
                
            matches = self._load_user_data(user_id, "KundaliMatch")
            
            match_data = {
                'id': data.get('id', f"match_{datetime.now().timestamp()}"),
                'userProfileId': user_id,
                'partnerName': data.get('partnerName', ''),
                'partnerBirthDate': data.get('partnerBirthDate', ''),
                'partnerLocation': data.get('partnerLocation', ''),
                'compatibilityScore': data.get('compatibilityScore', 0),
                'detailedAnalysis': data.get('detailedAnalysis', {}),
                'createdAt': datetime.now().isoformat()
            }
            
            matches.append(match_data)
            
            # Keep only last 20 matches to manage storage
            matches = matches[-20:]
            
            self._save_user_data(user_id, "KundaliMatch", matches)
            logger.info(f"Saved compatibility match for {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error saving match: {e}")
            return False
            
    def get_user_matches(self, user_id: str) -> List[Dict]:
        """Get user's compatibility matches"""
        try:
            matches = self._load_user_data(user_id, "KundaliMatch")
            # Sort by creation date descending
            matches.sort(key=lambda x: x.get('createdAt', ''), reverse=True)
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
                
            charts = self._load_user_data(user_id, "BirthChart")
            
            chart_data = {
                'id': data.get('id', f"chart_{datetime.now().timestamp()}"),
                'userProfileId': user_id,
                'chartType': data.get('chartType', 'natal'),
                'systems': data.get('systems', ['western']),
                'planetaryPositions': data.get('planetaryPositions', []),
                'chartSVG': data.get('chartSVG', ''),
                'birthData': data.get('birthData', {}),
                'createdAt': datetime.now().isoformat()
            }
            
            # Keep only the latest chart for each type/system combination
            chart_key = f"{chart_data['chartType']}_{','.join(sorted(chart_data['systems']))}"
            charts = [c for c in charts if f"{c.get('chartType')}_{','.join(sorted(c.get('systems', [])))}" != chart_key]
            
            charts.append(chart_data)
            
            self._save_user_data(user_id, "BirthChart", charts)
            logger.info(f"Saved birth chart for {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error saving birth chart: {e}")
            return False
            
    def get_birth_chart(self, user_id: str, chart_type: str = 'natal') -> Optional[Dict]:
        """Get user's birth chart"""
        try:
            charts = self._load_user_data(user_id, "BirthChart")
            
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
                
            bookmarks = self._load_user_data(user_id, "BookmarkedReading")
            
            bookmark_data = {
                'id': data.get('id', f"bookmark_{datetime.now().timestamp()}"),
                'userProfileId': user_id,
                'readingType': data.get('readingType', 'horoscope'),
                'title': data.get('title', ''),
                'content': data.get('content', ''),
                'originalDate': data.get('originalDate', date.today().isoformat()),
                'bookmarkedAt': datetime.now().isoformat()
            }
            
            bookmarks.append(bookmark_data)
            
            # Keep only last 50 bookmarks to manage storage
            bookmarks = bookmarks[-50:]
            
            self._save_user_data(user_id, "BookmarkedReading", bookmarks)
            logger.info(f"Saved bookmarked reading for {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error saving bookmarked reading: {e}")
            return False
            
    def get_bookmarked_readings(self, user_id: str) -> List[Dict]:
        """Get user's bookmarked readings"""
        try:
            bookmarks = self._load_user_data(user_id, "BookmarkedReading")
            # Sort by bookmark date descending
            bookmarks.sort(key=lambda x: x.get('bookmarkedAt', ''), reverse=True)
            return bookmarks
        except Exception as e:
            logger.error(f"Error fetching bookmarked readings for {user_id}: {e}")
            return []
            
    def remove_bookmarked_reading(self, user_id: str, bookmark_id: str) -> bool:
        """Remove a bookmarked reading"""
        try:
            bookmarks = self._load_user_data(user_id, "BookmarkedReading")
            
            # Filter out the bookmark to remove
            original_count = len(bookmarks)
            bookmarks = [b for b in bookmarks if b.get('id') != bookmark_id]
            
            if len(bookmarks) < original_count:
                self._save_user_data(user_id, "BookmarkedReading", bookmarks)
                logger.info(f"Removed bookmarked reading {bookmark_id} for {user_id}")
                return True
            else:
                logger.warning(f"Bookmark {bookmark_id} not found for user {user_id}")
                return False
        except Exception as e:
            logger.error(f"Error removing bookmarked reading: {e}")
            return False
