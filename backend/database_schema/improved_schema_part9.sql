-- =============================================================================
-- 18. 시드 데이터 및 초기 설정
-- =============================================================================

-- 시스템 설정 테이블 생성
CREATE TABLE system_settings (
    id SERIAL PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    setting_type VARCHAR(20) DEFAULT 'string' CHECK (setting_type IN ('string', 'number', 'boolean', 'json')),
    description TEXT,
    is_editable BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_system_settings_key ON system_settings(setting_key);
COMMENT ON TABLE system_settings IS '시스템 전반의 설정값을 저장하는 테이블';

-- 체크리스트 템플릿 테이블 생성
CREATE TABLE checklist_templates (
    id SERIAL PRIMARY KEY,
    template_name VARCHAR(100) NOT NULL,
    disease_type VARCHAR(50) NOT NULL,
    question_key VARCHAR(100) NOT NULL,
    question_text TEXT NOT NULL,
    answer_type VARCHAR(20) NOT NULL CHECK (answer_type IN ('boolean', 'text', 'number', 'select')),
    select_options JSONB,
    is_required BOOLEAN DEFAULT false,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(disease_type, question_key),
    CONSTRAINT fk_checklist_templates_creator FOREIGN KEY (created_by) REFERENCES admins(id) ON DELETE SET NULL
);

CREATE INDEX idx_checklist_templates_disease_type ON checklist_templates(disease_type);
CREATE INDEX idx_checklist_templates_display_order ON checklist_templates(display_order);
COMMENT ON TABLE checklist_templates IS '질병별 체크리스트 템플릿을 저장하는 테이블';

-- 시스템 설정 초기값 삽입
INSERT INTO system_settings (setting_key, setting_value, setting_type, description, is_editable) VALUES
('app_version', '1.0.0', 'string', '앱 버전', false),
('max_file_size_mb', '10', 'number', '최대 파일 업로드 크기 (MB)', true),
('ai_report_timeout_seconds', '30', 'number', 'AI 리포트 생성 타임아웃 (초)', true),
('push_notification_enabled', 'true', 'boolean', '푸시 알림 활성화 여부', true),
('maintenance_mode', 'false', 'boolean', '유지보수 모드', true),
('supported_languages', '["ko", "en"]', 'json', '지원 언어 목록', true),
('schema_version', '2.0', 'string', '데이터베이스 스키마 버전', false);

-- 치매 체크리스트 템플릿
INSERT INTO checklist_templates (template_name, disease_type, question_key, question_text, answer_type, select_options, is_required, display_order, is_active) VALUES
('치매 체크리스트', '치매', 'memory_check', '오늘 날짜와 요일을 기억하시나요?', 'boolean', NULL, true, 1, true),
('치매 체크리스트', '치매', 'family_recognition', '가족 사진을 보고 누구인지 아시나요?', 'boolean', NULL, true, 2, true),
('치매 체크리스트', '치매', 'meal_memory', '오늘 드신 식사를 기억하시나요?', 'boolean', NULL, true, 3, true),
('치매 체크리스트', '치매', 'mood_state', '기분 상태는 어떠신가요?', 'select', '["매우 좋음", "좋음", "보통", "나쁨", "매우 나쁨"]', true, 4, true),
('치매 체크리스트', '치매', 'sleep_quality', '밤에 잠을 잘 주무셨나요?', 'boolean', NULL, false, 5, true);

-- 당뇨 체크리스트 템플릿
INSERT INTO checklist_templates (template_name, disease_type, question_key, question_text, answer_type, select_options, is_required, display_order, is_active) VALUES
('당뇨 체크리스트', '당뇨', 'blood_sugar_check', '혈당을 측정하셨나요?', 'boolean', NULL, true, 1, true),
('당뇨 체크리스트', '당뇨', 'blood_sugar_level', '혈당 수치는 얼마였나요?', 'number', NULL, false, 2, true),
('당뇨 체크리스트', '당뇨', 'medication_taken', '당뇨약을 정시에 복용하셨나요?', 'boolean', NULL, true, 3, true),
('당뇨 체크리스트', '당뇨', 'diet_control', '식단 조절을 잘 지키셨나요?', 'boolean', NULL, true, 4, true),
('당뇨 체크리스트', '당뇨', 'exercise_done', '가벼운 운동을 하셨나요?', 'boolean', NULL, false, 5, true);
