"""
메인 FastAPI 애플리케이션
"""
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
import os
from dotenv import load_dotenv

from .database import get_db, engine
from .models import Base
from .schemas import UserLogin, TokenResponse, UserResponse
from .auth import authenticate_user, create_token_response, get_current_user
from .routers import auth, caregiver, guardian, admin, ai

# 환경 변수 로드
load_dotenv()

# 데이터베이스 테이블 생성
Base.metadata.create_all(bind=engine)

# FastAPI 앱 생성
app = FastAPI(
    title=os.getenv("APP_NAME", "GoodHands Care Service"),
    description="재외동포 케어 서비스 API",
    version=os.getenv("APP_VERSION", "1.0.0"),
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 개발 환경에서는 모든 오리진 허용
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 정적 파일 서빙 (업로드된 이미지)
app.mount("/static", StaticFiles(directory="uploads"), name="static")

# 라우터 등록
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(caregiver.router, prefix="/api/caregiver", tags=["caregiver"])
app.include_router(guardian.router, prefix="/api/guardian", tags=["guardian"])
app.include_router(admin.router, prefix="/api/admin", tags=["admin"])
app.include_router(ai.router, prefix="/api/ai", tags=["ai"])

@app.get("/")
async def root():
    """루트 엔드포인트"""
    return {
        "message": "GoodHands Care Service API",
        "version": os.getenv("APP_VERSION", "1.0.0"),
        "status": "active"
    }

@app.get("/health")
async def health_check():
    """헬스 체크 엔드포인트"""
    return {"status": "healthy", "timestamp": "2024-01-01T00:00:00Z"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True if os.getenv("DEBUG", "True") == "True" else False
    )
