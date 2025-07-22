"""
데이터베이스 연결 설정 모듈
"""
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

# 환경 변수 로드
load_dotenv()

# 데이터베이스 URL 가져오기
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://username:password@localhost:5432/goodhands_db")

# 데이터베이스 엔진 생성
engine = create_engine(DATABASE_URL)

# 세션 로컬 클래스 생성
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 베이스 클래스 생성
Base = declarative_base()

# 데이터베이스 세션 의존성
def get_db():
    """
    데이터베이스 세션을 가져오는 의존성 함수
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
