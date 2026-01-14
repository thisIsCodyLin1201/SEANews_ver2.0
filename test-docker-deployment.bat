@echo off
REM Docker 部署測試腳本 (Windows)

echo ======================================
echo SEANews Docker 部署測試
echo ======================================

REM 1. 檢查 Docker 是否運行
echo.
echo [1/6] 檢查 Docker 環境...
docker info >nul 2>&1
if errorlevel 1 (
    echo X Docker 未運行，請先啟動 Docker Desktop
    exit /b 1
)
echo √ Docker 運行正常

REM 2. 停止並刪除舊容器
echo.
echo [2/6] 清理舊容器...
docker stop seanews >nul 2>&1
docker rm seanews >nul 2>&1
echo √ 舊容器已清理

REM 3. 構建鏡像
echo.
echo [3/6] 構建 Docker 鏡像...
echo （使用多 PyPI 鏡像源以提高成功率）
docker build -t seanews:test .
if errorlevel 1 (
    echo X 鏡像構建失敗
    exit /b 1
)
echo √ 鏡像構建成功

REM 4. 啟動容器（不需要 OPENAI_API_KEY）
echo.
echo [4/6] 啟動容器（降級模式）...
docker run -d --name seanews -p 8787:8787 -e APP_USERNAME=CathaySEA -e APP_PASSWORD=CathaySEA seanews:test

REM 等待容器啟動
echo 等待服務啟動...
timeout /t 5 /nobreak >nul

REM 5. 檢查容器狀態
echo.
echo [5/6] 檢查容器狀態...
docker ps | findstr seanews >nul
if errorlevel 1 (
    echo X 容器未運行
    echo 查看日誌：
    docker logs seanews
    exit /b 1
)
echo √ 容器運行中
docker ps | findstr seanews

REM 6. 測試 API 健康檢查
echo.
echo [6/6] 測試 API 端點...

set MAX_RETRIES=10
set RETRY=0

:retry_loop
curl -f http://localhost:8787/api/health >nul 2>&1
if errorlevel 1 (
    set /a RETRY+=1
    if %RETRY% LSS %MAX_RETRIES% (
        echo 等待 API 就緒... (%RETRY%/%MAX_RETRIES%)
        timeout /t 2 /nobreak >nul
        goto retry_loop
    ) else (
        echo X API 健康檢查失敗
        echo 容器日誌：
        docker logs seanews --tail 50
        exit /b 1
    )
)

echo √ API 健康檢查通過

REM 測試登入端點
echo.
echo 測試登入 API...
curl -s -X POST http://localhost:8787/api/auth/login -H "Content-Type: application/json" -d "{\"username\":\"CathaySEA\",\"password\":\"CathaySEA\"}"
echo.

REM 顯示容器日誌
echo.
echo 容器啟動日誌：
docker logs seanews --tail 20

REM 總結
echo.
echo ======================================
echo √ 所有測試通過！
echo ======================================
echo.
echo 訪問應用：
echo   - 前端: http://localhost:8787
echo   - 健康檢查: http://localhost:8787/api/health
echo.
echo 查看日誌: docker logs seanews -f
echo 停止容器: docker stop seanews
echo 刪除容器: docker rm seanews
echo.

REM 可選：如果有 .env 文件，提示完整功能測試
if exist .env (
    findstr "OPENAI_API_KEY" .env >nul 2>&1
    if not errorlevel 1 (
        echo 提示：檢測到 .env 文件，可以測試完整功能：
        echo   docker stop seanews ^&^& docker rm seanews
        echo   docker run -d --name seanews -p 8787:8787 --env-file .env seanews:test
    )
)

pause
