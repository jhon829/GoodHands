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

-- =============================================================================
-- 4. 관리자 프로필 테이블 (admins)
-- 설명: 시스템 관리자의 상세 정보 및 권한
-- =============================================================================
CREATE TABLE admins (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL,                          -- 사용자 기본 정보 ID (1:1 관계)
    name VARCHAR(100) NOT NULL,                               -- 관리자 실명
    employee_id VARCHAR(50),                                  -- 직원 번호
    department VARCHAR(50),                                   -- 소속 부서
    position VARCHAR(50),                                     -- 직급
    permissions JSONB,                                        -- 권한 정보 JSON
    access_level INTEGER DEFAULT 1 CHECK (access_level >= 1 AND access_level <= 10), -- 접근 권한 레벨
    phone VARCHAR(20),                                        -- 연락처
    is_super_admin BOOLEAN DEFAULT false,                     -- 최고 관리자 여부
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 등록 시간
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 수정 시간
    
    -- 외래키 제약조건
    CONSTRAINT fk_admins_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 인덱스 생성
CREATE INDEX idx_admins_user_id ON admins(user_id);
CREATE INDEX idx_admins_employee_id ON admins(employee_id);
CREATE INDEX idx_admins_access_level ON admins(access_level);

-- 코멘트 추가
COMMENT ON TABLE admins IS '시스템 관리자의 상세 정보 및 권한을 저장하는 테이블';
COMMENT ON COLUMN admins.id IS '관리자 고유 식별자 (자동 증가)';
COMMENT ON COLUMN admins.user_id IS '사용자 기본 정보 테이블과의 연결 ID (1:1 관계)';
COMMENT ON COLUMN admins.name IS '관리자 실명';
COMMENT ON COLUMN admins.employee_id IS '회사 내 직원 번호';
COMMENT ON COLUMN admins.department IS '소속 부서명';
COMMENT ON COLUMN admins.position IS '직급 또는 직책';
COMMENT ON COLUMN admins.permissions IS '세부 권한 설정 JSON';
COMMENT ON COLUMN admins.access_level IS '접근 권한 레벨 (1: 기본 ~ 10: 최고)';
COMMENT ON COLUMN admins.phone IS '업무용 연락처';
COMMENT ON COLUMN admins.is_super_admin IS '최고 관리자 권한 여부';
COMMENT ON COLUMN admins.created_at IS '등록 시간';
COMMENT ON COLUMN admins.updated_at IS '정보 마지막 수정 시간';

-- =============================================================================
-- 5. 요양원 정보 테이블 (nursing_homes)
-- 설명: 시니어가 거주하는 요양원의 정보
-- =============================================================================
CREATE TABLE nursing_homes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,                               -- 요양원 이름
    business_number VARCHAR(50),                              -- 사업자 번호
    address TEXT NOT NULL,                                    -- 주소
    phone VARCHAR(20),                                        -- 대표 전화번호
    fax VARCHAR(20),                                          -- 팩스 번호
    email VARCHAR(100),                                       -- 이메일
    contact_person VARCHAR(100),                              -- 담당자 이름
    contact_phone VARCHAR(20),                                -- 담당자 연락처
    capacity INTEGER,                                         -- 수용 인원
    current_residents INTEGER DEFAULT 0,                      -- 현재 입소자 수
    facility_type VARCHAR(50),                                -- 시설 유형 (요양원, 주간보호센터 등)
    license_number VARCHAR(100),                              -- 운영 허가번호
    accreditation_level VARCHAR(20),                          -- 평가 등급
    services JSONB,                                           -- 제공 서비스 목록
    is_active BOOLEAN DEFAULT true,                           -- 운영 상태
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 등록 시간
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP            -- 수정 시간
);

-- 인덱스 생성
CREATE INDEX idx_nursing_homes_name ON nursing_homes(name);
CREATE INDEX idx_nursing_homes_is_active ON nursing_homes(is_active);
CREATE INDEX idx_nursing_homes_facility_type ON nursing_homes(facility_type);

-- 코멘트 추가
COMMENT ON TABLE nursing_homes IS '시니어가 거주하는 요양원의 정보를 저장하는 테이블';
COMMENT ON COLUMN nursing_homes.id IS '요양원 고유 식별자 (자동 증가)';
COMMENT ON COLUMN nursing_homes.name IS '요양원 정식 명칭';
COMMENT ON COLUMN nursing_homes.business_number IS '사업자 등록번호';
COMMENT ON COLUMN nursing_homes.address IS '요양원 주소';
COMMENT ON COLUMN nursing_homes.phone IS '요양원 대표 전화번호';
COMMENT ON COLUMN nursing_homes.fax IS '팩스 번호';
COMMENT ON COLUMN nursing_homes.email IS '요양원 이메일 주소';
COMMENT ON COLUMN nursing_homes.contact_person IS '담당자 이름';
COMMENT ON COLUMN nursing_homes.contact_phone IS '담당자 직통 전화번호';
COMMENT ON COLUMN nursing_homes.capacity IS '최대 수용 가능 인원';
COMMENT ON COLUMN nursing_homes.current_residents IS '현재 입소자 수';
COMMENT ON COLUMN nursing_homes.facility_type IS '시설 유형 분류';
COMMENT ON COLUMN nursing_homes.license_number IS '운영 허가번호';
COMMENT ON COLUMN nursing_homes.accreditation_level IS '정부 평가 등급';
COMMENT ON COLUMN nursing_homes.services IS '제공 서비스 목록 JSON';
COMMENT ON COLUMN nursing_homes.is_active IS '현재 운영 중인지 여부';
COMMENT ON COLUMN nursing_homes.created_at IS '등록 시간';
COMMENT ON COLUMN nursing_homes.updated_at IS '정보 마지막 수정 시간';

