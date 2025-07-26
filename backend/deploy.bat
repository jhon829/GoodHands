@echo off
echo ======================================
echo    Good Hands 서비스 배포 시작
echo ======================================

cd /d "%~dp0"

echo.
echo [1/7] 환경 확인 중...
if not exist "docker-compose.prod.yml" (
    echo ❌ docker-compose.prod.yml 파일을 찾을 수 없습니다.
    pause
    exit /b 1
)

if not exist "ssl\ssl.crt" (
    echo ❌ SSL 인증서 파일을 찾을 수 없습니다.
    pause
    exit /b 1
)

echo ✅ 필수 파일 확인 완료

echo.
echo [2/7] 기존 서비스 중지 중...
docker-compose -f docker-compose.prod.yml down 2>nul

echo.
echo [3/7] Docker 이미지 빌드 중...
docker-compose -f docker-compose.prod.yml build

if %errorlevel% neq 0 (
    echo ❌ Docker 이미지 빌드에 실패했습니다.
    pause
    exit /b 1
)

echo ✅ Docker 이미지 빌드 완료

echo.
echo [4/7] SSL 키 파일 암호 제거 중...
echo 비밀번호를 입력해주세요: hwang0609!
docker run --rm -v "%cd%\ssl:/ssl" alpine/openssl rsa -in /ssl/ssl.key -out /ssl/ssl_decrypted.key

if %errorlevel% equ 0 (
    echo ✅ SSL 키 파일 암호 제거 완료
    move ssl\ssl_decrypted.key ssl\ssl.key
) else (
    echo ⚠️ SSL 키 파일 암호 제거 실패 - 수동으로 처리 필요
)

echo.
echo [5/7] 데이터베이스 초기화 중...
docker-compose -f docker-compose.prod.yml up -d postgres
timeout /t 10 /nobreak

echo.
echo [6/7] 백엔드 서비스 시작 중...
docker-compose -f docker-compose.prod.yml up -d backend
timeout /t 15 /nobreak

echo.
echo [7/7] 전체 서비스 시작 중...
docker-compose -f docker-compose.prod.yml up -d

echo.
echo ======================================
echo       배포 완료!
echo ======================================
echo.
echo 🌐 서비스 접속: https://pay.gzonesoft.co.kr
echo 📖 API 문서: https://pay.gzonesoft.co.kr/docs
echo 📊 헬스체크: https://pay.gzonesoft.co.kr/health
echo.
echo 📋 서비스 상태 확인 중...
timeout /t 5 /nobreak

docker-compose -f docker-compose.prod.yml ps

echo.
echo 📝 로그 확인 명령어:
echo    docker-compose -f docker-compose.prod.yml logs -f
echo.
echo 🛑 서비스 중지 명령어:
echo    docker-compose -f docker-compose.prod.yml down
echo.

pause
