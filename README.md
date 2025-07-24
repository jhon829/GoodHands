# 🏥 Good Hands (Sinabro) - 재외동포 케어 서비스

<div align="center">

![Good Hands Logo](https://via.placeholder.com/200x100/4CAF50/FFFFFF?text=Good+Hands)

**해외 거주 재외동포를 위한 AI 기반 부모님 돌봄 서비스**

[![Python](https://img.shields.io/badge/Python-3.13-blue)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.116.0-green)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue)](https://postgresql.org)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://docker.com)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[🚀 데모 보기](#-데모) • [📖 API 문서](http://localhost:8000/docs) • [🔧 설치 가이드](#-빠른-시작) • [💬 문의하기](#-문의)

</div>

---

## 📋 프로젝트 개요

**Good Hands**는 해외에 거주하는 재외동포 자녀들이 한국에 계신 부모님의 돌봄 상황을 실시간으로 확인할 수 있는 통합 케어 플랫폼입니다. 

AI가 케어기버의 돌봄 기록을 분석하여 자동으로 가족 친화적인 리포트를 생성하고, 실시간으로 가족들에게 전달합니다.

### 🎯 해결하고자 하는 문제
- 해외 거주로 인한 부모님 안부 확인의 어려움
- 케어기버와의 소통 장벽 및 신뢰성 문제
- 부모님의 실제 상태와 케어 품질에 대한 객관적 정보 부족
- 언어와 문화적 차이로 인한 의사소통의 한계

---

## ✨ 주요 기능

### 👨‍⚕️ 케어기버 앱 기능
- **📍 GPS 기반 출퇴근 관리**: 정확한 위치 확인 및 인증 사진
- **✅ 맞춤형 체크리스트**: 질병별 특화된 10가지 체크리스트 (치매, 당뇨, 고혈압 등)
- **📝 6가지 핵심 돌봄노트**: 
  - 오늘의 특별한 순간
  - 가족에 대한 그리움 표현
  - 감정 상태 변화  - 대화 내용
  - 눈에 띄는 변화
  - 케어 에피소드
- **📅 돌봄 이력 관리**: 캘린더 기반 이력 조회
- **🔔 실시간 알림**: 중요 상황 발생 시 즉시 알림

### 👨‍👩‍👧‍👦 가디언 앱 기능
- **🤖 AI 자동 리포트**: 매일 생성되는 따뜻한 톤의 가족 리포트
- **📊 추이 분석**: 4주간 상태 변화 추이 및 개선 제안
- **🏷️ 스마트 키워드**: #건강함 #기분좋음 #가족그리움 등 직관적 상태 표시
- **💬 양방향 피드백**: 케어기버에게 직접 요청사항 전달
- **📱 실시간 모니터링**: 부모님 상태 실시간 확인
- **🌍 다국어 지원**: 해외 거주자를 위한 현지 언어 지원

### 🤖 AI 분석 시스템
- **자동 점수 계산**: 건강, 정신, 신체, 사회, 일상 영역별 5점 척도
- **개인화된 분석**: 시니어별 질병과 특성을 고려한 맞춤 분석
- **추이 분석**: 최근 4주간 상태 변화 패턴 분석
- **특이사항 감지**: 평소와 다른 패턴 자동 감지 및 알림
- **구체적 제안**: 가족이 실천할 수 있는 구체적 행동 가이드

### ⚙️ 관리자 시스템
- **👥 사용자 관리**: 케어기버-시니어-가디언 매핑 관리
- **📊 통합 대시보드**: 전체 서비스 현황 모니터링
- **📢 공지사항 발송**: 사용자별 맞춤 알림 전송
- **🔍 품질 관리**: 케어 품질 모니터링 및 개선

---

## 🛠️ 기술 스택

<div align="center">

### Backend
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![SQLAlchemy](https://img.shields.io/badge/SQLAlchemy-D71F00?style=for-the-badge&logo=sqlalchemy&logoColor=white)젝트 기여 방법

### 🎥 데모 및 스크린샷
- **[라이브 데모](http://demo.goodhands.co.kr)**: 실제 동작하는 데모 환경
- **[동영상 데모](https://youtube.com/watch?v=demo)**: 주요 기능 시연 영상
- **[스크린샷 갤러리](screenshots/)**: UI/UX 스크린샷 모음

---

## 👥 팀 및 기여

### 🏗️ 핵심 개발팀
- **[@jhon829](https://github.com/jhon829)** - 백엔드 개발 리드
- **프론트엔드 개발자** - 모집 중
- **UI/UX 디자이너** - 모집 중

### 🤝 기여 방법

#### 1. 이슈 리포팅
버그 발견이나 기능 제안시 [GitHub Issues](https://github.com/jhon829/sinabro/issues)를 활용해주세요.

#### 2. 코드 기여
```bash
# 1. Fork 및 Clone
git clone https://github.com/YOUR_USERNAME/sinabro.git

# 2. 브랜치 생성
git checkout -b feature/amazing-feature

# 3. 커밋 및 푸시
git commit -m "feat: 놀라운 기능 추가"
git push origin feature/amazing-feature

# 4. Pull Request 생성
```

#### 3. 문서 개선
API 문서, README, 가이드 문서의 개선사항이 있다면 언제든 PR을 보내주세요.

### 📜 커밋 컨벤션
```
feat: 새로운 기능 추가
fix: 버그 수정
docs: 문서 수정
style: 코드 스타일 변경
refactor: 코드 리팩토링
test: 테스트 추가/수정
chore: 빌드 프로세스 또는 보조 도구 변경
```

---

## 🏆 라이선스

이 프로젝트는 **MIT License** 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

```
MIT License

Copyright (c) 2024 Good Hands Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

---

## 📞 문의

### 💬 소통 채널
- **GitHub Issues**: [프로젝트 이슈](https://github.com/jhon829/sinabro/issues)
- **GitHub Discussions**: [토론 및 질문](https://github.com/jhon829/sinabro/discussions)
- **이메일**: goodhands.dev@gmail.com
- **Slack**: #goodhands-dev (팀 내부)

### 🌐 관련 링크
- **프로젝트 홈페이지**: https://goodhands.co.kr (예정)
- **API 문서**: http://localhost:8000/docs
- **개발 블로그**: https://blog.goodhands.co.kr (예정)
- **사용자 가이드**: https://guide.goodhands.co.kr (예정)

### 📧 비즈니스 문의
서비스 도입, 파트너십, 투자 관련 문의는 business@goodhands.co.kr로 연락해주세요.

---

## 🙏 감사의 말

### 💡 영감과 동기
이 프로젝트는 코로나19 팬데믹 기간 동안 해외에 거주하며 한국의 부모님을 돌볼 수 없었던 많은 재외동포들의 어려움에서 시작되었습니다. 기술을 통해 가족 간의 거리를 좁히고, 더 나은 돌봄 서비스를 제공하고자 합니다.

### 🤝 기여해주신 분들
- **오픈소스 커뮤니티**: FastAPI, SQLAlchemy 등 훌륭한 도구들
- **베타 테스터들**: 귀중한 피드백을 제공해주신 분들
- **멘토와 조언자들**: 프로젝트 방향성에 도움을 주신 분들

### 🌟 특별한 감사
이 서비스를 통해 조금이나마 마음의 위안을 얻으시길 바라며, 모든 재외동포 가족들에게 따뜻한 마음을 전합니다.

---

<div align="center">

## 🌟 프로젝트가 도움이 되었다면 ⭐️을 눌러주세요!

**"따뜻한 손길로 연결하는 가족의 마음"** ❤️

[![Star this repo](https://img.shields.io/github/stars/jhon829/sinabro?style=social)](https://github.com/jhon829/sinabro)
[![Fork this repo](https://img.shields.io/github/forks/jhon829/sinabro?style=social)](https://github.com/jhon829/sinabro/fork)
[![Watch this repo](https://img.shields.io/github/watchers/jhon829/sinabro?style=social)](https://github.com/jhon829/sinabro)

</div>

---

*마지막 업데이트: 2024년 1월 24일*
*버전: v1.0.0*