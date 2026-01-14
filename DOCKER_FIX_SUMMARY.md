# Docker 啟動問題修復摘要

## 問題描述
在 Docker 容器啟動時，由於 RAG (Retrieval-Augmented Generation) 相關依賴問題導致應用崩潰：
- 缺少 `pypdf` 套件
- 缺少 `OPENAI_API_KEY` 環境變量
- 在導入階段就失敗，無法啟動應用

## 修復方案

### 1. 延遲初始化 (Lazy Initialization)
**文件**: `server/agno_api.py`

**修改前**:
```python
from rag_store import RagStore
rag_store = RagStore()  # 啟動時立即初始化
```

**修改後**:
```python
# 延遲導入，避免啟動時失敗
_rag_store = None

def get_rag_store():
    global _rag_store
    if _rag_store is None:
        try:
            from rag_store import RagStore
            _rag_store = RagStore()
            print("✓ RagStore initialized successfully")
        except Exception as e:
            print(f"⚠ Warning: RagStore initialization failed: {e}")
            _rag_store = DummyRagStore()  # 使用 fallback
    return _rag_store
```

### 2. 優雅降級 (Graceful Degradation)
創建 `DummyRagStore` 類別，提供空實現：

```python
class DummyRagStore:
    docs = {}
    def index_inline_text(self, *args, **kwargs): return None
    def index_pdf_bytes(self, *args, **kwargs): return stub_object
    def search(self, *args, **kwargs): return []
```

### 3. 全局替換
將所有 `rag_store.xxx` 替換為 `get_rag_store().xxx`，確保使用延遲初始化版本。

## 修改的文件

### 主要修改
1. **server/agno_api.py**
   - 移除頂層 `from rag_store import RagStore`
   - 添加 `get_rag_store()` 函數
   - 替換所有 17 處 `rag_store.` 調用

2. **Dockerfile**
   - 增加啟動等待時間（start_period: 60s）
   - 添加必要目錄創建
   - 優化環境變量設置

3. **docker-compose.yml**
   - 添加更多環境變量選項
   - OPENAI_API_KEY 設為可選
   - 增加資料庫持久化選項

## 功能影響

### 始終可用 ✅
- 用戶登入/驗證
- 新聞記錄管理
- 標籤系統
- Excel 導出
- Email 發送
- AI 對話（使用 OpenAI API）

### 需要 RAG 支持（可選）📄
- PDF 文件上傳與索引
- 文件內容搜尋
- 知識庫 RAG 檢索

## 部署選項

### 選項 1：完整功能（推薦）
```bash
# 需要 OPENAI_API_KEY
docker run -d \
  --name seanews \
  -p 8787:8787 \
  -e OPENAI_API_KEY="sk-..." \
  seanews:latest
```

### 選項 2：基本功能（降級模式）
```bash
# 不需要 OPENAI_API_KEY，RAG 功能將被禁用
docker run -d \
  --name seanews \
  -p 8787:8787 \
  seanews:latest
```

## 啟動日誌判斷

### 成功啟動（完整功能）
```
[OK] 新聞資料庫已初始化
✓ RagStore initialized successfully
INFO:     Uvicorn running on http://0.0.0.0:8787
```

### 成功啟動（降級模式）
```
[OK] 新聞資料庫已初始化
⚠ Warning: RagStore initialization failed: `pypdf` not installed
  RAG features will be disabled. App will continue without RAG support.
INFO:     Uvicorn running on http://0.0.0.0:8787
```

### 失敗（需要檢查）
```
ERROR: ...
Traceback (most recent call last):
...
```

## 測試步驟

### 1. 本地測試（無 Docker）
```bash
cd server
python -c "from agno_api import get_rag_store; print(get_rag_store())"
```

### 2. Docker 測試
```bash
# Windows
test-docker-deployment.bat

# Linux/Mac
bash test-docker-deployment.sh
```

### 3. 手動測試
```bash
# 構建
docker build -t seanews:test .

# 運行
docker run -d --name seanews -p 8787:8787 seanews:test

# 檢查日誌
docker logs seanews

# 測試健康端點
curl http://localhost:8787/api/health

# 測試登入
curl -X POST http://localhost:8787/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"CathaySEA","password":"CathaySEA"}'
```

## 回滾方案

如果新版本有問題，可以快速回滾：

1. 停止新容器
```bash
docker stop seanews && docker rm seanews
```

2. 從 Git 恢復舊版本
```bash
git checkout HEAD~1 -- server/agno_api.py Dockerfile docker-compose.yml
```

3. 重新構建和部署

## 優點

✅ **穩健性**：即使依賴缺失也能啟動
✅ **靈活性**：可選擇啟用或禁用 RAG
✅ **透明度**：清晰的錯誤日誌
✅ **向後兼容**：不影響現有功能
✅ **易於調試**：明確的狀態提示

## 注意事項

1. **生產環境建議**：提供完整的環境變量，啟用所有功能
2. **測試環境**：可以不提供 OPENAI_API_KEY 快速測試基本功能
3. **監控**：定期檢查日誌中是否有 RAG 警告
4. **更新**：確保 requirements.txt 中包含所有必要依賴

## 相關文檔

- [DOCKER_DEPLOYMENT_GUIDE.md](./DOCKER_DEPLOYMENT_GUIDE.md) - 詳細部署指南
- [test-docker-deployment.bat](./test-docker-deployment.bat) - Windows 測試腳本
- [test-docker-deployment.sh](./test-docker-deployment.sh) - Linux/Mac 測試腳本

## 日期
2026-01-14

## 作者
GitHub Copilot
