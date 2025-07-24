-- =============================================================================
-- 4. 관리자 프로필 테이블 (admins)
-- =============================================================================
CREATE TABLE admins (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    employee_id VARCHAR(50),
    department VARCHAR(50),
    position VARCHAR(50),
    permissions JSONB,
    access_level INTEGER DEFAULT 1 CHECK (access_level >= 1 AND access_level <= 10),
    phone VARCHAR(20),
    is_super_admin BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_admins_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_admins_user_id ON admins(user_id);
CREATE INDEX idx_admins_employee_id ON admins(employee_id);
CREATE INDEX idx_admins_access_level ON admins(access_level);

COMMENT ON TABLE admins IS '시스템 관리자의 상세 정보 및 권한을 저장하는 테이블';

-- =============================================================================
-- 5. 요양원 정보 테이블 (nursing_homes)
-- =============================================================================
CREATE TABLE nursing_homes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    business_number VARCHAR(50),
    address TEXT NOT NULL,
    phone VARCHAR(20),
    fax VARCHAR(20),
    email VARCHAR(100),
    contact_person VARCHAR(100),
    contact_phone VARCHAR(20),
    capacity INTEGER,
    current_residents INTEGER DEFAULT 0,
    facility_type VARCHAR(50),
    license_number VARCHAR(100),
    accreditation_level VARCHAR(20),
    services JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_nursing_homes_name ON nursing_homes(name);
CREATE INDEX idx_nursing_homes_is_active ON nursing_homes(is_active);
CREATE INDEX idx_nursing_homes_facility_type ON nursing_homes(facility_type);

COMMENT ON TABLE nursing_homes IS '시니어가 거주하는 요양원의 정보를 저장하는 테이블';
