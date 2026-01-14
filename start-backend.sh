#!/bin/bash

echo "===================================="
echo "啟動 SEANews 後端服務"
echo "===================================="
echo ""

cd "$(dirname "$0")"

echo "[1/2] 檢查環境..."
if [ ! -f "server/agno_api.py" ]; then
    echo "[錯誤] 找不到 server/agno_api.py"
    exit 1
fi

if [ ! -f ".env" ]; then
    echo "[警告] 找不到 .env 文件"
    echo "將使用系統環境變量"
fi

echo "[2/2] 啟動後端..."
echo "後端將在 http://localhost:8787 運行"
echo "按 Ctrl+C 停止服務"
echo ""

cd server
python -m uvicorn agno_api:app --host 127.0.0.1 --port 8787 --reload --log-level info
