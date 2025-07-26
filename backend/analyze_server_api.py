#!/usr/bin/env python3
"""
Good Hands 서버 API 구조 분석 및 로컬 코드 동기화
실제 서버: https://pay.gzonesoft.co.kr:10007
"""

import requests
import json
import urllib3
from datetime import datetime
import os

# SSL 경고 비활성화
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

SERVER_URL = "https://pay.gzonesoft.co.kr:10007"

def test_server_endpoints():
    """서버 엔드포인트 실제 테스트"""
    print("🔍 서버 API 구조 분석 시작...")
    
    # 기본 엔드포인트들
    endpoints = [
        {"method": "GET", "path": "/", "desc": "루트 엔드포인트"},
        {"method": "GET", "path": "/health", "desc": "헬스체크"},
        {"method": "GET", "path": "/docs", "desc": "API 문서"},
        {"method": "GET", "path": "/openapi.json", "desc": "OpenAPI 스펙"},
    ]
    
    # 인증 엔드포인트들
    auth_endpoints = [
        {"method": "POST", "path": "/api/auth/login", "desc": "로그인", "data": {"user_code": "CG001", "password": "password123"}},
    ]
    
    results = {}
    
    print("📋 기본 엔드포인트 테스트:")
    for endpoint in endpoints:
        try:
            url = f"{SERVER_URL}{endpoint['path']}"
            response = requests.get(url, verify=False, timeout=10)
            
            print(f"  {endpoint['method']} {endpoint['path']}: {response.status_code}")
            
            if response.status_code == 200:
                try:
                    data = response.json()
                    results[endpoint['path']] = {
                        "status": response.status_code,
                        "data": data
                    }
                    if endpoint['path'] == "/":
                        print(f"    📱 서비스: {data.get('message', 'N/A')}")
                        print(f"    🔢 버전: {data.get('version', 'N/A')}")
                    elif endpoint['path'] == "/health":
                        print(f"    💚 상태: {data.get('status', 'N/A')}")
                except:
                    # HTML 응답일 수 있음
                    results[endpoint['path']] = {
                        "status": response.status_code,
                        "content_type": response.headers.get('content-type', '')
                    }
            else:
                print(f"    ❌ 오류: {response.status_code}")
                
        except Exception as e:
            print(f"    ❌ 연결 실패: {e}")
    
    print("\n🔐 인증 엔드포인트 테스트:")
    for endpoint in auth_endpoints:
        try:
            url = f"{SERVER_URL}{endpoint['path']}"
            response = requests.post(url, json=endpoint['data'], verify=False, timeout=10)
            
            print(f"  {endpoint['method']} {endpoint['path']}: {response.status_code}")
            
            if response.status_code in [200, 201]:
                try:
                    data = response.json()
                    results[endpoint['path']] = {
                        "status": response.status_code,
                        "data": data
                    }
                    print(f"    🔑 토큰 타입: {data.get('token_type', 'N/A')}")
                    print(f"    👤 사용자 타입: {data.get('user_type', 'N/A')}")
                    print(f"    ⏰ 만료 시간: {data.get('expires_in', 'N/A')}초")
                    
                    # JWT 토큰 저장 (다른 API 테스트용)
                    if 'access_token' in data:
                        global jwt_token
                        jwt_token = data['access_token']
                        print(f"    ✅ JWT 토큰 획득 성공")
                        
                except Exception as e:
                    print(f"    ⚠️ 응답 파싱 실패: {e}")
            else:
                print(f"    ❌ 인증 실패: {response.status_code}")
                try:
                    error_data = response.json()
                    print(f"    📝 오류 메시지: {error_data.get('detail', 'N/A')}")
                except:
                    pass
                    
        except Exception as e:
            print(f"    ❌ 연결 실패: {e}")
    
    return results

def test_authenticated_endpoints():
    """JWT 토큰을 사용한 인증 필요 엔드포인트 테스트"""
    if 'jwt_token' not in globals():
        print("❌ JWT 토큰이 없어 인증 엔드포인트 테스트를 건너뜁니다.")
        return {}
    
    print("\n🎯 인증 필요 엔드포인트 테스트:")
    
    headers = {"Authorization": f"Bearer {jwt_token}"}
    
    protected_endpoints = [
        {"method": "GET", "path": "/api/caregiver/home", "desc": "케어기버 홈"},
        {"method": "GET", "path": "/api/caregiver/seniors", "desc": "담당 시니어 목록"},
        {"method": "GET", "path": "/api/guardian/home", "desc": "가디언 홈"},
        {"method": "GET", "path": "/api/guardian/reports", "desc": "가디언 리포트"},
        {"method": "GET", "path": "/api/admin/dashboard", "desc": "관리자 대시보드"},
    ]
    
    results = {}
    
    for endpoint in protected_endpoints:
        try:
            url = f"{SERVER_URL}{endpoint['path']}"
            response = requests.get(url, headers=headers, verify=False, timeout=10)
            
            print(f"  {endpoint['method']} {endpoint['path']}: {response.status_code}")
            
            if response.status_code == 200:
                try:
                    data = response.json()
                    results[endpoint['path']] = {
                        "status": response.status_code,
                        "data": data
                    }
                    
                    # 응답 구조 분석
                    if isinstance(data, dict):
                        keys = list(data.keys())[:5]  # 처음 5개 키만
                        print(f"    📋 응답 키: {keys}")
                    elif isinstance(data, list) and len(data) > 0:
                        print(f"    📊 리스트 길이: {len(data)}")
                        if isinstance(data[0], dict):
                            keys = list(data[0].keys())[:5]
                            print(f"    📋 첫 번째 항목 키: {keys}")
                            
                except Exception as e:
                    print(f"    ⚠️ 응답 파싱 실패: {e}")
                    
            elif response.status_code == 401:
                print(f"    🚫 인증 실패 (토큰 만료?)")
            elif response.status_code == 403:
                print(f"    🚫 권한 부족")
            elif response.status_code == 404:
                print(f"    🔍 엔드포인트 없음")
            else:
                print(f"    ❌ 오류: {response.status_code}")
                
        except Exception as e:
            print(f"    ❌ 연결 실패: {e}")
    
    return results

