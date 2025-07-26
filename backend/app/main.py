from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from app.config import settings
from app.database import get_db
from app.models import User, Caregiver, Guardian, Admin
from app.schemas.user import UserLogin, UserCreate, UserResponse, Token
from app.services.auth import authenticate_user, create_access_token, get_password_hash

# 새로 추가된 임포트
from app.exceptions import http_exception_handler, general_exception_handler
from app.response_models import success_response, LoginResponse
from app.logging_config import LoggingMiddleware, setup_logging

# 라우터 임포트
from app.routers import caregiver, guardian, ai, admin

# 로깅 설정
setup_logging()

# 태그 설명 정의
tags_metadata = [
    {
        "name": "auth",
        "description": "사용자 인증 관련 API (로그인, 회원가입)",
    },
    {
        "name": "caregiver", 
        "description": "케어기버 전용 API (출근/퇴근, 체크리스트, 돌봄노트)",
    },
    {
        "name": "guardian",
        "description": "가디언 전용 API (리포트 조회, 피드백 전송)",
    },
    {
        "name": "ai",
        "description": "AI 분석 관련 API (리포트 생성, 추이 분석)",
    },
    {
        "name": "admin",
        "description": "관리자 전용 API (사용자 관리, 시스템 설정)",
    }
]

# FastAPI 앱 생성 (문서화 개선)
app = FastAPI(
    title="Good Hands Care Service API",
    description="""
## 재외동포 케어 서비스 API

### 주요 기능
- **인증**: JWT 토큰 기반 로그인/회원가입
- **케어기버**: 출근/퇴근, 체크리스트, 돌봄노트, 케어 스케줄
- **가디언**: AI 리포트 조회, 추이 분석, 피드백 전송  
- **AI 분석**: 자동 점수 계산, 추이 분석, 특이사항 감지

### 테스트 계정
- 케어기버: `CG001` / `password123`
- 가디언: `GD001` / `password123`
- 관리자: `AD001` / `admin123`
    """,
    version="1.0.0",
    openapi_tags=tags_metadata
)

# 미들웨어 추가
app.add_middleware(LoggingMiddleware)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 예외 핸들러 등록
app.add_exception_handler(HTTPException, http_exception_handler)
app.add_exception_handler(Exception, general_exception_handler)

# 정적 파일 서빙 (업로드된 파일들)
app.mount("/uploads", StaticFiles(directory=settings.upload_dir), name="uploads")

security = HTTPBearer()

# 라우터 연결
app.include_router(caregiver.router, prefix="/api/caregiver", tags=["caregiver"])
app.include_router(guardian.router, prefix="/api/guardian", tags=["guardian"])
app.include_router(ai.router, prefix="/api/ai", tags=["ai"])
app.include_router(admin.router, prefix="/api/admin", tags=["admin"])

@app.get("/")
async def root():
    return {"message": "Good Hands Care Service API", "version": "1.0.0", "status": "running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": "2024-01-01T00:00:00Z"}

# 인증 관련 API
@app.post("/api/auth/login", response_model=LoginResponse, tags=["auth"])
async def login(user_credentials: UserLogin, db: Session = Depends(get_db)):
    """사용자 로그인 (개선된 응답)"""
    user = authenticate_user(db, user_credentials.user_code, user_credentials.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="사용자 코드 또는 비밀번호가 올바르지 않습니다",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = create_access_token(data={"sub": user.user_code})
    
    # 사용자 정보 구성
    user_info = {
        "id": user.id,
        "user_code": user.user_code,
        "user_type": user.user_type,
        "email": user.email
    }
    
    # 사용자 타입별 추가 정보
    if user.user_type == "caregiver" and user.caregiver_profile:
        user_info["name"] = user.caregiver_profile.name
        user_info["phone"] = user.caregiver_profile.phone
    elif user.user_type == "guardian" and user.guardian_profile:
        user_info["name"] = user.guardian_profile.name
        user_info["phone"] = user.guardian_profile.phone
        user_info["country"] = user.guardian_profile.country
    elif user.user_type == "admin" and user.admin_profile:
        user_info["name"] = user.admin_profile.name
    
    return LoginResponse(
        access_token=access_token,
        token_type="bearer",
        expires_in=settings.access_token_expire_minutes * 60,
        user_type=user.user_type,
        user_info=user_info
    )

@app.post("/api/auth/register", response_model=UserResponse)
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """사용자 회원가입"""
    # 기존 사용자 확인
    existing_user = db.query(User).filter(User.user_code == user_data.user_code).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User code already registered"
        )
    
    # 사용자 생성
    hashed_password = get_password_hash(user_data.password)
    db_user = User(
        user_code=user_data.user_code,
        user_type=user_data.user_type,
        email=user_data.email,
        password_hash=hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    # 사용자 타입별 추가 정보 생성
    if user_data.user_type == "caregiver":
        caregiver = Caregiver(
            user_id=db_user.id,
            name=user_data.name,
            phone=user_data.phone
        )
        db.add(caregiver)
    elif user_data.user_type == "guardian":
        guardian = Guardian(
            user_id=db_user.id,
            name=user_data.name,
            phone=user_data.phone,
            country=user_data.country
        )
        db.add(guardian)
    elif user_data.user_type == "admin":
        admin = Admin(
            user_id=db_user.id,
            name=user_data.name,
            permissions={"all": True}
        )
        db.add(admin)
    
    db.commit()
    return db_user

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
