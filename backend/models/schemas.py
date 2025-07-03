from pydantic import BaseModel, Field, validator
from typing import List, Optional
from datetime import datetime

class ChatRequest(BaseModel):
    conversationId: Optional[str] = None
    message: str
    context: Optional[dict] = None

class MatchUser(BaseModel):
    birth_date: str
    birth_time: str
    timezone: str
    latitude: float
    longitude: float
    
    @validator('birth_date')
    def validate_birth_date(cls, v):
        try:
            datetime.strptime(v, '%Y-%m-%d')
            return v
        except ValueError:
            raise ValueError('Birth date must be in YYYY-MM-DD format')
    
    @validator('birth_time')
    def validate_birth_time(cls, v):
        try:
            datetime.strptime(v, '%H:%M')
            return v
        except ValueError:
            raise ValueError('Birth time must be in HH:MM format')
    
    @validator('latitude')
    def validate_latitude(cls, v):
        if not -90 <= v <= 90:
            raise ValueError('Latitude must be between -90 and 90')
        return v
    
    @validator('longitude')
    def validate_longitude(cls, v):
        if not -180 <= v <= 180:
            raise ValueError('Longitude must be between -180 and 180')
        return v

class MatchPartner(BaseModel):
    name: str
    birth_date: str
    birth_time: str
    timezone: str
    latitude: float
    longitude: float
    
    @validator('birth_date')
    def validate_birth_date(cls, v):
        try:
            datetime.strptime(v, '%Y-%m-%d')
            return v
        except ValueError:
            raise ValueError('Birth date must be in YYYY-MM-DD format')
    
    @validator('birth_time')
    def validate_birth_time(cls, v):
        try:
            datetime.strptime(v, '%H:%M')
            return v
        except ValueError:
            raise ValueError('Birth time must be in HH:MM format')
    
    @validator('latitude')
    def validate_latitude(cls, v):
        if not -90 <= v <= 90:
            raise ValueError('Latitude must be between -90 and 90')
        return v
    
    @validator('longitude')
    def validate_longitude(cls, v):
        if not -180 <= v <= 180:
            raise ValueError('Longitude must be between -180 and 180')
        return v

class MatchRequest(BaseModel):
    user: MatchUser
    partner: MatchPartner
    matchType: str
    systems: List[str]

class SimpleMatchRequest(BaseModel):
    person1: dict
    person2: dict
    systems: List[str] = ["western"]
    match_type: str = "compatibility"

class ChartBirthData(BaseModel):
    date: str
    time: str
    timezone: str
    latitude: float
    longitude: float
    
    @validator('date')
    def validate_date(cls, v):
        try:
            datetime.strptime(v, '%Y-%m-%d')
            return v
        except ValueError:
            raise ValueError('Date must be in YYYY-MM-DD format')
    
    @validator('time')
    def validate_time(cls, v):
        try:
            datetime.strptime(v, '%H:%M')
            return v
        except ValueError:
            raise ValueError('Time must be in HH:MM format')
    
    @validator('latitude')
    def validate_latitude(cls, v):
        if not -90 <= v <= 90:
            raise ValueError('Latitude must be between -90 and 90')
        return v
    
    @validator('longitude')
    def validate_longitude(cls, v):
        if not -180 <= v <= 180:
            raise ValueError('Longitude must be between -180 and 180')
        return v

class ChartRequest(BaseModel):
    birthData: ChartBirthData
    chartType: str
    systems: List[str]
    options: Optional[dict] = None

class SimpleChartRequest(BaseModel):
    birth_date: str
    birth_time: str
    timezone: str
    latitude: float
    longitude: float
    system: str = "western"
    chart_type: str = "natal"
    
    @validator('birth_date')
    def validate_birth_date(cls, v):
        try:
            datetime.strptime(v, '%Y-%m-%d')
            return v
        except ValueError:
            raise ValueError('Birth date must be in YYYY-MM-DD format')
    
    @validator('birth_time')
    def validate_birth_time(cls, v):
        try:
            datetime.strptime(v, '%H:%M')
            return v
        except ValueError:
            raise ValueError('Birth time must be in HH:MM format')
    
    @validator('latitude')
    def validate_latitude(cls, v):
        if not -90 <= v <= 90:
            raise ValueError('Latitude must be between -90 and 90')
        return v
    
    @validator('longitude')
    def validate_longitude(cls, v):
        if not -180 <= v <= 180:
            raise ValueError('Longitude must be between -180 and 180')
        return v

class ReportRequest(BaseModel):
    title: str
    content: str

class DetailedReportRequest(BaseModel):
    birthData: ChartBirthData
    reportType: str  # "love_forecast", "birth_chart", "career_forecast", "year_ahead"
    options: Optional[dict] = None
    userId: Optional[str] = None
    
    @validator('reportType')
    def validate_report_type(cls, v):
        allowed_types = ["love_forecast", "birth_chart", "career_forecast", "year_ahead"]
        if v not in allowed_types:
            raise ValueError(f'Report type must be one of: {", ".join(allowed_types)}')
        return v

class SimpleReportRequest(BaseModel):
    birth_date: str
    birth_time: str
    timezone: str
    latitude: float
    longitude: float
    report_type: str = "personality"
    
    @validator('birth_date')
    def validate_birth_date(cls, v):
        try:
            datetime.strptime(v, '%Y-%m-%d')
            return v
        except ValueError:
            raise ValueError('Birth date must be in YYYY-MM-DD format')
    
    @validator('birth_time')
    def validate_birth_time(cls, v):
        try:
            datetime.strptime(v, '%H:%M')
            return v
        except ValueError:
            raise ValueError('Birth time must be in HH:MM format')
    
    @validator('latitude')
    def validate_latitude(cls, v):
        if not -90 <= v <= 90:
            raise ValueError('Latitude must be between -90 and 90')
        return v
    
    @validator('longitude')
    def validate_longitude(cls, v):
        if not -180 <= v <= 180:
            raise ValueError('Longitude must be between -180 and 180')
        return v

class AppleAuthRequest(BaseModel):
    idToken: str
    userIdentifier: str
    email: Optional[str] = None
    firstName: Optional[str] = None
    lastName: Optional[str] = None
    
    @validator('idToken')
    def validate_id_token(cls, v):
        if not v or len(v) < 100:  # Basic validation
            raise ValueError('Invalid Apple ID token format')
        return v
    
    @validator('userIdentifier')
    def validate_user_identifier(cls, v):
        if not v:
            raise ValueError('User identifier is required')
        return v
