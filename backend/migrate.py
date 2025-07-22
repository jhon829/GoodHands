"""
데이터베이스 마이그레이션 관리 스크립트
"""
import os
import sys
import subprocess
from datetime import datetime

def run_command(command):
    """명령어 실행 및 결과 반환"""
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ {command}")
            if result.stdout:
                print(result.stdout)
            return True
        else:
            print(f"❌ {command}")
            print(result.stderr)
            return False
    except Exception as e:
        print(f"❌ 오류 발생: {e}")
        return False

def create_migration(message=None):
    """새로운 마이그레이션 생성"""
    if not message:
        message = f"migration_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    
    print(f"🔄 마이그레이션 생성: {message}")
    return run_command(f"alembic revision --autogenerate -m \"{message}\"")

def upgrade_database():
    """데이터베이스 업그레이드"""
    print("🔄 데이터베이스 업그레이드 중...")
    return run_command("alembic upgrade head")

def downgrade_database(revision="-1"):
    """데이터베이스 다운그레이드"""
    print(f"🔄 데이터베이스 다운그레이드: {revision}")
    return run_command(f"alembic downgrade {revision}")

def show_current_revision():
    """현재 리비전 표시"""
    print("📊 현재 데이터베이스 리비전:")
    return run_command("alembic current")

def show_migration_history():
    """마이그레이션 히스토리 표시"""
    print("📋 마이그레이션 히스토리:")
    return run_command("alembic history")

def main():
    """메인 함수"""
    if len(sys.argv) < 2:
        print("사용법:")
        print("  python migrate.py create [메시지]    - 새 마이그레이션 생성")
        print("  python migrate.py upgrade            - 데이터베이스 업그레이드")
        print("  python migrate.py downgrade [버전]   - 데이터베이스 다운그레이드")
        print("  python migrate.py current            - 현재 리비전 표시")
        print("  python migrate.py history            - 마이그레이션 히스토리 표시")
        return
    
    command = sys.argv[1]
    
    if command == "create":
        message = sys.argv[2] if len(sys.argv) > 2 else None
        create_migration(message)
    elif command == "upgrade":
        upgrade_database()
    elif command == "downgrade":
        revision = sys.argv[2] if len(sys.argv) > 2 else "-1"
        downgrade_database(revision)
    elif command == "current":
        show_current_revision()
    elif command == "history":
        show_migration_history()
    else:
        print(f"❌ 알 수 없는 명령어: {command}")

if __name__ == "__main__":
    main()
