@echo off
REM Windows 批次測試腳本

echo === 測試登入 API ===
echo.

set API_URL=http://localhost:8787
if not "%1"=="" set API_URL=%1

echo 測試 API: %API_URL%
echo.

echo 1. 測試健康檢查端點...
curl -X GET "%API_URL%/api/health" -H "Content-Type: application/json" -w "\nHTTP Status: %%{http_code}\n" -s
echo.

echo 2. 測試 POST 登入端點 (正確憑證)...
curl -X POST "%API_URL%/api/auth/login" -H "Content-Type: application/json" -d "{\"username\":\"CathaySEA\",\"password\":\"CathaySEA\"}" -w "\nHTTP Status: %%{http_code}\n" -s
echo.

echo 3. 測試 POST 登入端點 (錯誤憑證)...
curl -X POST "%API_URL%/api/auth/login" -H "Content-Type: application/json" -d "{\"username\":\"wrong\",\"password\":\"wrong\"}" -w "\nHTTP Status: %%{http_code}\n" -s
echo.

echo === 測試完成 ===
pause
