@echo off
REM Good Hands Docker 빌드 및 배포 스크립트 (외부 DB 연동)
REM 작성일: 2025-07-26

echo =====================================
echo Good Hands Docker 빌드 및 배포 시작
echo =====================================

REM 1. 프로젝트 디렉토리로 이동
cd /d "\\tsclient\C\Users\융합인재센터16\goodHands\backend"
echo 현재 디렉토리: %CD%

REM 2. 환경 변수 설정
set COMPOSE_FILE=docker-compose.external-db.yml
set IMAGE_NAME=goodhands-backend
set CONTAINER_NAME=goodhands-backend-https

REM 3. MySQL 비밀번호 입력
set /p MYSQL_PASSWORD=MariaDB 비밀번호를 입력하세요: 
if "%MYSQL_PASSWORD%"=="" (
    echo ❌ 비밀번호를 입력해야 합니다!
    pause
    exit /b 1
)

REM 4. 환경 변수 파일 업데이트
echo MYSQL_PASSWORD=%MYSQL_PASSWORD%> .env.local
echo DATABASE_URL=mysql+pymysql://root:%MYSQL_PASSWORD%@49.50.131.188:3306/goodhands>> .env.local

REM 5. 기존 컨테이너 중지 (안전하게)
echo 기존 컨테이너 중지 중...
docker-compose -f %COMPOSE_FILE% --env-file .env.local stop backend 2>nul
docker container rm %CONTAINER_NAME% 2>nul

REM 6. 이미지 빌드 (최적화된 Dockerfile 사용)
echo Docker 이미지 빌드 중...
docker-compose -f %COMPOSE_FILE% --env-file .env.local build --pull backend
if %ERRORLEVEL% neq 0 (
    echo ❌ Docker 빌드 실패!
    pause
    exit /b 1
)

REM 7. 사용하지 않는 이미지 정리
echo 사용하지 않는 이미지 정리 중...
docker image prune -f

REM 8. 서비스 시작
echo 서비스 시작 중...
docker-compose -f %COMPOSE_FILE% --env-file .env.local up -d
if %ERRORLEVEL% neq 0 (
    echo ❌ 서비스 시작 실패!
    pause
    exit /b 1
)

REM 9. 서비스 상태 확인
echo 서비스 상태 확인 중...
timeout /t 10
docker-compose -f %COMPOSE_FILE% --env-file .env.local ps

REM 10. 외부 DB 연결 테스트
echo 외부 DB 연결 테스트 중...
timeout /t 30
docker exec %CONTAINER_NAME% python -c "
import pymysql
try:
    conn = pymysql.connect(host='49.50.131.188', port=3306, user='root', password='%MYSQL_PASSWORD%', database='goodhands')
    print('✅ MariaDB 연결 성공!')
    conn.close()
except Exception as e:
    print('❌ MariaDB 연결 실패:', e)
"

REM 11. 헬스체크
echo 헬스체크 실행 중...
timeout /t 30
curl -k https://localhost:10007/health
if %ERRORLEVEL% neq 0 (
    echo ⚠️  헬스체크 실패 - 로그를 확인하세요
    docker-compose -f %COMPOSE_FILE% --env-file .env.local logs --tail=50 backend
)

REM 12. 배포 완료 메시지
echo =====================================
echo ✅ 배포 완료!
echo =====================================
echo 서비스 접속: https://pay.gzonesoft.co.kr:10007
echo API 문서: https://pay.gzonesoft.co.kr:10007/docs
echo 로그 확인: docker-compose -f %COMPOSE_FILE% --env-file .env.local logs -f backend
echo =====================================

REM 13. 환경 파일 정리
del .env.local

REM 14. 로그 모니터링 옵션
set /p "show_logs=로그를 실시간으로 보시겠습니까? (y/n): "
if /i "%show_logs%"=="y" (
    docker-compose -f %COMPOSE_FILE% logs -f backend
)

pause
