from __future__ import annotations

from typing import List, Optional, Dict, Any
from pydantic import BaseModel

class HealthResponse(BaseModel):
    status: str
    service: str
    version: str
    timestamp: str
    environment: str

class ChatResponse(BaseModel):
    reply: str
    messageId: Optional[str] = None
    suggestedFollowUps: List[str]

class MatchResult(BaseModel):
    overallScore: int
    vedicScore: int
    chineseScore: int
    synastryAspects: List[str]
    userChart: Dict[str, Any]
    partnerChart: Dict[str, Any]
