"""
프론트엔드 개발자를 위한 API 문서화 개선
"""
from fastapi import FastAPI

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
