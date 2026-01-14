#!/bin/bash
# Docker 模組導入修復測試腳本
# 用於在網路條件允許時重新構建和測試

echo "===================================="
echo "Docker 模組導入修復測試"
echo "===================================="
echo ""

echo "[1/5] 清理舊容器和映像..."
docker rm -f seanews-module-test 2>/dev/null || true
docker rmi seanews:module-fix 2>/dev/null || true
echo ""

echo "[2/5] 構建新映像（應用模組導入修復）..."
echo "注意：這可能需要 5-10 分鐘，取決於網路速度"
if ! docker build -t seanews:module-fix .; then
    echo ""
    echo "[錯誤] 構建失敗！可能是網路問題。"
    echo ""
    echo "臨時解決方案：使用現有映像測試修復"
    echo "執行以下命令："
    echo "docker run -d --name seanews-module-test -p 8787:8787 -e PYTHONPATH=/app/server -w /app/server seanews:latest python -m uvicorn agno_api:app --host 0.0.0.0 --port 8787 --log-level info"
    exit 1
fi
echo ""

echo "[3/5] 啟動測試容器..."
if ! docker run -d --name seanews-module-test -p 8787:8787 seanews:module-fix; then
    echo "[錯誤] 容器啟動失敗！"
    exit 1
fi
echo ""

echo "[4/5] 等待容器啟動（5秒）..."
sleep 5
echo ""

echo "[5/5] 檢查容器日誌..."
docker logs seanews-module-test 2>&1 | grep -E "Application startup complete|ModuleNotFoundError|ERROR"
echo ""

echo "===================================="
echo "測試 API 健康檢查"
echo "===================================="
curl http://localhost:8787/api/health
echo ""
echo ""

echo "===================================="
echo "測試結果"
echo "===================================="
docker ps --filter name=seanews-module-test --format "容器狀態: {{.Status}}"
echo ""

echo "完整日誌:"
docker logs seanews-module-test
echo ""

echo "===================================="
echo "後續操作"
echo "===================================="
echo "如果測試成功："
echo "  docker tag seanews:module-fix seanews:latest"
echo "  docker rm -f seanews-module-test"
echo ""
echo "如果測試失敗："
echo "  docker logs seanews-module-test  # 查看詳細錯誤"
echo "  docker rm -f seanews-module-test # 清理容器"
echo ""
