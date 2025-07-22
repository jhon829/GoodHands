@echo off
echo ========================================
echo  Good Hands 데이터베이스 초기화
echo ========================================
echo.

echo 1. 기존 데이터베이스 삭제 중...
if exist goodhands.db (
    del goodhands.db
    echo ✅ 기존 데이터베이스 삭제 완료
) else (
    echo ℹ️ 기존 데이터베이스 파일 없음
)

echo.
echo 2. 새 데이터베이스 생성 중...
py -c "from app.database import Base, engine; from app.models import *; Base.metadata.create_all(bind=engine); print('✅ 데이터베이스 테이블 생성 완료')"

echo.
echo 3. 시드 데이터 생성 중...
py seed_data.py

echo.
echo ========================================
echo  데이터베이스 초기화 완료!
echo ========================================
echo.
echo 이제 start.bat을 실행해서 서버를 시작하세요.
pause
