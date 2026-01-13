#!/bin/bash

# 測試登入 API 的腳本

echo "=== 測試登入 API ==="
echo ""

# 設置 API 地址
API_URL="${1:-http://localhost:8787}"

echo "測試 API: $API_URL"
echo ""

# 測試 1: 健康檢查
echo "1. 測試健康檢查端點..."
curl -X GET "$API_URL/api/health" \
  -H "Content-Type: application/json" \
  -w "\nHTTP Status: %{http_code}\n" \
  -s
echo ""

# 測試 2: OPTIONS 預檢請求 (CORS)
echo "2. 測試 OPTIONS 預檢請求..."
curl -X OPTIONS "$API_URL/api/auth/login" \
  -H "Origin: http://localhost:5173" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -w "\nHTTP Status: %{http_code}\n" \
  -v \
  2>&1 | grep -E "(HTTP/|Access-Control-|< )"
echo ""

# 測試 3: 正確的登入請求
echo "3. 測試正確的登入憑證..."
curl -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"CathaySEA","password":"CathaySEA"}' \
  -w "\nHTTP Status: %{http_code}\n" \
  -s
echo ""

# 測試 4: 錯誤的登入請求
echo "4. 測試錯誤的登入憑證..."
curl -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"wrong","password":"wrong"}' \
  -w "\nHTTP Status: %{http_code}\n" \
  -s
echo ""

# 測試 5: 空白登入請求
echo "5. 測試空白憑證..."
curl -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"","password":""}' \
  -w "\nHTTP Status: %{http_code}\n" \
  -s
echo ""

echo "=== 測試完成 ==="
