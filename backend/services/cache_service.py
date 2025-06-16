"""
FastAPI-compatible cache service using Redis
"""
import redis
import json
import pickle
from typing import Any, Optional, Union
import os
import logging

logger = logging.getLogger(__name__)

class FastAPICache:
    """Redis-based cache service compatible with FastAPI"""
    
    def __init__(self, redis_url: str = None):
        self.redis_url = redis_url or os.environ.get("REDIS_URL", "redis://localhost:6379/0")
        try:
            self.redis_client = redis.from_url(self.redis_url, decode_responses=False)
            # Test connection
            self.redis_client.ping()
            logger.info(f"Cache service connected to Redis: {self.redis_url}")
        except Exception as e:
            logger.warning(f"Cache service failed to connect to Redis: {e}")
            self.redis_client = None
    
    def get(self, key: str) -> Any:
        """Get value from cache"""
        if not self.redis_client:
            return None
            
        try:
            value = self.redis_client.get(key)
            if value is None:
                return None
            return pickle.loads(value)
        except Exception as e:
            logger.error(f"Cache get error for key {key}: {e}")
            return None
    
    def set(self, key: str, value: Any, timeout: int = 300) -> bool:
        """Set value in cache with timeout in seconds"""
        if not self.redis_client:
            return False
            
        try:
            serialized_value = pickle.dumps(value)
            return self.redis_client.setex(key, timeout, serialized_value)
        except Exception as e:
            logger.error(f"Cache set error for key {key}: {e}")
            return False
    
    def delete(self, key: str) -> bool:
        """Delete key from cache"""
        if not self.redis_client:
            return False
            
        try:
            return bool(self.redis_client.delete(key))
        except Exception as e:
            logger.error(f"Cache delete error for key {key}: {e}")
            return False
    
    def clear(self) -> bool:
        """Clear all cache"""
        if not self.redis_client:
            return False
            
        try:
            return self.redis_client.flushdb()
        except Exception as e:
            logger.error(f"Cache clear error: {e}")
            return False
    
    def has(self, key: str) -> bool:
        """Check if key exists in cache"""
        if not self.redis_client:
            return False
            
        try:
            return bool(self.redis_client.exists(key))
        except Exception as e:
            logger.error(f"Cache exists check error for key {key}: {e}")
            return False

# Global cache instance
cache = FastAPICache()
