#!/bin/bash
# Docker 部署測試腳本

echo "======================================"
echo "SEANews Docker 部署測試"
echo "======================================"

# 顏色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 檢查 Docker 是否運行
echo -e "\n${YELLOW}[1/6] 檢查 Docker 環境...${NC}"
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}✗ Docker 未運行，請先啟動 Docker Desktop${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker 運行正常${NC}"

# 2. 停止並刪除舊容器
echo -e "\n${YELLOW}[2/6] 清理舊容器...${NC}"
docker stop seanews 2>/dev/null || true
docker rm seanews 2>/dev/null || true
echo -e "${GREEN}✓ 舊容器已清理${NC}"

# 3. 構建鏡像
echo -e "\n${YELLOW}[3/6] 構建 Docker 鏡像...${NC}"
if docker build -t seanews:test . ; then
    echo -e "${GREEN}✓ 鏡像構建成功${NC}"
else
    echo -e "${RED}✗ 鏡像構建失敗${NC}"
    exit 1
fi

# 4. 啟動容器（不需要 OPENAI_API_KEY）
echo -e "\n${YELLOW}[4/6] 啟動容器（降級模式）...${NC}"
docker run -d \
  --name seanews \
  -p 8787:8787 \
  -e APP_USERNAME=CathaySEA \
  -e APP_PASSWORD=CathaySEA \
  seanews:test

# 等待容器啟動
echo "等待服務啟動..."
sleep 5

# 5. 檢查容器狀態
echo -e "\n${YELLOW}[5/6] 檢查容器狀態...${NC}"
if docker ps | grep -q seanews; then
    echo -e "${GREEN}✓ 容器運行中${NC}"
    docker ps | grep seanews
else
    echo -e "${RED}✗ 容器未運行${NC}"
    echo "查看日誌："
    docker logs seanews
    exit 1
fi

# 6. 測試 API 健康檢查
echo -e "\n${YELLOW}[6/6] 測試 API 端點...${NC}"
max_retries=10
retry=0

while [ $retry -lt $max_retries ]; do
    if curl -f http://localhost:8787/api/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ API 健康檢查通過${NC}"
        
        # 測試登入端點
        echo -e "\n測試登入 API..."
        response=$(curl -s -X POST http://localhost:8787/api/auth/login \
          -H "Content-Type: application/json" \
          -d '{"username":"CathaySEA","password":"CathaySEA"}')
        
        if echo "$response" | grep -q "token"; then
            echo -e "${GREEN}✓ 登入 API 正常${NC}"
        else
            echo -e "${YELLOW}⚠ 登入響應: $response${NC}"
        fi
        break
    fi
    
    retry=$((retry+1))
    echo "等待 API 就緒... ($retry/$max_retries)"
    sleep 2
done

if [ $retry -eq $max_retries ]; then
    echo -e "${RED}✗ API 健康檢查失敗${NC}"
    echo "容器日誌："
    docker logs seanews --tail 50
    exit 1
fi

# 顯示容器日誌
echo -e "\n${YELLOW}容器啟動日誌：${NC}"
docker logs seanews --tail 20

# 總結
echo -e "\n======================================"
echo -e "${GREEN}✓ 所有測試通過！${NC}"
echo -e "======================================"
echo ""
echo "訪問應用："
echo "  - 前端: http://localhost:8787"
echo "  - 健康檢查: http://localhost:8787/api/health"
echo ""
echo "查看日誌: docker logs seanews -f"
echo "停止容器: docker stop seanews"
echo "刪除容器: docker rm seanews"
echo ""

# 可選：如果有 OPENAI_API_KEY，提示完整功能測試
if [ -f .env ] && grep -q "OPENAI_API_KEY" .env; then
    echo -e "${YELLOW}提示：檢測到 .env 文件，可以測試完整功能：${NC}"
    echo "  docker stop seanews && docker rm seanews"
    echo "  docker run -d --name seanews -p 8787:8787 --env-file .env seanews:test"
fi
