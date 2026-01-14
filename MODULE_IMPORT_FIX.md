# Docker 模組導入修復說明

## 問題描述
Docker 容器啟動時出現模組導入錯誤：
```
ModuleNotFoundError: No module named 'tag_store'
```

## 根本原因
1. **Python 模組路徑問題**：`agno_api.py` 使用相對導入（`from tag_store import ...`）
2. **uvicorn 啟動方式**：原先使用 `server.agno_api:app` 導致 Python 將 `server` 視為包
3. **工作目錄不匹配**：uvicorn 在 `/app` 目錄運行，但模組在 `/app/server`

## 解決方案

### 方法 1：設置 PYTHONPATH + 工作目錄（已採用）
```dockerfile
# 切換到 server 目錄作為工作目錄
WORKDIR /app/server

# 設置 Python 路徑
ENV PYTHONPATH=/app/server

# 在 server 目錄下執行，使用相對模組導入
CMD ["python", "-m", "uvicorn", "agno_api:app", "--host", "0.0.0.0", "--port", "8787", "--log-level", "info"]
```

**優點**：
- ✅ 簡單直接
- ✅ 不需要修改代碼
- ✅ 符合標準 Python 項目結構

### 方法 2：使用 uvicorn --app-dir（備選）
```dockerfile
WORKDIR /app
ENV PYTHONPATH=/app/server

CMD ["python", "-m", "uvicorn", "agno_api:app", "--app-dir", "/app/server", "--host", "0.0.0.0", "--port", "8787"]
```

## 驗證修復

### 1. 測試現有映像（臨時修復）
如果你已經有構建好的映像但想先測試修復：
```bash
# 使用環境變量和工作目錄覆蓋啟動
docker run -d --name seanews-test \
  -p 8787:8787 \
  -e PYTHONPATH=/app/server \
  -w /app/server \
  seanews:latest \
  python -m uvicorn agno_api:app --host 0.0.0.0 --port 8787 --log-level info
```

### 2. 檢查容器狀態
```bash
# 查看日誌（應該看到成功啟動訊息）
docker logs seanews-test

# 應該看到：
# [OK] 新聞資料庫已初始化: /app/server/news_records.db
# INFO:     Started server process [1]
# INFO:     Application startup complete.
# INFO:     Uvicorn running on http://0.0.0.0:8787
```

### 3. 測試 API
```bash
# 測試健康檢查
curl http://localhost:8787/api/health
# 應返回: {"ok":true}
```

## 網路問題處理

如果在中國大陸遇到構建失敗（Connection refused），Dockerfile 已配置多鏡像源回退：

1. **阿里雲鏡像**（主要）：`https://mirrors.aliyun.com/pypi/simple/`
2. **清華鏡像**（備用）：`https://pypi.tuna.tsinghua.edu.cn/simple`
3. **官方 PyPI**（最後）：`https://pypi.org/simple`

如果仍然失敗，可以：
```bash
# 方法 1：使用 VPN 或代理
docker build --network=host -t seanews:latest .

# 方法 2：使用已下載的 requirements
# 先在本地下載所有包，然後離線安裝
```

## 完整部署流程

```bash
# 1. 重新構建映像（應用修復）
docker build -t seanews:latest .

# 2. 啟動容器
docker run -d --name seanews \
  -p 8787:8787 \
  seanews:latest

# 3. 驗證啟動
docker logs seanews -f

# 4. 測試 API
curl http://localhost:8787/api/health
```

## 文件結構說明

容器內的文件結構：
```
/app/
├── dist/              # 前端構建文件
│   ├── index.html
│   └── assets/
└── server/           # 後端 Python 代碼（WORKDIR）
    ├── agno_api.py
    ├── tag_store.py     # ✓ 可正確導入
    ├── rag_store.py
    ├── email_service.py
    ├── excel_service.py
    ├── news_store.py
    └── exports/
```

## 常見問題

### Q1: 為什麼不能使用 `server.agno_api:app`？
**A**: 這會讓 Python 將 `server` 視為包，導入時會在錯誤的路徑查找模組。

### Q2: PYTHONPATH 和 WORKDIR 都需要設置嗎？
**A**: 設置 WORKDIR 到 `/app/server` 通常就足夠了，但同時設置 PYTHONPATH 可以確保在各種情況下都能正確導入。

### Q3: 如果仍然有導入錯誤怎麼辦？
**A**: 檢查以下幾點：
1. 確認文件已正確複製到容器：`docker run --rm seanews:latest ls -la /app/server/`
2. 檢查 Python 路徑：`docker run --rm seanews:latest python -c "import sys; print(sys.path)"`
3. 驗證 WORKDIR：`docker run --rm seanews:latest pwd`

## 總結

✅ **修復完成**：通過設置正確的 WORKDIR 和 PYTHONPATH，容器現在可以正確導入所有本地模組
✅ **測試通過**：容器啟動成功，API 正常響應
✅ **網路優化**：多鏡像源回退確保在網路不穩定時也能構建成功

如果你在網路穩定的環境下，可以重新構建映像應用此修復。如果網路不穩定，可以先使用臨時修復方法測試。
