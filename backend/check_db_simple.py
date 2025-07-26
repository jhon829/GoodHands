import sqlite3
import json
import sys

# UTF-8 인코딩 설정
if sys.platform == "win32":
    import codecs
    sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())

def check_database():
    db_path = 'goodhands.db'
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        print("=" * 50)
        print("Good Hands 데이터베이스 정보")
        print("=" * 50)
        
        # 테이블 목록 조회
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = cursor.fetchall()
        
        print(f"\n테이블 목록 ({len(tables)}개):")
        for table in tables:
            print(f"  - {table[0]}")
        
        print("\n" + "=" * 50)
        
        # 각 테이블의 구조와 데이터 조회
        for table_name in [t[0] for t in tables]:
            print(f"\n테이블: {table_name}")
            print("-" * 30)
            
            # 테이블 구조 조회
            cursor.execute(f"PRAGMA table_info({table_name})")
            columns = cursor.fetchall()
            
            print("컬럼 구조:")
            for col in columns:
                col_id, name, data_type, not_null, default, pk = col
                pk_str = " (PK)" if pk else ""
                not_null_str = " NOT NULL" if not_null else ""
                default_str = f" DEFAULT {default}" if default else ""
                print(f"  - {name}: {data_type}{pk_str}{not_null_str}{default_str}")
            
            # 데이터 개수 조회
            cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
            count = cursor.fetchone()[0]
            print(f"\n데이터 개수: {count}행")
            
            # 실제 데이터 조회 (최대 3개)
            if count > 0:
                cursor.execute(f"SELECT * FROM {table_name} LIMIT 3")
                rows = cursor.fetchall()
                
                print("\n샘플 데이터:")
                column_names = [col[1] for col in columns]
                
                for i, row in enumerate(rows, 1):
                    print(f"  [{i}번째 행]")
                    for j, value in enumerate(row):
                        if j < len(column_names):
                            print(f"    {column_names[j]}: {value}")
                    print()
            
            print("=" * 50)
        
        conn.close()
        print("\n데이터베이스 조회 완료!")
        
    except Exception as e:
        print(f"오류 발생: {e}")

if __name__ == "__main__":
    check_database()
