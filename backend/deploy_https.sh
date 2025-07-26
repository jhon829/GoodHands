#!/bin/bash

echo "🚀 Good Hands HTTPS 배포 시작!"
echo "==============================="

# 프로젝트 디렉토리로 이동
cd "$(dirname "$0")"
pwd

# 기존 Good Hands 컨테이너 정리 (안전하게)
echo "📦 기존 Good Hands 컨테이너 정리 중..."
docker-compose -f docker-compose.https.yml down --remove-orphans 2>/dev/null || true

# Docker 이미지 빌드
echo "🔨 Docker 이미지 빌드 중..."
docker-compose -f docker-compose.https.yml build --no-cache

# SSL 인증서 권한 설정
echo "🔒 SSL 인증서 권한 설정 중..."
chmod 644 ssl/ssl.crt ssl/chain.crt
chmod 600 ssl/ssl_decrypted.key

# Docker Compose 실행
echo "🐳 Good Hands 서비스 시작 중..."
docker-compose -f docker-compose.https.yml up -d

# 서비스 상태 확인
echo "⏳ 서비스 시작 대기 중..."
sleep 10

# 컨테이너 상태 확인
echo "📊 컨테이너 상태 확인:"
docker-compose -f docker-compose.https.yml ps

# 헬스체크
echo "🔍 헬스체크 실행 중..."
sleep 5

# 로컬 헬스체크 (HTTPS)
echo "🏠 로컬 HTTPS 헬스체크..."
curl -k -s https://localhost:10007/health | head -3 || echo "❌ 로컬 HTTPS 연결 실패"

# 로컬 헬스체크 (HTTP)
echo "🏠 로컬 HTTP 헬스체크..."
curl -s http://localhost:10008/health | head -3 || echo "❌ 로컬 HTTP 연결 실패"

# 로그 확인
echo "📜 최근 로그 확인:"
docker-compose -f docker-compose.https.yml logs --tail=10

echo ""
echo "✅ 배포 완료!"
echo "==============================="
echo "🌐 접속 URL:"
echo "   HTTPS: https://pay.gzonesoft.co.kr:10007/"
echo "   HTTPS (로컬): https://localhost:10007/"
echo "   HTTP (리다이렉트): http://localhost:10008/"
echo ""
echo "📚 API 문서:"
echo "   Swagger: https://localhost:10007/docs"
echo "   ReDoc: https://localhost:10007/redoc"
echo ""
echo "🔧 관리 명령어:"
echo "   상태 확인: docker-compose -f docker-compose.https.yml ps"
echo "   로그 확인: docker-compose -f docker-compose.https.yml logs -f"
echo "   중지: docker-compose -f docker-compose.https.yml down"
echo ""
echo "🎉 Good Hands 서비스가 HTTPS로 성공적으로 배포되었습니다!"