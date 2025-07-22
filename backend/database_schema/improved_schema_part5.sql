-- =============================================================================
-- 8. 돌봄 세션 테이블 (care_sessions) - 현재 모델 기반 개선
-- =============================================================================
CREATE TABLE care_sessions (
    id SERIAL PRIMARY KEY,
    caregiver_id INTEGER NOT NULL,
    senior_id INTEGER NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
    start_location VARCHAR(255),
    end_location VARCHAR(255),
    start_gps_lat DECIMAL(10, 8),
    start_gps_lng DECIMAL(11, 8),
    end_gps_lat DECIMAL(10, 8),
    end_gps_lng DECIMAL(11, 8),
    start_photo VARCHAR(500),
    end_photo VARCHAR(500),
    total_hours DECIMAL(4, 2),
    session_notes TEXT,
    weather VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_care_sessions_caregiver FOREIGN KEY (caregiver_id) REFERENCES caregivers(id) ON DELETE RESTRICT,
    CONSTRAINT fk_care_sessions_senior FOREIGN KEY (senior_id) REFERENCES seniors(id) ON DELETE RESTRICT
);

CREATE INDEX idx_care_sessions_caregiver_id ON care_sessions(caregiver_id);
CREATE INDEX idx_care_sessions_senior_id ON care_sessions(senior_id);
CREATE INDEX idx_care_sessions_start_time ON care_sessions(start_time);
CREATE INDEX idx_care_sessions_status ON care_sessions(status);
CREATE INDEX idx_care_sessions_caregiver_date ON care_sessions(caregiver_id, DATE(start_time));

COMMENT ON TABLE care_sessions IS '케어기버의 출근부터 퇴근까지 하나의 돌봄 세션을 기록하는 테이블';

-- =============================================================================
-- 9. 출근/퇴근 로그 테이블 (attendance_logs) - 현재 모델 기반 개선
-- =============================================================================
CREATE TABLE attendance_logs (
    id SERIAL PRIMARY KEY,
    care_session_id INTEGER NOT NULL,
    log_type VARCHAR(20) NOT NULL CHECK (log_type IN ('checkin', 'checkout')),
    location VARCHAR(255),
    gps_lat DECIMAL(10, 8),
    gps_lng DECIMAL(11, 8),
    photo VARCHAR(500),
    verification_method VARCHAR(30) DEFAULT 'gps_photo',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_attendance_logs_session FOREIGN KEY (care_session_id) REFERENCES care_sessions(id) ON DELETE CASCADE
);

CREATE INDEX idx_attendance_logs_session_id ON attendance_logs(care_session_id);
CREATE INDEX idx_attendance_logs_type ON attendance_logs(log_type);
CREATE INDEX idx_attendance_logs_created_at ON attendance_logs(created_at);

COMMENT ON TABLE attendance_logs IS '케어기버의 출근/퇴근 기록을 상세히 저장하는 테이블';
