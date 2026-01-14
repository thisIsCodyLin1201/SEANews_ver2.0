# Zeabur 502 錯誤修復清單

## ✅ 已修復的問題

### 1. Dockerfile CMD 配置 ✨
**問題**：
```dockerfile
# ❌ 舊版本
CMD sh -c "export PYTHONPATH=/app/server:\$PYTHONPATH && cd /app/server && python -m uvicorn agno_api:app --host 0.0.0.0 --port ${PORT} --log-level info"
```

**問題分析**：
- 多餘的 `export PYTHONPATH`（ENV 已設置）
- 多餘的 `cd /app/server`（WORKDIR 已設置）
- Shell 變量展開可能導致問題

**修復**：
```dockerfile
# ✅ 新版本
CMD ["sh", "-c", "python -m uvicorn agno_api:app --host 0.0.0.0 --port ${PORT} --log-level info"]
```

### 2. ENV 設置順序優化 🔧
**修復前**：
```dockerfile
WORKDIR /app/server
ENV PYTHONPATH=/app/server
```

**修復後**：
```dockerfile
ENV PYTHONPATH=/app/server
WORKDIR /app/server
```

**原因**：確保環境變量在切換目錄前已設置。

## 📁 正確的目錄結構

```
/app/
├── server/                    # Python 後端代碼
│   ├── agno_api.py           # 主應用（WORKDIR 在這裡）
│   ├── tag_store.py          # 模組（可直接 import）
│   ├── rag_store.py
│   ├── email_service.py
│   ├── excel_service.py
│   ├── news_store.py
│   ├── __init__.py
│   ├── requirements.txt
│   └── exports/
└── dist/                      # 前端靜態文件
    ├── index.html
    ├── assets/
    └── ...
```

## 🔍 關鍵配置檢查

### 1. PYTHONPATH 設置
```dockerfile
ENV PYTHONPATH=/app/server
```
✅ 允許 Python 導入 `/app/server/` 中的模組

### 2. WORKDIR 設置
```dockerfile
WORKDIR /app/server
```
✅ uvicorn 在 `/app/server` 目錄執行
✅ `agno_api.py` 可以使用相對導入同級模組

### 3. 模組導入（agno_api.py）
```python
from tag_store import get_doc_tags, load_tag_store, set_custom_tags, set_doc_tags
from email_service import send_email_with_attachment, generate_news_report_html
from excel_service import generate_news_excel, generate_batch_news_excel, cleanup_old_exports
```
✅ 直接導入（因為在同一目錄且 PYTHONPATH 包含 /app/server）

### 4. 靜態文件路徑（agno_api.py）
```python
dist_path = Path(__file__).parent.parent / "dist"
# __file__ = /app/server/agno_api.py
# parent = /app/server
# parent.parent = /app
# dist = /app/dist ✅
```

### 5. PORT 環境變量
```dockerfile
ENV PORT=8000
```
✅ 提供默認值，Zeabur 會自動覆蓋

### 6. CMD 命令
```dockerfile
CMD ["sh", "-c", "python -m uvicorn agno_api:app --host 0.0.0.0 --port ${PORT} --log-level info"]
```
✅ 使用 exec 格式
✅ 支持 `${PORT}` 環境變量展開
✅ 在當前 WORKDIR (/app/server) 執行

## 🧪 本地測試命令

### 構建鏡像
```bash
docker build -t seanews:zeabur-fixed .
```

### 運行容器（模擬 Zeabur）
```bash
docker run -d \
  --name seanews-test \
  -p 8000:8000 \
  -e PORT=8000 \
  -e OPENAI_API_KEY=your-key \
  -e OPENAI_MODEL=gpt-5.2-2025-12-11 \
  -e APP_USERNAME=CathaySEA \
  -e APP_PASSWORD=CathaySEA \
  -e APP_SECRET_KEY=cathay-sea-news-secret-key-2026 \
  seanews:zeabur-fixed
```

### 查看日誌
```bash
docker logs seanews-test
```

**預期輸出**：
```
[OK] 新聞資料庫已初始化: /app/server/news_records.db
INFO:     Started server process [1]
INFO:     Waiting for application startup.
[OK] 檢測到 15 個 API 路由
[OK] 靜態文件服務已啟用 (html=True): /app/dist
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

### 測試健康檢查
```bash
curl http://localhost:8000/api/health
# 預期: {"ok":true}
```

### 測試前端
打開瀏覽器：`http://localhost:8000`

## 🚀 Zeabur 部署檢查清單

### 部署前檢查
- [x] Dockerfile 已修復 CMD 配置
- [x] ENV 設置順序正確
- [x] PYTHONPATH 正確設置
- [x] WORKDIR 正確設置
- [x] 所有 server 文件已複製
- [x] dist 目錄已從前端構建複製
- [ ] 代碼已推送到 GitHub

### Zeabur 環境變量設置
必需設置：
```env
OPENAI_API_KEY=sk-proj-你的密鑰
OPENAI_MODEL=gpt-5.2-2025-12-11
APP_USERNAME=CathaySEA
APP_PASSWORD=你的密碼
APP_SECRET_KEY=cathay-sea-news-secret-key-2026
```

