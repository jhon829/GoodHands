# migrate_checklist.py - 체크리스트 데이터 마이그레이션 스크립트 (당뇨병/고혈압 추가)
from sqlalchemy.orm import sessionmaker
from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, ForeignKey, create_engine
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.declarative import declarative_base
import os
import sys

# 현재 디렉터리를 Python path에 추가
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from app.database import engine, Base
    print("기존 데이터베이스 연결 사용")
except ImportError:
    # 대안으로 직접 연결
    DATABASE_URL = "sqlite:///./goodhands.db"
    engine = create_engine(DATABASE_URL)
    Base = declarative_base()
    print("직접 데이터베이스 연결 생성")

# 새로운 모델 정의
class ChecklistTemplate(Base):
    __tablename__ = "checklist_templates"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    template_type = Column(String(20), nullable=False)  # 'common', 'disease_specific'
    disease_type = Column(String(50))  # '치매', '당뇨' 등
    description = Column(Text)
    is_active = Column(Boolean, default=True)
    display_order = Column(Integer, default=0)
    created_at = Column(DateTime, server_default=func.now())

class ChecklistQuestion(Base):
    __tablename__ = "checklist_questions"
    
    id = Column(Integer, primary_key=True, index=True)
    template_id = Column(Integer, ForeignKey("checklist_templates.id"), nullable=False)
    category = Column(String(100))
    question_text = Column(Text, nullable=False)
    question_key = Column(String(100), nullable=False)
    question_type = Column(String(20), nullable=False)  # 'single_choice', 'multiple_choice', 'text', 'number', 'mixed'
    is_required = Column(Boolean, default=True)
    display_order = Column(Integer, default=0)
    additional_info = Column(Text)  # SQLite에서는 JSON 대신 TEXT 사용
    created_at = Column(DateTime, server_default=func.now())

class QuestionOption(Base):
    __tablename__ = "question_options"
    
    id = Column(Integer, primary_key=True, index=True)
    question_id = Column(Integer, ForeignKey("checklist_questions.id"), nullable=False)
    option_text = Column(Text, nullable=False)
    option_value = Column(String(100), nullable=False)
    display_order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)

class ChecklistResponseNew(Base):
    __tablename__ = "checklist_responses_new"
    
    id = Column(Integer, primary_key=True, index=True)
    care_session_id = Column(Integer, nullable=False)  # FK 제약 조건 임시 제거
    question_id = Column(Integer, ForeignKey("checklist_questions.id"), nullable=False)
    answer_type = Column(String(20), nullable=False)  # 'single', 'multiple', 'text', 'number', 'mixed'
    answer_value = Column(Text, nullable=False)  # JSON 문자열로 저장
    additional_notes = Column(Text)  # 추가 텍스트
    created_at = Column(DateTime, server_default=func.now())

def create_checklist_tables():
    """새로운 체크리스트 테이블들을 생성"""
    print("체크리스트 테이블을 생성합니다...")
    
    try:
        # 새 테이블들 생성
        ChecklistTemplate.__table__.create(engine, checkfirst=True)
        print("✅ checklist_templates 테이블 생성 완료")
        
        ChecklistQuestion.__table__.create(engine, checkfirst=True)
        print("✅ checklist_questions 테이블 생성 완료")
        
        QuestionOption.__table__.create(engine, checkfirst=True)
        print("✅ question_options 테이블 생성 완료")
        
        ChecklistResponseNew.__table__.create(engine, checkfirst=True)
        print("✅ checklist_responses_new 테이블 생성 완료")
        
        print("모든 테이블 생성 완료!")
        return True
        
    except Exception as e:
        print(f"❌ 테이블 생성 중 오류: {e}")
        return False