-- =============================================================================
-- 6. 시니어 질병 정보 테이블 (senior_diseases)
-- 설명: 시니어별 질병 정보를 상세히 저장
-- =============================================================================
CREATE TABLE senior_diseases (
    id SERIAL PRIMARY KEY,
    senior_id INTEGER NOT NULL,                               -- 시니어 ID
    disease_type VARCHAR(50) NOT NULL,                        -- 질병 유형 (치매, 당뇨, 고혈압 등)
    disease_code VARCHAR(20),                                 -- 질병 코드 (KCD, ICD 등)
    severity VARCHAR(20) CHECK (severity IN ('mild', 'moderate', 'severe')), -- 중증도
    diagnosis_date DATE,                                      -- 진단일
    medication JSONB,                                         -- 복용 약물 정보
    notes TEXT,                                               -- 질병 관련 특이사항
    is_primary BOOLEAN DEFAULT false,                         -- 주요 질병 여부
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 등록 시간
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 수정 시간
    
    -- 외래키 제약조건
    CONSTRAINT fk_senior_diseases_senior FOREIGN KEY (senior_id) REFERENCES seniors(id) ON DELETE CASCADE
);

-- 인덱스 생성
CREATE INDEX idx_senior_diseases_senior_id ON senior_diseases(senior_id);
CREATE INDEX idx_senior_diseases_type ON senior_diseases(disease_type);
CREATE INDEX idx_senior_diseases_primary ON senior_diseases(is_primary);

-- 코멘트 추가
COMMENT ON TABLE senior_diseases IS '시니어별 질병 정보를 상세히 저장하는 테이블';
COMMENT ON COLUMN senior_diseases.id IS '질병 정보 고유 식별자 (자동 증가)';
COMMENT ON COLUMN senior_diseases.senior_id IS '해당 시니어 ID';
COMMENT ON COLUMN senior_diseases.disease_type IS '질병 유형 (치매, 당뇨, 고혈압, 파킨슨병 등)';
COMMENT ON COLUMN senior_diseases.disease_code IS '표준 질병 분류 코드';
COMMENT ON COLUMN senior_diseases.severity IS '질병 중증도 (경증, 중등도, 중증)';
COMMENT ON COLUMN senior_diseases.diagnosis_date IS '최초 진단일';
COMMENT ON COLUMN senior_diseases.medication IS '현재 복용 중인 약물 정보 JSON';
COMMENT ON COLUMN senior_diseases.notes IS '질병 관련 추가 정보 및 특이사항';
COMMENT ON COLUMN senior_diseases.is_primary IS '주요(기저) 질병 여부';
COMMENT ON COLUMN senior_diseases.created_at IS '등록 시간';
COMMENT ON COLUMN senior_diseases.updated_at IS '정보 마지막 수정 시간';

-- =============================================================================
-- 7. 시니어 정보 테이블 (seniors)
-- 설명: 돌봄 서비스를 받는 시니어(어르신)들의 정보
-- =============================================================================
CREATE TABLE seniors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,                               -- 시니어 실명
    birth_date DATE,                                          -- 생년월일
    age INTEGER,                                              -- 나이
    gender VARCHAR(10) CHECK (gender IN ('male', 'female')),  -- 성별
    photo VARCHAR(500),                                       -- 시니어 사진 경로
    id_number_encrypted VARCHAR(200),                         -- 암호화된 주민등록번호
    blood_type VARCHAR(5),                                    -- 혈액형
    height DECIMAL(5,2),                                      -- 키 (cm)
    weight DECIMAL(5,2),                                      -- 몸무게 (kg)
    nursing_home_id INTEGER,                                  -- 거주 요양원 ID
    room_number VARCHAR(20),                                  -- 방 번호
    caregiver_id INTEGER,                                     -- 담당 케어기버 ID
    guardian_id INTEGER NOT NULL,                             -- 담당 가디언 ID
    admission_date DATE,                                      -- 입소일
    care_level VARCHAR(20),                                   -- 요양 등급
    mobility_status VARCHAR(30),                              -- 거동 상태
    cognitive_status VARCHAR(30),                             -- 인지 상태
    emergency_contact VARCHAR(20),                            -- 비상 연락처
    medical_notes TEXT,                                       -- 의료 특이사항
    dietary_requirements TEXT,                                -- 식단 요구사항
    allergies TEXT,                                           -- 알레르기 정보
    preferences JSONB,                                        -- 개인 선호사항
    family_info JSONB,                                        -- 가족 정보
    is_active BOOLEAN DEFAULT true,                           -- 서비스 이용 상태
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 등록 시간
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 수정 시간
    
    -- 외래키 제약조건
    CONSTRAINT fk_seniors_nursing_home FOREIGN KEY (nursing_home_id) REFERENCES nursing_homes(id) ON DELETE SET NULL,
    CONSTRAINT fk_seniors_caregiver FOREIGN KEY (caregiver_id) REFERENCES caregivers(id) ON DELETE SET NULL,
    CONSTRAINT fk_seniors_guardian FOREIGN KEY (guardian_id) REFERENCES guardians(id) ON DELETE RESTRICT
);

-- 인덱스 생성
CREATE INDEX idx_seniors_caregiver_id ON seniors(caregiver_id);
CREATE INDEX idx_seniors_guardian_id ON seniors(guardian_id);
CREATE INDEX idx_seniors_nursing_home_id ON seniors(nursing_home_id);
CREATE INDEX idx_seniors_age ON seniors(age);
CREATE INDEX idx_seniors_is_active ON seniors(is_active);

