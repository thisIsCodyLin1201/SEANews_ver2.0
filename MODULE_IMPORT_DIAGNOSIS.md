# 模組導入問題診斷與修復

## 🔍 問題描述

在 Zeabur 部署時出現 502 Bad Gateway 錯誤，容器日誌顯示：

```
ModuleNotFoundError: No module named 'tag_store'
```

## 🎯 根本原因

雖然 `tag_store.py` 文件存在於 `/app/server/` 目錄中，但 Python 無法找到該模組，原因可能包括：

1. **PYTHONPATH 配置不正確**
2. **WORKDIR 設置後 Python 路徑未更新**
3. **Zeabur 環境變量覆蓋了 Dockerfile 設置**
4. **相對導入路徑問題**

## ✅ 已實施的解決方案

### 1. 添加 `__init__.py`
使 server 目錄成為 Python 包：

```python
# server/__init__.py
# Server package initialization
# This file makes the server directory a Python package
```

### 2. 更新 Dockerfile CMD
確保 PYTHONPATH 在運行時正確設置：

```dockerfile
CMD sh -c "export PYTHONPATH=/app/server:\$PYTHONPATH && cd /app/server && python -m uvicorn agno_api:app --host 0.0.0.0 --port ${PORT} --log-level info"
```

**關鍵改進**：
- ✅ 使用 `export PYTHONPATH` 確保環境變量生效
- ✅ `\$PYTHONPATH` 轉義防止構建時展開
- ✅ 明確 `cd /app/server` 確保工作目錄正確
- ✅ 保持動態端口支持

### 3. 添加導入測試腳本
創建 `server/test_imports.py` 用於診斷：

```bash
# 在容器中運行
docker exec <container-name> python test_imports.py
```

## 🧪 驗證步驟

### 本地測試
```bash
# Windows
test-zeabur-dockerfile.bat

# Linux/Mac
./test-zeabur-dockerfile.sh
```

測試腳本會自動：
1. 構建映像
2. 啟動容器
3. 運行導入測試
4. 檢查 API 健康

### 手動驗證

```bash
# 1. 構建映像
docker build -t seanews:test .

# 2. 啟動容器
docker run -d --name test-import -p 8000:8000 -e PORT=8000 seanews:test

# 3. 測試導入
docker exec test-import python test_imports.py

# 4. 查看日誌
docker logs test-import

# 5. 清理
docker rm -f test-import
```

## 📊 預期輸出

### 成功的導入測試輸出
```
============================================================
Python 模組導入測試
============================================================

Python 版本: 3.11.x

當前工作目錄: /app/server

Python 路徑 (sys.path):
  1. /app/server
  2. /usr/local/lib/python3.11
  ...

============================================================
嘗試導入 server 模組...
============================================================

[測試 1] 導入 tag_store...
✅ tag_store 導入成功

[測試 2] 導入 email_service...
✅ email_service 導入成功

[測試 3] 導入 excel_service...
✅ excel_service 導入成功

[測試 4] 導入 news_store...
✅ news_store 導入成功

[測試 5] 導入 rag_store...
⚠️  rag_store 導入失敗（預期，因為有 lazy import）

============================================================
檢查文件是否存在...
============================================================
✅ tag_store.py 存在
✅ email_service.py 存在
✅ excel_service.py 存在
✅ news_store.py 存在
✅ rag_store.py 存在
✅ agno_api.py 存在
✅ __init__.py 存在

============================================================
測試完成
============================================================
```

### 成功的應用啟動日誌
```
[OK] 新聞資料庫已初始化: /app/server/news_records.db
INFO:     Started server process [1]
INFO:     Waiting for application startup.
[OK] 檢測到 15 個 API 路由
[OK] 靜態文件服務已啟用 (html=True): /app/dist
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

## 🔧 故障排查

### 如果導入仍然失敗

#### 方案 A: 檢查容器內部
```bash
# 進入容器
docker exec -it <container-name> /bin/sh

# 檢查工作目錄
pwd

# 列出文件
ls -la

# 檢查 Python 路徑
python -c "import sys; print('\n'.join(sys.path))"

