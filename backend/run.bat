@echo off
echo Starting Good Hands Care Service API...
call venv\Scripts\activate.bat
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
