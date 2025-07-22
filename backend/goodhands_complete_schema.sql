-- =============================================================================
-- Good Hands 재외동포 케어 서비스 - 완전한 데이터베이스 스키마
-- 작성일: 2025년 7월 17일
-- 버전: 2.0 (피드백 반영 개선 버전)
-- 
-- 피드백 반영 사항:
-- 1. ✅ 테이블명 스네이크 표기법 및 소문자 적용 (이미 적용됨)
-- 2. ✅ 데이터타입 및 데이터길이 명시
-- 3. ✅ 모든 컬럼에 상세한 주석(코멘트) 추가
-- 4. ✅ 제약조건 및 인덱스 최적화
-- 5. ✅ 현재 모델과의 호환성 유지
-- =============================================================================

-- 실행 방법:
-- psql -d goodhands -f goodhands_complete_schema.sql

-- 기존 테이블 삭제 (개발 환경용)
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS feedbacks CASCADE;
DROP TABLE IF EXISTS ai_reports CASCADE;
DROP TABLE IF EXISTS care_notes CASCADE;
DROP TABLE IF EXISTS checklist_responses CASCADE;
DROP TABLE IF EXISTS attendance_logs CASCADE;
DROP TABLE IF EXISTS care_sessions CASCADE;
DROP TABLE IF EXISTS senior_diseases CASCADE;
DROP TABLE IF EXISTS seniors CASCADE;
DROP TABLE IF EXISTS nursing_homes CASCADE;
DROP TABLE IF EXISTS admins CASCADE;
DROP TABLE IF EXISTS guardians CASCADE;
DROP TABLE IF EXISTS caregivers CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS checklist_templates CASCADE;
DROP TABLE IF EXISTS system_settings CASCADE;

-- ============================================================================
-- PART 1: 기본 사용자 및 프로필 테이블
-- ============================================================================

-- 1. 사용자 기본 테이블
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    user_code VARCHAR(20) UNIQUE NOT NULL,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('caregiver', 'guardian', 'admin')),
    email VARCHAR(100) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_user_code ON users(user_code);
CREATE INDEX idx_users_user_type ON users(user_type);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_is_active ON users(is_active);

COMMENT ON TABLE users IS '모든 사용자의 기본 인증 정보를 저장하는 테이블';
COMMENT ON COLUMN users.id IS '사용자 고유 식별자 (자동 증가)';
COMMENT ON COLUMN users.user_code IS '사용자 고유 코드 (CG001: 케어기버, GD001: 가디언, AD001: 관리자)';
COMMENT ON COLUMN users.user_type IS '사용자 유형 (caregiver: 케어기버, guardian: 가디언, admin: 관리자)';
COMMENT ON COLUMN users.email IS '이메일 주소 (로그인 ID 및 알림용)';
COMMENT ON COLUMN users.password_hash IS 'bcrypt 등으로 암호화된 비밀번호';
COMMENT ON COLUMN users.is_active IS '계정 활성화 상태 (탈퇴시 false)';
COMMENT ON COLUMN users.last_login_at IS '마지막 로그인 시간';
COMMENT ON COLUMN users.created_at IS '계정 생성 시간';
COMMENT ON COLUMN users.updated_at IS '정보 마지막 수정 시간';
