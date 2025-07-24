# 🎨 프론트엔드 개발자를 위한 API 가이드

## 📋 개발 환경 설정

### API 서버 정보
- **Base URL**: `http://localhost:8000`
- **API 문서**: `http://localhost:8000/docs` (Swagger UI)
- **API 스키마**: `http://localhost:8000/openapi.json`

### 인증 방식
JWT Bearer Token 방식을 사용합니다.

```javascript
// 1. 로그인
const loginResponse = await fetch('/api/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    user_code: 'CG001',
    password: 'password123'
  })
});

const { access_token, user_type } = await loginResponse.json();

// 2. 이후 모든 요청에 토큰 포함
const apiCall = await fetch('/api/caregiver/home', {
  headers: {
    'Authorization': `Bearer ${access_token}`,
    'Content-Type': 'application/json'
  }
});
```

## 🔑 테스트 계정

| 사용자 유형 | 아이디 | 비밀번호 | 설명 |
|------------|--------|----------|------|
| 케어기버 | CG001 | password123 | 케어기버 전용 기능 테스트 |
| 가디언 | GD001 | password123 | 가디언 전용 기능 테스트 |
| 관리자 | AD001 | admin123 | 관리자 전용 기능 테스트 |

## 📱 주요 화면별 API 호출 순서

### 케어기버 앱

#### 1️⃣ 로그인 화면
```javascript
// 로그인
POST /api/auth/login
{
  "user_code": "CG001",
  "password": "password123"
}

// 응답
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer",
  "expires_in": 1800,
  "user_type": "caregiver"
}
```

#### 2️⃣ 홈 화면
```javascript
// 홈 화면 데이터 조회
GET /api/caregiver/home

// 응답
{
  "success": true,
  "data": {
    "caregiver_name": "김케어",
    "today_sessions": [...],
    "seniors": [...],
    "notifications": [...]
  }
}
```

#### 3️⃣ 출근/퇴근 체크
```javascript
// 출근 체크
POST /api/caregiver/attendance/checkin
FormData: {
  "senior_id": 1,
  "location": "서울시 강남구",
  "gps_lat": 37.5665,
  "gps_lng": 126.9780,
  "photo": File
}

// 퇴근 체크  
POST /api/caregiver/attendance/checkout
FormData: {
  "senior_id": 1,
  "location": "서울시 강남구", 
  "gps_lat": 37.5665,
  "gps_lng": 126.9780,
  "photo": File
}
```

#### 4️⃣ 체크리스트 제출
```javascript
POST /api/caregiver/checklist
{
  "senior_id": 1,
  "responses": [
    {
      "question_key": "health_check",
      "question_text": "건강상태는 어떠신가요?",
      "answer": true,
      "notes": "특이사항 없음"
    }
  ]
}
```

#### 5️⃣ 돌봄노트 제출
```javascript
POST /api/caregiver/care-note  
{
  "senior_id": 1,
  "notes": [
    {
      "question_type": "special_moments",
      "question_text": "오늘의 특별한 순간",
      "content": "오늘 웃으면서 TV를 보셨습니다"
    }
  ]
}
```

#### 6️⃣ AI 분석 트리거
```javascript
POST /api/ai/trigger-ai-analysis
{
  "care_session_id": 1
}

// 응답
{
  "success": true,
  "message": "AI 분석이 완료되었습니다",
  "report_id": 15,
  "ai_result": {
    "ai_comment": "오늘 어르신이...",
    "keywords": ["건강함", "기분좋음"],
    "score_percentage": 85.5
  }
}
```

### 가디언 앱

#### 1️⃣ 홈 화면
```javascript
GET /api/guardian/home

// 응답
{
  "success": true,
  "data": {
    "guardian_name": "김가디언",
    "seniors": [...],
    "recent_reports": [...],
    "unread_notifications": [...]
  }
}
```

#### 2️⃣ AI 리포트 목록
```javascript
GET /api/guardian/reports?senior_id=1&page=1&size=20

// 응답 (페이지네이션)
{
  "success": true,
  "items": [...],
  "total": 50,
  "page": 1,
  "size": 20,
  "has_next": true
}
```

#### 3️⃣ 추이 분석
```javascript
GET /api/guardian/trend-analysis/1

// 응답
{
  "success": true,
  "data": {
    "trend": "improving",
    "trend_strength": 7.2,
    "average_score": 78.5,
    "weekly_data": [...],
    "category_analysis": {...},
    "alerts": [...],
    "recommendations": [...]
  }
}
```

#### 4️⃣ 피드백 전송
```javascript
POST /api/guardian/feedback
{
  "ai_report_id": 15,
  "message": "오늘 리포트 잘 받았습니다. 감사합니다.",
  "requirements": "내일은 산책 시간을 늘려주세요",
  "rating": 5
}
```

## 🚨 에러 처리

모든 API는 표준화된 에러 응답을 반환합니다:

```javascript
// 에러 응답 형식
{
  "success": false,
  "detail": "에러 메시지",
  "error_code": "AUTH_001",
  "timestamp": "2025-01-24T10:00:00Z",
  "path": "/api/auth/login"
}
```

### 주요 에러 코드

| 에러 코드 | 설명 | HTTP 상태 |
|----------|------|-----------|
| AUTH_001 | 잘못된 인증 정보 | 401 |
| AUTH_002 | 토큰 만료 | 401 |
| AUTH_003 | 권한 부족 | 403 |
| USER_001 | 사용자를 찾을 수 없음 | 404 |
| CARE_001 | 시니어를 찾을 수 없음 | 404 |
| FILE_001 | 파일 크기 초과 | 400 |
| AI_001 | AI 분석 실패 | 500 |

