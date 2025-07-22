-- =============================================================================
-- 6. 시니어 질병 정보 테이블 (senior_diseases)
-- =============================================================================
CREATE TABLE senior_diseases (
    id SERIAL PRIMARY KEY,
    senior_id INTEGER NOT NULL,
    disease_type VARCHAR(50) NOT NULL,
    disease_code VARCHAR(20),
    severity VARCHAR(20) CHECK (severity IN ('mild', 'moderate', 'severe')),
    diagnosis_date DATE,
    medication JSONB,
    notes TEXT,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_senior_diseases_senior FOREIGN KEY (senior_id) REFERENCES seniors(id) ON DELETE CASCADE
);

CREATE INDEX idx_senior_diseases_senior_id ON senior_diseases(senior_id);
CREATE INDEX idx_senior_diseases_type ON senior_diseases(disease_type);
CREATE INDEX idx_senior_diseases_primary ON senior_diseases(is_primary);

COMMENT ON TABLE senior_diseases IS '시니어별 질병 정보를 상세히 저장하는 테이블';

-- =============================================================================
-- 7. 시니어 정보 테이블 (seniors)
-- =============================================================================
CREATE TABLE seniors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    birth_date DATE,
    age INTEGER,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female')),
    photo VARCHAR(500),
    id_number_encrypted VARCHAR(200),
    blood_type VARCHAR(5),
    height DECIMAL(5,2),
    weight DECIMAL(5,2),
    nursing_home_id INTEGER,
    room_number VARCHAR(20),
    caregiver_id INTEGER,
    guardian_id INTEGER NOT NULL,
    admission_date DATE,
    care_level VARCHAR(20),
    mobility_status VARCHAR(30),
    cognitive_status VARCHAR(30),
    emergency_contact VARCHAR(20),
    medical_notes TEXT,
    dietary_requirements TEXT,
    allergies TEXT,
    preferences JSONB,
    family_info JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_seniors_nursing_home FOREIGN KEY (nursing_home_id) REFERENCES nursing_homes(id) ON DELETE SET NULL,
    CONSTRAINT fk_seniors_caregiver FOREIGN KEY (caregiver_id) REFERENCES caregivers(id) ON DELETE SET NULL,
    CONSTRAINT fk_seniors_guardian FOREIGN KEY (guardian_id) REFERENCES guardians(id) ON DELETE RESTRICT
);

CREATE INDEX idx_seniors_caregiver_id ON seniors(caregiver_id);
CREATE INDEX idx_seniors_guardian_id ON seniors(guardian_id);
CREATE INDEX idx_seniors_nursing_home_id ON seniors(nursing_home_id);
CREATE INDEX idx_seniors_age ON seniors(age);
CREATE INDEX idx_seniors_is_active ON seniors(is_active);

COMMENT ON TABLE seniors IS '돌봄 서비스를 받는 시니어들의 상세 정보를 저장하는 테이블';
