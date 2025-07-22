import sqlite3

def check_database():
    try:
        conn = sqlite3.connect('goodhands.db')
        cursor = conn.cursor()
        
        # 테이블 목록 조회
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = cursor.fetchall()
        
        print("=== 현재 데이터베이스 테이블 목록 ===")
        for table in tables:
            print(f"- {table[0]}")
        
        print(f"\n총 {len(tables)}개의 테이블이 있습니다.")
        
        # 각 테이블의 스키마 정보 조회
        print("\n=== 테이블 스키마 정보 ===")
        for table in tables:
            table_name = table[0]
            print(f"\n[{table_name}]")
            cursor.execute(f"PRAGMA table_info({table_name})")
            columns = cursor.fetchall()
            for col in columns:
                print(f"  - {col[1]} {col[2]} {'NOT NULL' if col[3] else ''} {'PK' if col[5] else ''}")
        
        conn.close()
        
    except Exception as e:
        print(f"데이터베이스 확인 중 오류: {e}")

if __name__ == "__main__":
    check_database()
