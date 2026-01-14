@echo off
REM Zeabur Dockerfile 本地測試腳本
REM 模擬 Zeabur 環境進行本地測試

echo ====================================
echo Zeabur Dockerfile 本地測試
echo ====================================
echo.

echo [提示] 本測試將模擬 Zeabur 部署環境
echo [提示] 使用動態端口和環境變量
echo.

REM 設置測試端口
set TEST_PORT=8000
echo [1/6] 設置測試端口: %TEST_PORT%
echo.

echo [2/6] 清理舊容器和映像...
docker rm -f seanews-zeabur-test 2>nul
docker rmi seanews:zeabur-test 2>nul
echo.

echo [3/6] 構建 Zeabur 優化的 Docker 映像...
echo 注意：這可能需要 3-5 分鐘
docker build -t seanews:zeabur-test .
if errorlevel 1 (
    echo.
    echo [錯誤] 構建失敗！請檢查錯誤信息。
    pause
    exit /b 1
)
echo [成功] 映像構建完成
echo.

echo [4/6] 啟動容器（模擬 Zeabur 環境）...
docker run -d ^
  --name seanews-zeabur-test ^
  -p %TEST_PORT%:8000 ^
  -e PORT=8000 ^
  -e OPENAI_API_KEY=%OPENAI_API_KEY% ^
  -e OPENAI_MODEL=%OPENAI_MODEL% ^
  -e APP_USERNAME=%APP_USERNAME% ^
  -e APP_PASSWORD=%APP_PASSWORD% ^
  -e APP_SECRET_KEY=%APP_SECRET_KEY% ^
  seanews:zeabur-test

if errorlevel 1 (
    echo [錯誤] 容器啟動失敗！
    pause
    exit /b 1
)
echo [成功] 容器已啟動
echo.

echo [5/6] 等待服務啟動（10秒）...
timeout /t 10 /nobreak >nul
echo.

echo [5.5/6] 測試 Python 模組導入...
docker exec seanews-zeabur-test python test_imports.py
echo.

echo [6/6] 測試 API 健康檢查...
curl http://localhost:%TEST_PORT%/api/health
echo.
echo.

echo ====================================
echo 測試結果
echo ====================================
docker logs seanews-zeabur-test 2>&1 | findstr /C:"Application startup complete" /C:"ERROR" /C:"ModuleNotFoundError"
echo.

echo 容器狀態:
docker ps --filter name=seanews-zeabur-test --format "{{.Status}}"
echo.

echo ====================================
echo 訪問測試
echo ====================================
echo 前端: http://localhost:%TEST_PORT%
echo API: http://localhost:%TEST_PORT%/api/health
echo.

echo ====================================
echo 完整日誌
echo ====================================
docker logs seanews-zeabur-test
echo.

echo ====================================
echo 後續操作
echo ====================================
echo 測試成功後，可以推送到 GitHub 並在 Zeabur 部署
echo.
echo 清理測試環境:
echo   docker rm -f seanews-zeabur-test
echo   docker rmi seanews:zeabur-test
echo.
pause
