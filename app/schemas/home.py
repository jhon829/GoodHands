"""
홈 화면 관련 스키마
"""
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from .senior import SeniorResponse
from .care import CareSessionResponse
from .report import AIReportResponse, NotificationResponse

class CaregiverHomeResponse(BaseModel):
    caregiver_name: str
    today_sessions: List[CareSessionResponse]
    seniors: List[SeniorResponse]
    notifications: List[NotificationResponse]
    
    class Config:
        from_attributes = True

class GuardianHomeResponse(BaseModel):
    guardian_name: str
    seniors: List[SeniorResponse]
    recent_reports: List[AIReportResponse]
    unread_notifications: List[NotificationResponse]
    
    class Config:
        from_attributes = True

class AdminHomeResponse(BaseModel):
    admin_name: str
    total_users: int
    total_seniors: int
    total_reports: int
    recent_activities: List[dict]
    system_status: dict
    
    class Config:
        from_attributes = True

class DashboardStats(BaseModel):
    total_caregivers: int
    total_guardians: int
    total_seniors: int
    active_sessions: int
    reports_today: int
    pending_feedbacks: int

class ActivityLog(BaseModel):
    id: int
    user_id: int
    user_name: str
    user_type: str
    action: str
    description: str
    timestamp: datetime
    
    class Config:
        from_attributes = True
