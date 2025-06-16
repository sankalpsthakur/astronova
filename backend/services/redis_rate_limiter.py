"""
Redis-based rate limiter service for AstroNova API
Provides flexible rate limiting with multiple time windows and user-specific limits
"""

import time
import json
from typing import Optional, Dict, Tuple, List
import redis
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)

class RateLimitExceeded(Exception):
    """Exception raised when rate limit is exceeded"""
    def __init__(self, message: str, reset_time: int, remaining: int = 0):
        self.message = message
        self.reset_time = reset_time
        self.remaining = remaining
        super().__init__(self.message)

class RedisRateLimiter:
    """
    Redis-based rate limiter with sliding window algorithm
    Supports multiple rate limit rules and user-specific overrides
    """
    
    def __init__(self, redis_url: str = "redis://localhost:6379/0"):
        """
        Initialize Redis rate limiter
        
        Args:
            redis_url: Redis connection URL
        """
        self.redis_client = redis.from_url(redis_url, decode_responses=True)
        self.default_limits = {
            # Format: "requests/window_seconds"
            "default": [
                {"requests": 200, "window": 86400},  # 200 per day
                {"requests": 50, "window": 3600},    # 50 per hour
                {"requests": 10, "window": 60}       # 10 per minute
            ],
            "chat": [
                {"requests": 30, "window": 3600},    # 30 per hour for chat
                {"requests": 5, "window": 60}        # 5 per minute for chat
            ],
            "chart": [
                {"requests": 10, "window": 3600},    # 10 per hour for chart generation
                {"requests": 2, "window": 60}        # 2 per minute for chart generation
            ],
            "ephemeris": [
                {"requests": 100, "window": 3600},   # 100 per hour for ephemeris
                {"requests": 20, "window": 60}       # 20 per minute for ephemeris
            ]
        }
        
    def _get_user_limits(self, user_id: str, endpoint: str) -> List[Dict]:
        """
        Get rate limits for a specific user and endpoint
        
        Args:
            user_id: User identifier
            endpoint: API endpoint category
            
        Returns:
            List of rate limit rules
        """
        # Check for user-specific overrides in Redis
        override_key = f"rate_limit:override:{user_id}:{endpoint}"
        override = self.redis_client.get(override_key)
        
        if override:
            try:
                return json.loads(override)
            except json.JSONDecodeError:
                logger.warning(f"Invalid override format for {override_key}")
        
        # Return default limits for endpoint or general default
        return self.default_limits.get(endpoint, self.default_limits["default"])
    
    def _get_window_key(self, user_id: str, endpoint: str, window: int) -> str:
        """Generate Redis key for rate limit window"""
        current_window = int(time.time()) // window
        return f"rate_limit:{user_id}:{endpoint}:{window}:{current_window}"
    
    def _check_single_limit(self, user_id: str, endpoint: str, limit_rule: Dict) -> Tuple[bool, int, int]:
        """
        Check a single rate limit rule
        
        Args:
            user_id: User identifier
            endpoint: API endpoint category
            limit_rule: Rate limit rule with 'requests' and 'window'
            
        Returns:
            Tuple of (is_allowed, remaining_requests, reset_time)
        """
        requests = limit_rule["requests"]
        window = limit_rule["window"]
        
        key = self._get_window_key(user_id, endpoint, window)
        current_window = int(time.time()) // window
        reset_time = (current_window + 1) * window
        
        # Use Redis pipeline for atomic operations
        pipe = self.redis_client.pipeline()
        pipe.get(key)
        pipe.incr(key)
        pipe.expire(key, window)
        results = pipe.execute()
        
        current_count = int(results[1])  # Count after increment
        remaining = max(0, requests - current_count)
        
        is_allowed = current_count <= requests
        
        if not is_allowed:
            logger.warning(
                f"Rate limit exceeded for user {user_id} on {endpoint}: "
                f"{current_count}/{requests} in {window}s window"
            )
        
        return is_allowed, remaining, reset_time
    
    def check_rate_limit(self, user_id: str, endpoint: str = "default") -> Dict:
        """
        Check if request is allowed under rate limits
        
        Args:
            user_id: User identifier (IP address, user ID, API key, etc.)
            endpoint: API endpoint category for specific limits
            
        Returns:
            Dict with rate limit status and metadata
            
        Raises:
            RateLimitExceeded: If any rate limit is exceeded
        """
        if not user_id:
            user_id = "anonymous"
            
        limits = self._get_user_limits(user_id, endpoint)
        
        # Check all rate limit rules
        strictest_remaining = float('inf')
        earliest_reset = 0
        
        for limit_rule in limits:
            is_allowed, remaining, reset_time = self._check_single_limit(
                user_id, endpoint, limit_rule
            )
            
            if not is_allowed:
                raise RateLimitExceeded(
                    f"Rate limit exceeded: {limit_rule['requests']} requests per "
                    f"{limit_rule['window']} seconds",
                    reset_time,
                    remaining
                )
            
            strictest_remaining = min(strictest_remaining, remaining)
            earliest_reset = max(earliest_reset, reset_time)
        
        return {
            "allowed": True,
            "remaining": int(strictest_remaining) if strictest_remaining != float('inf') else 0,
            "reset_time": earliest_reset,
            "endpoint": endpoint,
            "user_id": user_id
        }
    
    def get_rate_limit_status(self, user_id: str, endpoint: str = "default") -> Dict:
        """
        Get current rate limit status without incrementing counters
        
        Args:
            user_id: User identifier
            endpoint: API endpoint category
            
        Returns:
            Dict with current rate limit status
        """
        if not user_id:
            user_id = "anonymous"
            
        limits = self._get_user_limits(user_id, endpoint)
        status = []
        
        for limit_rule in limits:
            requests = limit_rule["requests"]
            window = limit_rule["window"]
            key = self._get_window_key(user_id, endpoint, window)
            
            current_count = int(self.redis_client.get(key) or 0)
            remaining = max(0, requests - current_count)
            current_window = int(time.time()) // window
            reset_time = (current_window + 1) * window
            
            status.append({
                "limit": requests,
                "window": window,
                "used": current_count,
                "remaining": remaining,
                "reset_time": reset_time,
                "reset_datetime": datetime.fromtimestamp(reset_time).isoformat()
            })
        
        return {
            "endpoint": endpoint,
            "user_id": user_id,
            "limits": status
        }
    
    def set_user_override(self, user_id: str, endpoint: str, limits: List[Dict], 
                         expiry_hours: int = 24) -> bool:
        """
        Set custom rate limits for a specific user
        
        Args:
            user_id: User identifier
            endpoint: API endpoint category
            limits: List of rate limit rules
            expiry_hours: Hours until override expires
            
        Returns:
            True if override was set successfully
        """
        try:
            override_key = f"rate_limit:override:{user_id}:{endpoint}"
            self.redis_client.setex(
                override_key,
                expiry_hours * 3600,
                json.dumps(limits)
            )
            
            logger.info(f"Set rate limit override for {user_id}:{endpoint}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to set rate limit override: {e}")
            return False
    
    def remove_user_override(self, user_id: str, endpoint: str) -> bool:
        """
        Remove custom rate limits for a specific user
        
        Args:
            user_id: User identifier
            endpoint: API endpoint category
            
        Returns:
            True if override was removed successfully
        """
        try:
            override_key = f"rate_limit:override:{user_id}:{endpoint}"
            deleted = self.redis_client.delete(override_key)
            
            if deleted:
                logger.info(f"Removed rate limit override for {user_id}:{endpoint}")
            
            return bool(deleted)
            
        except Exception as e:
            logger.error(f"Failed to remove rate limit override: {e}")
            return False
    
    def reset_user_limits(self, user_id: str, endpoint: str = None) -> bool:
        """
        Reset rate limit counters for a user
        
        Args:
            user_id: User identifier
            endpoint: Specific endpoint to reset, or None for all
            
        Returns:
            True if reset was successful
        """
        try:
            if endpoint:
                pattern = f"rate_limit:{user_id}:{endpoint}:*"
            else:
                pattern = f"rate_limit:{user_id}:*"
            
            keys = self.redis_client.keys(pattern)
            if keys:
                deleted = self.redis_client.delete(*keys)
                logger.info(f"Reset {deleted} rate limit keys for {user_id}")
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to reset rate limits: {e}")
            return False
    
    def get_top_users(self, endpoint: str = None, limit: int = 10) -> List[Dict]:
        """
        Get top users by request count
        
        Args:
            endpoint: Specific endpoint to analyze
            limit: Maximum number of users to return
            
        Returns:
            List of user statistics
        """
        try:
            if endpoint:
                pattern = f"rate_limit:*:{endpoint}:*"
            else:
                pattern = "rate_limit:*"
            
            keys = self.redis_client.keys(pattern)
            user_stats = {}
            
            for key in keys:
                parts = key.split(':')
                if len(parts) >= 4:
                    user_id = parts[2]
                    count = int(self.redis_client.get(key) or 0)
                    
                    if user_id not in user_stats:
                        user_stats[user_id] = 0
                    user_stats[user_id] += count
            
            # Sort by request count and return top users
            top_users = sorted(
                [{"user_id": uid, "total_requests": count} 
                 for uid, count in user_stats.items()],
                key=lambda x: x["total_requests"],
                reverse=True
            )[:limit]
            
            return top_users
            
        except Exception as e:
            logger.error(f"Failed to get top users: {e}")
            return []
    
    def health_check(self) -> Dict:
        """
        Check Redis connection and rate limiter health
        
        Returns:
            Dict with health status and metrics
        """
        try:
            # Test Redis connection
            self.redis_client.ping()
            
            # Get some basic metrics
            info = self.redis_client.info('memory')
            used_memory = info.get('used_memory_human', 'unknown')
            
            # Count rate limit keys
            keys = self.redis_client.keys('rate_limit:*')
            active_limits = len(keys)
            
            return {
                "status": "healthy",
                "redis_connected": True,
                "used_memory": used_memory,
                "active_limits": active_limits,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Rate limiter health check failed: {e}")
            return {
                "status": "unhealthy",
                "redis_connected": False,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }

# Global rate limiter instance
rate_limiter = None

def get_rate_limiter(redis_url: str = None) -> RedisRateLimiter:
    """
    Get or create global rate limiter instance
    
    Args:
        redis_url: Redis connection URL (optional)
        
    Returns:
        RedisRateLimiter instance
    """
    global rate_limiter
    
    if rate_limiter is None:
        import os
        redis_url = redis_url or os.environ.get("REDIS_URL", "redis://localhost:6379/0")
        rate_limiter = RedisRateLimiter(redis_url)
    
    return rate_limiter