"""
인증 관련 라우터
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..database import get_db
from ..schemas import UserLogin, TokenResponse, UserResponse
from ..auth import authenticate_user, create_token_response

router = APIRouter()

@router.post("/login", response_model=TokenResponse)
async def login(user_credentials: UserLogin, db: Session = Depends(get_db)):
    """사용자 로그인"""
    user = authenticate_user(db, user_credentials.user_code, user_credentials.password)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="잘못된 사용자 코드 또는 비밀번호입니다.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return create_token_response(user)

@router.post("/logout")
async def logout():
    """사용자 로그아웃"""
    return {"message": "로그아웃되었습니다."}

@router.post("/refresh")
async def refresh_token():
    """토큰 갱신"""
    return {"message": "토큰 갱신 기능은 향후 구현 예정입니다."}

@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user = Depends(get_current_user)):
    """현재 사용자 정보 조회"""
    return current_user