def insert_checklist_data():
    """체크리스트 데이터를 삽입"""
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()
    
    try:
        print("체크리스트 데이터를 삽입합니다...")
        
        # 1. 템플릿 생성
        print("📋 템플릿 생성 중...")
        templates_data = [
            {'name': '공통 체크리스트', 'template_type': 'common', 'disease_type': None, 'description': '모든 환자에게 공통으로 적용되는 기본 체크리스트', 'display_order': 1},
            {'name': '치매/알츠하이머 팔로잉', 'template_type': 'disease_specific', 'disease_type': '치매', 'description': '치매 및 알츠하이머 환자 전용 체크리스트', 'display_order': 2},
            {'name': '당뇨병 팔로잉', 'template_type': 'disease_specific', 'disease_type': '당뇨', 'description': '당뇨병 환자 전용 체크리스트', 'display_order': 3},
            {'name': '고혈압 팔로잉', 'template_type': 'disease_specific', 'disease_type': '고혈압', 'description': '고혈압 환자 전용 체크리스트', 'display_order': 4},
            {'name': '파킨슨병 팔로잉', 'template_type': 'disease_specific', 'disease_type': '파킨슨병', 'description': '파킨슨병 환자 전용 체크리스트', 'display_order': 5}
        ]
        
        template_objects = []
        for template_data in templates_data:
            template = ChecklistTemplate(**template_data)
            db.add(template)
            template_objects.append(template)
        
        db.commit()
        # refresh_all() 대신 개별적으로 refresh
        for template in template_objects:
            db.refresh(template)
        print(f"✅ {len(templates_data)}개 템플릿 생성 완료!")
        
        # 2. 공통 체크리스트 질문들
        print("🍽️ 공통 체크리스트 질문 생성 중...")
        common_template = db.query(ChecklistTemplate).filter(ChecklistTemplate.template_type == 'common').first()
        
        if not common_template:
            raise Exception("공통 템플릿을 찾을 수 없습니다.")
        
        common_questions_data = [
            {
                'template_id': common_template.id,
                'category': '식사 및 영양 상태',
                'question_text': '어르신의 오늘 식사는 어떠셨나요?',
                'question_key': 'meal_amount',
                'question_type': 'single_choice',
                'display_order': 1,
                'options': [
                    {'option_text': '평소처럼 잘 드심 (3끼 모두 잘 드심)', 'option_value': 'full_meal', 'display_order': 1},
                    {'option_text': '보통 정도 드심 (평소의 70-80% 정도)', 'option_value': 'normal_meal', 'display_order': 2},
                    {'option_text': '적게 드심 (평소의 50% 정도)', 'option_value': 'light_meal', 'display_order': 3},
                    {'option_text': '거의 안 드심 (한두 번 정도만)', 'option_value': 'minimal_meal', 'display_order': 4}
                ]
            },
            {
                'template_id': common_template.id,
                'category': '식사 및 영양 상태',
                'question_text': '특별히 좋아하신 음식이 있으시나요?',
                'question_key': 'favorite_food',
                'question_type': 'text',
                'display_order': 2,
                'options': []
            },
            {
                'template_id': common_template.id,
                'category': '식사 및 영양 상태',
                'question_text': '거부하신 음식이 있으시나요?',
                'question_key': 'refused_food',
                'question_type': 'text',
                'display_order': 3,
                'options': []
            },
            {
                'template_id': common_template.id,
                'category': '식사 및 영양 상태',
                'question_text': '식사 시 도움이 필요한 정도는?',
                'question_key': 'meal_assistance',
                'question_type': 'single_choice',
                'display_order': 4,
                'options': [
                    {'option_text': '독립', 'option_value': 'independent', 'display_order': 1},
                    {'option_text': '부분 도움', 'option_value': 'partial_help', 'display_order': 2},
                    {'option_text': '전적 도움', 'option_value': 'full_help', 'display_order': 3}
                ]
            }
        ]
        
        # 공통 질문과 옵션 추가
        for question_data in common_questions_data:
            options_data = question_data.pop('options')
            question = ChecklistQuestion(**question_data)
            db.add(question)
            db.flush()  # ID를 얻기 위해
            
            for option_data in options_data:
                option_data['question_id'] = question.id
                option = QuestionOption(**option_data)
                db.add(option)
        
        print(f"✅ {len(common_questions_data)}개 공통 질문 생성 완료!")
        
        # 3. 치매 질병별 질문들
        print("🧠 치매 질병별 질문 생성 중...")
        dementia_template = db.query(ChecklistTemplate).filter(
            ChecklistTemplate.disease_type == '치매'
        ).first()
        
        if dementia_template:
            dementia_questions_data = [
                {
                    'template_id': dementia_template.id,
                    'category': '기억력과 인지 상태',
                    'question_text': '오늘 기억력과 인지 상태는 어떠셨나요?',
                    'question_key': 'memory_cognitive_state',
                    'question_type': 'mixed',
                    'display_order': 1,
                    'options': [
                        {'option_text': '평상시와 비슷하게 잘 기억하심', 'option_value': 'normal_memory', 'display_order': 1},
                        {'option_text': '가끔 헷갈려하시지만 대부분 기억하심', 'option_value': 'occasional_confusion', 'display_order': 2},
                        {'option_text': '자주 혼란스러워하심', 'option_value': 'frequent_confusion', 'display_order': 3},
                        {'option_text': '거의 기억하지 못하심', 'option_value': 'severe_memory_loss', 'display_order': 4}
                    ]
                },
                {
                    'template_id': dementia_template.id,
                    'category': '기억력과 인지 상태',
                    'question_text': '가족이나 주변 사람들을 얼마나 잘 알아보셨나요?',
                    'question_key': 'family_recognition',
                    'question_type': 'mixed',
                    'display_order': 2,
                    'additional_info': '언급하신 가족 이름도 기록해주세요',
                    'options': [
                        {'option_text': '모든 사람을 잘 알아보심', 'option_value': 'recognizes_all', 'display_order': 1},
                        {'option_text': '가족은 알아보지만 가끔 헷갈림', 'option_value': 'recognizes_family_mostly', 'display_order': 2},
                        {'option_text': '가족도 가끔 못 알아보심', 'option_value': 'occasional_family_confusion', 'display_order': 3},
                        {'option_text': '대부분 알아보지 못하심', 'option_value': 'poor_recognition', 'display_order': 4}
                    ]
                },
                {
                    'template_id': dementia_template.id,
                    'category': '행동 및 감정',
                    'question_text': '평소와 다른 행동이나 감정 변화가 있었나요?',
                    'question_key': 'behavior_emotion_change',
                    'question_type': 'mixed',
                    'display_order': 3,
                    'additional_info': '구체적인 행동을 기록해주세요',
                    'options': [
                        {'option_text': '평상시와 같이 안정적', 'option_value': 'stable', 'display_order': 1},
                        {'option_text': '약간 불안하거나 초조해하심', 'option_value': 'mild_anxiety', 'display_order': 2},
                        {'option_text': '자주 동요하거나 반복 행동', 'option_value': 'frequent_agitation', 'display_order': 3},
                        {'option_text': '심하게 흥분하거나 공격적', 'option_value': 'severe_agitation', 'display_order': 4}
                    ]
                },
                {
                    'template_id': dementia_template.id,
                    'category': '일상생활 능력',
                    'question_text': '일상생활(화장실, 옷 입기 등)은 어떻게 하셨나요?',
                    'question_key': 'daily_living_activities',
                    'question_type': 'mixed',
                    'display_order': 4,
                    'additional_info': '특히 어려워하는 부분을 기록해주세요',
                    'options': [
                        {'option_text': '혼자서 대부분 잘 하심', 'option_value': 'mostly_independent', 'display_order': 1},
                        {'option_text': '약간의 도움이 필요하심', 'option_value': 'some_assistance', 'display_order': 2},
                        {'option_text': '많은 도움이 필요하심', 'option_value': 'much_assistance', 'display_order': 3},
                        {'option_text': '거의 모든 것에 도움 필요', 'option_value': 'full_assistance', 'display_order': 4}
                    ]
                }
            ]
            
            # 치매 질문과 옵션 추가
            for question_data in dementia_questions_data:
                options_data = question_data.pop('options')
                question = ChecklistQuestion(**question_data)
                db.add(question)
                db.flush()
                
                for option_data in options_data:
                    option_data['question_id'] = question.id
                    option = QuestionOption(**option_data)
                    db.add(option)
            
            print(f"✅ {len(dementia_questions_data)}개 치매 질문 생성 완료!")
        
        # 4. 당뇨병 질병별 질문들
        print("🍬 당뇨병 질병별 질문 생성 중...")
        diabetes_template = db.query(ChecklistTemplate).filter(
            ChecklistTemplate.disease_type == '당뇨'
        ).first()
        
        if diabetes_template:
            diabetes_questions_data = [
                {
                    'template_id': diabetes_template.id,
                    'category': '혈당 관리',
                    'question_text': '혈당 관리는 어떻게 하고 계신가요?',
                    'question_key': 'blood_sugar_management',
                    'question_type': 'mixed',
                    'display_order': 1,
                    'additional_info': '오늘 혈당 수치를 측정했다면 기록해주세요 (mg/dL)',
                    'options': [
                        {'option_text': '규칙적으로 잘 측정하고 관리하심', 'option_value': 'well_managed', 'display_order': 1},
                        {'option_text': '가끔 측정하시고 대체로 안정적', 'option_value': 'occasionally_measured', 'display_order': 2},
                        {'option_text': '측정을 자주 깜빡하심', 'option_value': 'often_forgets', 'display_order': 3},
                        {'option_text': '측정하기 어려워하심', 'option_value': 'difficult_to_measure', 'display_order': 4}
                    ]
                },
                {
                    'template_id': diabetes_template.id,
                    'category': '약물 관리',
                    'question_text': '당뇨 약물이나 인슐린 관리는 어떠셨나요?',
                    'question_key': 'medication_insulin_management',
                    'question_type': 'mixed',
                    'display_order': 2,
                    'additional_info': '특이사항이 있다면 기록해주세요',
                    'options': [
                        {'option_text': '시간에 맞춰 잘 복용/투여하심', 'option_value': 'on_time', 'display_order': 1},
                        {'option_text': '가끔 시간이 늦어지지만 복용함', 'option_value': 'slightly_delayed', 'display_order': 2},
                        {'option_text': '자주 빼먹으시거나 거부하심', 'option_value': 'often_missed', 'display_order': 3},
                        {'option_text': '도움 없이는 관리 어려움', 'option_value': 'needs_assistance', 'display_order': 4}
                    ]
                },
                {
                    'template_id': diabetes_template.id,
                    'category': '발 상태 점검',
                    'question_text': '발 상태나 상처는 어떠신가요?',
                    'question_key': 'foot_condition',
                    'question_type': 'mixed',
                    'display_order': 3,
                    'additional_info': '상처가 있다면 위치와 상태를 자세히 기록해주세요',
                    'options': [
                        {'option_text': '깨끗하고 특별한 문제 없음', 'option_value': 'clean_normal', 'display_order': 1},
                        {'option_text': '약간 건조하거나 굳은살 정도', 'option_value': 'dry_callus', 'display_order': 2},
                        {'option_text': '작은 상처나 물집이 있음', 'option_value': 'minor_wounds', 'display_order': 3},
                        {'option_text': '염증이나 심각한 상처', 'option_value': 'serious_wounds', 'display_order': 4}
                    ]
                },
                {
                    'template_id': diabetes_template.id,
                    'category': '식이 관리',
                    'question_text': '당뇨식 관리나 단 음식 조절은 어떠셨나요?',
                    'question_key': 'diet_sugar_control',
                    'question_type': 'mixed',
                    'display_order': 4,
                    'additional_info': '특이사항이 있다면 기록해주세요',
                    'options': [
                        {'option_text': '당뇨식을 잘 지키심', 'option_value': 'good_diet_control', 'display_order': 1},
                        {'option_text': '대체로 지키지만 가끔 단 음식 드심', 'option_value': 'mostly_controlled', 'display_order': 2},
                        {'option_text': '자주 단 음식을 원하시거나 드심', 'option_value': 'frequent_sweet_foods', 'display_order': 3},
                        {'option_text': '식이 조절이 어려움', 'option_value': 'difficult_diet_control', 'display_order': 4}
                    ]
                }
            ]
            
            # 당뇨병 질문과 옵션 추가
            for question_data in diabetes_questions_data:
                options_data = question_data.pop('options')
                question = ChecklistQuestion(**question_data)
                db.add(question)
                db.flush()
                
                for option_data in options_data:
                    option_data['question_id'] = question.id
                    option = QuestionOption(**option_data)
                    db.add(option)
            
            print(f"✅ {len(diabetes_questions_data)}개 당뇨병 질문 생성 완료!")
        
        # 5. 고혈압 질병별 질문들
        print("💓 고혈압 질병별 질문 생성 중...")
        hypertension_template = db.query(ChecklistTemplate).filter(
            ChecklistTemplate.disease_type == '고혈압'
        ).first()
        
        if hypertension_template:
            hypertension_questions_data = [
                {
                    'template_id': hypertension_template.id,
                    'category': '혈압 상태 및 증상',
                    'question_text': '혈압 상태나 관련 증상은 어떠셨나요?',
                    'question_key': 'blood_pressure_symptoms',
                    'question_type': 'mixed',
                    'display_order': 1,
                    'additional_info': '혈압을 측정했다면 기록해주세요 (예: 120/80 mmHg)',
                    'options': [
                        {'option_text': '특별한 증상 없이 안정적', 'option_value': 'stable_no_symptoms', 'display_order': 1},
                        {'option_text': '가끔 두통이나 어지러움 호소', 'option_value': 'occasional_headache', 'display_order': 2},
                        {'option_text': '자주 머리가 아프다고 하심', 'option_value': 'frequent_headache', 'display_order': 3},
                        {'option_text': '숨이 차거나 가슴 답답함 호소', 'option_value': 'shortness_of_breath', 'display_order': 4}
                    ]
                },
                {
                    'template_id': hypertension_template.id,
                    'category': '약물 복용',
                    'question_text': '혈압약 복용은 어떻게 하고 계신가요?',
                    'question_key': 'medication_compliance',
                    'question_type': 'mixed',
                    'display_order': 2,
                    'additional_info': '부작용이나 문제가 있다면 기록해주세요',
                    'options': [
                        {'option_text': '매일 규칙적으로 잘 복용하심', 'option_value': 'regular_compliance', 'display_order': 1},
                        {'option_text': '가끔 빼먹지만 대체로 복용', 'option_value': 'mostly_compliant', 'display_order': 2},
                        {'option_text': '자주 깜빡하시거나 거부하심', 'option_value': 'poor_compliance', 'display_order': 3},
                        {'option_text': '부작용 때문에 복용 어려워함', 'option_value': 'side_effects', 'display_order': 4}
                    ]
                },
                {
                    'template_id': hypertension_template.id,
                    'category': '식이 및 생활습관',
                    'question_text': '짠 음식 조절이나 생활습관은 어떠셨나요?',
                    'question_key': 'diet_lifestyle',
                    'question_type': 'mixed',
                    'display_order': 3,
                    'additional_info': '특이사항이 있다면 기록해주세요',
                    'options': [
                        {'option_text': '저염식을 잘 지키심', 'option_value': 'good_low_salt_diet', 'display_order': 1},
                        {'option_text': '대체로 지키지만 가끔 짠 음식 드심', 'option_value': 'mostly_controlled', 'display_order': 2},
                        {'option_text': '자주 짠 음식을 선호하심', 'option_value': 'prefers_salty_foods', 'display_order': 3},
                        {'option_text': '식이 조절이 어려움', 'option_value': 'difficult_diet_control', 'display_order': 4}
                    ]
                },
                {
                    'template_id': hypertension_template.id,
                    'category': '부종 및 체중',
                    'question_text': '몸의 부종이나 체중 변화는 어떠신가요?',
                    'question_key': 'edema_weight_change',
                    'question_type': 'mixed',
                    'display_order': 4,
                    'additional_info': '부종이 있다면 위치를 기록해주세요',
                    'options': [
                        {'option_text': '특별한 변화나 부종 없음', 'option_value': 'no_change', 'display_order': 1},
                        {'option_text': '약간의 발목 부종', 'option_value': 'mild_ankle_edema', 'display_order': 2},
                        {'option_text': '눈에 띄는 부종이나 체중 증가', 'option_value': 'noticeable_edema', 'display_order': 3},
                        {'option_text': '심한 부종으로 불편해하심', 'option_value': 'severe_edema', 'display_order': 4}
                    ]
                }
            ]
            
            # 고혈압 질문과 옵션 추가
            for question_data in hypertension_questions_data:
                options_data = question_data.pop('options')
                question = ChecklistQuestion(**question_data)
                db.add(question)
                db.flush()
                
                for option_data in options_data:
                    option_data['question_id'] = question.id
                    option = QuestionOption(**option_data)
                    db.add(option)
            
            print(f"✅ {len(hypertension_questions_data)}개 고혈압 질문 생성 완료!")
        
        db.commit()
        print("🎉 모든 체크리스트 데이터 삽입 완료!")
        
        # 생성된 데이터 요약
        template_count = db.query(ChecklistTemplate).count()
        question_count = db.query(ChecklistQuestion).count()
        option_count = db.query(QuestionOption).count()
        
        print(f"\n📊 생성된 데이터 요약:")
        print(f"- 템플릿: {template_count}개")
        print(f"- 질문: {question_count}개")
        print(f"- 옵션: {option_count}개")
        
        # 질병별 질문 수 상세 정보
        print(f"\n📋 질병별 질문 수:")
        print(f"- 공통 체크리스트: {len(common_questions_data)}개")
        if dementia_template:
            print(f"- 치매: {len(dementia_questions_data)}개")
        if diabetes_template:
            print(f"- 당뇨병: {len(diabetes_questions_data)}개")
        if hypertension_template:
            print(f"- 고혈압: {len(hypertension_questions_data)}개")
        
        return True
        
    except Exception as e:
        print(f"❌ 데이터 삽입 중 오류: {e}")
        db.rollback()
        return False
    finally:
        db.close()

