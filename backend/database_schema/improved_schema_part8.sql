-- =============================================================================
-- 15. 트리거 및 함수 설정 (계속)
-- =============================================================================

-- 각 테이블에 updated_at 트리거 적용
CREATE TRIGGER tr_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_caregivers_updated_at BEFORE UPDATE ON caregivers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_guardians_updated_at BEFORE UPDATE ON guardians FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_admins_updated_at BEFORE UPDATE ON admins FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_nursing_homes_updated_at BEFORE UPDATE ON nursing_homes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_seniors_updated_at BEFORE UPDATE ON seniors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_senior_diseases_updated_at BEFORE UPDATE ON senior_diseases FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_care_sessions_updated_at BEFORE UPDATE ON care_sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_checklist_responses_updated_at BEFORE UPDATE ON checklist_responses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_care_notes_updated_at BEFORE UPDATE ON care_notes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_ai_reports_updated_at BEFORE UPDATE ON ai_reports FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_feedbacks_updated_at BEFORE UPDATE ON feedbacks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER tr_notifications_updated_at BEFORE UPDATE ON notifications FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- 16. 복합 인덱스 및 성능 최적화
-- =============================================================================

-- 자주 함께 조회되는 컬럼들에 대한 복합 인덱스
CREATE INDEX idx_care_sessions_senior_date ON care_sessions(senior_id, DATE(start_time));
CREATE INDEX idx_checklist_responses_session_question ON checklist_responses(care_session_id, question_key);
CREATE INDEX idx_care_notes_session_type ON care_notes(care_session_id, question_type);
CREATE INDEX idx_feedbacks_guardian_status ON feedbacks(guardian_id, status);

-- 부분 인덱스 (조건부 인덱스)
CREATE INDEX idx_active_care_sessions ON care_sessions(caregiver_id, senior_id) WHERE status = 'active';
CREATE INDEX idx_unread_notifications ON notifications(receiver_id, created_at) WHERE is_read = false;
CREATE INDEX idx_pending_feedbacks ON feedbacks(ai_report_id, created_at) WHERE status = 'pending';
CREATE INDEX idx_active_seniors ON seniors(caregiver_id) WHERE is_active = true;

-- =============================================================================
-- 17. 뷰(View) 생성
-- =============================================================================

-- 케어기버 대시보드용 뷰
CREATE VIEW v_caregiver_dashboard AS
SELECT 
    c.id as caregiver_id,
    c.name as caregiver_name,
    u.user_code,
    COUNT(DISTINCT s.id) as total_seniors,
    COUNT(DISTINCT cs.id) as total_sessions,
    COUNT(DISTINCT CASE WHEN cs.status = 'active' THEN cs.id END) as active_sessions,
    COUNT(DISTINCT ar.id) as total_reports,
    MAX(cs.start_time) as last_session_date,
    c.status as caregiver_status
FROM caregivers c
JOIN users u ON u.id = c.user_id
LEFT JOIN seniors s ON s.caregiver_id = c.id
LEFT JOIN care_sessions cs ON cs.caregiver_id = c.id
LEFT JOIN ai_reports ar ON ar.care_session_id = cs.id
WHERE u.is_active = true
GROUP BY c.id, c.name, u.user_code, c.status;

-- 가디언 대시보드용 뷰
CREATE VIEW v_guardian_dashboard AS
SELECT 
    g.id as guardian_id,
    g.name as guardian_name,
    u.user_code,
    g.country,
    COUNT(DISTINCT s.id) as total_seniors,
    COUNT(DISTINCT ar.id) as total_reports,
    COUNT(DISTINCT CASE WHEN ar.created_at >= CURRENT_DATE - INTERVAL '7 days' THEN ar.id END) as reports_this_week,
    COUNT(DISTINCT f.id) as total_feedbacks,
    COUNT(DISTINCT CASE WHEN f.status = 'pending' THEN f.id END) as pending_feedbacks
FROM guardians g
JOIN users u ON u.id = g.user_id
LEFT JOIN seniors s ON s.guardian_id = g.id
LEFT JOIN care_sessions cs ON cs.senior_id = s.id
LEFT JOIN ai_reports ar ON ar.care_session_id = cs.id
LEFT JOIN feedbacks f ON f.guardian_id = g.id
WHERE u.is_active = true
GROUP BY g.id, g.name, u.user_code, g.country;
