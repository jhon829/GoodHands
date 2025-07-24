"""
케어기버 관련 라우터
"""
from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile, Form
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, date

from ..database import get_db
from ..models import User, Senior, CareSession, ChecklistResponse, CareNote, Notification
from ..schemas import (
    CareSessionResponse, SeniorResponse, ChecklistSubmission, CareNoteSubmission,
    CaregiverHomeResponse, AttendanceCheckIn, AttendanceCheckOut
)
from ..services.auth import get_current_user
from ..services.care import CareService
from ..services.file import FileService

router = APIRouter()

@router.get("/home", response_model=CaregiverHomeResponse)
async def get_caregiver_home(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """케어기버 홈 화면 데이터 조회"""
    try:
        # 케어기버 프로필 조회 (관계를 통해)
        if not current_user.caregiver_profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="케어기버 정보를 찾을 수 없습니다."
            )
        
        caregiver = current_user.caregiver_profile
        
        # 오늘 날짜 기준 돌봄 세션 조회
        today = date.today()
        today_sessions = db.query(CareSession).filter(
            CareSession.caregiver_id == caregiver.id,
            CareSession.created_at >= today
        ).all()
        
        # 담당 시니어 목록 조회
        seniors = db.query(Senior).filter(
            Senior.caregiver_id == caregiver.id
        ).all()
        
        # 읽지 않은 알림 조회
        notifications = db.query(Notification).filter(
            Notification.receiver_id == current_user.id,
            Notification.is_read == False
        ).order_by(Notification.created_at.desc()).limit(10).all()
        
        return CaregiverHomeResponse(
            caregiver_name=caregiver.name,
            today_sessions=today_sessions,
            seniors=seniors,
            notifications=notifications
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"홈 데이터 조회 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/seniors", response_model=List[SeniorResponse])
async def get_assigned_seniors(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """담당 시니어 목록 조회"""
    try:
        # 케어기버 프로필 확인
        if not current_user.caregiver_profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="케어기버 정보를 찾을 수 없습니다."
            )
        
        caregiver = current_user.caregiver_profile
        
        seniors = db.query(Senior).filter(
            Senior.caregiver_id == caregiver.id
        ).all()
        
        return seniors
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"시니어 목록 조회 중 오류가 발생했습니다: {str(e)}"
        )

@router.post("/attendance/checkin")
async def check_in_attendance(
    senior_id: int = Form(...),
    location: str = Form(...),
    photo: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """출근 체크인"""
    try:
        # 케어기버 프로필 확인
        if not current_user.caregiver_profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="케어기버 정보를 찾을 수 없습니다."
            )
        
        caregiver = current_user.caregiver_profile
        
        # 시니어 확인
        senior = db.query(Senior).filter(Senior.id == senior_id).first()
        if not senior:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="시니어를 찾을 수 없습니다."
            )
        
        # 이미지 저장
        file_service = FileService()
        photo_path = await file_service.save_uploaded_file(photo)
        
        # 돌봄 세션 생성
        care_session = CareSession(
            caregiver_id=caregiver.id,
            senior_id=senior_id,
            start_time=datetime.utcnow(),
            start_location=location,
            start_photo=photo_path,
            status="active"
        )
        
        db.add(care_session)
        db.commit()
        db.refresh(care_session)
        
        return {
            "message": "출근 체크가 완료되었습니다.",
            "session_id": care_session.id,
            "start_time": care_session.start_time
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"출근 체크 중 오류가 발생했습니다: {str(e)}"
        )

@router.post("/attendance/checkout")
async def check_out_attendance(
    session_id: int = Form(...),
    location: str = Form(...),
    photo: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """퇴근 체크아웃"""
    try:
        # 돌봄 세션 조회
        care_session = db.query(CareSession).filter(
            CareSession.id == session_id,
            CareSession.caregiver_id == current_user.id
        ).first()
        
        if not care_session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="돌봄 세션을 찾을 수 없습니다."
            )
        
        if care_session.status != "active":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미 종료된 세션입니다."
            )
        
        # 이미지 저장
        file_service = FileService()
        photo_path = await file_service.save_uploaded_file(photo)
        
        # 돌봄 세션 종료
        care_session.end_time = datetime.utcnow()
        care_session.end_location = location
        care_session.end_photo = photo_path
        care_session.status = "completed"
        
        db.commit()
        
        return {
            "message": "퇴근 체크가 완료되었습니다.",
            "session_id": care_session.id,
            "end_time": care_session.end_time,
            "duration": str(care_session.end_time - care_session.start_time)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"퇴근 체크 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/checklist/{senior_id}")
async def get_checklist_template(
    senior_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """체크리스트 템플릿 조회"""
    try:
        # 시니어 정보 조회
        senior = db.query(Senior).filter(Senior.id == senior_id).first()
        if not senior:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="시니어를 찾을 수 없습니다."
            )
        
        # 케어 서비스를 통해 체크리스트 템플릿 생성
        care_service = CareService(db)
        template = care_service.get_checklist_template(senior)
        
        return {
            "senior_info": senior,
            "template": template
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"체크리스트 템플릿 조회 중 오류가 발생했습니다: {str(e)}"
        )

