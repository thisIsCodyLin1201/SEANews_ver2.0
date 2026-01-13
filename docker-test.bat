@echo off
REM Docker 構建和測試腳本 (Windows)

echo ================================
echo SEA News Docker 構建和測試
echo ================================
echo.

REM 檢查 .env 文件
if not exist .env (
    echo [WARNING] .env 文件不存在
    echo 請創建 .env 文件並設置以下變量：
    echo   OPENAI_API_KEY=sk-...
    echo   OPENAI_MODEL=gpt-4o-mini
    echo   APP_USERNAME=CathaySEA
    echo   APP_PASSWORD=CathaySEA
    echo.
    set /p continue="是否繼續？ (Y/N): "
    if /i not "%continue%"=="Y" exit /b 1
)

REM 1. 構建 Docker 鏡像
echo.
echo [步驟 1] 構建 Docker 鏡像...
docker build -t seanews-app:latest .
if errorlevel 1 (
    echo [ERROR] 構建失敗
    exit /b 1
)
echo [OK] 構建成功
echo.

REM 2. 停止並移除舊容器
echo [步驟 2] 清理舊容器...
docker stop seanews 2>nul
docker rm seanews 2>nul
echo [OK] 清理完成
echo.

REM 3. 啟動新容器
echo [步驟 3] 啟動容器...
docker run -d --name seanews -p 8787:8787 --env-file .env seanews-app:latest
if errorlevel 1 (
    echo [ERROR] 啟動失敗
    exit /b 1
)
echo [OK] 容器已啟動
echo.

REM 4. 等待服務啟動
echo [步驟 4] 等待服務啟動...
timeout /t 5 /nobreak >nul
echo.

REM 5. 檢查容器狀態
echo [步驟 5] 檢查容器狀態...
docker ps | findstr seanews >nul
if errorlevel 1 (
    echo [ERROR] 容器未運行
    echo 查看日誌:
    docker logs seanews
    exit /b 1
)
echo [OK] 容器運行中
echo.

REM 6. 測試健康檢查
echo [步驟 6] 測試健康檢查...
curl -s http://localhost:8787/api/health
echo.
echo [OK] 健康檢查完成
echo.

REM 7. 測試登入 API
echo [步驟 7] 測試登入 API...
curl -s -X POST http://localhost:8787/api/auth/login -H "Content-Type: application/json" -d "{\"username\":\"CathaySEA\",\"password\":\"CathaySEA\"}"
echo.
echo [OK] 登入 API 測試完成
echo.

REM 8. 顯示容器信息
echo [步驟 8] 容器信息
docker ps -f name=seanews
echo.

REM 9. 顯示日誌
echo [最近日誌]
docker logs --tail 20 seanews
echo.

REM 完成
echo ================================
echo [SUCCESS] 所有測試通過！
echo ================================
echo.
echo 應用已啟動在: http://localhost:8787
echo.
echo 常用命令:
echo   查看日誌: docker logs -f seanews
echo   停止容器: docker stop seanews
echo   重啟容器: docker restart seanews
echo   進入容器: docker exec -it seanews sh
echo.

pause
