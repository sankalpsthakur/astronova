from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import uuid
import logging
from services.cloudkit_service import CloudKitService

logger = logging.getLogger(__name__)

@dataclass
class User:
    id: str
    apple_user_id: str
    email: Optional[str]
    first_name: Optional[str]
    last_name: Optional[str]
    user_identifier: str
    created_at: datetime
    updated_at: datetime
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': self.id,
            'apple_user_id': self.apple_user_id,
            'email': self.email,
            'firstName': self.first_name,
            'lastName': self.last_name,
            'fullName': f"{self.first_name or ''} {self.last_name or ''}".strip(),
            'userIdentifier': self.user_identifier,
            'createdAt': self.created_at.isoformat(),
            'updatedAt': self.updated_at.isoformat()
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'User':
        return cls(
            id=data['id'],
            apple_user_id=data['apple_user_id'],
            email=data.get('email'),
            first_name=data.get('firstName'),
            last_name=data.get('lastName'),
            user_identifier=data['userIdentifier'],
            created_at=datetime.fromisoformat(data['createdAt'].replace('Z', '+00:00')),
            updated_at=datetime.fromisoformat(data['updatedAt'].replace('Z', '+00:00'))
        )

class UserService:
    """
    Service for user management
    """
    
    def __init__(self):
        self.cloudkit = CloudKitService()
        # In-memory cache for development - use Redis in production
        self._user_cache = {}
    
    def create_or_update_user(
        self,
        apple_user_id: str,
        email: Optional[str],
        first_name: Optional[str],
        last_name: Optional[str],
        user_identifier: str
    ) -> User:
        """
        Create new user or update existing user
        """
        try:
            # Try to find existing user by Apple ID
            existing_user = self._find_user_by_apple_id(apple_user_id)
            
            if existing_user:
                # Update existing user
                existing_user.email = email or existing_user.email
                existing_user.first_name = first_name or existing_user.first_name
                existing_user.last_name = last_name or existing_user.last_name
                existing_user.updated_at = datetime.utcnow()
                
                # Update cache
                self._user_cache[existing_user.id] = existing_user
                
                logger.info(f"Updated existing user: {existing_user.id}")
                return existing_user
            else:
                # Create new user
                user = User(
                    id=str(uuid.uuid4()),
                    apple_user_id=apple_user_id,
                    email=email,
                    first_name=first_name,
                    last_name=last_name,
                    user_identifier=user_identifier,
                    created_at=datetime.utcnow(),
                    updated_at=datetime.utcnow()
                )
                
                # Add to cache
                self._user_cache[user.id] = user
                
                logger.info(f"Created new user: {user.id}")
                return user
                
        except Exception as e:
            logger.error(f"Failed to create/update user: {str(e)}")
            raise
    
    def get_user_by_id(self, user_id: str) -> Optional[User]:
        """
        Get user by internal ID
        """
        try:
            # Check cache first
            if user_id in self._user_cache:
                return self._user_cache[user_id]
            
            # Try to load from CloudKit
            user_data = self.cloudkit.get_user_profile(user_id)
            if user_data:
                user = User.from_dict(user_data)
                self._user_cache[user_id] = user
                return user
            
            return None
            
        except Exception as e:
            logger.error(f"Failed to get user by ID {user_id}: {str(e)}")
            return None
    
    def update_user(self, user_id: str, update_data: Dict[str, Any]) -> Optional[User]:
        """
        Update user with new data
        """
        try:
            user = self.get_user_by_id(user_id)
            if not user:
                return None
            
            # Update fields
            if 'email' in update_data:
                user.email = update_data['email']
            if 'firstName' in update_data:
                user.first_name = update_data['firstName']
            if 'lastName' in update_data:
                user.last_name = update_data['lastName']
            
            user.updated_at = datetime.utcnow()
            
            # Update cache
            self._user_cache[user_id] = user
            
            logger.info(f"Updated user: {user_id}")
            return user
            
        except Exception as e:
            logger.error(f"Failed to update user {user_id}: {str(e)}")
            return None
    
    def delete_user(self, user_id: str) -> bool:
        """
        Delete user account
        """
        try:
            # Remove from cache
            if user_id in self._user_cache:
                del self._user_cache[user_id]
            
            # Delete from CloudKit
            success = self.cloudkit.delete_user_profile(user_id)
            
            if success:
                logger.info(f"Deleted user: {user_id}")
            
            return success
            
        except Exception as e:
            logger.error(f"Failed to delete user {user_id}: {str(e)}")
            return False
    
    def _find_user_by_apple_id(self, apple_user_id: str) -> Optional[User]:
        """
        Find user by Apple ID (searches cache and CloudKit)
        """
        try:
            # Search cache first
            for user in self._user_cache.values():
                if user.apple_user_id == apple_user_id:
                    return user
            
            # Search CloudKit - this would require a custom query method
            # For now, we'll rely on the cache and creation logic
            return None
            
        except Exception as e:
            logger.error(f"Failed to find user by Apple ID {apple_user_id}: {str(e)}")
            return None
    
    def get_token_expiry(self) -> datetime:
        """
        Get token expiry time
        """
        return datetime.utcnow() + timedelta(hours=2)
    
    def get_user_statistics(self, user_id: str) -> Dict[str, Any]:
        """
        Get user usage statistics
        """
        try:
            user = self.get_user_by_id(user_id)
            if not user:
                return {}
            
            # Get user's data from CloudKit
            chat_history = self.cloudkit.get_conversation_history(user_id, "", limit=100)
            birth_charts = self.cloudkit.get_birth_chart(user_id)
            horoscopes = []  # Would need to implement horoscope history
            
            return {
                'total_chats': len(chat_history),
                'charts_generated': 1 if birth_charts else 0,
                'member_since': user.created_at.isoformat(),
                'last_active': user.updated_at.isoformat()
            }
            
        except Exception as e:
            logger.error(f"Failed to get user statistics for {user_id}: {str(e)}")
            return {}
    
    def is_premium_user(self, user_id: str) -> bool:
        """
        Check if user has premium subscription
        TODO: Integrate with actual subscription service
        """
        # For now, all authenticated users are considered premium
        user = self.get_user_by_id(user_id)
        return user is not None