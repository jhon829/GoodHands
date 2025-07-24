from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey, Text, JSON, Float, DECIMAL
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

# 돌봄 세션 관련 모델
class CareSession(Base):
    __tablename__ = "care_sessions"
    
    id = Column(Integer, primary_key=True, index=True)
    caregiver_id = Column(Integer, ForeignKey("caregivers.id"), nullable=False)
    senior_id = Column(Integer, ForeignKey("seniors.id"), nullable=False)
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime)
    status = Column(String(20), default="active")  # active, completed, cancelled
    start_location = Column(String(255))
    end_location = Column(String(255))
    start_photo = Column(String(255))
    end_photo = Column(String(255))
    created_at = Column(DateTime, server_default=func.now())
    
    # 관계 설정
    caregiver = relationship("Caregiver")
    senior = relationship("Senior")

class AttendanceLog(Base):
    __tablename__ = "attendance_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    care_session_id = Column(Integer, ForeignKey("care_sessions.id"), nullable=False)
    type = Column(String(20), nullable=False)  # checkin, checkout
    location = Column(String(255))
    gps_lat = Column(Float)
    gps_lng = Column(Float)
    photo = Column(String(255))
    created_at = Column(DateTime, server_default=func.now())
    
    # 관계 설정
    care_session = relationship("CareSession")

class ChecklistResponse(Base):
    __tablename__ = "checklist_responses"
    
    id = Column(Integer, primary_key=True, index=True)
    care_session_id = Column(Integer, ForeignKey("care_sessions.id"), nullable=False)
    question_key = Column(String(100), nullable=False)
    question_text = Column(Text)
    answer = Column(JSON)  # Boolean, String, Number 등 다양한 답변 형식
    notes = Column(Text)
    score_value = Column(Integer)  # 점수화된 값
    category = Column(String(50))  # 카테고리 분류
    weight = Column(DECIMAL(3,2), default=1.0)  # 가중치
    created_at = Column(DateTime, server_default=func.now())
    
    # 관계 설정
    care_session = relationship("CareSession")

class CareNote(Base):
    __tablename__ = "care_notes"
    
    id = Column(Integer, primary_key=True, index=True)
    care_session_id = Column(Integer, ForeignKey("care_sessions.id"), nullable=False)
    question_type = Column(String(50), nullable=False)  # special_moments, family_longing 등
    question_text = Column(Text)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, server_default=func.now())
    
    # 관계 설정
    care_session = relationship("CareSession")
