import time
from typing import Any, Optional
from functools import lru_cache

_cache = {}

def get(key: str) -> Optional[Any]:
    entry = _cache.get(key)
    if not entry:
        return None
    value, expires_at = entry
    if expires_at is not None and expires_at < time.time():
        del _cache[key]
        return None
    return value

def set(key: str, value: Any, ttl: Optional[int] = None) -> None:
    expires_at = time.time() + ttl if ttl is not None else None
    _cache[key] = (value, expires_at)

def cache(maxsize: int = 128):
    """Simple cache decorator using functools.lru_cache."""
    def decorator(func):
        return lru_cache(maxsize=maxsize)(func)
    return decorator
