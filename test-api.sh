#!/bin/bash

echo "🧪 测试登录 API"
echo "==============="
echo ""

# 设置 API 地址
API_URL="${1:-http://localhost:8787}"

echo "📍 测试地址: $API_URL"
echo ""

# 测试 1: 检查根路径（应该返回 HTML）
echo "1️⃣ 测试根路径 GET /"
curl -s -o /dev/null -w "状态码: %{http_code}\n" "$API_URL/"
echo ""

# 测试 2: 检查登录 API（POST 请求）
echo "2️⃣ 测试登录 API POST /api/auth/login"
RESPONSE=$(curl -s -w "\n状态码: %{http_code}" -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"CathaySEA","password":"CathaySEA"}')

echo "$RESPONSE"
echo ""

# 测试 3: 检查错误的方法（GET 到登录 API，应该返回 405）
echo "3️⃣ 测试错误方法 GET /api/auth/login（预期 405）"
curl -s -o /dev/null -w "状态码: %{http_code}\n" "$API_URL/api/auth/login"
echo ""

# 测试 4: 检查不存在的 API（应该返回 404）
echo "4️⃣ 测试不存在的 API /api/not-exist"
curl -s -o /dev/null -w "状态码: %{http_code}\n" "$API_URL/api/not-exist"
echo ""

# 测试 5: 检查静态资源
echo "5️⃣ 测试静态资源 /assets/*"
curl -s -o /dev/null -w "状态码: %{http_code}\n" "$API_URL/assets/index.js" 2>/dev/null || echo "状态码: (文件可能不存在)"
echo ""

echo "==============="
echo "✅ 测试完成"
echo ""
echo "预期结果："
echo "  1️⃣ 根路径: 200 (HTML)"
echo "  2️⃣ POST 登录: 200 (JSON with success=true)"
echo "  3️⃣ GET 登录: 405 (方法不允许)"
echo "  4️⃣ 不存在 API: 404"
echo "  5️⃣ 静态资源: 200 或 404"
