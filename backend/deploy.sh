#!/bin/bash

# Good Hands 서비스 배포 스크립트
# 사용법: ./deploy.sh

set -e  # 에러 발생시 스크립트 중단

echo "🚀 Good Hands 서비스 배포를 시작합니다..."

# 1. 환경 변수 확인
if [ ! -f .env.deploy ]; then
    echo "❌ .env.deploy 파일이 없습니다. 먼저 환경 변수를 설정해주세요."
    exit 1
fi

# 2. 환경 변수 로드
export $(cat .env.deploy | grep -v '^#' | xargs)

# 3. 필수 변수 확인
required_vars=("DOMAIN_NAME" "EMAIL" "POSTGRES_PASSWORD" "SECRET_KEY")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ $var 환경 변수가 설정되지 않았습니다."
        exit 1
    fi
done

echo "✅ 환경 변수 확인 완료"

# 4. Docker 및 Docker Compose 설치 확인
if ! command -v docker &> /dev/null; then
    echo "📦 Docker를 설치합니다..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo usermod -aG docker $USER
fi

if ! command -v docker-compose &> /dev/null; then
    echo "📦 Docker Compose를 설치합니다..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

echo "✅ Docker 환경 확인 완료"

# 5. 기존 서비스 중지 (있다면)
echo "🛑 기존 서비스를 중지합니다..."
docker-compose -f docker-compose.prod.yml down || true

# 6. 이미지 빌드
echo "🔨 Docker 이미지를 빌드합니다..."
docker-compose -f docker-compose.prod.yml build

# 7. SSL 인증서 생성을 위한 임시 nginx 시작
echo "🔒 SSL 인증서를 생성합니다..."
# Nginx 설정을 SSL 이전 버전으로 임시 교체
cp nginx.conf nginx.conf.ssl.bak
cat > nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name $DOMAIN_NAME www.$DOMAIN_NAME;

        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 301 https://\$server_name\$request_uri;
        }
    }
}
EOF

# 8. 임시 nginx 시작 및 SSL 인증서 발급
docker-compose -f docker-compose.prod.yml up -d nginx
docker-compose -f docker-compose.prod.yml run --rm certbot

# 9. SSL 적용된 nginx 설정으로 교체
mv nginx.conf.ssl.bak nginx.conf
cat > nginx.prod.conf << EOF
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server backend:8000;
    }

    # HTTP to HTTPS redirect
    server {
        listen 80;
        server_name $DOMAIN_NAME www.$DOMAIN_NAME;
        return 301 https://\$server_name\$request_uri;
    }

    # HTTPS server
    server {
        listen 443 ssl http2;
        server_name $DOMAIN_NAME www.$DOMAIN_NAME;

        ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;

        # SSL 설정
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;

        # 파일 업로드 크기 제한
        client_max_body_size 10M;

        # API 요청
        location /api/ {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # 업로드된 파일
        location /uploads/ {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # API 문서
        location /docs {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # 기본 페이지
        location / {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF

# nginx 설정 교체
mv nginx.prod.conf nginx.conf

# 10. 전체 서비스 시작
echo "🚀 서비스를 시작합니다..."
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d

# 11. 서비스 상태 확인
echo "🔍 서비스 상태를 확인합니다..."
sleep 10
docker-compose -f docker-compose.prod.yml ps

# 12. SSL 자동 갱신 크론잡 설정
echo "⏰ SSL 인증서 자동 갱신을 설정합니다..."
(crontab -l 2>/dev/null; echo "0 12 * * * cd $(pwd) && docker-compose -f docker-compose.prod.yml run --rm certbot renew && docker-compose -f docker-compose.prod.yml exec nginx nginx -s reload") | crontab -

echo "✅ 배포가 완료되었습니다!"
echo "🌐 서비스 접속: https://$DOMAIN_NAME"
echo "📖 API 문서: https://$DOMAIN_NAME/docs"
echo "📊 관리자 로그인: https://$DOMAIN_NAME/admin"

echo ""
echo "📋 다음 단계:"
echo "1. 도메인 DNS를 서버 IP로 설정"
echo "2. 방화벽에서 80, 443 포트 허용"
echo "3. 서비스 정상 동작 확인"
echo "4. 관리자 계정으로 로그인 테스트"