## 📊 데이터 모델

### 시니어 정보
```javascript
{
  "id": 1,
  "name": "김시니어",
  "age": 75,
  "gender": "여성",
  "photo": "http://localhost:8000/uploads/senior1.jpg",
  "diseases": ["고혈압", "당뇨"],
  "nursing_home": {
    "name": "행복요양원",
    "address": "서울시 강남구",
    "phone": "02-1234-5678"
  }
}
```

### AI 리포트
```javascript
{
  "id": 15,
  "care_session_id": 1,
  "keywords": ["건강함", "기분좋음", "가족그리움"],
  "content": "오늘 어르신의 전반적인 상태는...",
  "ai_comment": "어르신이 오늘 가족 이야기를 많이 하셨으니...",
  "checklist_score_total": 42,
  "checklist_score_percentage": 85.5,
  "trend_comparison": {
    "trend": "improving",
    "change": 5.2,
    "message": "지난 주 대비 5.2% 개선되었습니다"
  },
  "special_notes_summary": "특이사항 없음",
  "status": "generated",
  "created_at": "2025-01-24T10:00:00Z"
}
```

### 추이 분석 결과
```javascript
{
  "trend": "improving",        // "improving", "stable", "declining"
  "trend_strength": 7.2,       // 추세 강도 (0-10)
  "average_score": 78.5,       // 평균 점수
  "score_change": 5.2,         // 점수 변화
  "weekly_data": [
    {
      "week": "2025-01-13",
      "score": 75.0,
      "trend_indicator": "stable",
      "checklist_count": 3
    }
  ],
  "category_analysis": {
    "health": {
      "current_score": 4.2,
      "trend": "improving",
      "change": 0.3,
      "average": 4.0
    }
  },
  "alerts": [
    {
      "type": "score_drop",
      "severity": "high",
      "message": "이번 주 컨디션이 15.0% 급격히 저하되었습니다",
      "recommendation": "가디언에게 즉시 연락하여 상태 확인이 필요합니다"
    }
  ],
  "recommendations": [
    "현재 상태가 좋아지고 있습니다! 지금의 케어 방식을 유지하세요",
    "가디언께서 더 자주 안부 연락을 해주시면 더욱 좋을 것 같습니다"
  ]
}
```

## 📁 파일 업로드

### 이미지 업로드 (출근/퇴근 사진)
```javascript
const formData = new FormData();
formData.append('senior_id', '1');
formData.append('location', '서울시 강남구');
formData.append('gps_lat', '37.5665');
formData.append('gps_lng', '126.9780');
formData.append('photo', fileBlob, 'attendance.jpg');

fetch('/api/caregiver/attendance/checkin', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`
    // Content-Type은 설정하지 않음 (multipart/form-data 자동 설정)
  },
  body: formData
});
```

### 지원하는 파일 형식
- **이미지**: JPG, JPEG, PNG, GIF
- **최대 크기**: 10MB
- **응답**: 업로드된 파일 URL 반환

## 🔄 페이지네이션

모든 목록 API는 페이지네이션을 지원합니다:

```javascript
GET /api/guardian/reports?page=1&size=20&sort_by=created_at&sort_order=desc

// 응답
{
  "success": true,
  "items": [...],
  "total": 100,
  "page": 1,
  "size": 20,
  "has_next": true,
  "has_previous": false,
  "total_pages": 5
}
```

## 💡 개발 팁

### 1. 토큰 관리
```javascript
// 토큰 만료 처리
const apiCall = async (url, options = {}) => {
  const response = await fetch(url, {
    ...options,
    headers: {
      'Authorization': `Bearer ${getToken()}`,
      ...options.headers
    }
  });
  
  if (response.status === 401) {
    // 토큰 만료 → 로그인 화면으로 이동
    redirectToLogin();
    return;
  }
  
  return response.json();
};
```

### 2. 에러 처리
```javascript
const handleApiError = (error) => {
  switch (error.error_code) {
    case 'AUTH_001':
      showMessage('로그인 정보가 올바르지 않습니다');
      break;
    case 'CARE_001':
      showMessage('시니어 정보를 찾을 수 없습니다');
      break;
    default:
      showMessage('오류가 발생했습니다. 다시 시도해주세요');
  }
};
```

### 3. 이미지 표시
```javascript
// 업로드된 이미지 URL 사용
const imageUrl = `http://localhost:8000/uploads/${filename}`;
<img src={imageUrl} alt="케어 사진" />
```

### 4. 실시간 업데이트
현재는 폴링 방식 권장 (WebSocket은 추후 구현 예정):

```javascript
// 30초마다 새로운 알림 확인
setInterval(async () => {
  const notifications = await fetch('/api/guardian/notifications');
  updateNotifications(notifications);
}, 30000);
```

## 🚀 다음 단계

1. **개발 환경 설정**: API 서버 실행 (`python -m uvicorn app.main:app --reload`)
2. **Swagger UI 확인**: `http://localhost:8000/docs`에서 API 테스트
3. **기본 화면 구현**: 로그인 → 홈 화면 → 주요 기능
4. **점진적 기능 추가**: 출근체크 → 체크리스트 → AI 리포트

## 📞 문의사항

API 관련 문의사항이 있으시면 백엔드 개발자에게 연락해주세요!
- Swagger UI에서 실시간 테스트 가능
- 모든 엔드포인트는 현재 동작 중
- 추가 기능 요청 시 언제든 개발 가능
