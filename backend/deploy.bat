@echo off
echo ========================================
echo  Good Hands 케어 서비스 배포 (Windows)
echo ========================================

set COMPOSE_PROJECT_NAME=goodhands

echo 📦 기존 컨테이너 정리 중...
docker-compose down

echo 🏗️  이미지 빌드 중...
docker-compose build

echo 🔄 컨테이너 시작 중...
docker-compose up -d

echo 🏥 헬스 체크 중...
timeout /t 10 /nobreak > nul

echo 🎉 배포 완료!
echo 📊 API 문서: http://localhost:8000/docs
echo 🗄️  관리자 패널: http://localhost:8000/admin
echo 📋 로그 확인: docker-compose logs -f

pause