⚠️ **不要設置**：
- `PORT` - Zeabur 自動管理
- `PYTHONPATH` - Dockerfile 已設置
- `WORKDIR` - Docker 配置

### 部署後驗證
- [ ] 構建成功（無錯誤）
- [ ] 容器啟動成功（綠色狀態）
- [ ] 健康檢查通過
- [ ] 訪問域名顯示登錄頁面
- [ ] API 端點響應正常
- [ ] 登錄功能正常
- [ ] 可以發送新聞搜索請求

## 🔧 故障排查

### 如果仍然出現 502 錯誤

#### 1. 檢查構建日誌
在 Zeabur Dashboard → 服務 → Logs → Build Logs

**尋找**：
- ❌ 依賴安裝失敗
- ❌ 前端構建失敗
- ❌ 複製文件失敗

#### 2. 檢查運行日誌
在 Zeabur Dashboard → 服務 → Logs → Runtime Logs

**尋找**：
- ❌ `ModuleNotFoundError: No module named 'tag_store'`
- ❌ `FileNotFoundError: [Errno 2] No such file or directory: '/app/dist'`
- ❌ `Address already in use`
- ❌ 任何 Python traceback

#### 3. 檢查環境變量
在 Zeabur Dashboard → 服務 → Environment Variables

**確認**：
- ✅ `OPENAI_API_KEY` 已設置且正確
- ✅ `OPENAI_MODEL` 已設置
- ✅ `APP_USERNAME` 已設置
- ✅ `APP_PASSWORD` 已設置
- ✅ `APP_SECRET_KEY` 已設置
- ❌ 沒有設置 `PORT`（Zeabur 自動管理）

#### 4. 檢查容器狀態
在 Zeabur Dashboard → 服務

**確認**：
- ✅ 狀態為綠色（Running）
- ✅ 沒有重啟循環
- ✅ 健康檢查通過

#### 5. 手動測試健康檢查
```bash
curl https://your-app.zeabur.app/api/health
```

**預期**：`{"ok":true}`

**如果失敗**：
- 檢查應用是否真的在運行
- 檢查端口是否正確綁定
- 檢查健康檢查路由是否存在

## 📊 常見錯誤和解決方案

### 錯誤 1: ModuleNotFoundError
```
ModuleNotFoundError: No module named 'tag_store'
```

**原因**：PYTHONPATH 或 WORKDIR 設置不正確

**解決**：
- 確認 Dockerfile 中 `ENV PYTHONPATH=/app/server`
- 確認 Dockerfile 中 `WORKDIR /app/server`
- 確認 `COPY server ./server` 執行成功

### 錯誤 2: FileNotFoundError (dist)
```
FileNotFoundError: [Errno 2] No such file or directory: '/app/dist'
```

**原因**：前端構建產物沒有正確複製

**解決**：
- 確認前端構建成功：`RUN npm run build`
- 確認複製命令：`COPY --from=frontend-builder /app/dist ./dist`

### 錯誤 3: Address already in use
```
OSError: [Errno 98] Address already in use
```

**原因**：端口綁定問題

**解決**：
- 不要在環境變量中設置 `PORT`
- 讓 Zeabur 自動管理端口

### 錯誤 4: 502 Bad Gateway（無日誌）
**原因**：應用啟動失敗或崩潰

**解決**：
1. 檢查運行日誌
2. 查找 Python traceback
3. 檢查所有環境變量是否設置

## ✅ 最終檢查

### Dockerfile 關鍵行
```dockerfile
# 第 70 行 - ENV 設置
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app/server

# 第 75 行 - WORKDIR
WORKDIR /app/server

# 第 78 行 - PORT
ENV PORT=8000

# 第 87 行 - CMD
CMD ["sh", "-c", "python -m uvicorn agno_api:app --host 0.0.0.0 --port ${PORT} --log-level info"]
```

### 確認文件存在
```bash
# 在容器中執行
docker exec seanews-test ls -la /app/server/
# 應該看到：
# - agno_api.py
# - tag_store.py
# - rag_store.py
# - email_service.py
# - excel_service.py
# - news_store.py
# - __init__.py

docker exec seanews-test ls -la /app/dist/
# 應該看到：
# - index.html
# - assets/
```

### 確認 Python 路徑
```bash
docker exec seanews-test python -c "import sys; print('\\n'.join(sys.path))"
# 應該包含：
# /app/server
```

## 🎉 成功標誌

如果看到以下輸出，表示部署成功：

```
[OK] 新聞資料庫已初始化: /app/server/news_records.db
INFO:     Started server process [1]
INFO:     Waiting for application startup.
[OK] 檢測到 15 個 API 路由
[OK] 靜態文件服務已啟用 (html=True): /app/dist
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

訪問應用域名應該：
- ✅ 顯示登錄頁面
- ✅ 可以登錄
- ✅ 可以發送新聞搜索
- ✅ AI 正常回覆

---

**下一步**：
1. 提交修復後的 Dockerfile
2. 推送到 GitHub
3. 在 Zeabur 重新部署
4. 驗證所有功能正常

如有問題請檢查日誌並參考故障排查部分。
