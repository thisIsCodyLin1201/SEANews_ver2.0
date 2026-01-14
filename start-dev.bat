@echo off
echo ====================================
echo 啟動 SEANews 完整開發環境
echo ====================================
echo.
echo [提示] 此腳本將同時啟動前端和後端
echo        前端: http://localhost:5176
echo        後端: http://localhost:8787
echo.
echo [注意] 需要開啟兩個終端窗口
echo.

cd /d "%~dp0"

echo [選項] 
echo 1. 啟動後端 (在此窗口)
echo 2. 啟動前端 (在新窗口)
echo 3. 同時啟動 (推薦)
echo.
set /p choice="請選擇 (1/2/3): "

if "%choice%"=="1" (
    echo.
    echo 啟動後端...
    call start-backend.bat
) else if "%choice%"=="2" (
    echo.
    echo 啟動前端...
    npm run dev
) else if "%choice%"=="3" (
    echo.
    echo [1/2] 在新窗口啟動後端...
    start "SEANews Backend" cmd /k start-backend.bat
    timeout /t 3 /nobreak > nul
    
    echo [2/2] 啟動前端...
    npm run dev
) else (
    echo 無效選擇
    pause
)