@router.post("/checklist")
async def submit_checklist(
    checklist_data: ChecklistSubmission,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """체크리스트 제출"""
    try:
        # 돌봄 세션 확인
        care_session = db.query(CareSession).filter(
            CareSession.id == checklist_data.session_id,
            CareSession.caregiver_id == current_user.id
        ).first()
        
        if not care_session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="돌봄 세션을 찾을 수 없습니다."
            )
        
        # 체크리스트 응답 저장
        for response in checklist_data.responses:
            checklist_response = ChecklistResponse(
                session_id=checklist_data.session_id,
                question_key=response.question_key,
                question_text=response.question_text,
                answer=response.answer,
                notes=response.notes
            )
            db.add(checklist_response)
        
        db.commit()
        
        return {
            "message": "체크리스트가 성공적으로 제출되었습니다.",
            "session_id": checklist_data.session_id,
            "responses_count": len(checklist_data.responses)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"체크리스트 제출 중 오류가 발생했습니다: {str(e)}"
        )

@router.post("/care-note")
async def submit_care_note(
    care_note_data: CareNoteSubmission,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """돌봄노트 제출"""
    try:
        # 돌봄 세션 확인
        care_session = db.query(CareSession).filter(
            CareSession.id == care_note_data.session_id,
            CareSession.caregiver_id == current_user.id
        ).first()
        
        if not care_session:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="돌봄 세션을 찾을 수 없습니다."
            )
        
        # 돌봄노트 저장
        for note in care_note_data.notes:
            care_note = CareNote(
                session_id=care_note_data.session_id,
                question_type=note.question_type,
                question_text=note.question_text,
                content=note.content
            )
            db.add(care_note)
        
        db.commit()
        
        return {
            "message": "돌봄노트가 성공적으로 제출되었습니다.",
            "session_id": care_note_data.session_id,
            "notes_count": len(care_note_data.notes)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"돌봄노트 제출 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/care-history")
async def get_care_history(
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """돌봄 이력 조회"""
    try:
        query = db.query(CareSession).filter(
            CareSession.caregiver_id == current_user.id
        )
        
        if start_date:
            query = query.filter(CareSession.start_time >= start_date)
        if end_date:
            query = query.filter(CareSession.start_time <= end_date)
        
        care_sessions = query.order_by(CareSession.start_time.desc()).all()
        
        return {
            "care_sessions": care_sessions,
            "total_count": len(care_sessions)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"돌봄 이력 조회 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/profile")
async def get_caregiver_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """케어기버 프로필 조회"""
    try:
        return {
            "user_info": current_user,
            "assigned_seniors_count": db.query(Senior).filter(
                Senior.caregiver_id == current_user.id
            ).count(),
            "total_sessions": db.query(CareSession).filter(
                CareSession.caregiver_id == current_user.id
            ).count()
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"프로필 조회 중 오류가 발생했습니다: {str(e)}"
        )

# 케어 스케줄 관련 엔드포인트 추가
from datetime import date, timedelta, time, datetime
from app.models.enhanced_care import CareSchedule

@router.get("/care-schedule/{senior_id}")
async def get_care_schedule(
    senior_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """시니어별 케어 스케줄 조회"""
    
    # 케어기버 권한 확인
    if not current_user.caregiver_profile:
        raise HTTPException(status_code=403, detail="케어기버 권한이 필요합니다")
    
    schedules = db.query(CareSchedule).filter(
        CareSchedule.senior_id == senior_id,
        CareSchedule.caregiver_id == current_user.caregiver_profile.id,
        CareSchedule.is_active == True
    ).all()
    
    # 요일명 매핑
    day_names = ["일", "월", "화", "수", "목", "금", "토"]
    
    schedule_data = []
    for schedule in schedules:
        # 다음 케어 날짜 계산
        next_care_date = calculate_next_care_date(schedule.day_of_week)
        
        schedule_data.append({
            "id": schedule.id,
            "day_of_week": schedule.day_of_week,
            "day_name": day_names[schedule.day_of_week],
            "start_time": schedule.start_time.strftime("%H:%M"),
            "end_time": schedule.end_time.strftime("%H:%M"),
            "next_care_date": next_care_date.strftime("%Y-%m-%d"),
            "notes": schedule.notes
        })
    
    return {
        "senior_id": senior_id,
        "schedules": schedule_data,
        "total_schedules": len(schedule_data)
    }

def calculate_next_care_date(day_of_week: int) -> date:
    """다음 케어 날짜 계산"""
    today = date.today()
    days_ahead = day_of_week - today.weekday()
    
    if days_ahead <= 0:  # 오늘이거나 지나간 요일
        days_ahead += 7
    
    return today + timedelta(days=days_ahead)

@router.post("/care-schedule")
async def create_care_schedule(
    schedule_data: dict,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """새로운 케어 스케줄 생성"""
    
    if not current_user.caregiver_profile:
        raise HTTPException(status_code=403, detail="케어기버 권한이 필요합니다")
    
    # 중복 스케줄 확인
    existing = db.query(CareSchedule).filter(
        CareSchedule.senior_id == schedule_data["senior_id"],
        CareSchedule.caregiver_id == current_user.caregiver_profile.id,
        CareSchedule.day_of_week == schedule_data["day_of_week"],
        CareSchedule.is_active == True
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail="해당 요일에 이미 스케줄이 있습니다")
    
    new_schedule = CareSchedule(
        caregiver_id=current_user.caregiver_profile.id,
        senior_id=schedule_data["senior_id"],
        day_of_week=schedule_data["day_of_week"],
        start_time=datetime.strptime(schedule_data["start_time"], "%H:%M").time(),
        end_time=datetime.strptime(schedule_data["end_time"], "%H:%M").time(),
        notes=schedule_data.get("notes", "")
    )
    
    db.add(new_schedule)
    db.commit()
    db.refresh(new_schedule)
    
    return {
        "message": "케어 스케줄이 생성되었습니다",
        "schedule_id": new_schedule.id
    }
