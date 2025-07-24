"""
관리자 관련 라우터
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, date

from ..database import get_db
from ..models import User, Senior, CareSession, AIReport, Feedback, Notification
from ..schemas import (
    UserCreate, UserResponse, SeniorCreate, SeniorResponse, 
    NotificationCreate, NotificationResponse
)
from ..services.auth import get_current_user, get_password_hash
from ..services.notification import NotificationService

router = APIRouter()

def verify_admin_permission(current_user: User):
    """관리자 권한 확인"""
    if current_user.user_type != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="관리자 권한이 필요합니다."
        )

@router.get("/dashboard")
async def get_admin_dashboard(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """관리자 대시보드 데이터 조회"""
    verify_admin_permission(current_user)
    
    try:
        # 전체 통계 조회
        total_users = db.query(User).count()
        total_caregivers = db.query(User).filter(User.user_type == "caregiver").count()
        total_guardians = db.query(User).filter(User.user_type == "guardian").count()
        total_seniors = db.query(Senior).count()
        
        # 오늘 활동 통계
        today = date.today()
        today_sessions = db.query(CareSession).filter(
            CareSession.created_at >= today
        ).count()
        
        today_reports = db.query(AIReport).filter(
            AIReport.created_at >= today
        ).count()
        
        # 펜딩 피드백 수
        pending_feedbacks = db.query(Feedback).filter(
            Feedback.status == "pending"
        ).count()
        
        # 최근 활동 (최근 20개)
        recent_activities = db.query(CareSession).order_by(
            CareSession.created_at.desc()
        ).limit(20).all()
        
        return {
            "statistics": {
                "total_users": total_users,
                "total_caregivers": total_caregivers,
                "total_guardians": total_guardians,
                "total_seniors": total_seniors,
                "today_sessions": today_sessions,
                "today_reports": today_reports,
                "pending_feedbacks": pending_feedbacks
            },
            "recent_activities": recent_activities
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"대시보드 데이터 조회 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/users", response_model=List[UserResponse])
async def get_users(
    user_type: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """사용자 목록 조회"""
    verify_admin_permission(current_user)
    
    try:
        query = db.query(User)
        
        if user_type:
            query = query.filter(User.user_type == user_type)
        
        users = query.order_by(User.created_at.desc()).all()
        
        return users
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"사용자 목록 조회 중 오류가 발생했습니다: {str(e)}"
        )

@router.post("/users", response_model=UserResponse)
async def create_user(
    user_data: UserCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """새 사용자 생성"""
    verify_admin_permission(current_user)
    
    try:
        # 사용자 코드 중복 확인
        existing_user = db.query(User).filter(
            User.user_code == user_data.user_code
        ).first()
        
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미 존재하는 사용자 코드입니다."
            )
        
        # 이메일 중복 확인
        if user_data.email:
            existing_email = db.query(User).filter(
                User.email == user_data.email
            ).first()
            
            if existing_email:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="이미 존재하는 이메일입니다."
                )
        
        # 새 사용자 생성
        new_user = User(
            user_code=user_data.user_code,
            user_type=user_data.user_type,
            name=user_data.name,
            email=user_data.email,
            phone=user_data.phone,
            password_hash=get_password_hash(user_data.password),
            is_active=True
        )
        
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        
        return new_user
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"사용자 생성 중 오류가 발생했습니다: {str(e)}"
        )

@router.put("/users/{user_id}/activate")
async def activate_user(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """사용자 활성화"""
    verify_admin_permission(current_user)
    
    try:
        user = db.query(User).filter(User.id == user_id).first()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="사용자를 찾을 수 없습니다."
            )
        
        user.is_active = True
        db.commit()
        
        return {"message": "사용자가 활성화되었습니다."}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"사용자 활성화 중 오류가 발생했습니다: {str(e)}"
        )

@router.put("/users/{user_id}/deactivate")
async def deactivate_user(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """사용자 비활성화"""
    verify_admin_permission(current_user)
    
    try:
        user = db.query(User).filter(User.id == user_id).first()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="사용자를 찾을 수 없습니다."
            )
        
        user.is_active = False
        db.commit()
        
        return {"message": "사용자가 비활성화되었습니다."}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"사용자 비활성화 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/seniors", response_model=List[SeniorResponse])
async def get_seniors(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """시니어 목록 조회"""
    verify_admin_permission(current_user)
    
    try:
        seniors = db.query(Senior).order_by(Senior.created_at.desc()).all()
        
        return seniors
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"시니어 목록 조회 중 오류가 발생했습니다: {str(e)}"
        )

@router.post("/seniors", response_model=SeniorResponse)
async def create_senior(
    senior_data: SeniorCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """새 시니어 생성"""
    verify_admin_permission(current_user)
    
    try:
        # 케어기버 및 가디언 존재 확인
        caregiver = db.query(User).filter(
            User.id == senior_data.caregiver_id,
            User.user_type == "caregiver"
        ).first()
        
        if not caregiver:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="케어기버를 찾을 수 없습니다."
            )
        
        guardian = db.query(User).filter(
            User.id == senior_data.guardian_id,
            User.user_type == "guardian"
        ).first()
        
        if not guardian:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="가디언을 찾을 수 없습니다."
            )
        
        # 새 시니어 생성
        new_senior = Senior(
            name=senior_data.name,
            age=senior_data.age,
            gender=senior_data.gender,
            photo=senior_data.photo,
            caregiver_id=senior_data.caregiver_id,
            guardian_id=senior_data.guardian_id,
            nursing_home_id=senior_data.nursing_home_id,
            diseases=senior_data.diseases,
            preferences=senior_data.preferences
        )
        
        db.add(new_senior)
        db.commit()
        db.refresh(new_senior)
        
        return new_senior
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"시니어 생성 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/reports")
async def get_reports(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """리포트 목록 조회"""
    verify_admin_permission(current_user)
    
    try:
        query = db.query(AIReport)
        
        if start_date:
            query = query.filter(AIReport.created_at >= start_date)
        if end_date:
            query = query.filter(AIReport.created_at <= end_date)
        
        reports = query.order_by(AIReport.created_at.desc()).all()
        
        return {
            "reports": reports,
            "total_count": len(reports)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"리포트 목록 조회 중 오류가 발생했습니다: {str(e)}"
        )

@router.post("/notifications/broadcast")
async def broadcast_notification(
    notification_data: NotificationCreate,
    user_type: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """전체 또는 특정 사용자 그룹에 알림 전송"""
    verify_admin_permission(current_user)
    
    try:
        # 대상 사용자 조회
        query = db.query(User).filter(User.is_active == True)
        
        if user_type:
            query = query.filter(User.user_type == user_type)
        
        target_users = query.all()
        
        # 알림 서비스 초기화
        notification_service = NotificationService(db)
        
        # 각 사용자에게 알림 전송
        sent_count = 0
        for user in target_users:
            await notification_service.send_notification(
                sender_id=current_user.id,
                receiver_id=user.id,
                type=notification_data.type,
                title=notification_data.title,
                content=notification_data.content,
                data=notification_data.data
            )
            sent_count += 1
        
        return {
            "message": f"알림이 {sent_count}명에게 전송되었습니다.",
            "sent_count": sent_count
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"알림 전송 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/feedbacks")
async def get_feedbacks(
    status: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """피드백 목록 조회"""
    verify_admin_permission(current_user)
    
    try:
        query = db.query(Feedback)
        
        if status:
            query = query.filter(Feedback.status == status)
        
        feedbacks = query.order_by(Feedback.created_at.desc()).all()
        
        return {
            "feedbacks": feedbacks,
            "total_count": len(feedbacks)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"피드백 목록 조회 중 오류가 발생했습니다: {str(e)}"
        )

@router.put("/feedbacks/{feedback_id}/status")
async def update_feedback_status(
    feedback_id: int,
    status: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """피드백 상태 업데이트"""
    verify_admin_permission(current_user)
    
    try:
        feedback = db.query(Feedback).filter(Feedback.id == feedback_id).first()
        
        if not feedback:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="피드백을 찾을 수 없습니다."
            )
        
        feedback.status = status
        feedback.updated_at = datetime.utcnow()
        
        db.commit()
        
        return {"message": "피드백 상태가 업데이트되었습니다."}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"피드백 상태 업데이트 중 오류가 발생했습니다: {str(e)}"
        )
