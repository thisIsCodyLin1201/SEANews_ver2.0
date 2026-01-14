@echo off
REM Docker 網絡問題快速修復腳本

echo ======================================
echo Docker 構建網絡問題診斷與修復
echo ======================================

echo.
echo [1/5] 檢查 Docker 服務...
docker info >nul 2>&1
if errorlevel 1 (
    echo X Docker 未運行
    echo   請啟動 Docker Desktop 後重試
    pause
    exit /b 1
)
echo √ Docker 運行正常

echo.
echo [2/5] 測試網絡連接...
echo 測試 PyPI 官方...
curl -I -m 5 https://pypi.org/simple/ >nul 2>&1
if errorlevel 1 (
    echo X PyPI 官方連接失敗
    set USE_MIRROR=1
) else (
    echo √ PyPI 官方可訪問
    set USE_MIRROR=0
)

echo.
echo 測試阿里雲鏡像...
curl -I -m 5 https://mirrors.aliyun.com/pypi/simple/ >nul 2>&1
if errorlevel 1 (
    echo X 阿里雲鏡像連接失敗
) else (
    echo √ 阿里雲鏡像可訪問
)

echo.
echo 測試清華鏡像...
curl -I -m 5 https://pypi.tuna.tsinghua.edu.cn/simple/ >nul 2>&1
if errorlevel 1 (
    echo X 清華鏡像連接失敗
) else (
    echo √ 清華鏡像可訪問
)

echo.
echo [3/5] 清理舊構建緩存...
docker builder prune -f >nul 2>&1
echo √ 緩存已清理

echo.
echo [4/5] 開始構建鏡像...
echo 使用更新後的 Dockerfile（支持多鏡像源）
echo.

REM 使用 --progress=plain 查看詳細日誌
docker build -t seanews:latest . --progress=plain

if errorlevel 1 (
    echo.
    echo ======================================
    echo X 構建失敗
    echo ======================================
    echo.
    echo 常見解決方案：
    echo.
    echo 1. 檢查網絡設置
    echo    Docker Desktop -^> Settings -^> Docker Engine
    echo    添加 DNS: "dns": ["8.8.8.8", "114.114.114.114"]
    echo.
    echo 2. 使用宿主機網絡構建
    echo    docker build --network=host -t seanews:latest .
    echo.
    echo 3. 查看完整日誌
    echo    docker build -t seanews:latest . --progress=plain --no-cache ^> build.log 2^>^&1
    echo.
    echo 4. 參考詳細指南
    echo    查看 DOCKER_NETWORK_FIX.md
    echo.
    pause
    exit /b 1
)

echo.
echo [5/5] 驗證鏡像...
docker images | findstr seanews >nul 2>&1
if errorlevel 1 (
    echo X 鏡像未找到
    exit /b 1
)

echo.
echo ======================================
echo √ 構建成功！
echo ======================================
echo.
echo 鏡像信息：
docker images | findstr seanews
echo.
echo 下一步：
echo   測試運行: docker run -d --name seanews -p 8787:8787 seanews:latest
echo   查看日誌: docker logs seanews
echo   停止容器: docker stop seanews
echo.
pause
