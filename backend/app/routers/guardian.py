"""
가디언 관련 라우터
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, date

from ..database import get_db
from ..models import User, Senior, AIReport, CareSession, Feedback, Notification
from ..schemas import (
    GuardianHomeResponse, AIReportResponse, FeedbackSubmission, 
    SeniorResponse, NotificationResponse
)
from ..services.auth import get_current_user
from ..services.notification import NotificationService

router = APIRouter()

@router.get("/home", response_model=GuardianHomeResponse)
async def get_guardian_home(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """가디언 홈 화면 데이터 조회"""
    try:
        # 담당 시니어 목록 조회
        seniors = db.query(Senior).filter(
            Senior.guardian_id == current_user.id
        ).all()
        
        senior_ids = [senior.id for senior in seniors]
        
        # 최근 리포트 조회 (최근 10개)
        recent_reports = db.query(AIReport).join(CareSession).filter(
            CareSession.senior_id.in_(senior_ids)
        ).order_by(AIReport.created_at.desc()).limit(10).all()
        
        # 읽지 않은 알림 조회
        unread_notifications = db.query(Notification).filter(
            Notification.receiver_id == current_user.id,
            Notification.is_read == False
        ).order_by(Notification.created_at.desc()).limit(10).all()
        
        return GuardianHomeResponse(
            guardian_name=current_user.name,
            seniors=seniors,
            recent_reports=recent_reports,
            unread_notifications=unread_notifications
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"홈 데이터 조회 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/seniors", response_model=List[SeniorResponse])
async def get_guardian_seniors(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """담당 시니어 목록 조회"""
    try:
        seniors = db.query(Senior).filter(
            Senior.guardian_id == current_user.id
        ).all()
        
        return seniors
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"시니어 목록 조회 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/reports", response_model=List[AIReportResponse])
async def get_reports(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    senior_id: Optional[int] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """AI 리포트 목록 조회"""
    try:
        # 가디언이 담당하는 시니어들 조회
        seniors = db.query(Senior).filter(
            Senior.guardian_id == current_user.id
        ).all()
        
        senior_ids = [senior.id for senior in seniors]
        
        # 리포트 쿼리 작성
        query = db.query(AIReport).join(CareSession).filter(
            CareSession.senior_id.in_(senior_ids)
        )
        
        # 필터 적용
        if start_date:
            query = query.filter(AIReport.created_at >= start_date)
        if end_date:
            query = query.filter(AIReport.created_at <= end_date)
        if senior_id:
            if senior_id not in senior_ids:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="해당 시니어의 리포트에 접근할 권한이 없습니다."
                )
            query = query.filter(CareSession.senior_id == senior_id)
        
        reports = query.order_by(AIReport.created_at.desc()).all()
        
        return reports
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"리포트 목록 조회 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/reports/{report_id}")
async def get_report_detail(
    report_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """AI 리포트 상세 조회"""
    try:
        # 리포트 조회
        report = db.query(AIReport).filter(AIReport.id == report_id).first()
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="리포트를 찾을 수 없습니다."
            )
        
        # 세션 정보 조회
        session = db.query(CareSession).filter(
            CareSession.id == report.session_id
        ).first()
        
        # 시니어 정보 조회
        senior = db.query(Senior).filter(
            Senior.id == session.senior_id
        ).first()
        
        # 권한 확인
        if senior.guardian_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="해당 리포트에 접근할 권한이 없습니다."
            )
        
        # 리포트 읽음 상태 업데이트
        if report.status == "generated":
            report.status = "read"
            db.commit()
        
        return {
            "report": report,
            "session": session,
            "senior": senior,
            "caregiver": session.caregiver
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"리포트 상세 조회 중 오류가 발생했습니다: {str(e)}"
        )

@router.post("/feedback")
async def submit_feedback(
    feedback_data: FeedbackSubmission,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """피드백 제출"""
    try:
        # 리포트 존재 확인
        report = db.query(AIReport).filter(
            AIReport.id == feedback_data.report_id
        ).first()
        
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="리포트를 찾을 수 없습니다."
            )
        
        # 세션 및 시니어 정보 조회
        session = db.query(CareSession).filter(
            CareSession.id == report.session_id
        ).first()
        
        senior = db.query(Senior).filter(
            Senior.id == session.senior_id
        ).first()
        
        # 권한 확인
        if senior.guardian_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="해당 리포트에 피드백할 권한이 없습니다."
            )
        
        # 피드백 생성
        feedback = Feedback(
            report_id=feedback_data.report_id,
            guardian_id=current_user.id,
            message=feedback_data.message,
            requirements=feedback_data.requirements,
            status="pending"
        )
        
        db.add(feedback)
        db.commit()
        db.refresh(feedback)
        
        # 케어기버에게 알림 전송
        notification_service = NotificationService(db)
        await notification_service.send_notification(
            sender_id=current_user.id,
            receiver_id=session.caregiver_id,
            type="feedback",
            title="새로운 피드백이 도착했습니다",
            content=f"{senior.name}님 담당 가디언으로부터 피드백이 도착했습니다.",
            data={"feedback_id": feedback.id, "report_id": report.id}
        )
        
        return {
            "message": "피드백이 성공적으로 제출되었습니다.",
            "feedback_id": feedback.id,
            "status": "pending"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"피드백 제출 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/feedback/history")
async def get_feedback_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """피드백 이력 조회"""
    try:
        feedbacks = db.query(Feedback).filter(
            Feedback.guardian_id == current_user.id
        ).order_by(Feedback.created_at.desc()).all()
        
        return {
            "feedbacks": feedbacks,
            "total_count": len(feedbacks)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"피드백 이력 조회 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/notifications", response_model=List[NotificationResponse])
async def get_notifications(
    unread_only: bool = False,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """알림 목록 조회"""
    try:
        query = db.query(Notification).filter(
            Notification.receiver_id == current_user.id
        )
        
        if unread_only:
            query = query.filter(Notification.is_read == False)
        
        notifications = query.order_by(Notification.created_at.desc()).all()
        
        return notifications
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"알림 목록 조회 중 오류가 발생했습니다: {str(e)}"
        )

@router.put("/notifications/{notification_id}/read")
async def mark_notification_read(
    notification_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """알림 읽음 처리"""
    try:
        notification = db.query(Notification).filter(
            Notification.id == notification_id,
            Notification.receiver_id == current_user.id
        ).first()
        
        if not notification:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="알림을 찾을 수 없습니다."
            )
        
        notification.is_read = True
        notification.read_at = datetime.utcnow()
        
        db.commit()
        
        return {"message": "알림이 읽음 처리되었습니다."}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"알림 읽음 처리 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/profile")
async def get_guardian_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """가디언 프로필 조회"""
    try:
        # 담당 시니어 수 조회
        seniors_count = db.query(Senior).filter(
            Senior.guardian_id == current_user.id
        ).count()
        
        # 총 리포트 수 조회
        seniors = db.query(Senior).filter(
            Senior.guardian_id == current_user.id
        ).all()
        
        senior_ids = [senior.id for senior in seniors]
        
        total_reports = db.query(AIReport).join(CareSession).filter(
            CareSession.senior_id.in_(senior_ids)
        ).count()
        
        return {
            "user_info": current_user,
            "assigned_seniors_count": seniors_count,
            "total_reports": total_reports,
            "pending_feedback": db.query(Feedback).filter(
                Feedback.guardian_id == current_user.id,
                Feedback.status == "pending"
            ).count()
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"프로필 조회 중 오류가 발생했습니다: {str(e)}"
        )