-- 코멘트 추가
COMMENT ON TABLE seniors IS '돌봄 서비스를 받는 시니어(어르신)들의 상세 정보를 저장하는 테이블';
COMMENT ON COLUMN seniors.id IS '시니어 고유 식별자 (자동 증가)';
COMMENT ON COLUMN seniors.name IS '시니어 실명';
COMMENT ON COLUMN seniors.birth_date IS '생년월일';
COMMENT ON COLUMN seniors.age IS '나이';
COMMENT ON COLUMN seniors.gender IS '성별 (male: 남성, female: 여성)';
COMMENT ON COLUMN seniors.photo IS '시니어 사진 파일 저장 경로';
COMMENT ON COLUMN seniors.id_number_encrypted IS '암호화된 주민등록번호';
COMMENT ON COLUMN seniors.blood_type IS '혈액형 (A, B, AB, O)';
COMMENT ON COLUMN seniors.height IS '키 (센티미터 단위)';
COMMENT ON COLUMN seniors.weight IS '몸무게 (킬로그램 단위)';
COMMENT ON COLUMN seniors.nursing_home_id IS '거주 중인 요양원 ID';
COMMENT ON COLUMN seniors.room_number IS '요양원 내 방 번호';
COMMENT ON COLUMN seniors.caregiver_id IS '담당 케어기버 ID';
COMMENT ON COLUMN seniors.guardian_id IS '담당 가디언(보호자) ID';
COMMENT ON COLUMN seniors.admission_date IS '요양원 입소일';
COMMENT ON COLUMN seniors.care_level IS '장기요양 등급 (1~5등급, 인지지원등급)';
COMMENT ON COLUMN seniors.mobility_status IS '거동 상태 (자립, 부분도움, 완전도움)';
COMMENT ON COLUMN seniors.cognitive_status IS '인지 상태 (정상, 경미, 중등도, 중증)';
COMMENT ON COLUMN seniors.emergency_contact IS '응급상황 시 연락처';
COMMENT ON COLUMN seniors.medical_notes IS '의료진이 작성한 특이사항';
COMMENT ON COLUMN seniors.dietary_requirements IS '식단 관련 요구사항 및 제한사항';
COMMENT ON COLUMN seniors.allergies IS '알레르기 정보';
COMMENT ON COLUMN seniors.preferences IS '개인 선호사항 JSON (음식, 활동 등)';
COMMENT ON COLUMN seniors.family_info IS '가족 구성원 정보 JSON';
COMMENT ON COLUMN seniors.is_active IS '현재 서비스 이용 중인지 여부';
COMMENT ON COLUMN seniors.created_at IS '등록 시간';
COMMENT ON COLUMN seniors.updated_at IS '정보 마지막 수정 시간';

-- =============================================================================
-- 8. 돌봄 세션 테이블 (care_sessions)
-- 설명: 케어기버의 출근부터 퇴근까지 하나의 돌봄 세션을 기록
-- =============================================================================
CREATE TABLE care_sessions (
    id SERIAL PRIMARY KEY,
    caregiver_id INTEGER NOT NULL,                            -- 케어기버 ID
    senior_id INTEGER NOT NULL,                               -- 담당 시니어 ID
    start_time TIMESTAMP NOT NULL,                            -- 돌봄 시작 시간 (출근)
    end_time TIMESTAMP,                                       -- 돌봄 종료 시간 (퇴근)
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')), -- 세션 상태
    start_location VARCHAR(255),                              -- 출근 위치 정보
    end_location VARCHAR(255),                                -- 퇴근 위치 정보
    start_gps_lat DECIMAL(10, 8),                             -- 출근 GPS 위도
    start_gps_lng DECIMAL(11, 8),                             -- 출근 GPS 경도
    end_gps_lat DECIMAL(10, 8),                               -- 퇴근 GPS 위도
    end_gps_lng DECIMAL(11, 8),                               -- 퇴근 GPS 경도
    start_photo VARCHAR(500),                                 -- 출근 인증 사진 경로
    end_photo VARCHAR(500),                                   -- 퇴근 인증 사진 경로
    total_hours DECIMAL(4, 2),                                -- 총 돌봄 시간 (시간 단위)
    session_notes TEXT,                                       -- 세션 전체 메모
    weather VARCHAR(50),                                      -- 날씨 정보
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 생성 시간
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 수정 시간
    
    -- 외래키 제약조건
    CONSTRAINT fk_care_sessions_caregiver FOREIGN KEY (caregiver_id) REFERENCES caregivers(id) ON DELETE RESTRICT,
    CONSTRAINT fk_care_sessions_senior FOREIGN KEY (senior_id) REFERENCES seniors(id) ON DELETE RESTRICT
);

-- 인덱스 생성
CREATE INDEX idx_care_sessions_caregiver_id ON care_sessions(caregiver_id);
CREATE INDEX idx_care_sessions_senior_id ON care_sessions(senior_id);
CREATE INDEX idx_care_sessions_start_time ON care_sessions(start_time);
CREATE INDEX idx_care_sessions_status ON care_sessions(status);
CREATE INDEX idx_care_sessions_caregiver_date ON care_sessions(caregiver_id, DATE(start_time));

-- 코멘트 추가
COMMENT ON TABLE care_sessions IS '케어기버의 출근부터 퇴근까지 하나의 돌봄 세션을 기록하는 테이블';
COMMENT ON COLUMN care_sessions.id IS '돌봄 세션 고유 식별자 (자동 증가)';
COMMENT ON COLUMN care_sessions.caregiver_id IS '돌봄을 수행한 케어기버 ID';
COMMENT ON COLUMN care_sessions.senior_id IS '돌봄을 받은 시니어 ID';
COMMENT ON COLUMN care_sessions.start_time IS '돌봄 시작 시간 (출근 체크 시간)';
COMMENT ON COLUMN care_sessions.end_time IS '돌봄 종료 시간 (퇴근 체크 시간)';
COMMENT ON COLUMN care_sessions.status IS '세션 상태 (active: 진행중, completed: 완료, cancelled: 취소)';
COMMENT ON COLUMN care_sessions.start_location IS '출근 위치 정보 (주소 또는 GPS 좌표)';
COMMENT ON COLUMN care_sessions.end_location IS '퇴근 위치 정보 (주소 또는 GPS 좌표)';
COMMENT ON COLUMN care_sessions.start_gps_lat IS '출근 GPS 위도 좌표';
COMMENT ON COLUMN care_sessions.start_gps_lng IS '출근 GPS 경도 좌표';
COMMENT ON COLUMN care_sessions.end_gps_lat IS '퇴근 GPS 위도 좌표';
COMMENT ON COLUMN care_sessions.end_gps_lng IS '퇴근 GPS 경도 좌표';
COMMENT ON COLUMN care_sessions.start_photo IS '출근 인증 사진 파일 경로';
COMMENT ON COLUMN care_sessions.end_photo IS '퇴근 인증 사진 파일 경로';
COMMENT ON COLUMN care_sessions.total_hours IS '총 돌봄 시간 (시간 단위, 소수점 2자리)';
COMMENT ON COLUMN care_sessions.session_notes IS '돌봄 세션 전체에 대한 메모';
COMMENT ON COLUMN care_sessions.weather IS '돌봄 당일 날씨 정보';
COMMENT ON COLUMN care_sessions.created_at IS '세션 생성 시간';
COMMENT ON COLUMN care_sessions.updated_at IS '세션 정보 마지막 수정 시간';

