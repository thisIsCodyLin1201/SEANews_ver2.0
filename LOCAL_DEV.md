# 本地開發快速指南

## 🚀 啟動步驟

### 方法 1：自動啟動（推薦）
雙擊運行：
```
start-dev.bat
```
選擇選項 3（同時啟動前後端）

### 方法 2：手動分別啟動

**終端 1 - 啟動後端**：
```bash
.\start-backend.bat
```
或
```bash
cd server
python -m uvicorn agno_api:app --host 127.0.0.1 --port 8787 --reload
```

**終端 2 - 啟動前端**：
```bash
npm run dev
```

## ✅ 驗證

1. **後端啟動成功**：
   - 看到診斷日誌輸出環境變量
   - 訪問 http://localhost:8787/api/health 返回 `{"ok":true}`

2. **前端啟動成功**：
   - 看到 `Local: http://localhost:5176/`
   - 訪問 http://localhost:5176 顯示登錄頁面

3. **登錄功能測試**：
   - 用戶名：`CathaySEA`（或 .env 中的 APP_USERNAME）
   - 密碼：`CathaySEA`（或 .env 中的 APP_PASSWORD）
   - 點擊登錄按鈕應該成功

## ❌ 常見問題

### 問題：登錄按鈕連線錯誤

**原因**：後端沒有運行

**解決**：
1. 開啟新終端運行 `.\start-backend.bat`
2. 確認看到 uvicorn 啟動信息
3. 測試 http://localhost:8787/api/health

### 問題：端口被占用

**解決**：
```bash
# 查看占用 8787 端口的進程
netstat -ano | findstr :8787

# 終止進程（替換 PID）
taskkill /PID <進程ID> /F
```

### 問題：環境變量未設置

**症狀**：看到 `OPENAI_API_KEY: 未設置 ✗`

**解決**：
1. 確認項目根目錄有 `.env` 文件
2. 檢查 `.env` 內容是否包含必需變量：
   ```env
   OPENAI_API_KEY=sk-proj-...
   OPENAI_MODEL=gpt-5.2-2025-12-11
   APP_USERNAME=CathaySEA
   APP_PASSWORD=CathaySEA
   APP_SECRET_KEY=cathay-sea-news-secret-key-2026
   ```

## 📝 端口說明

| 服務 | 本地端口 | 用途 |
|------|---------|------|
| 前端 (Vite) | 5176 | 開發服務器 |
| 後端 (FastAPI) | 8787 | API 服務 |

前端通過 Vite proxy 將 `/api/*` 請求轉發到 `http://localhost:8787`

## 🔧 開發工具

### 查看後端日誌
後端終端會實時顯示：
- 環境變量狀態
- API 請求日誌
- 錯誤信息

### 熱重載
- 後端：修改 Python 文件後自動重啟
- 前端：修改 JSX/CSS 後自動刷新

## 🎯 快速測試

### 測試後端 API
```bash
# 健康檢查
curl http://localhost:8787/api/health

# 登錄測試
curl -X POST http://localhost:8787/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"CathaySEA\",\"password\":\"CathaySEA\"}"
```

### 測試前端
1. 打開 http://localhost:5176
2. 打開瀏覽器開發者工具 (F12)
3. 查看 Console 和 Network 標籤
4. 登錄時觀察 `/api/auth/login` 請求
