#!/bin/bash

# Docker 構建和測試腳本

set -e  # 遇到錯誤立即退出

echo "================================"
echo "SEA News Docker 構建和測試"
echo "================================"
echo ""

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 檢查 .env 文件
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  警告: .env 文件不存在${NC}"
    echo "請創建 .env 文件並設置以下變量："
    echo "  OPENAI_API_KEY=sk-..."
    echo "  OPENAI_MODEL=gpt-4o-mini"
    echo "  APP_USERNAME=CathaySEA"
    echo "  APP_PASSWORD=CathaySEA"
    echo ""
    read -p "是否繼續？ (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 1. 構建 Docker 鏡像
echo -e "${GREEN}📦 步驟 1: 構建 Docker 鏡像${NC}"
docker build -t seanews-app:latest . || {
    echo -e "${RED}❌ 構建失敗${NC}"
    exit 1
}
echo -e "${GREEN}✅ 構建成功${NC}"
echo ""

# 2. 停止並移除舊容器（如果存在）
echo -e "${GREEN}🧹 步驟 2: 清理舊容器${NC}"
docker stop seanews 2>/dev/null || true
docker rm seanews 2>/dev/null || true
echo -e "${GREEN}✅ 清理完成${NC}"
echo ""

# 3. 啟動新容器
echo -e "${GREEN}🚀 步驟 3: 啟動容器${NC}"
docker run -d \
  --name seanews \
  -p 8787:8787 \
  --env-file .env \
  seanews-app:latest || {
    echo -e "${RED}❌ 啟動失敗${NC}"
    exit 1
}
echo -e "${GREEN}✅ 容器已啟動${NC}"
echo ""

# 4. 等待服務啟動
echo -e "${GREEN}⏳ 步驟 4: 等待服務啟動${NC}"
sleep 5

# 5. 檢查容器狀態
echo -e "${GREEN}🔍 步驟 5: 檢查容器狀態${NC}"
if docker ps | grep -q seanews; then
    echo -e "${GREEN}✅ 容器運行中${NC}"
else
    echo -e "${RED}❌ 容器未運行${NC}"
    echo "查看日誌:"
    docker logs seanews
    exit 1
fi
echo ""

# 6. 測試健康檢查
echo -e "${GREEN}🏥 步驟 6: 測試健康檢查${NC}"
HEALTH_CHECK=$(curl -s http://localhost:8787/api/health)
if echo "$HEALTH_CHECK" | grep -q '"ok":true'; then
    echo -e "${GREEN}✅ 健康檢查通過: $HEALTH_CHECK${NC}"
else
    echo -e "${RED}❌ 健康檢查失敗: $HEALTH_CHECK${NC}"
    docker logs seanews
    exit 1
fi
echo ""

# 7. 測試登入 API
echo -e "${GREEN}🔐 步驟 7: 測試登入 API${NC}"
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8787/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"CathaySEA","password":"CathaySEA"}')

if echo "$LOGIN_RESPONSE" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ 登入 API 測試通過${NC}"
    echo "響應: $LOGIN_RESPONSE"
else
    echo -e "${RED}❌ 登入 API 測試失敗${NC}"
    echo "響應: $LOGIN_RESPONSE"
    docker logs seanews
    exit 1
fi
echo ""

# 8. 顯示容器信息
echo -e "${GREEN}📊 步驟 8: 容器信息${NC}"
echo "容器 ID: $(docker ps -q -f name=seanews)"
echo "容器狀態: $(docker ps -f name=seanews --format '{{.Status}}')"
echo "端口映射: $(docker ps -f name=seanews --format '{{.Ports}}')"
echo ""

# 9. 顯示日誌
echo -e "${GREEN}📝 最近日誌:${NC}"
docker logs --tail 20 seanews
echo ""

# 完成
echo "================================"
echo -e "${GREEN}✅ 所有測試通過！${NC}"
echo "================================"
echo ""
echo "應用已啟動在: http://localhost:8787"
echo ""
echo "常用命令:"
echo "  查看日誌: docker logs -f seanews"
echo "  停止容器: docker stop seanews"
echo "  重啟容器: docker restart seanews"
echo "  進入容器: docker exec -it seanews sh"
echo ""
