"""
Pydantic 스키마 정의
"""
from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional, List, Dict, Any
from enum import Enum

# 사용자 관련 스키마
class UserType(str, Enum):
    CAREGIVER = "caregiver"
    GUARDIAN = "guardian"
    ADMIN = "admin"

class UserBase(BaseModel):
    user_code: str
    user_type: UserType
    name: str
    email: Optional[EmailStr] = None
    phone: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    user_code: str
    password: str

class UserResponse(UserBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_type: UserType
    user_code: str
    expires_in: int
# 시니어 관련 스키마
class SeniorBase(BaseModel):
    name: str
    age: Optional[int] = None
    gender: Optional[str] = None
    photo: Optional[str] = None
    diseases: Optional[Dict[str, Any]] = None
    preferences: Optional[Dict[str, Any]] = None

class SeniorCreate(SeniorBase):
    caregiver_id: int
    guardian_id: int
    nursing_home_id: Optional[int] = None

class SeniorResponse(SeniorBase):
    id: int
    caregiver_id: int
    guardian_id: int
    nursing_home_id: Optional[int] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# 돌봄 세션 관련 스키마
class CareSessionStatus(str, Enum):
    ACTIVE = "active"
    COMPLETED = "completed"
    CANCELLED = "cancelled"

class CareSessionBase(BaseModel):
    senior_id: int
    start_location: Optional[str] = None
    end_location: Optional[str] = None

class CareSessionCreate(CareSessionBase):
    caregiver_id: int

class CareSessionResponse(CareSessionBase):
    id: int
    caregiver_id: int
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    start_photo: Optional[str] = None
    end_photo: Optional[str] = None
    status: CareSessionStatus
    created_at: datetime
    
    class Config:
        from_attributes = True
# 체크리스트 관련 스키마
class ChecklistResponseBase(BaseModel):
    question_key: str
    question_text: Optional[str] = None
    answer: str
    notes: Optional[str] = None

class ChecklistResponseCreate(ChecklistResponseBase):
    session_id: int

class ChecklistResponseResponse(ChecklistResponseBase):
    id: int
    session_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class ChecklistSubmission(BaseModel):
    session_id: int
    responses: List[ChecklistResponseBase]

# 돌봄노트 관련 스키마
class CareNoteBase(BaseModel):
    question_type: str
    question_text: Optional[str] = None
    content: str

class CareNoteCreate(CareNoteBase):
    session_id: int

class CareNoteResponse(CareNoteBase):
    id: int
    session_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class CareNoteSubmission(BaseModel):
    session_id: int
    notes: List[CareNoteBase]
# AI 리포트 관련 스키마
class AIReportBase(BaseModel):
    keywords: List[str]
    content: str
    ai_comment: Optional[str] = None

class AIReportCreate(AIReportBase):
    session_id: int

class AIReportResponse(AIReportBase):
    id: int
    session_id: int
    status: str
    created_at: datetime
    
    class Config:
        from_attributes = True

# 피드백 관련 스키마
class FeedbackBase(BaseModel):
    message: str
    requirements: Optional[str] = None

class FeedbackCreate(FeedbackBase):
    report_id: int
    guardian_id: int

class FeedbackResponse(FeedbackBase):
    id: int
    report_id: int
    guardian_id: int
    status: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class FeedbackSubmission(BaseModel):
    report_id: int
    message: str
    requirements: Optional[str] = None

# 알림 관련 스키마
class NotificationBase(BaseModel):
    type: str
    title: str
    content: str
    data: Optional[Dict[str, Any]] = None

class NotificationCreate(NotificationBase):
    sender_id: Optional[int] = None
    receiver_id: int

class NotificationResponse(NotificationBase):
    id: int
    sender_id: Optional[int] = None
    receiver_id: int
    is_read: bool
    created_at: datetime
    read_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# 출근/퇴근 관련 스키마
class AttendanceCheckIn(BaseModel):
    senior_id: int
    location: str

class AttendanceCheckOut(BaseModel):
    session_id: int
    location: str

# 케어기버 홈 화면 스키마
class CaregiverHomeResponse(BaseModel):
    caregiver_name: str
    today_sessions: List[CareSessionResponse]
    seniors: List[SeniorResponse]
    notifications: List[NotificationResponse]

# 가디언 홈 화면 스키마
class GuardianHomeResponse(BaseModel):
    guardian_name: str
    seniors: List[SeniorResponse]
    recent_reports: List[AIReportResponse]
    unread_notifications: List[NotificationResponse]
