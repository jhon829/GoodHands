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
-- psql -d goodhands -f goodhands_unified_schema.sql

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
