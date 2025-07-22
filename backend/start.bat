@echo off
echo ========================================
echo  Good Hands 케어 서비스 백엔드 시작
echo ========================================
echo.

echo 1. 데이터베이스 확인 중...
py -c "import os; print('✅ 데이터베이스 파일 존재') if os.path.exists('goodhands.db') else print('❌ 데이터베이스 파일 없음')"

echo.
echo 2. 서버 시작 중...
echo    API 문서: http://localhost:8000/docs
echo    서버 주소: http://localhost:8000
echo.
echo 테스트 계정:
echo    케어기버: CG001 / password123
echo    가디언: GD001 / password123
echo    관리자: AD001 / admin123
echo.
echo 서버를 중지하려면 Ctrl+C를 눌러주세요.
echo ========================================

py -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
