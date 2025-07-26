# Good Hands 서비스 배포 가이드

## 🚀 빠른 배포 (5분 완성)

### 1단계: 환경 변수 설정
```bash
# .env.deploy 파일을 편집하여 실제 값으로 수정
nano .env.deploy
```

필수 수정 항목:
- `DOMAIN_NAME`: 실제 도메인명
- `EMAIL`: 관리자 이메일
- `POSTGRES_PASSWORD`: 데이터베이스 비밀번호 (복잡하게)
- `SECRET_KEY`: JWT 시크릿 키 (아래 명령어로 생성)

```bash
# JWT 시크릿 키 생성
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

### 2단계: 서버에 파일 업로드
```bash
# 서버에 프로젝트 파일 업로드
scp -r backend/ user@your-server:/opt/goodhands/
```

### 3단계: 서버에서 배포 실행
```bash
# 서버 접속
ssh user@your-server

# 프로젝트 디렉토리로 이동
cd /opt/goodhands/backend

# 배포 스크립트 실행 권한 부여
chmod +x deploy.sh

# 배포 실행
./deploy.sh
```

## 🔧 수동 배포 (단계별)

### 1. Docker 환경 준비
```bash
# Docker 설치
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER

# Docker Compose 설치
sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. 환경 변수 설정
```bash
# .env.deploy를 .env로 복사하고 편집
cp .env.deploy .env
nano .env
```

### 3. DNS 설정
도메인 관리 패널에서:
- A 레코드: `your-domain.com` → `서버IP`
- A 레코드: `www.your-domain.com` → `서버IP`

### 4. 방화벽 설정
```bash
# Ubuntu/Debian
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
```

### 5. 서비스 시작
```bash
# 프로덕션 환경으로 시작
docker-compose -f docker-compose.prod.yml up -d

# 로그 확인
docker-compose -f docker-compose.prod.yml logs -f
```

## 🔍 배포 후 확인사항

### 서비스 상태 확인
```bash
# 컨테이너 상태 확인
docker-compose -f docker-compose.prod.yml ps

# 로그 확인
docker-compose -f docker-compose.prod.yml logs backend
docker-compose -f docker-compose.prod.yml logs postgres
docker-compose -f docker-compose.prod.yml logs nginx
```

### API 테스트
```bash
# 기본 헬스체크
curl https://your-domain.com/health

# API 문서 접속
https://your-domain.com/docs

# 로그인 테스트
curl -X POST https://your-domain.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"user_code": "AD001", "password": "admin123"}'
```

## 🛠️ 운영 관리

### 백업
```bash
# 데이터베이스 백업
docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U goodhands_user goodhands > backup_$(date +%Y%m%d_%H%M%S).sql

# 업로드 파일 백업
tar -czf uploads_backup_$(date +%Y%m%d_%H%M%S).tar.gz uploads/
```

### 로그 관리
```bash
# 로그 로테이션 설정
sudo logrotate -d /etc/logrotate.d/docker-containers

# 실시간 로그 모니터링
docker-compose -f docker-compose.prod.yml logs -f --tail=100
```

### 업데이트
```bash
# 코드 업데이트 후
git pull origin main
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

# 데이터베이스 마이그레이션 (필요시)
docker-compose -f docker-compose.prod.yml exec backend python -m alembic upgrade head
```

## 🚨 트러블슈팅

### 일반적인 문제들

1. **SSL 인증서 발급 실패**
   ```bash
   # 도메인 DNS 확인
   nslookup your-domain.com
   
   # 수동 인증서 발급
   docker-compose -f docker-compose.prod.yml run --rm certbot certonly --webroot -w /var/www/certbot --email your-email@example.com --agree-tos --no-eff-email -d your-domain.com
   ```

2. **데이터베이스 연결 실패**
   ```bash
   # PostgreSQL 컨테이너 로그 확인
   docker-compose -f docker-compose.prod.yml logs postgres
   
   # 데이터베이스 직접 접속
   docker-compose -f docker-compose.prod.yml exec postgres psql -U goodhands_user -d goodhands
   ```

3. **백엔드 서비스 시작 실패**
   ```bash
   # 백엔드 로그 상세 확인
   docker-compose -f docker-compose.prod.yml logs backend
   
   # 컨테이너 내부 확인
   docker-compose -f docker-compose.prod.yml exec backend bash
   ```

### 성능 모니터링
```bash
# 시스템 리소스 확인
docker stats

# 디스크 사용량 확인
df -h
du -sh uploads/

# 메모리 사용량 확인
free -m
```

## 📞 지원 및 문의

배포 중 문제가 발생하면:
1. 로그 파일 확인 (`docker-compose logs`)
2. 환경 변수 설정 재확인
3. 방화벽 및 DNS 설정 확인
4. SSL 인증서 상태 확인

기술 지원: [GitHub Issues](https://github.com/jhon829/sinabro/issues)
