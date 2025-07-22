-- =============================================================================
-- 12. AI 리포트 테이블 (ai_reports) - 현재 모델 기반 개선
-- =============================================================================
CREATE TABLE ai_reports (
    id SERIAL PRIMARY KEY,
    care_session_id INTEGER UNIQUE NOT NULL,
    report_version VARCHAR(10) DEFAULT '1.0',
    keywords JSONB,
    summary TEXT,
    content TEXT NOT NULL,
    ai_comment TEXT,
    emotion_analysis JSONB,
    health_indicators JSONB,
    recommendations JSONB,
    risk_level VARCHAR(20) DEFAULT 'normal' CHECK (risk_level IN ('low', 'normal', 'medium', 'high', 'critical')),
    quality_score DECIMAL(3, 2) CHECK (quality_score >= 0 AND quality_score <= 10),
    generation_time_ms INTEGER,
    ai_model_version VARCHAR(50),
    status VARCHAR(20) DEFAULT 'generated' CHECK (status IN ('generated', 'read', 'reviewed', 'archived')),
    is_reviewed BOOLEAN DEFAULT false,
    reviewed_by INTEGER,
    reviewed_at TIMESTAMP,
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_ai_reports_session FOREIGN KEY (care_session_id) REFERENCES care_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_ai_reports_reviewer FOREIGN KEY (reviewed_by) REFERENCES admins(id) ON DELETE SET NULL
);

CREATE INDEX idx_ai_reports_session_id ON ai_reports(care_session_id);
CREATE INDEX idx_ai_reports_status ON ai_reports(status);
CREATE INDEX idx_ai_reports_risk_level ON ai_reports(risk_level);
CREATE INDEX idx_ai_reports_quality_score ON ai_reports(quality_score);
CREATE INDEX idx_ai_reports_created_at ON ai_reports(created_at);

COMMENT ON TABLE ai_reports IS 'AI가 생성한 돌봄 리포트를 저장하는 테이블 (현재 모델 기반 개선)';

-- =============================================================================
-- 13. 피드백 테이블 (feedbacks) - 현재 모델 기반 개선
-- =============================================================================
CREATE TABLE feedbacks (
    id SERIAL PRIMARY KEY,
    ai_report_id INTEGER NOT NULL,
    guardian_id INTEGER NOT NULL,
    feedback_type VARCHAR(20) DEFAULT 'general' CHECK (feedback_type IN (
        'general', 'concern', 'request', 'appreciation', 'complaint', 'suggestion'
    )),
    message TEXT NOT NULL,
    requirements TEXT,
    urgency_level VARCHAR(20) DEFAULT 'normal' CHECK (urgency_level IN ('low', 'normal', 'high', 'urgent')),
    sentiment_score DECIMAL(3, 2) CHECK (sentiment_score >= -1 AND sentiment_score <= 1),
    requires_response BOOLEAN DEFAULT false,
    caregiver_notified BOOLEAN DEFAULT false,
    admin_notified BOOLEAN DEFAULT false,
    response_message TEXT,
    response_by INTEGER,
    response_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'acknowledged', 'in_progress', 'resolved', 'closed')),
    read_at TIMESTAMP,
    priority_score INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_feedbacks_report FOREIGN KEY (ai_report_id) REFERENCES ai_reports(id) ON DELETE CASCADE,
    CONSTRAINT fk_feedbacks_guardian FOREIGN KEY (guardian_id) REFERENCES guardians(id) ON DELETE RESTRICT,
    CONSTRAINT fk_feedbacks_responder FOREIGN KEY (response_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_feedbacks_report_id ON feedbacks(ai_report_id);
CREATE INDEX idx_feedbacks_guardian_id ON feedbacks(guardian_id);
CREATE INDEX idx_feedbacks_status ON feedbacks(status);
CREATE INDEX idx_feedbacks_urgency_level ON feedbacks(urgency_level);
CREATE INDEX idx_feedbacks_created_at ON feedbacks(created_at);

COMMENT ON TABLE feedbacks IS '가디언이 AI 리포트에 대해 남긴 피드백을 저장하는 테이블 (현재 모델 기반 개선)';
