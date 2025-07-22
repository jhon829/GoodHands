"""
인증 시스템 모듈
"""
from datetime import datetime, timedelta
from typing import Optional, Dict, Any

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session
import os
from dotenv import load_dotenv

from .database import get_db
from .models import User
from .schemas import UserResponse, TokenResponse

# 환경 변수 로드
load_dotenv()

# 설정값
SECRET_KEY = os.getenv("SECRET_KEY", "your-super-secret-key-here")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))

# 패스워드 해싱
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# HTTP Bearer 토큰 스키마
security = HTTPBearer()

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """패스워드 검증"""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """패스워드 해시 생성"""
    return pwd_context.hash(password)

def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    """JWT 액세스 토큰 생성"""
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    
    return encoded_jwt
def verify_token(token: str) -> Dict[str, Any]:
    """JWT 토큰 검증"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_code: str = payload.get("sub")
        
        if user_code is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        return payload
    
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
            headers={"WWW-Authenticate": "Bearer"},
        )

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """현재 사용자 정보 가져오기"""
    payload = verify_token(credentials.credentials)
    user_code = payload.get("sub")
    
    user = db.query(User).filter(User.user_code == user_code).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    
    return user

def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    """현재 활성 사용자 정보 가져오기"""
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    return current_user

def authenticate_user(db: Session, user_code: str, password: str) -> Optional[User]:
    """사용자 인증"""
    user = db.query(User).filter(User.user_code == user_code).first()
    
    if not user:
        return None
    
    if not verify_password(password, user.password_hash):
        return None
    
    return user

def create_token_response(user: User) -> TokenResponse:
    """토큰 응답 생성"""
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.user_code, "user_type": user.user_type},
        expires_delta=access_token_expires
    )
    
    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user_type=user.user_type,
        user_code=user.user_code,
        expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )
