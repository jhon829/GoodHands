from sqlalchemy import create_engine
from app.database import Base
from app.config import settings
from app.models import *  # 모든 모델 import

def create_tables():
    """데이터베이스 테이블 생성"""
    engine = create_engine(settings.database_url)
    Base.metadata.create_all(bind=engine)
    print("데이터베이스 테이블이 생성되었습니다.")

if __name__ == "__main__":
    create_tables()
