# 🏥 Good Hands Care Service

재외동포 케어 서비스 - 해외 거주 한국인 자녀들을 위한 부모님 돌봄 서비스

## 📋 프로젝트 개요

Good Hands는 해외에 거주하는 한국인 자녀들이 국내에 계신 부모님의 돌봄 상황을 실시간으로 확인할 수 있는 서비스입니다. 케어기버가 제공하는 돌봄 서비스를 AI가 분석하여 자동으로 리포트를 생성하고, 가족들에게 전달합니다.

## 🎯 주요 기능

### 👨‍⚕️ 케어기버 앱
- **출근/퇴근 관리**: GPS 기반 위치 확인 및 인증 사진 업로드
- **체크리스트**: 질병별 맞춤형 체크리스트 (치매, 당뇨, 고혈압 등)
- **돌봄노트**: 6개 핵심 질문 기반 돌봄 기록
- **실시간 알림**: 중요 상황 발생 시 즉시 알림

### 👨‍👩‍👧‍👦 가디언 앱
- **AI 리포트**: 자동 생성된 일일 돌봄 리포트
- **실시간 모니터링**: 부모님 상태 실시간 확인
- **피드백 시스템**: 케어기버에게 직접 요청사항 전달
- **가족 소통**: 다국어 지원으로 해외에서도 편리하게 이용

### 🤖 AI 분석 시스템
- **키워드 자동 생성**: 건강함, 기분좋음, 가족그리움 등
- **맞춤형 리포트**: 시니어별 특성을 고려한 개인화된 분석
- **개선 제안**: 가족에게 구체적이고 실용적인 행동 가이드 제공

## 🛠️ 기술 스택

### Backend
- **Framework**: FastAPI (Python 3.13)
- **Database**: PostgreSQL (개발환경: SQLite)
- **Authentication**: JWT Token
- **API Documentation**: Swagger UI
- **Migration**: Alembic

### Frontend (예정)
- **Mobile**: React Native
- **Web**: React.js
- **State Management**: Redux Toolkit
- **API Client**: Axios

### Infrastructure
- **Containerization**: Docker & Docker Compose
- **Database**: PostgreSQL
- **File Storage**: Local Storage (추후 AWS S3)
- **Deployment**: Heroku, AWS, GCP

## 🚀 빠른 시작

### 개발 환경 설정

1. **저장소 클론**
   ```bash
   git clone https://github.com/jhon829/sinabro.git
   cd sinabro/backend
   ```

2. **패키지 설치**
   ```bash
   pip install -r requirements.txt
   ```

3. **데이터베이스 설정**
   ```bash
   # 데이터베이스 생성
   python -c "from app.database import Base, engine; from app.models import *; Base.metadata.create_all(bind=engine)"
   
   # 시드 데이터 생성
   python seed_data.py
   ```

4. **서버 실행**
   ```bash
   python -m uvicorn app.main:app --reload
   ```

5. **API 문서 확인**
   - Swagger UI: http://localhost:8000/docs
   - ReDoc: http://localhost:8000/redoc

### 테스트 계정
- **케어기버**: CG001 / password123
- **가디언**: GD001 / password123
- **관리자**: AD001 / admin123

## 📱 API 엔드포인트

### 🔐 인증
- `POST /api/auth/login` - 로그인
- `POST /api/auth/register` - 회원가입

### 👨‍⚕️ 케어기버
- `GET /api/caregiver/home` - 홈 화면
- `POST /api/caregiver/attendance/checkin` - 출근 체크
- `POST /api/caregiver/attendance/checkout` - 퇴근 체크
- `POST /api/caregiver/checklist` - 체크리스트 제출
- `POST /api/caregiver/care-note` - 돌봄노트 제출

### 👨‍👩‍👧‍👦 가디언
- `GET /api/guardian/home` - 홈 화면
- `GET /api/guardian/reports` - 리포트 목록
- `POST /api/guardian/feedback` - 피드백 제출

### 🤖 AI 리포트
- `POST /api/ai/generate-report` - AI 리포트 생성
- `GET /api/ai/reports/{report_id}` - 리포트 조회
- `POST /api/ai/analyze-checklist` - 체크리스트 분석

## 🐳 Docker 배포

### 개발 환경
```bash
# 서버 실행
docker-compose up -d
```

### 프로덕션 환경
```bash
# 환경 변수 설정 후 배포
docker-compose -f docker-compose.prod.yml up -d
```

## 🔄 데이터베이스 마이그레이션

```bash
# 마이그레이션 생성
python migrate.py create "describe_your_changes"

# 마이그레이션 적용
python migrate.py upgrade

# 롤백
python migrate.py downgrade
```

## 📊 프로젝트 구조

```
sinabro/
├── backend/
│   ├── app/
│   │   ├── models/          # 데이터베이스 모델
│   │   ├── routers/         # API 라우터
│   │   ├── schemas/         # 데이터 스키마
│   │   ├── services/        # 비즈니스 로직
│   │   └── main.py          # 메인 애플리케이션
│   ├── alembic/             # 데이터베이스 마이그레이션
│   ├── requirements.txt     # Python 의존성
│   └── docker-compose.yml   # Docker 설정
└── frontend/                # React Native 앱 (예정)
```

## 🎯 개발 로드맵

### ✅ 완료된 기능
- [x] 백엔드 API 개발
- [x] 데이터베이스 설계
- [x] 인증 시스템
- [x] AI 리포트 생성
- [x] 체크리스트 시스템
- [x] 돌봄노트 시스템
- [x] 관리자 대시보드

### 🔄 진행 중
- [ ] React Native 앱 개발
- [ ] 실시간 알림 시스템
- [ ] 이미지 업로드 최적화

### 📋 예정 기능
- [ ] 화상 통화 기능
- [ ] 다국어 지원
- [ ] IoT 기기 연동
- [ ] 웹 대시보드

## 👥 기여 방법

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 문의

- **개발자**: jhon829
- **GitHub**: https://github.com/jhon829
- **이메일**: [이메일 주소]

## 🙏 감사의 말

이 프로젝트는 해외에 거주하는 한국인 가족들의 어려움을 해결하고자 시작되었습니다. 모든 피드백과 기여를 환영합니다.

---

**"따뜻한 손길로 연결하는 가족의 마음"** ❤️
