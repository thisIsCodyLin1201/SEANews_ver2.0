# Docker 部署指南

## 修復說明

### 問題
1. 啟動時 RAG 相關模組初始化失敗導致應用崩潰
2. 缺少 `pypdf` 或 `OPENAI_API_KEY` 會造成啟動錯誤

### 解決方案
1. **延遲初始化 (Lazy Initialization)**：RAG Store 只在實際使用時才初始化
2. **優雅降級 (Graceful Degradation)**：初始化失敗時使用 DummyRagStore，保證應用正常運行
3. **清晰的錯誤提示**：啟動時會顯示警告，但不會中斷服務

## Docker 構建與運行

### 1. 構建鏡像

```bash
# 基本構建
docker build -t seanews:latest .

# 查看構建日誌
docker build -t seanews:latest . --progress=plain
```

### 2. 運行容器

#### 基本運行（不需要 RAG 功能）
```bash
docker run -d \
  --name seanews \
  -p 8787:8787 \
  seanews:latest
```

#### 完整功能運行（包含 RAG）
```bash
docker run -d \
  --name seanews \
  -p 8787:8787 \
  -e OPENAI_API_KEY="your-api-key-here" \
  -e OPENAI_EMBEDDING_MODEL="text-embedding-3-small" \
  -v $(pwd)/server/exports:/app/server/exports \
  seanews:latest
```

#### 使用 docker-compose
```bash
# 啟動
docker-compose up -d

# 查看日誌
docker-compose logs -f

# 停止
docker-compose down
```

### 3. 健康檢查

```bash
# 檢查容器狀態
docker ps

# 測試健康端點
curl http://localhost:8787/api/health

# 查看容器日誌
docker logs seanews

# 進入容器查看
docker exec -it seanews bash
```

## 環境變量說明

| 變量名 | 必需 | 默認值 | 說明 |
|--------|------|--------|------|
| `PORT` | 否 | 8787 | 服務端口 |
| `OPENAI_API_KEY` | 否* | - | OpenAI API 密鑰 |
| `OPENAI_EMBEDDING_MODEL` | 否 | text-embedding-3-small | Embedding 模型 |
| `PYTHONUNBUFFERED` | 否 | 1 | Python 輸出不緩衝 |

*註：如果不提供 `OPENAI_API_KEY`，RAG 功能將被禁用，但應用仍可正常運行

## 啟動日誌說明

### 正常啟動（含 RAG）
```
[OK] 新聞資料庫已初始化
✓ RagStore initialized successfully
INFO:     Started server process
INFO:     Uvicorn running on http://0.0.0.0:8787
```

### 降級模式（無 RAG）
```
[OK] 新聞資料庫已初始化
⚠ Warning: RagStore initialization failed: `pypdf` not installed
  RAG features will be disabled. App will continue without RAG support.
INFO:     Started server process
INFO:     Uvicorn running on http://0.0.0.0:8787
```

## 功能說明

### 始終可用的功能
- ✅ 用戶登入/登出
- ✅ 新聞摘要生成
- ✅ 標籤管理
- ✅ Excel 導出
- ✅ Email 發送
- ✅ 研究報告生成

### 需要 RAG 的功能（可選）
- 📄 PDF 文件上傳與索引
- 🔍 文件內容搜尋
- 📚 知識庫檢索

## 故障排除

### 問題：容器無法啟動
```bash
# 查看詳細日誌
docker logs seanews --tail 100

# 檢查端口是否被佔用
netstat -ano | findstr "8787"  # Windows
lsof -i :8787                   # Linux/Mac
```

### 問題：RAG 功能不可用
1. 檢查是否設置了 `OPENAI_API_KEY`
2. 查看容器日誌確認 RagStore 是否初始化成功
3. 確認 `pypdf` 已安裝在容器中

### 問題：前端無法訪問
1. 確認容器正在運行：`docker ps`
2. 測試健康檢查：`curl http://localhost:8787/api/health`
3. 檢查防火牆設置

## 本地開發 vs Docker 部署

### 本地開發
```bash
# 啟動後端（需要安裝依賴）
cd server
pip install -r requirements.txt
uvicorn agno_api:app --host 127.0.0.1 --port 8787

# 啟動前端（另一個終端）
npm install
npm run dev
```

### Docker 部署
```bash
# 一次性構建和運行
docker-compose up --build
```

## 部署平台

### Zeabur
1. 連接 GitHub 倉庫
2. 自動檢測 Dockerfile
3. 設置環境變量
4. 部署

### Render
1. 選擇 Docker 部署方式
2. 設置環境變量
3. 配置健康檢查路徑：`/api/health`
4. 部署

### Railway
1. 從 GitHub 導入
2. 自動檢測 Dockerfile
3. 添加環境變量
4. 部署

## 性能優化

### 構建優化
- 使用多階段構建減小鏡像大小
- `.dockerignore` 排除不必要的文件
- 使用 `--no-cache-dir` 安裝 Python 包

### 運行優化
- 健康檢查間隔設置為 30 秒
- 啟動等待時間設置為 60 秒（給 RAG 初始化預留時間）
- 使用持久化存儲掛載 exports 目錄

## 安全建議

1. **不要在鏡像中包含 `.env` 文件**
2. **使用環境變量或密鑰管理服務**
3. **定期更新依賴包**
4. **使用非 root 用戶運行（可選）**

```dockerfile
# 添加到 Dockerfile
RUN useradd -m -u 1000 appuser
USER appuser
```

## 總結

現在的應用具有以下特點：
- ✅ **穩健性**：即使 RAG 失敗也能正常運行
- ✅ **靈活性**：可以選擇是否啟用 RAG 功能
- ✅ **可觀察性**：清晰的日誌輸出
- ✅ **易部署**：Docker 一鍵部署
