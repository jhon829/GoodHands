#!/bin/bash

# 도커 컨테이너 배포 스크립트

echo "🚀 Good Hands 케어 서비스 배포 시작"

# 환경 변수 설정
export COMPOSE_PROJECT_NAME=goodhands

# 기존 컨테이너 정지 및 제거
echo "📦 기존 컨테이너 정리 중..."
docker-compose down

# 이미지 빌드
echo "🏗️  이미지 빌드 중..."
docker-compose build

# 컨테이너 시작
echo "🔄 컨테이너 시작 중..."
docker-compose up -d

# 헬스 체크
echo "🏥 헬스 체크 중..."
sleep 10

# 백엔드 서비스 상태 확인
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ 백엔드 서비스 정상 실행"
else
    echo "❌ 백엔드 서비스 실행 실패"
    docker-compose logs backend
    exit 1
fi

# 데이터베이스 상태 확인
if docker-compose exec postgres pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
    echo "✅ 데이터베이스 정상 실행"
else
    echo "❌ 데이터베이스 연결 실패"
    docker-compose logs postgres
    exit 1
fi

echo "🎉 배포 완료!"
echo "📊 API 문서: http://localhost:8000/docs"
echo "🗄️  관리자 패널: http://localhost:8000/admin"
echo "📋 로그 확인: docker-compose logs -f"
