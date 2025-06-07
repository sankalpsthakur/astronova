from pydantic import BaseModel, Field
from typing import List, Optional

class ChatRequest(BaseModel):
    conversationId: Optional[str] = None
    message: str
    context: Optional[dict] = None

class MatchUser(BaseModel):
    birthDate: str
    birthTime: str
    timezone: str
    latitude: float
    longitude: float

class MatchPartner(MatchUser):
    name: str

class MatchRequest(BaseModel):
    user: MatchUser
    partner: MatchPartner
    matchType: str
    systems: List[str]

class ChartBirthData(BaseModel):
    date: str
    time: str
    timezone: str
    latitude: float
    longitude: float

class ChartRequest(BaseModel):
    birthData: ChartBirthData
    chartType: str
    systems: List[str]
    options: Optional[dict] = None

class ReportRequest(BaseModel):
    title: str
    content: str
