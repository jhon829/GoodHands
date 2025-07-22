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

-- 기존 테이블이 있다면 삭제 (개발 환경용)
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
-- 설명: 모든 사용자(케어기버, 가디언, 관리자)의 기본 인증 정보
-- =============================================================================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    user_code VARCHAR(20) UNIQUE NOT NULL,                    -- 사용자 고유 코드 (CG001, GD001 등)
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('caregiver', 'guardian', 'admin')), -- 사용자 유형
    email VARCHAR(100) UNIQUE,                                -- 이메일 주소 (로그인용)
    password_hash VARCHAR(255) NOT NULL,                      -- 암호화된 비밀번호
    is_active BOOLEAN DEFAULT true,                           -- 계정 활성화 상태
    last_login_at TIMESTAMP,                                  -- 마지막 로그인 시간
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 계정 생성 시간
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP            -- 정보 수정 시간
);

-- 인덱스 생성
CREATE INDEX idx_users_user_code ON users(user_code);
CREATE INDEX idx_users_user_type ON users(user_type);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_is_active ON users(is_active);

-- 코멘트 추가
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

-- =============================================================================
-- 2. 케어기버 프로필 테이블 (caregivers)
-- 설명: 케어기버의 상세 정보 및 업무 관련 데이터
-- =============================================================================
CREATE TABLE caregivers (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL,                          -- 사용자 기본 정보 ID (1:1 관계)
    name VARCHAR(100) NOT NULL,                               -- 케어기버 실명
    phone VARCHAR(20),                                        -- 휴대폰 번호
    profile_image VARCHAR(500),                               -- 프로필 이미지 경로
    license_number VARCHAR(50),                               -- 자격증 번호
    license_type VARCHAR(50),                                 -- 자격증 종류 (요양보호사 등)
    experience_years INTEGER DEFAULT 0,                       -- 경력 연수
    specialties JSONB,                                        -- 전문 분야 (치매, 당뇨 등)
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'on_leave')), -- 근무 상태
    hire_date DATE,                                           -- 고용 시작일
    emergency_contact VARCHAR(20),                            -- 비상 연락처
    address TEXT,                                             -- 주소
    notes TEXT,                                               -- 특이사항 메모
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 등록 시간
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 수정 시간
    
    -- 외래키 제약조건
    CONSTRAINT fk_caregivers_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 인덱스 생성
CREATE INDEX idx_caregivers_user_id ON caregivers(user_id);
CREATE INDEX idx_caregivers_status ON caregivers(status);
CREATE INDEX idx_caregivers_license_number ON caregivers(license_number);

-- 코멘트 추가
COMMENT ON TABLE caregivers IS '케어기버의 상세 정보 및 업무 관련 데이터를 저장하는 테이블';
COMMENT ON COLUMN caregivers.id IS '케어기버 고유 식별자 (자동 증가)';
COMMENT ON COLUMN caregivers.user_id IS '사용자 기본 정보 테이블과의 연결 ID (1:1 관계)';
COMMENT ON COLUMN caregivers.name IS '케어기버 실명';
COMMENT ON COLUMN caregivers.phone IS '휴대폰 번호 (010-1234-5678 형식)';
COMMENT ON COLUMN caregivers.profile_image IS '프로필 사진 파일 저장 경로';
COMMENT ON COLUMN caregivers.license_number IS '요양보호사 자격증 번호';
COMMENT ON COLUMN caregivers.license_type IS '자격증 종류 (요양보호사, 간병사 등)';
COMMENT ON COLUMN caregivers.experience_years IS '돌봄 업무 경력 연수';
COMMENT ON COLUMN caregivers.specialties IS '전문 분야 JSON (["치매", "당뇨", "고혈압"])';
COMMENT ON COLUMN caregivers.status IS '근무 상태 (active: 활동, inactive: 비활성, on_leave: 휴직)';
COMMENT ON COLUMN caregivers.hire_date IS '고용 시작일';
COMMENT ON COLUMN caregivers.emergency_contact IS '비상 연락처';
COMMENT ON COLUMN caregivers.address IS '거주지 주소';
COMMENT ON COLUMN caregivers.notes IS '관리자용 특이사항 메모';
COMMENT ON COLUMN caregivers.created_at IS '등록 시간';
COMMENT ON COLUMN caregivers.updated_at IS '정보 마지막 수정 시간';

-- =============================================================================
-- 3. 가디언 프로필 테이블 (guardians)
-- 설명: 가디언(보호자)의 상세 정보
-- =============================================================================
CREATE TABLE guardians (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL,                          -- 사용자 기본 정보 ID (1:1 관계)
    name VARCHAR(100) NOT NULL,                               -- 가디언 실명
    phone VARCHAR(20),                                        -- 휴대폰 번호
    country VARCHAR(100),                                     -- 거주 국가
    city VARCHAR(100),                                        -- 거주 도시
    time_zone VARCHAR(50),                                    -- 시간대 (Asia/Seoul, America/New_York 등)
    relationship_type VARCHAR(30),                            -- 시니어와의 관계 (자녀, 손자 등)
    preferred_language VARCHAR(10) DEFAULT 'ko',              -- 선호 언어 (ko, en 등)
    notification_preferences JSONB,                           -- 알림 설정 (푸시, 이메일 등)
    emergency_contact VARCHAR(20),                            -- 비상 연락처
    notes TEXT,                                               -- 특이사항 메모
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 등록 시간
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 수정 시간
    
    -- 외래키 제약조건
    CONSTRAINT fk_guardians_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 인덱스 생성
CREATE INDEX idx_guardians_user_id ON guardians(user_id);
CREATE INDEX idx_guardians_country ON guardians(country);
CREATE INDEX idx_guardians_relationship ON guardians(relationship_type);

-- 코멘트 추가
COMMENT ON TABLE guardians IS '가디언(보호자)의 상세 정보를 저장하는 테이블';
COMMENT ON COLUMN guardians.id IS '가디언 고유 식별자 (자동 증가)';
COMMENT ON COLUMN guardians.user_id IS '사용자 기본 정보 테이블과의 연결 ID (1:1 관계)';
COMMENT ON COLUMN guardians.name IS '가디언 실명';
COMMENT ON COLUMN guardians.phone IS '휴대폰 번호 (국제 번호 포함 가능)';
COMMENT ON COLUMN guardians.country IS '현재 거주 중인 국가명';
COMMENT ON COLUMN guardians.city IS '현재 거주 중인 도시명';
COMMENT ON COLUMN guardians.time_zone IS '거주지 시간대 (리포트 발송 시간 조정용)';
COMMENT ON COLUMN guardians.relationship_type IS '시니어와의 관계 (자녀, 손자, 며느리 등)';
COMMENT ON COLUMN guardians.preferred_language IS 'UI 및 알림 언어 설정';
COMMENT ON COLUMN guardians.notification_preferences IS '알림 설정 JSON (푸시, 이메일, SMS 등)';
COMMENT ON COLUMN guardians.emergency_contact IS '가디언의 비상 연락처';
COMMENT ON COLUMN guardians.notes IS '관리자용 특이사항 메모';
COMMENT ON COLUMN guardians.created_at IS '등록 시간';
COMMENT ON COLUMN guardians.updated_at IS '정보 마지막 수정 시간';
