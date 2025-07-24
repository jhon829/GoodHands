-- =============================================================================
-- Good Hands 재외동포 케어 서비스 데이터베이스 스키마 (개선 버전)
-- 작성일: 2025년 7월 17일
-- 기존 모델 분석 후 피드백 반영하여 개선
-- 피드백 반영 사항:
-- 1. 데이터타입 및 길이 명시
-- 2. 컬럼별 상세 주석 추가  
-- 3. 제약조건 강화
-- 4. 성능 최적화 인덱스 추가
-- =============================================================================

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

-- =============================================================================
-- 1. 사용자 기본 테이블 (users)
-- =============================================================================
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
