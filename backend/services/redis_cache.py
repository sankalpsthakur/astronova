import json
import os
from typing import Any, Optional

import redis

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
try:
    _client = redis.Redis.from_url(REDIS_URL)
    _client.ping()
except Exception:
    _client = None


def get(key: str) -> Optional[Any]:
    if not _client:
        return None
    try:
        val = _client.get(key)
        if val is None:
            return None
        return json.loads(val)
    except Exception:
        return None


def set(key: str, value: Any, ttl: int = 3600) -> None:
    if not _client:
        return
    try:
        _client.setex(key, ttl, json.dumps(value))
    except Exception:
        pass
