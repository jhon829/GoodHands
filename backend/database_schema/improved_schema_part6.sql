-- =============================================================================
-- 10. 체크리스트 응답 테이블 (checklist_responses) - 현재 모델 기반 개선
-- =============================================================================
CREATE TABLE checklist_responses (
    id SERIAL PRIMARY KEY,
    care_session_id INTEGER NOT NULL,
    question_key VARCHAR(100) NOT NULL,
    question_text TEXT NOT NULL,
    answer_type VARCHAR(20) NOT NULL CHECK (answer_type IN ('boolean', 'text', 'number', 'select', 'json')),
    answer JSONB NOT NULL,
    boolean_value BOOLEAN,
    text_value TEXT,
    number_value DECIMAL(10, 2),
    select_value VARCHAR(100),
    notes TEXT,
    is_required BOOLEAN DEFAULT false,
    response_time INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_checklist_responses_session FOREIGN KEY (care_session_id) REFERENCES care_sessions(id) ON DELETE CASCADE
);

CREATE INDEX idx_checklist_responses_session_id ON checklist_responses(care_session_id);
CREATE INDEX idx_checklist_responses_question_key ON checklist_responses(question_key);
CREATE INDEX idx_checklist_responses_answer_type ON checklist_responses(answer_type);

COMMENT ON TABLE checklist_responses IS '케어기버가 작성한 체크리스트 응답을 저장하는 테이블 (현재 모델 기반 개선)';

-- =============================================================================
-- 11. 돌봄노트 테이블 (care_notes) - 현재 모델 기반 개선
-- =============================================================================
CREATE TABLE care_notes (
    id SERIAL PRIMARY KEY,
    care_session_id INTEGER NOT NULL,
    question_type VARCHAR(50) NOT NULL CHECK (question_type IN (
        'special_moments',
        'family_longing',
        'emotional_state',
        'conversation',
        'changes',
        'care_episodes'
    )),
    question_text TEXT NOT NULL,
    content TEXT NOT NULL,
    keywords VARCHAR(500),
    emotion_score INTEGER CHECK (emotion_score >= 1 AND emotion_score <= 5),
    importance_level VARCHAR(20) DEFAULT 'normal' CHECK (importance_level IN ('low', 'normal', 'high', 'urgent')),
    attachments JSONB,
    word_count INTEGER,
    writing_time INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_care_notes_session FOREIGN KEY (care_session_id) REFERENCES care_sessions(id) ON DELETE CASCADE
);

CREATE INDEX idx_care_notes_session_id ON care_notes(care_session_id);
CREATE INDEX idx_care_notes_question_type ON care_notes(question_type);
CREATE INDEX idx_care_notes_importance_level ON care_notes(importance_level);
CREATE INDEX idx_care_notes_emotion_score ON care_notes(emotion_score);

COMMENT ON TABLE care_notes IS '케어기버가 작성한 6개 핵심 질문의 돌봄노트를 저장하는 테이블 (현재 모델 기반 개선)';