# 手動測試導入
python -c "from tag_store import get_doc_tags; print('Success')"
```

#### 方案 B: 檢查 PYTHONPATH
```bash
# 在容器中
docker exec <container-name> env | grep PYTHON
```

預期輸出：
```
PYTHONPATH=/app/server
PYTHONUNBUFFERED=1
PYTHONDONTWRITEBYTECODE=1
```

#### 方案 C: 檢查文件權限
```bash
docker exec <container-name> ls -la /app/server/*.py
```

確保所有 .py 文件都有讀取權限。

### 如果 Zeabur 部署失敗

#### 1. 查看構建日誌
在 Zeabur Dashboard 中檢查構建是否成功。

#### 2. 查看運行日誌
```
Zeabur Dashboard → 選擇服務 → Logs 標籤
```

尋找：
- `ModuleNotFoundError` 
- `ImportError`
- Python 路徑相關錯誤

#### 3. 檢查環境變量
確認沒有意外設置的環境變量覆蓋 PYTHONPATH。

#### 4. 手動重新部署
有時環境變量更新需要重新部署：
```
Zeabur Dashboard → 服務設置 → Redeploy
```

## 🔄 替代方案

如果上述方案都不行，可以嘗試以下替代方案：

### 方案 1: 使用絕對導入（不推薦）

修改 `agno_api.py`：

```python
# 從
from tag_store import get_doc_tags

# 改為
import sys
sys.path.insert(0, '/app/server')
from tag_store import get_doc_tags
```

### 方案 2: 修改 uvicorn 啟動方式

```dockerfile
CMD sh -c "cd /app && python -m uvicorn server.agno_api:app --host 0.0.0.0 --port ${PORT}"
```

然後修改所有導入為：
```python
from server.tag_store import get_doc_tags
```

### 方案 3: 使用 Python 模組運行（當前方案）

```dockerfile
WORKDIR /app/server
PYTHONPATH=/app/server
CMD sh -c "export PYTHONPATH=/app/server:\$PYTHONPATH && cd /app/server && python -m uvicorn agno_api:app ..."
```

## 📝 最佳實踐

### 1. 保持簡單的導入路徑
- ✅ 使用相對於 WORKDIR 的導入
- ✅ 設置明確的 PYTHONPATH
- ❌ 避免複雜的相對導入

### 2. 確保文件結構清晰
```
/app/
  ├── server/
  │   ├── __init__.py          # 使 server 成為 Python 包
  │   ├── agno_api.py
  │   ├── tag_store.py
  │   ├── email_service.py
  │   └── ...
  └── dist/                     # 前端靜態文件
```

### 3. 測試導入
在部署前先測試導入：
```bash
docker build -t test .
docker run --rm test python -c "from tag_store import get_doc_tags; print('OK')"
```

### 4. 監控日誌
部署後立即檢查日誌，確認沒有導入錯誤。

## 🎯 Zeabur 特別注意事項

### 環境變量優先級
Zeabur 會注入環境變量，可能覆蓋 Dockerfile 中的設置。

**解決**：在 CMD 中明確設置 PYTHONPATH
```dockerfile
CMD sh -c "export PYTHONPATH=/app/server:\$PYTHONPATH && ..."
```

### 動態端口
確保使用 `${PORT}` 而不是硬編碼端口。

### 構建緩存
如果修改了 Dockerfile，可能需要清除構建緩存：
```
Zeabur Dashboard → 服務設置 → Clear Build Cache → Redeploy
```

## 📚 相關文檔

- [MODULE_IMPORT_FIX.md](./MODULE_IMPORT_FIX.md) - 原始模組導入修復
- [ZEABUR_DEPLOYMENT.md](./ZEABUR_DEPLOYMENT.md) - Zeabur 部署指南
- [DOCKERFILE_COMPARISON.md](./DOCKERFILE_COMPARISON.md) - Dockerfile 版本對比

## ✅ 檢查清單

部署前確認：
- [ ] `server/__init__.py` 已創建
- [ ] Dockerfile CMD 包含 `export PYTHONPATH`
- [ ] WORKDIR 設置為 `/app/server`
- [ ] 所有 server/*.py 文件已複製
- [ ] 本地測試通過

部署後確認：
- [ ] 構建成功
- [ ] 容器啟動成功
- [ ] 日誌無導入錯誤
- [ ] API 健康檢查通過
- [ ] 前端可訪問

---

**更新時間**：2026-01-14  
**狀態**：已修復並測試

如有問題，請查看容器日誌並使用 `test_imports.py` 診斷具體導入失敗原因。