-- =============================================================================
-- 9. 출근/퇴근 로그 테이블 (attendance_logs)
-- 설명: 케어기버의 출근/퇴근 기록을 상세히 저장
-- =============================================================================
CREATE TABLE attendance_logs (
    id SERIAL PRIMARY KEY,
    care_session_id INTEGER NOT NULL,                         -- 돌봄 세션 ID
    log_type VARCHAR(20) NOT NULL CHECK (log_type IN ('checkin', 'checkout')), -- 로그 유형
    location VARCHAR(255),                                    -- 위치 정보
    gps_lat DECIMAL(10, 8),                                   -- GPS 위도
    gps_lng DECIMAL(11, 8),                                   -- GPS 경도
    photo VARCHAR(500),                                       -- 인증 사진 경로
    verification_method VARCHAR(30) DEFAULT 'gps_photo',      -- 인증 방법
    notes TEXT,                                               -- 추가 메모
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 기록 시간
    
    -- 외래키 제약조건
    CONSTRAINT fk_attendance_logs_session FOREIGN KEY (care_session_id) REFERENCES care_sessions(id) ON DELETE CASCADE
);

-- 인덱스 생성
CREATE INDEX idx_attendance_logs_session_id ON attendance_logs(care_session_id);
CREATE INDEX idx_attendance_logs_type ON attendance_logs(log_type);
CREATE INDEX idx_attendance_logs_created_at ON attendance_logs(created_at);

-- 코멘트 추가
COMMENT ON TABLE attendance_logs IS '케어기버의 출근/퇴근 기록을 상세히 저장하는 테이블';
COMMENT ON COLUMN attendance_logs.id IS '출근/퇴근 로그 고유 식별자 (자동 증가)';
COMMENT ON COLUMN attendance_logs.care_session_id IS '해당 돌봄 세션 ID';
COMMENT ON COLUMN attendance_logs.log_type IS '로그 유형 (checkin: 출근, checkout: 퇴근)';
COMMENT ON COLUMN attendance_logs.location IS '출근/퇴근 위치 정보';
COMMENT ON COLUMN attendance_logs.gps_lat IS 'GPS 위도 좌표';
COMMENT ON COLUMN attendance_logs.gps_lng IS 'GPS 경도 좌표';
COMMENT ON COLUMN attendance_logs.photo IS '출근/퇴근 인증 사진 파일 경로';
COMMENT ON COLUMN attendance_logs.verification_method IS '인증 방법 (GPS+사진, QR코드 등)';
COMMENT ON COLUMN attendance_logs.notes IS '출근/퇴근 시 추가 메모';
COMMENT ON COLUMN attendance_logs.created_at IS '출근/퇴근 기록 시간';

-- =============================================================================
-- 10. 체크리스트 응답 테이블 (checklist_responses)
-- 설명: 케어기버가 작성한 체크리스트 응답을 저장
-- =============================================================================
CREATE TABLE checklist_responses (
    id SERIAL PRIMARY KEY,
    care_session_id INTEGER NOT NULL,                         -- 돌봄 세션 ID
    question_key VARCHAR(100) NOT NULL,                       -- 질문 식별 키
    question_text TEXT NOT NULL,                              -- 질문 내용
    answer_type VARCHAR(20) NOT NULL CHECK (answer_type IN ('boolean', 'text', 'number', 'select', 'json')), -- 응답 유형
    answer JSONB NOT NULL,                                    -- 원본 응답 데이터 (JSON)
    boolean_value BOOLEAN,                                    -- boolean 타입 응답
    text_value TEXT,                                          -- 텍스트 타입 응답
    number_value DECIMAL(10, 2),                              -- 숫자 타입 응답
    select_value VARCHAR(100),                                -- 선택형 응답
    notes TEXT,                                               -- 추가 메모
    is_required BOOLEAN DEFAULT false,                        -- 필수 응답 여부
    response_time INTEGER,                                    -- 응답 소요 시간 (초)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 응답 시간
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 수정 시간
    
    -- 외래키 제약조건
    CONSTRAINT fk_checklist_responses_session FOREIGN KEY (care_session_id) REFERENCES care_sessions(id) ON DELETE CASCADE
);

-- 인덱스 생성
CREATE INDEX idx_checklist_responses_session_id ON checklist_responses(care_session_id);
CREATE INDEX idx_checklist_responses_question_key ON checklist_responses(question_key);
CREATE INDEX idx_checklist_responses_answer_type ON checklist_responses(answer_type);

-- 코멘트 추가
COMMENT ON TABLE checklist_responses IS '케어기버가 작성한 체크리스트 응답을 저장하는 테이블';
COMMENT ON COLUMN checklist_responses.id IS '체크리스트 응답 고유 식별자 (자동 증가)';
COMMENT ON COLUMN checklist_responses.care_session_id IS '해당 돌봄 세션 ID';
COMMENT ON COLUMN checklist_responses.question_key IS '질문 식별 키 (memory_check, medication_taken 등)';
COMMENT ON COLUMN checklist_responses.question_text IS '실제 질문 내용 텍스트';
COMMENT ON COLUMN checklist_responses.answer_type IS '응답 유형 (boolean, text, number, select)';
COMMENT ON COLUMN checklist_responses.answer IS '원본 응답 데이터 JSON';
COMMENT ON COLUMN checklist_responses.boolean_value IS 'Yes/No 형태의 boolean 응답';
COMMENT ON COLUMN checklist_responses.text_value IS '자유 텍스트 응답';
COMMENT ON COLUMN checklist_responses.number_value IS '숫자 형태의 응답 (혈압, 혈당 등)';
COMMENT ON COLUMN checklist_responses.select_value IS '선택형 응답 (좋음/보통/나쁨 등)';
COMMENT ON COLUMN checklist_responses.notes IS '응답에 대한 추가 메모';
COMMENT ON COLUMN checklist_responses.is_required IS '필수 응답 여부';
COMMENT ON COLUMN checklist_responses.response_time IS '응답 작성에 소요된 시간 (초)';
COMMENT ON COLUMN checklist_responses.created_at IS '응답 작성 시간';
COMMENT ON COLUMN checklist_responses.updated_at IS '응답 수정 시간';

