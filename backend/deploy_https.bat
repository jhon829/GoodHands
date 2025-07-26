@echo off
chcp 65001 >nul
cls

echo 🚀 Good Hands HTTPS 배포 시작!
echo ===============================

:: 프로젝트 디렉토리로 이동
cd /d "%~dp0"
echo 📁 현재 디렉토리: %CD%

:: 기존 Good Hands 컨테이너 정리 (안전하게)
echo 📦 기존 Good Hands 컨테이너 정리 중...
docker-compose -f docker-compose.https.yml down --remove-orphans 2>nul

:: Docker 이미지 빌드
echo 🔨 Docker 이미지 빌드 중...
docker-compose -f docker-compose.https.yml build --no-cache
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Docker 빌드 실패!
    pause
    exit /b 1
)

:: Docker Compose 실행
echo 🐳 Good Hands 서비스 시작 중...
docker-compose -f docker-compose.https.yml up -d
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Docker Compose 실행 실패!
    pause
    exit /b 1
)

:: 서비스 시작 대기
echo ⏳ 서비스 시작 대기 중...
timeout /t 15 /nobreak >nul

:: 컨테이너 상태 확인
echo 📊 컨테이너 상태 확인:
docker-compose -f docker-compose.https.yml ps

:: 헬스체크
echo 🔍 헬스체크 실행 중...
timeout /t 5 /nobreak >nul

:: 로컬 헬스체크 시도
echo 🏠 로컬 헬스체크 시도 중...
curl -k -s https://localhost:10007/health 2>nul || curl -s http://localhost:10008/health 2>nul || echo ❌ 헬스체크 연결 실패

:: 로그 확인
echo 📜 최신 로그 확인:
docker-compose -f docker-compose.https.yml logs --tail=10

echo.
echo ✅ 배포 완료!
echo ===============================
echo 🌐 접속 URL:
echo    HTTPS: https://pay.gzonesoft.co.kr:10007/
echo    HTTPS (로컬): https://localhost:10007/
echo    HTTP (리다이렉트): http://localhost:10008/
echo.
echo 📚 API 문서:
echo    Swagger: https://localhost:10007/docs
echo    ReDoc: https://localhost:10007/redoc
echo.
echo 🔧 관리 명령어:
echo    상태 확인: docker-compose -f docker-compose.https.yml ps
echo    로그 확인: docker-compose -f docker-compose.https.yml logs -f
echo    중지: docker-compose -f docker-compose.https.yml down
echo.
echo 🎉 Good Hands 서비스가 HTTPS로 성공적으로 배포되었습니다!

pause