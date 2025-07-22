"""
데이터베이스 모델 정의
"""
from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, ForeignKey, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime

Base = declarative_base()

class User(Base):
    """사용자 테이블"""
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    user_code = Column(String(10), unique=True, index=True, nullable=False)
    user_type = Column(String(20), nullable=False)  # caregiver, guardian, admin
    name = Column(String(50), nullable=False)
    password_hash = Column(String(255), nullable=False)
    email = Column(String(100), unique=True, index=True)
    phone = Column(String(20))
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # 관계 설정
    caregiver_sessions = relationship("CareSession", foreign_keys="CareSession.caregiver_id", back_populates="caregiver")
    guardian_seniors = relationship("Senior", foreign_keys="Senior.guardian_id", back_populates="guardian")
    feedbacks = relationship("Feedback", back_populates="guardian")

class Senior(Base):
    """시니어 테이블"""
    __tablename__ = "seniors"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), nullable=False)
    age = Column(Integer)
    gender = Column(String(10))
    photo = Column(String(255))
    caregiver_id = Column(Integer, ForeignKey("users.id"))
    guardian_id = Column(Integer, ForeignKey("users.id"))
    nursing_home_id = Column(Integer, ForeignKey("nursing_homes.id"))
    diseases = Column(JSON)  # 질병 정보를 JSON으로 저장
    preferences = Column(JSON)  # 선호사항을 JSON으로 저장
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # 관계 설정
    caregiver = relationship("User", foreign_keys=[caregiver_id])
    guardian = relationship("User", foreign_keys=[guardian_id], back_populates="guardian_seniors")
    nursing_home = relationship("NursingHome", back_populates="seniors")
    care_sessions = relationship("CareSession", back_populates="senior")

class NursingHome(Base):
    """요양원 테이블"""
    __tablename__ = "nursing_homes"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    address = Column(String(200))
    phone = Column(String(20))
    contact_person = Column(String(50))
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # 관계 설정
    seniors = relationship("Senior", back_populates="nursing_home")

class CareSession(Base):
    """돌봄 세션 테이블"""
    __tablename__ = "care_sessions"
    
    id = Column(Integer, primary_key=True, index=True)
    caregiver_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    senior_id = Column(Integer, ForeignKey("seniors.id"), nullable=False)
    start_time = Column(DateTime)
    end_time = Column(DateTime)
    start_location = Column(String(255))  # GPS 좌표
    end_location = Column(String(255))    # GPS 좌표
    start_photo = Column(String(255))     # 출근 인증 사진
    end_photo = Column(String(255))       # 퇴근 인증 사진
    status = Column(String(20), default="active")  # active, completed, cancelled
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # 관계 설정
    caregiver = relationship("User", foreign_keys=[caregiver_id], back_populates="caregiver_sessions")
    senior = relationship("Senior", back_populates="care_sessions")
    checklist_responses = relationship("ChecklistResponse", back_populates="session")
    care_notes = relationship("CareNote", back_populates="session")
    ai_reports = relationship("AIReport", back_populates="session")
class ChecklistResponse(Base):
    """체크리스트 응답 테이블"""
    __tablename__ = "checklist_responses"
    
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("care_sessions.id"), nullable=False)
    question_key = Column(String(50), nullable=False)
    question_text = Column(Text)
    answer = Column(String(100))  # boolean, select, text 답변
    notes = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # 관계 설정
    session = relationship("CareSession", back_populates="checklist_responses")

class CareNote(Base):
    """돌봄노트 테이블"""
    __tablename__ = "care_notes"
    
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("care_sessions.id"), nullable=False)
    question_type = Column(String(50), nullable=False)
    question_text = Column(Text)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # 관계 설정
    session = relationship("CareSession", back_populates="care_notes")

class AIReport(Base):
    """AI 리포트 테이블"""
    __tablename__ = "ai_reports"
    
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("care_sessions.id"), nullable=False)
    keywords = Column(JSON)  # 키워드 배열
    content = Column(Text, nullable=False)
    ai_comment = Column(Text)
    status = Column(String(20), default="generated")  # generated, sent, read
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # 관계 설정
    session = relationship("CareSession", back_populates="ai_reports")
    feedbacks = relationship("Feedback", back_populates="report")
class Feedback(Base):
    """가디언 피드백 테이블"""
    __tablename__ = "feedbacks"
    
    id = Column(Integer, primary_key=True, index=True)
    report_id = Column(Integer, ForeignKey("ai_reports.id"), nullable=False)
    guardian_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    message = Column(Text, nullable=False)
    requirements = Column(Text)  # 특별 요구사항
    status = Column(String(20), default="pending")  # pending, reviewed, completed
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # 관계 설정
    report = relationship("AIReport", back_populates="feedbacks")
    guardian = relationship("User", back_populates="feedbacks")

class Notification(Base):
    """알림 테이블"""
    __tablename__ = "notifications"
    
    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("users.id"))
    receiver_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    type = Column(String(20), nullable=False)  # report, feedback, notice, alert
    title = Column(String(100), nullable=False)
    content = Column(Text, nullable=False)
    data = Column(JSON)  # 추가 데이터
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    read_at = Column(DateTime)
    
    # 관계 설정
    sender = relationship("User", foreign_keys=[sender_id])
    receiver = relationship("User", foreign_keys=[receiver_id])

# 모든 모델을 한 번에 import할 수 있도록 __all__ 정의
__all__ = [
    "User",
    "Senior", 
    "NursingHome",
    "CareSession",
    "ChecklistResponse",
    "CareNote",
    "AIReport",
    "Feedback",
    "Notification"
]