-- =============================================================================
-- 11. 돌봄노트 테이블 (care_notes)
-- 설명: 케어기버가 작성한 6개 핵심 질문의 돌봄노트를 저장
-- =============================================================================
CREATE TABLE care_notes (
    id SERIAL PRIMARY KEY,
    care_session_id INTEGER NOT NULL,                         -- 돌봄 세션 ID
    question_type VARCHAR(50) NOT NULL CHECK (question_type IN (
        'special_moments',      -- 특별한 순간
        'family_longing',       -- 가족 그리움
        'emotional_state',      -- 감정 상태
        'conversation',         -- 대화 내용
        'changes',             -- 변화사항
        'care_episodes'        -- 돌봄 에피소드
    )),                                                       -- 질문 유형
    question_text TEXT NOT NULL,                              -- 질문 내용
    content TEXT NOT NULL,                                    -- 돌봄노트 내용
    keywords VARCHAR(500),                                    -- 키워드 추출 (쉼표로 구분)
    emotion_score INTEGER CHECK (emotion_score >= 1 AND emotion_score <= 5), -- 감정 점수 (1-5)
    importance_level VARCHAR(20) DEFAULT 'normal' CHECK (importance_level IN ('low', 'normal', 'high', 'urgent')), -- 중요도
    attachments JSONB,                                        -- 첨부파일 정보
    word_count INTEGER,                                       -- 작성된 단어 수
    writing_time INTEGER,                                     -- 작성 소요 시간 (초)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 작성 시간
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 수정 시간
    
    -- 외래키 제약조건
    CONSTRAINT fk_care_notes_session FOREIGN KEY (care_session_id) REFERENCES care_sessions(id) ON DELETE CASCADE
);

-- 인덱스 생성
CREATE INDEX idx_care_notes_session_id ON care_notes(care_session_id);
CREATE INDEX idx_care_notes_question_type ON care_notes(question_type);
CREATE INDEX idx_care_notes_importance_level ON care_notes(importance_level);
CREATE INDEX idx_care_notes_emotion_score ON care_notes(emotion_score);

-- 코멘트 추가
COMMENT ON TABLE care_notes IS '케어기버가 작성한 6개 핵심 질문의 돌봄노트를 저장하는 테이블';
COMMENT ON COLUMN care_notes.id IS '돌봄노트 고유 식별자 (자동 증가)';
COMMENT ON COLUMN care_notes.care_session_id IS '해당 돌봄 세션 ID';
COMMENT ON COLUMN care_notes.question_type IS '6개 핵심 질문 유형 구분';
COMMENT ON COLUMN care_notes.question_text IS '실제 질문 내용 텍스트';
COMMENT ON COLUMN care_notes.content IS '케어기버가 작성한 돌봄노트 내용';
COMMENT ON COLUMN care_notes.keywords IS '내용에서 추출한 주요 키워드 (쉼표로 구분)';
COMMENT ON COLUMN care_notes.emotion_score IS '시니어의 감정 상태 점수 (1: 매우 나쁨 ~ 5: 매우 좋음)';
COMMENT ON COLUMN care_notes.importance_level IS '해당 노트의 중요도 수준';
COMMENT ON COLUMN care_notes.attachments IS '첨부파일 정보 JSON (사진, 영상 경로 등)';
COMMENT ON COLUMN care_notes.word_count IS '작성된 돌봄노트의 단어 수';
COMMENT ON COLUMN care_notes.writing_time IS '돌봄노트 작성에 소요된 시간 (초)';
COMMENT ON COLUMN care_notes.created_at IS '돌봄노트 작성 시간';
COMMENT ON COLUMN care_notes.updated_at IS '돌봄노트 수정 시간';

-- =============================================================================
-- 12. AI 리포트 테이블 (ai_reports)
-- 설명: 체크리스트와 돌봄노트를 기반으로 생성된 AI 리포트를 저장
-- =============================================================================
CREATE TABLE ai_reports (
    id SERIAL PRIMARY KEY,
    care_session_id INTEGER UNIQUE NOT NULL,                  -- 돌봄 세션 ID (1:1 관계)
    report_version VARCHAR(10) DEFAULT '1.0',                 -- 리포트 버전
    keywords JSONB,                                           -- 추출된 키워드 JSON 배열
    summary TEXT,                                             -- 리포트 요약
    content TEXT NOT NULL,                                    -- AI가 생성한 리포트 본문
    ai_comment TEXT,                                          -- AI의 특별 코멘트 및 제안사항
    emotion_analysis JSONB,                                   -- 감정 분석 결과
    health_indicators JSONB,                                  -- 건강 지표 분석
    recommendations JSONB,                                    -- AI 추천사항 목록
    risk_level VARCHAR(20) DEFAULT 'normal' CHECK (risk_level IN ('low', 'normal', 'medium', 'high', 'critical')), -- 위험도
    quality_score DECIMAL(3, 2) CHECK (quality_score >= 0 AND quality_score <= 10), -- 리포트 품질 점수 (0-10)
    generation_time_ms INTEGER,                               -- 리포트 생성 소요 시간 (밀리초)
    ai_model_version VARCHAR(50),                             -- 사용된 AI 모델 버전
    status VARCHAR(20) DEFAULT 'generated' CHECK (status IN ('generated', 'read', 'reviewed', 'archived')), -- 상태
    is_reviewed BOOLEAN DEFAULT false,                        -- 관리자 검토 완료 여부
    reviewed_by INTEGER,                                      -- 검토한 관리자 ID
    reviewed_at TIMESTAMP,                                    -- 검토 완료 시간
    view_count INTEGER DEFAULT 0,                             -- 조회 횟수
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 생성 시간
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 수정 시간
    
    -- 외래키 제약조건
    CONSTRAINT fk_ai_reports_session FOREIGN KEY (care_session_id) REFERENCES care_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_ai_reports_reviewer FOREIGN KEY (reviewed_by) REFERENCES admins(id) ON DELETE SET NULL
);

-- 인덱스 생성
CREATE INDEX idx_ai_reports_session_id ON ai_reports(care_session_id);
CREATE INDEX idx_ai_reports_status ON ai_reports(status);
CREATE INDEX idx_ai_reports_risk_level ON ai_reports(risk_level);
CREATE INDEX idx_ai_reports_quality_score ON ai_reports(quality_score);
CREATE INDEX idx_ai_reports_created_at ON ai_reports(created_at);

