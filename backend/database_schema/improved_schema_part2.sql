-- =============================================================================
-- 2. 케어기버 프로필 테이블 (caregivers)
-- =============================================================================
CREATE TABLE caregivers (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    profile_image VARCHAR(500),
    license_number VARCHAR(50),
    license_type VARCHAR(50),
    experience_years INTEGER DEFAULT 0,
    specialties JSONB,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'on_leave')),
    hire_date DATE,
    emergency_contact VARCHAR(20),
    address TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_caregivers_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_caregivers_user_id ON caregivers(user_id);
CREATE INDEX idx_caregivers_status ON caregivers(status);
CREATE INDEX idx_caregivers_license_number ON caregivers(license_number);

COMMENT ON TABLE caregivers IS '케어기버의 상세 정보 및 업무 관련 데이터를 저장하는 테이블';

-- =============================================================================
-- 3. 가디언 프로필 테이블 (guardians)
-- =============================================================================
CREATE TABLE guardians (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    country VARCHAR(100),
    city VARCHAR(100),
    time_zone VARCHAR(50),
    relationship_type VARCHAR(30),
    preferred_language VARCHAR(10) DEFAULT 'ko',
    notification_preferences JSONB,
    emergency_contact VARCHAR(20),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_guardians_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_guardians_user_id ON guardians(user_id);
CREATE INDEX idx_guardians_country ON guardians(country);
CREATE INDEX idx_guardians_relationship ON guardians(relationship_type);

COMMENT ON TABLE guardians IS '가디언(보호자)의 상세 정보를 저장하는 테이블';
