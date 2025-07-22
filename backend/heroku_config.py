"""
Heroku 배포용 설정 파일
"""
from app.config import Settings

class HerokuSettings(Settings):
    """Heroku 환경 설정"""
    
    class Config:
        env_file = ".env"
        case_sensitive = True

# Heroku용 설정
settings = HerokuSettings()