-- 코멘트 추가
COMMENT ON TABLE ai_reports IS 'AI가 생성한 돌봄 리포트를 저장하는 테이블';
COMMENT ON COLUMN ai_reports.id IS 'AI 리포트 고유 식별자 (자동 증가)';
COMMENT ON COLUMN ai_reports.care_session_id IS '해당 돌봄 세션 ID (1:1 관계)';
COMMENT ON COLUMN ai_reports.report_version IS '리포트 템플릿 버전';
COMMENT ON COLUMN ai_reports.keywords IS '리포트에서 추출된 주요 키워드 JSON 배열';
COMMENT ON COLUMN ai_reports.summary IS '리포트 핵심 내용 요약 (1-2문장)';
COMMENT ON COLUMN ai_reports.content IS 'AI가 생성한 전체 리포트 본문';
COMMENT ON COLUMN ai_reports.ai_comment IS 'AI의 특별 코멘트 및 가족에게 제안하는 내용';
COMMENT ON COLUMN ai_reports.emotion_analysis IS '시니어 감정 상태 분석 결과 JSON';
COMMENT ON COLUMN ai_reports.health_indicators IS '건강 지표 및 변화 추이 JSON';
COMMENT ON COLUMN ai_reports.recommendations IS 'AI가 제안하는 돌봄 개선사항 JSON';
COMMENT ON COLUMN ai_reports.risk_level IS '전반적인 위험도 수준';
COMMENT ON COLUMN ai_reports.quality_score IS '리포트 품질 점수 (0-10, 높을수록 좋음)';
COMMENT ON COLUMN ai_reports.generation_time_ms IS 'AI 리포트 생성에 소요된 시간 (밀리초)';
COMMENT ON COLUMN ai_reports.ai_model_version IS '리포트 생성에 사용된 AI 모델 버전';
COMMENT ON COLUMN ai_reports.status IS '리포트 상태 (generated: 생성됨, read: 읽음, reviewed: 검토됨)';
COMMENT ON COLUMN ai_reports.is_reviewed IS '관리자의 리포트 검토 완료 여부';
COMMENT ON COLUMN ai_reports.reviewed_by IS '리포트를 검토한 관리자 사용자 ID';
COMMENT ON COLUMN ai_reports.reviewed_at IS '관리자 검토 완료 시간';
COMMENT ON COLUMN ai_reports.view_count IS '리포트 조회 횟수';
COMMENT ON COLUMN ai_reports.created_at IS 'AI 리포트 생성 시간';
COMMENT ON COLUMN ai_reports.updated_at IS '리포트 정보 마지막 수정 시간';

-- =============================================================================
-- 13. 피드백 테이블 (feedbacks)
-- 설명: 가디언이 AI 리포트에 대해 남긴 피드백 및 요청사항을 저장
-- =============================================================================
CREATE TABLE feedbacks (
    id SERIAL PRIMARY KEY,
    ai_report_id INTEGER NOT NULL,                            -- AI 리포트 ID
    guardian_id INTEGER NOT NULL,                             -- 피드백을 남긴 가디언 ID
    feedback_type VARCHAR(20) DEFAULT 'general' CHECK (feedback_type IN (
        'general',              -- 일반 피드백
        'concern',             -- 우려사항
        'request',             -- 요청사항
        'appreciation',        -- 감사 인사
        'complaint',           -- 불만사항
        'suggestion'           -- 제안사항
    )),                                                       -- 피드백 유형
    message TEXT NOT NULL,                                    -- 피드백 메시지 내용
    requirements TEXT,                                        -- 특별 요구사항
    urgency_level VARCHAR(20) DEFAULT 'normal' CHECK (urgency_level IN ('low', 'normal', 'high', 'urgent')), -- 긴급도
    sentiment_score DECIMAL(3, 2) CHECK (sentiment_score >= -1 AND sentiment_score <= 1), -- 감정 점수 (-1: 부정 ~ 1: 긍정)
    requires_response BOOLEAN DEFAULT false,                  -- 응답 필요 여부
    caregiver_notified BOOLEAN DEFAULT false,                 -- 케어기버 알림 완료 여부
    admin_notified BOOLEAN DEFAULT false,                     -- 관리자 알림 완료 여부
    response_message TEXT,                                    -- 관리자/케어기버 응답 메시지
    response_by INTEGER,                                      -- 응답한 사용자 ID
    response_at TIMESTAMP,                                    -- 응답 시간
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'acknowledged', 'in_progress', 'resolved', 'closed')), -- 처리 상태
    read_at TIMESTAMP,                                        -- 케어기버/관리자가 읽은 시간
    priority_score INTEGER DEFAULT 0,                         -- 우선순위 점수
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 피드백 작성 시간
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 수정 시간
    
    -- 외래키 제약조건
    CONSTRAINT fk_feedbacks_report FOREIGN KEY (ai_report_id) REFERENCES ai_reports(id) ON DELETE CASCADE,
    CONSTRAINT fk_feedbacks_guardian FOREIGN KEY (guardian_id) REFERENCES guardians(id) ON DELETE RESTRICT,
    CONSTRAINT fk_feedbacks_responder FOREIGN KEY (response_by) REFERENCES users(id) ON DELETE SET NULL
);

-- 인덱스 생성
CREATE INDEX idx_feedbacks_report_id ON feedbacks(ai_report_id);
CREATE INDEX idx_feedbacks_guardian_id ON feedbacks(guardian_id);
CREATE INDEX idx_feedbacks_status ON feedbacks(status);
CREATE INDEX idx_feedbacks_urgency_level ON feedbacks(urgency_level);
CREATE INDEX idx_feedbacks_created_at ON feedbacks(created_at);

