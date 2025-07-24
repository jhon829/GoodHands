"""
프론트엔드 개발자를 위한 API 문서화 개선
"""
from fastapi import FastAPI
from app.main import app

# Swagger UI 설정 개선
app.title = "Good Hands Care Service API"
app.description = """
## 재외동포 케어 서비스 API

### 주요 기능
- **인증**: JWT 토큰 기반 로그인/회원가입
- **케어기버**: 출근/퇴근, 체크리스트, 돌봄노트, 케어 스케줄
- **가디언**: AI 리포트 조회, 추이 분석, 피드백 전송
- **AI 분석**: 자동 점수 계산, 추이 분석, 특이사항 감지

### 인증 방법
1. POST `/api/auth/login`으로 로그인
2. 응답의 `access_token` 사용
3. 이후 모든 API 요청 헤더에 `Authorization: Bearer <token>` 추가

### 테스트 계정
- 케어기버: `CG001` / `password123`
- 가디언: `GD001` / `password123`
- 관리자: `AD001` / `admin123`

### 에러 응답 형식
```json
{
    "detail": "에러 메시지",
    "error_code": "ERROR_CODE",
    "timestamp": "2025-01-24T10:00:00Z"
}
```

### 페이지네이션 형식
```json
{
    "items": [...],
    "total": 100,
    "page": 1,
    "size": 20,
    "has_next": true
}
```
"""
app.version = "1.0.0"
app.contact = {
    "name": "Good Hands API Support",
    "email": "api@goodhands.com"
}
app.license_info = {
    "name": "MIT",
    "url": "https://opensource.org/licenses/MIT"
}

# 태그 설명 추가
tags_metadata = [
    {
        "name": "auth",
        "description": "사용자 인증 관련 API (로그인, 회원가입)",
    },
    {
        "name": "caregiver", 
        "description": "케어기버 전용 API (출근/퇴근, 체크리스트, 돌봄노트)",
    },
    {
        "name": "guardian",
        "description": "가디언 전용 API (리포트 조회, 피드백 전송)",
    },
    {
        "name": "ai",
        "description": "AI 분석 관련 API (리포트 생성, 추이 분석)",
    },
    {
        "name": "admin",
        "description": "관리자 전용 API (사용자 관리, 시스템 설정)",
    }
]

app.openapi_tags = tags_metadata
