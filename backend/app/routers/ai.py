"""
AI 리포트 관련 라우터
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from ..database import get_db
from ..models import User, CareSession, AIReport, ChecklistResponse, CareNote, Senior
from ..schemas import AIReportResponse, AIReportCreate
from ..services.auth import get_current_user
from ..services.ai_report import AIReportService
from ..services.notification import NotificationService

router = APIRouter()

@router.post("/generate-report")
async def generate_ai_report(
    session_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """AI 리포트 생성"""
    try:
        # 돌봄 세션 확인
        care_session = db.query(CareSession).filter(
            CareSession.id == session_id
        ).first()
        
        if not care_session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="돌봄 세션을 찾을 수 없습니다."
            )
        
        # 케어기버 권한 확인
        if care_session.caregiver_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="해당 세션의 리포트를 생성할 권한이 없습니다."
            )
        
        # 세션이 완료되었는지 확인
        if care_session.status != "completed":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="완료된 세션만 리포트를 생성할 수 있습니다."
            )
        
        # 이미 리포트가 생성되었는지 확인
        existing_report = db.query(AIReport).filter(
            AIReport.session_id == session_id
        ).first()
        
        if existing_report:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미 리포트가 생성된 세션입니다."
            )
        
        # 체크리스트 응답 조회
        checklist_responses = db.query(ChecklistResponse).filter(
            ChecklistResponse.session_id == session_id
        ).all()
        
        # 돌봄노트 조회
        care_notes = db.query(CareNote).filter(
            CareNote.session_id == session_id
        ).all()
        
        # 시니어 정보 조회
        senior = db.query(Senior).filter(
            Senior.id == care_session.senior_id
        ).first()
        
        # AI 리포트 서비스 초기화
        ai_report_service = AIReportService(db)
        
        # 리포트 생성
        report_data = await ai_report_service.generate_report(
            session=care_session,
            senior=senior,
            checklist_responses=checklist_responses,
            care_notes=care_notes
        )
        
        # 리포트 저장
        ai_report = AIReport(
            session_id=session_id,
            keywords=report_data["keywords"],
            content=report_data["content"],
            ai_comment=report_data["ai_comment"],
            status="generated"
        )
        
        db.add(ai_report)
        db.commit()
        db.refresh(ai_report)
        
        # 가디언에게 알림 전송
        notification_service = NotificationService(db)
        await notification_service.send_notification(
            sender_id=current_user.id,
            receiver_id=senior.guardian_id,
            type="report",
            title="새로운 돌봄 리포트가 생성되었습니다",
            content=f"{senior.name}님의 {care_session.start_time.strftime('%Y-%m-%d')} 돌봄 리포트가 생성되었습니다.",
            data={"report_id": ai_report.id, "session_id": session_id}
        )
        
        return {
            "message": "AI 리포트가 성공적으로 생성되었습니다.",
            "report_id": ai_report.id,
            "session_id": session_id
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI 리포트 생성 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/reports/{report_id}", response_model=AIReportResponse)
async def get_ai_report(
    report_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """AI 리포트 조회"""
    try:
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
        
        # 권한 확인 (케어기버 또는 가디언만 접근 가능)
        if (current_user.id != session.caregiver_id and 
            current_user.id != senior.guardian_id and 
            current_user.user_type != "admin"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="해당 리포트에 접근할 권한이 없습니다."
            )
        
        return report
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI 리포트 조회 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/report-templates")
async def get_report_templates(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """리포트 템플릿 조회"""
    try:
        ai_report_service = AIReportService(db)
        templates = ai_report_service.get_report_templates()
        
        return {
            "templates": templates,
            "message": "리포트 템플릿을 성공적으로 조회했습니다."
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"리포트 템플릿 조회 중 오류가 발생했습니다: {str(e)}"
        )

@router.post("/analyze-checklist")
async def analyze_checklist(
    session_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """체크리스트 분석"""
    try:
        # 돌봄 세션 확인
        care_session = db.query(CareSession).filter(
            CareSession.id == session_id
        ).first()
        
        if not care_session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="돌봄 세션을 찾을 수 없습니다."
            )
        
        # 권한 확인
        senior = db.query(Senior).filter(
            Senior.id == care_session.senior_id
        ).first()
        
        if (current_user.id != care_session.caregiver_id and 
            current_user.id != senior.guardian_id and 
            current_user.user_type != "admin"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="해당 세션의 체크리스트를 분석할 권한이 없습니다."
            )
        
        # 체크리스트 응답 조회
        checklist_responses = db.query(ChecklistResponse).filter(
            ChecklistResponse.session_id == session_id
        ).all()
        
        if not checklist_responses:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="체크리스트 응답을 찾을 수 없습니다."
            )
        
        # AI 리포트 서비스 초기화
        ai_report_service = AIReportService(db)
        
        # 체크리스트 분석
        analysis_result = await ai_report_service.analyze_checklist(
            checklist_responses=checklist_responses,
            senior=senior
        )
        
        return {
            "analysis": analysis_result,
            "session_id": session_id,
            "message": "체크리스트 분석이 완료되었습니다."
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"체크리스트 분석 중 오류가 발생했습니다: {str(e)}"
        )

@router.post("/regenerate-report")
async def regenerate_ai_report(
    report_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """AI 리포트 재생성"""
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
        
        # 권한 확인 (케어기버 또는 관리자만 재생성 가능)
        if (current_user.id != session.caregiver_id and 
            current_user.user_type != "admin"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="리포트를 재생성할 권한이 없습니다."
            )
        
        # 관련 데이터 조회
        checklist_responses = db.query(ChecklistResponse).filter(
            ChecklistResponse.session_id == report.session_id
        ).all()
        
        care_notes = db.query(CareNote).filter(
            CareNote.session_id == report.session_id
        ).all()
        
        senior = db.query(Senior).filter(
            Senior.id == session.senior_id
        ).first()
        
        # AI 리포트 서비스 초기화
        ai_report_service = AIReportService(db)
        
        # 리포트 재생성
        new_report_data = await ai_report_service.generate_report(
            session=session,
            senior=senior,
            checklist_responses=checklist_responses,
            care_notes=care_notes
        )
        
        # 기존 리포트 업데이트
        report.keywords = new_report_data["keywords"]
        report.content = new_report_data["content"]
        report.ai_comment = new_report_data["ai_comment"]
        report.status = "regenerated"
        
        db.commit()
        
        return {
            "message": "AI 리포트가 성공적으로 재생성되었습니다.",
            "report_id": report.id,
            "session_id": report.session_id
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI 리포트 재생성 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/keywords/trending")
async def get_trending_keywords(
    days: int = 30,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """인기 키워드 조회"""
    try:
        # 관리자만 접근 가능
        if current_user.user_type != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="관리자 권한이 필요합니다."
            )
        
        # AI 리포트 서비스 초기화
        ai_report_service = AIReportService(db)
        
        # 인기 키워드 조회
        trending_keywords = await ai_report_service.get_trending_keywords(days=days)
        
        return {
            "trending_keywords": trending_keywords,
            "period_days": days,
            "message": "인기 키워드를 성공적으로 조회했습니다."
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"인기 키워드 조회 중 오류가 발생했습니다: {str(e)}"
        )

# AI 분석 트리거 및 콜백 엔드포인트 추가
from app.services.ai_trigger import AIAnalysisTrigger
from app.models.enhanced_care import WeeklyChecklistScore, SpecialNote

@router.post("/trigger-ai-analysis")
async def trigger_ai_analysis(
    care_session_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """AI 분석 트리거 (백엔드 내부 처리)"""
    
    # 케어 세션 및 권한 확인
    care_session = db.query(CareSession).filter(
        CareSession.id == care_session_id
    ).first()
    
    if not care_session:
        raise HTTPException(status_code=404, detail="케어 세션을 찾을 수 없습니다")
    
    # AI 분석 서비스 실행
    ai_trigger = AIAnalysisTrigger(db)
    try:
        result = await ai_trigger.analyze_care_session(care_session_id)
        return result
    except Exception as e:
        raise HTTPException(
            status_code=500, 
            detail=f"AI 분석 실행 실패: {str(e)}"
        )

@router.get("/weekly-scores/{senior_id}")
async def get_weekly_scores(
    senior_id: int,
    weeks: int = 4,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """시니어의 주간 점수 조회"""
    
    from datetime import datetime, timedelta
    
    # 권한 확인
    senior = db.query(Senior).filter(Senior.id == senior_id).first()
    if not senior:
        raise HTTPException(status_code=404, detail="시니어를 찾을 수 없습니다")
    
    # 최근 N주 데이터 조회
    weeks_ago = datetime.now() - timedelta(weeks=weeks)
    
    weekly_scores = db.query(WeeklyChecklistScore).filter(
        WeeklyChecklistScore.senior_id == senior_id,
        WeeklyChecklistScore.week_start_date >= weeks_ago.date()
    ).order_by(WeeklyChecklistScore.week_start_date).all()
    
    return {
        "senior_id": senior_id,
        "senior_name": senior.name,
        "period_weeks": weeks,
        "weekly_scores": [
            {
                "week_start": score.week_start_date.isoformat(),
                "week_end": score.week_end_date.isoformat(),
                "score_percentage": float(score.score_percentage),
                "total_score": score.total_score,
                "checklist_count": score.checklist_count,
                "trend_indicator": score.trend_indicator,
                "score_breakdown": score.score_breakdown
            } for score in weekly_scores
        ]
    }

@router.get("/special-notes/{senior_id}")
async def get_special_notes(
    senior_id: int,
    limit: int = 10,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """시니어의 특이사항 조회"""
    
    # 권한 확인
    senior = db.query(Senior).filter(Senior.id == senior_id).first()
    if not senior:
        raise HTTPException(status_code=404, detail="시니어를 찾을 수 없습니다")
    
    # 최근 특이사항 조회
    special_notes = db.query(SpecialNote).filter(
        SpecialNote.senior_id == senior_id
    ).order_by(SpecialNote.created_at.desc()).limit(limit).all()
    
    return {
        "senior_id": senior_id,
        "senior_name": senior.name,
        "special_notes": [
            {
                "id": note.id,
                "note_type": note.note_type,
                "short_summary": note.short_summary,
                "detailed_content": note.detailed_content,
                "priority_level": note.priority_level,
                "is_resolved": note.is_resolved,
                "created_at": note.created_at.isoformat(),
                "resolved_at": note.resolved_at.isoformat() if note.resolved_at else None
            } for note in special_notes
        ]
    }
