# Good Hands 데이터베이스 스키마 개선 버전

## 📋 피드백 반영 사항

### ✅ 완료된 개선사항
1. **테이블명 스네이크 표기법**: 기존 코드가 이미 올바르게 적용되어 있음
2. **데이터타입 및 길이 명시**: 모든 컬럼에 적절한 데이터타입과 길이 지정
3. **컬럼별 상세 주석**: 모든 테이블과 컬럼에 COMMENT 추가
4. **제약조건 강화**: CHECK 제약조건, 외래키 제약조건 추가
5. **성능 최적화**: 복합 인덱스, 부분 인덱스 추가

## 📁 파일 구조

```
backend/database_schema/
├── improved_schema_part1.sql    # 사용자 기본 테이블
├── improved_schema_part2.sql    # 케어기버, 가디언 프로필
├── improved_schema_part3.sql    # 관리자, 요양원 정보
├── improved_schema_part4.sql    # 시니어 질병 정보, 시니어 정보
├── improved_schema_part5.sql    # 돌봄 세션, 출근/퇴근 로그
├── improved_schema_part6.sql    # 체크리스트, 돌봄노트
├── improved_schema_part7.sql    # AI 리포트, 피드백
├── improved_schema_part8.sql    # 알림, 트리거, 뷰
├── improved_schema_part9.sql    # 시드 데이터, 초기 설정
├── improved_schema_final.sql    # 완료 로그 및 가이드
├── goodhands_complete_schema.sql # 통합 완전한 스키마
└── README.md                    # 이 파일
```

## 🚀 스키마 적용 방법

### 1. 백업 생성 (중요!)
```bash
# PostgreSQL 백업
pg_dump goodhands > backup_$(date +%Y%m%d_%H%M%S).sql

# SQLite 백업 (현재 개발 환경)
cp goodhands.db goodhands_backup_$(date +%Y%m%d_%H%M%S).db
```

### 2. 완전한 스키마 적용
```bash
# PostgreSQL 적용
psql -d goodhands -f goodhands_complete_schema.sql

# 또는 개별 파일 순차 적용
psql -d goodhands -f improved_schema_part1.sql
psql -d goodhands -f improved_schema_part2.sql
# ... (part9까지 순차 실행)
```

### 3. 기존 데이터 마이그레이션 (필요시)
현재 개발 단계라면 새로운 스키마로 시작 권장
```sql
-- 기존 데이터가 있다면 마이그레이션 스크립트 작성
INSERT INTO new_users SELECT id, user_code, ... FROM old_users;
```

## 📊 주요 개선사항

### 데이터베이스 구조 개선
- **16개 테이블**: 체계적인 정규화 구조
- **2개 뷰**: 대시보드용 성능 최적화
- **자동 트리거**: updated_at 자동 업데이트
- **초기 데이터**: 시스템 설정 및 체크리스트 템플릿

### 성능 최적화
- **복합 인덱스**: 자주 함께 조회되는 컬럼
- **부분 인덱스**: 조건부 최적화
- **뷰 활용**: 복잡한 쿼리 미리 정의

### 데이터 무결성
- **CHECK 제약조건**: 데이터 유효성 검증
- **외래키 제약조건**: 참조 무결성 보장
- **UNIQUE 제약조건**: 중복 방지

## 🔧 ORM 모델 업데이트 가이드

### 현재 모델과의 차이점
1. **추가된 컬럼들**: 각 테이블에 메타데이터 컬럼 추가
2. **데이터타입 변경**: 더 명확한 타입 정의
3. **제약조건 추가**: SQLAlchemy 모델에 반영 필요

### 업데이트 순서
1. `app/models/user.py` - 사용자 관련 모델
2. `app/models/senior.py` - 시니어 관련 모델  
3. `app/models/care.py` - 돌봄 관련 모델
4. `app/models/report.py` - 리포트 관련 모델

## 📈 추가된 기능

### 새로운 테이블
- `system_settings`: 시스템 설정 관리
- `checklist_templates`: 질병별 체크리스트 템플릿
- `senior_diseases`: 시니어 질병 정보 상세 관리
- `attendance_logs`: 출근/퇴근 상세 로그

### 새로운 뷰
- `v_caregiver_dashboard`: 케어기버 대시보드 통계
- `v_guardian_dashboard`: 가디언 대시보드 통계

## ⚡ 성능 고려사항

### 인덱스 전략
- **Primary Key**: 모든 테이블 SERIAL PRIMARY KEY
- **Foreign Key**: 모든 외래키에 인덱스
- **복합 인덱스**: 자주 함께 조회되는 컬럼
- **부분 인덱스**: 조건부 쿼리 최적화

### 쿼리 최적화
- **뷰 활용**: 복잡한 집계 쿼리 미리 정의
- **JSONB 활용**: 유연한 데이터 구조
- **트리거 활용**: 자동화된 데이터 관리

## 🛠️ 개발 환경 설정

### 1. 환경변수 확인
```bash
# .env 파일 확인
DATABASE_URL=postgresql://user:password@localhost:5432/goodhands
```

### 2. 마이그레이션 도구 사용
```bash
# Alembic 초기화 (이미 되어 있다면 스킵)
alembic init alembic

# 새로운 마이그레이션 생성
alembic revision -m "improved_schema_v2"

# 마이그레이션 적용
alembic upgrade head
```

### 3. 시드 데이터 실행
```bash
python seed_data.py
```

## 🔍 검증 방법

### 1. 테이블 생성 확인
```sql
SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;
```

### 2. 인덱스 확인
```sql
SELECT indexname, tablename FROM pg_indexes WHERE schemaname = 'public';
```

### 3. 제약조건 확인
```sql
SELECT conname, contype FROM pg_constraint WHERE connamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
```

## 📞 문의사항

스키마 적용 중 문제가 발생하면:
1. 백업에서 복구
2. 로그 확인
3. 단계별 적용으로 문제 지점 파악

---

**주의**: 프로덕션 환경에서는 반드시 백업 후 적용하고, 점진적 마이그레이션을 권장합니다.