def analyze_openapi_spec():
    """OpenAPI 스펙 분석"""
    print("\n📚 OpenAPI 스펙 분석:")
    
    try:
        url = f"{SERVER_URL}/openapi.json"
        response = requests.get(url, verify=False, timeout=10)
        
        if response.status_code == 200:
            openapi_spec = response.json()
            
            # OpenAPI 정보
            info = openapi_spec.get('info', {})
            print(f"  📱 제목: {info.get('title', 'N/A')}")
            print(f"  🔢 버전: {info.get('version', 'N/A')}")
            print(f"  📝 설명: {info.get('description', 'N/A')[:100]}...")
            
            # 경로 분석
            paths = openapi_spec.get('paths', {})
            print(f"  🛣️ 총 엔드포인트 수: {len(paths)}")
            
            # 태그별 엔드포인트 분류
            tags = {}
            for path, methods in paths.items():
                for method, details in methods.items():
                    tag_list = details.get('tags', ['untagged'])
                    for tag in tag_list:
                        if tag not in tags:
                            tags[tag] = []
                        tags[tag].append(f"{method.upper()} {path}")
            
            print(f"  🏷️ API 카테고리:")
            for tag, endpoints in tags.items():
                print(f"    - {tag}: {len(endpoints)}개")
                for endpoint in endpoints[:3]:  # 처음 3개만 표시
                    print(f"      • {endpoint}")
                if len(endpoints) > 3:
                    print(f"      ... 및 {len(endpoints) - 3}개 더")
            
            # 스펙을 파일로 저장
            with open("server_openapi_spec.json", "w", encoding="utf-8") as f:
                json.dump(openapi_spec, f, indent=2, ensure_ascii=False)
            print(f"  💾 OpenAPI 스펙 저장: server_openapi_spec.json")
            
            return openapi_spec
            
        else:
            print(f"  ❌ OpenAPI 스펙 가져오기 실패: {response.status_code}")
            return None
            
    except Exception as e:
        print(f"  ❌ OpenAPI 스펙 분석 실패: {e}")
        return None

def generate_sync_analysis():
    """동기화 분석 리포트 생성"""
    print("\n📊 동기화 분석 리포트 생성 중...")
    
    # 로컬 프로젝트 구조 확인
    local_path = "\\\\tsclient\\C\\Users\\융합인재센터16\\goodHands\\backend"
    
    analysis = {
        "timestamp": datetime.now().isoformat(),
        "server_url": SERVER_URL,
        "local_path": local_path,
        "server_status": "운영 중",
        "sync_requirements": []
    }
    
    # 로컬 라우터 파일들 확인
    routers_path = os.path.join(local_path, "app", "routers")
    if os.path.exists(routers_path):
        router_files = [f for f in os.listdir(routers_path) if f.endswith('.py') and f != '__init__.py']
        analysis["local_routers"] = router_files
        print(f"  📁 로컬 라우터 파일들: {router_files}")
    else:
        print(f"  ❌ 로컬 라우터 디렉토리를 찾을 수 없습니다: {routers_path}")
        analysis["local_routers"] = []
    
    # 동기화 요구사항 생성
    analysis["sync_requirements"] = [
        "서버 OpenAPI 스펙과 로컬 라우터 비교",
        "응답 스키마 구조 확인 및 업데이트",
        "새로운 엔드포인트 추가",
        "모델 구조 업데이트",
        "환경 변수 설정 검증"
    ]
    
    with open("sync_analysis.json", "w", encoding="utf-8") as f:
        json.dump(analysis, f, indent=2, ensure_ascii=False)
    
    print(f"  💾 동기화 분석 저장: sync_analysis.json")
    return analysis

if __name__ == "__main__":
    print("=" * 70)
    print("🔄 Good Hands 서버-로컬 코드 동기화 분석")
    print("=" * 70)
    
    # JWT 토큰 저장용 전역 변수
    jwt_token = None
    
    # 1. 기본 엔드포인트 테스트
    basic_results = test_server_endpoints()
    
    # 2. OpenAPI 스펙 분석
    openapi_spec = analyze_openapi_spec()
    
    # 3. 인증 필요 엔드포인트 테스트
    auth_results = test_authenticated_endpoints()
    
    # 4. 동기화 분석 리포트 생성
    analysis = generate_sync_analysis()
    
    print("\n" + "=" * 70)
    print("📊 분석 완료!")
    print("=" * 70)
    print("✅ 서버 API 구조 분석 완료")
    print("✅ 실제 엔드포인트 테스트 완료")
    print("✅ 동기화 요구사항 파악 완료")
    
    print("\n📁 생성된 파일:")
    print("- server_openapi_spec.json (서버 API 전체 스펙)")
    print("- sync_analysis.json (동기화 분석 결과)")
    
    print("\n🎯 다음 단계:")
    print("1. 서버 스펙 기반으로 로컬 코드 업데이트")
    print("2. 응답 모델 스키마 동기화")
    print("3. 새로운 엔드포인트 구현")