-- 코멘트 추가
COMMENT ON TABLE feedbacks IS '가디언이 AI 리포트에 대해 남긴 피드백 및 요청사항을 저장하는 테이블';
COMMENT ON COLUMN feedbacks.id IS '피드백 고유 식별자 (자동 증가)';
COMMENT ON COLUMN feedbacks.ai_report_id IS '피드백 대상이 되는 AI 리포트 ID';
COMMENT ON COLUMN feedbacks.guardian_id IS '피드백을 작성한 가디언 사용자 ID';
COMMENT ON COLUMN feedbacks.feedback_type IS '피드백 유형 분류';
COMMENT ON COLUMN feedbacks.message IS '가디언이 작성한 피드백 메시지 내용';
COMMENT ON COLUMN feedbacks.requirements IS '특별 요구사항 또는 개선 요청사항';
COMMENT ON COLUMN feedbacks.urgency_level IS '피드백의 긴급도 수준';
COMMENT ON COLUMN feedbacks.sentiment_score IS '피드백의 감정 점수 (-1: 매우 부정 ~ 1: 매우 긍정)';
COMMENT ON COLUMN feedbacks.requires_response IS '관리자/케어기버 응답이 필요한지 여부';
COMMENT ON COLUMN feedbacks.caregiver_notified IS '케어기버에게 알림을 보냈는지 여부';
COMMENT ON COLUMN feedbacks.admin_notified IS '관리자에게 알림을 보냈는지 여부';
COMMENT ON COLUMN feedbacks.response_message IS '관리자 또는 케어기버의 응답 메시지';
COMMENT ON COLUMN feedbacks.response_by IS '응답을 작성한 사용자 ID';
COMMENT ON COLUMN feedbacks.response_at IS '응답이 작성된 시간';
COMMENT ON COLUMN feedbacks.status IS '피드백 처리 상태';
COMMENT ON COLUMN feedbacks.read_at IS '케어기버/관리자가 피드백을 읽은 시간';
COMMENT ON COLUMN feedbacks.priority_score IS '시스템에서 계산한 우선순위 점수';
COMMENT ON COLUMN feedbacks.created_at IS '피드백 작성 시간';
COMMENT ON COLUMN feedbacks.updated_at IS '피드백 정보 마지막 수정 시간';

-- =============================================================================
-- 14. 알림 테이블 (notifications)
-- 설명: 시스템에서 발생하는 모든 알림을 저장 (푸시 알림, 앱 내 알림 등)
-- =============================================================================
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    sender_id INTEGER,                                        -- 발송자 ID (시스템 알림의 경우 NULL)
    receiver_id INTEGER NOT NULL,                             -- 수신자 ID
    notification_type VARCHAR(30) NOT NULL CHECK (notification_type IN (
        'new_report',           -- 새 리포트 생성
        'feedback_received',    -- 피드백 수신
        'session_started',      -- 돌봄 세션 시작
        'session_completed',    -- 돌봄 세션 완료
        'emergency_alert',      -- 응급 상황 알림
        'system_notice',        -- 시스템 공지
        'reminder',            -- 리마인더
        'welcome'              -- 환영 메시지
    )),                                                       -- 알림 유형
    title VARCHAR(200) NOT NULL,                              -- 알림 제목
    content TEXT NOT NULL,                                    -- 알림 내용
    action_url VARCHAR(500),                                  -- 클릭 시 이동할 URL
    action_data JSONB,                                        -- 추가 액션 데이터
    priority_level VARCHAR(20) DEFAULT 'normal' CHECK (priority_level IN ('low', 'normal', 'high', 'urgent')), -- 우선순위
    is_push_sent BOOLEAN DEFAULT false,                       -- 푸시 알림 발송 여부
    push_sent_at TIMESTAMP,                                   -- 푸시 알림 발송 시간
    is_read BOOLEAN DEFAULT false,                            -- 읽음 여부
    read_at TIMESTAMP,                                        -- 읽은 시간
    expires_at TIMESTAMP,                                     -- 알림 만료 시간
    device_token VARCHAR(500),                                -- 디바이스 토큰
    platform VARCHAR(20),                                     -- 플랫폼 (iOS, Android, Web)
    retry_count INTEGER DEFAULT 0,                            -- 재전송 횟수
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 생성 시간
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 수정 시간
    
    -- 외래키 제약조건
    CONSTRAINT fk_notifications_sender FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT fk_notifications_receiver FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 인덱스 생성
CREATE INDEX idx_notifications_receiver_id ON notifications(receiver_id);
CREATE INDEX idx_notifications_type ON notifications(notification_type);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_priority_level ON notifications(priority_level);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX idx_notifications_receiver_unread ON notifications(receiver_id, is_read, created_at);

-- 코멘트 추가
COMMENT ON TABLE notifications IS '시스템에서 발생하는 모든 알림을 저장하는 테이블 (푸시 알림, 앱 내 알림)';
COMMENT ON COLUMN notifications.id IS '알림 고유 식별자 (자동 증가)';
COMMENT ON COLUMN notifications.sender_id IS '알림 발송자 사용자 ID (시스템 알림의 경우 NULL)';
COMMENT ON COLUMN notifications.receiver_id IS '알림 수신자 사용자 ID';
COMMENT ON COLUMN notifications.notification_type IS '알림 유형 분류';
COMMENT ON COLUMN notifications.title IS '알림 제목 (푸시 알림 제목으로도 사용)';
COMMENT ON COLUMN notifications.content IS '알림 내용 본문';
COMMENT ON COLUMN notifications.action_url IS '알림 클릭 시 이동할 URL 또는 딥링크';
COMMENT ON COLUMN notifications.action_data IS '알림과 관련된 추가 데이터 JSON';
COMMENT ON COLUMN notifications.priority_level IS '알림의 우선순위 수준';
COMMENT ON COLUMN notifications.is_push_sent IS '푸시 알림 발송 완료 여부';
COMMENT ON COLUMN notifications.push_sent_at IS '푸시 알림 실제 발송 시간';
COMMENT ON COLUMN notifications.is_read IS '사용자가 알림을 읽었는지 여부';
COMMENT ON COLUMN notifications.read_at IS '사용자가 알림을 읽은 시간';
COMMENT ON COLUMN notifications.expires_at IS '알림 만료 시간 (만료 후 자동 삭제 가능)';
COMMENT ON COLUMN notifications.device_token IS '푸시 알림용 디바이스 토큰';
COMMENT ON COLUMN notifications.platform IS '알림 수신 플랫폼 (iOS, Android, Web)';
COMMENT ON COLUMN notifications.retry_count IS '알림 발송 재시도 횟수';
COMMENT ON COLUMN notifications.created_at IS '알림 생성 시간';
COMMENT ON COLUMN notifications.updated_at IS '알림 정보 마지막 수정 시간';

