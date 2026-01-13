@echo off
chcp 65001 >nul
REM Docker Quick Test - Simplified Version

echo ================================
echo SEA News Docker Quick Test
echo ================================
echo.

REM Step 1: Check Docker
echo [1] Checking Docker...
docker --version
if errorlevel 1 (
    echo [ERROR] Docker not installed
    pause
    exit /b 1
)
echo [OK] Docker installed
echo.

REM Step 2: Build
echo [2] Building image...
docker build -t seanews-app:latest .
if errorlevel 1 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)
echo [OK] Build successful
echo.

REM Step 3: Clean old containers
echo [3] Cleaning old containers...
docker stop seanews >NUL 2>&1
docker rm seanews >NUL 2>&1
echo [OK] Cleaned
echo.

REM Step 4: Run container
echo [4] Starting container...
docker run -d --name seanews -p 8787:8787 --env-file .env seanews-app:latest
if errorlevel 1 (
    echo [ERROR] Failed to start
    docker logs seanews
    pause
    exit /b 1
)
echo [OK] Container started
echo.

REM Step 5: Wait
echo [5] Waiting 5 seconds...
timeout /t 5 /nobreak >nul
echo.

REM Step 6: Test
echo [6] Testing health endpoint...
curl -s http://localhost:8787/api/health
echo.
echo.

REM Step 7: Show logs
echo [7] Container logs:
docker logs --tail 15 seanews
echo.

echo ================================
echo SUCCESS! Application running at:
echo http://localhost:8787
echo ================================
echo.
echo Useful commands:
echo   docker logs -f seanews
echo   docker stop seanews
echo   docker restart seanews
echo.
pause
