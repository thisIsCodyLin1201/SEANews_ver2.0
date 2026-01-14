@echo off
echo ====================================
echo 啟動 SEANews 後端服務
echo ====================================
echo.

cd /d "%~dp0"

echo [1/2] 檢查環境...
if not exist "server\agno_api.py" (
    echo [錯誤] 找不到 server\agno_api.py
    pause
    exit /b 1
)

if not exist ".env" (
    echo [警告] 找不到 .env 文件
    echo 將使用系統環境變量
)

echo [2/2] 啟動後端...
echo 後端將在 http://localhost:8787 運行
echo 按 Ctrl+C 停止服務
echo.

cd server
python -m uvicorn agno_api:app --host 127.0.0.1 --port 8787 --reload --log-level info

pause
