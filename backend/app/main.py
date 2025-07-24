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

# 라우터 임포트
from app.routers import caregiver, guardian, ai, admin

# FastAPI 앱 생성
app = FastAPI(
    title="Good Hands Care Service API",
    description="재외동포 케어 서비스 API",
    version="1.0.0"
)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
@app.post("/api/auth/login", response_model=Token)
async def login(user_credentials: UserLogin, db: Session = Depends(get_db)):
    """사용자 로그인"""
    user = authenticate_user(db, user_credentials.user_code, user_credentials.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect user code or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = create_access_token(data={"sub": user.user_code})
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_type": user.user_type
    }

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