def main():
    """메인 실행 함수"""
    print("=" * 60)
    print("🚀 체크리스트 시스템 마이그레이션 시작 (당뇨병/고혈압 추가)")
    print("=" * 60)
    
    # 1. 테이블 생성
    if not create_checklist_tables():
        print("❌ 테이블 생성 실패. 마이그레이션을 중단합니다.")
        return
    
    print()
    
    # 2. 데이터 삽입
    if not insert_checklist_data():
        print("❌ 데이터 삽입 실패. 마이그레이션을 중단합니다.")
        return
    
    print()
    print("=" * 60) 
    print("✅ 마이그레이션 완료!")
    print("=" * 60)
    print("\n📝 다음 단계:")
    print("1. 서버 재시작: uvicorn app.main:app --reload")
    print("2. API 테스트: GET /api/caregiver/checklist/1")
    print("3. Swagger UI에서 새로운 체크리스트 구조 확인")
    print("\n🔗 테스트 URL:")
    print("- http://localhost:8000/docs")
    print("- http://localhost:8000/api/caregiver/checklist/1")
    print("\n🆕 추가된 질병 체크리스트:")
    print("- 당뇨병: 혈당관리, 약물관리, 발상태점검, 식이관리")
    print("- 고혈압: 혈압증상, 약물복용, 식이생활습관, 부종체중")

if __name__ == "__main__":
    main()