-- =============================================================================
-- 15. 시스템 설정 테이블 (system_settings)
-- 설명: 시스템 전반의 설정값을 저장
-- =============================================================================
CREATE TABLE system_settings (
    id SERIAL PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,                 -- 설정 키
    setting_value TEXT,                                       -- 설정 값
    setting_type VARCHAR(20) DEFAULT 'string' CHECK (setting_type IN ('string', 'number', 'boolean', 'json')), -- 설정 유형
    description TEXT,                                         -- 설정 설명
    is_editable BOOLEAN DEFAULT true,                         -- 편집 가능 여부
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 생성 시간
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP            -- 수정 시간
);

-- 인덱스 생성
CREATE INDEX idx_system_settings_key ON system_settings(setting_key);

-- 코멘트 추가
COMMENT ON TABLE system_settings IS '시스템 전반의 설정값을 저장하는 테이블';
COMMENT ON COLUMN system_settings.id IS '시스템 설정 고유 식별자 (자동 증가)';
COMMENT ON COLUMN system_settings.setting_key IS '설정 키 (app_version, max_file_size 등)';
COMMENT ON COLUMN system_settings.setting_value IS '설정 값 (문자열 형태로 저장)';
COMMENT ON COLUMN system_settings.setting_type IS '설정 값의 데이터 유형';
COMMENT ON COLUMN system_settings.description IS '설정에 대한 설명';
COMMENT ON COLUMN system_settings.is_editable IS '관리자가 편집 가능한지 여부';
COMMENT ON COLUMN system_settings.created_at IS '설정 생성 시간';
COMMENT ON COLUMN system_settings.updated_at IS '설정 마지막 수정 시간';

-- =============================================================================
-- 16. 체크리스트 템플릿 테이블 (checklist_templates)
-- 설명: 질병별 체크리스트 템플릿을 저장
-- =============================================================================
CREATE TABLE checklist_templates (
    id SERIAL PRIMARY KEY,
    template_name VARCHAR(100) NOT NULL,                      -- 템플릿 이름
    disease_type VARCHAR(50) NOT NULL,                        -- 적용 질병 유형
    question_key VARCHAR(100) NOT NULL,                       -- 질문 식별 키
    question_text TEXT NOT NULL,                              -- 질문 내용
    answer_type VARCHAR(20) NOT NULL CHECK (answer_type IN ('boolean', 'text', 'number', 'select')), -- 응답 유형
    select_options JSONB,                                     -- 선택형 질문의 옵션들
    is_required BOOLEAN DEFAULT false,                        -- 필수 응답 여부
    display_order INTEGER DEFAULT 0,                          -- 표시 순서
    is_active BOOLEAN DEFAULT true,                           -- 활성화 상태
    created_by INTEGER,                                       -- 생성자 ID
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 생성 시간
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,           -- 수정 시간
    
    -- 유니크 제약조건
    UNIQUE(disease_type, question_key),
    
    -- 외래키 제약조건
    CONSTRAINT fk_checklist_templates_creator FOREIGN KEY (created_by) REFERENCES admins(id) ON DELETE SET NULL
);

-- 인덱스 생성
CREATE INDEX idx_checklist_templates_disease_type ON checklist_templates(disease_type);
CREATE INDEX idx_checklist_templates_display_order ON checklist_templates(display_order);
CREATE INDEX idx_checklist_templates_is_active ON checklist_templates(is_active);

-- 코멘트 추가
COMMENT ON TABLE checklist_templates IS '질병별 체크리스트 템플릿을 저장하는 테이블';
COMMENT ON COLUMN checklist_templates.id IS '체크리스트 템플릿 고유 식별자 (자동 증가)';
COMMENT ON COLUMN checklist_templates.template_name IS '템플릿 이름 (치매 체크리스트, 당뇨 체크리스트 등)';
COMMENT ON COLUMN checklist_templates.disease_type IS '적용 대상 질병 유형';
COMMENT ON COLUMN checklist_templates.question_key IS '질문 식별 키 (memory_check, blood_sugar_check 등)';
COMMENT ON COLUMN checklist_templates.question_text IS '실제 질문 내용 텍스트';
COMMENT ON COLUMN checklist_templates.answer_type IS '응답 유형 (boolean, text, number, select)';
COMMENT ON COLUMN checklist_templates.select_options IS '선택형 질문의 선택지 JSON 배열';
COMMENT ON COLUMN checklist_templates.is_required IS '필수 응답 여부';
COMMENT ON COLUMN checklist_templates.display_order IS '화면에 표시될 순서';
COMMENT ON COLUMN checklist_templates.is_active IS '템플릿 활성화 상태';
COMMENT ON COLUMN checklist_templates.created_by IS '템플릿을 생성한 관리자 ID';
COMMENT ON COLUMN checklist_templates.created_at IS '템플릿 생성 시간';
COMMENT ON COLUMN checklist_templates.updated_at IS '템플릿 마지막 수정 시간';

-- =============================================================================
-- 스키마 생성 완료 알림
-- =============================================================================
DO $
BEGIN
    RAISE NOTICE '=== Good Hands Database Schema v2.0 Created Successfully ===';
    RAISE NOTICE 'Tables Created: 16개 테이블 (1-16번)';
    RAISE NOTICE '- users, caregivers, guardians, admins';
    RAISE NOTICE '- nursing_homes, senior_diseases, seniors';
    RAISE NOTICE '- care_sessions, attendance_logs';
    RAISE NOTICE '- checklist_responses, care_notes';
    RAISE NOTICE '- ai_reports, feedbacks, notifications';
    RAISE NOTICE '- system_settings, checklist_templates';
    RAISE NOTICE '';
    RAISE NOTICE '✅ 피드백 반영 완료:';
    RAISE NOTICE '1. 테이블명 스네이크 표기법 및 소문자 적용';
    RAISE NOTICE '2. 데이터타입 및 데이터길이 명시';
    RAISE NOTICE '3. 모든 컬럼에 상세한 주석(코멘트) 추가';
    RAISE NOTICE '4. 제약조건 및 인덱스 최적화';
    RAISE NOTICE '5. 현재 모델과의 호환성 유지';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 적용 방법:';
    RAISE NOTICE 'psql -d goodhands -f goodhands_complete_schema.sql';
    RAISE NOTICE '======================================================';
END $;