# 🔧 Docker 構建修復說明

## 問題診斷

### 錯誤現象
```
⚠️  警告: dist 目錄不存在，靜態文件服務未啟用
INFO:     192.168.27.1:39158 - "GET / HTTP/1.1" 404 Not Found
```

### 根本原因

**Dockerfile 第 16 行錯誤：**
```dockerfile
# ❌ 錯誤配置
RUN npm ci --only=production
```

這會跳過 `devDependencies`，但 **Vite、React、@vitejs/plugin-react** 等構建工具都在 `devDependencies` 中，導致：
1. `npm run build` 找不到 Vite 命令
2. 前端構建失敗，沒有生成 `dist/` 目錄
3. 後端啟動時找不到靜態文件，返回 404

## 修復方案

### 修改 Dockerfile

```diff
# 複製 package.json 和 package-lock.json
COPY package*.json ./

-# 安裝前端依賴
-RUN npm ci --only=production
+# 安裝前端依賴（包含 devDependencies，因為需要 Vite 等構建工具）
+RUN npm ci

# 複製前端源碼
```

### 為什麼這樣修改？

1. **構建階段需要 devDependencies**
   - Vite: 構建工具
   - @vitejs/plugin-react: React 插件
   - TypeScript: 類型檢查

2. **多階段構建的優勢**
   - Stage 1 安裝所有依賴 → 構建前端 → 產生 `dist/`
   - Stage 2 只複製 `dist/`（不複製 node_modules）
   - **最終鏡像不包含 devDependencies**，仍然保持精簡

3. **鏡像大小不受影響**
   ```dockerfile
   # Stage 1: 前端構建 (包含 devDependencies，構建完就丟棄)
   FROM node:20-alpine AS frontend-builder
   RUN npm ci  # 安裝所有依賴
   RUN npm run build  # 構建 dist/
   
   # Stage 2: 後端運行 (只保留 dist/，不保留 node_modules)
   FROM python:3.11-slim
   COPY --from=frontend-builder /app/dist ./dist  # 只複製構建產物
   ```

## 驗證修復

### 1. 檢查 Docker Desktop 運行

**Windows/Mac:**
```bash
# 開啟 Docker Desktop 應用程式
# 確認右下角圖示顯示綠色 (運行中)
```

**驗證命令:**
```bash
docker info
# 應該顯示 Docker 版本和系統信息
```

### 2. 重新構建

```bash
# 清理舊容器
docker stop seanews 2>NUL
docker rm seanews 2>NUL

# 重新構建（會看到 npm ci 安裝完整依賴）
docker build -t seanews-app:latest .

# 應該看到：
# [Stage 1] npm ci
# [Stage 1] added 500+ packages  ← 包含 devDependencies
# [Stage 1] npm run build
# [Stage 1] vite v5.x.x building for production...
# [Stage 1] dist/index.html  x.xx kB  ← 構建成功！
```

### 3. 運行並測試

```bash
# 啟動容器
docker run -d --name seanews -p 8787:8787 --env-file .env seanews-app:latest

# 等待 5 秒
timeout /t 5

# 查看日誌（應該看到成功信息）
docker logs seanews
```

**預期日誌:**
```
✅ 檢測到 XX 個 API 路由
✅ 靜態文件服務已啟用 (html=True): /app/dist  ← 成功！
INFO:     Uvicorn running on http://0.0.0.0:8787
```

### 4. 訪問測試

```bash
# 健康檢查
curl http://localhost:8787/api/health
# 預期: {"ok": true}

# 訪問首頁（不再 404）
curl http://localhost:8787/
# 預期: 返回 HTML 內容（包含 React 應用）

# 登入測試
curl -X POST http://localhost:8787/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"CathaySEA","password":"CathaySEA"}'
# 預期: {"success": true, "token": "..."}
```

## 自動化測試腳本（已更新）

### Windows
```bash
docker-test.bat
```

### Linux/Mac
```bash
chmod +x docker-test.sh
./docker-test.sh
```

**新增功能：**
- ✅ 自動檢查 Docker Desktop 是否運行
- ✅ 9 步驟自動化測試流程
- ✅ 詳細錯誤提示

## 常見錯誤處理

### 錯誤 1: Docker Desktop 未運行

```
ERROR: error during connect: ... dockerDesktopLinuxEngine ...
```

**解決：** 啟動 Docker Desktop 後重試

### 錯誤 2: 端口被占用

```
ERROR: Bind for 0.0.0.0:8787 failed: port is already allocated
```

**解決：**
```bash
# 查找占用進程
netstat -ano | findstr :8787

# 停止舊容器
docker stop seanews
docker rm seanews
```

### 錯誤 3: 構建緩存問題

如果修改後仍然失敗：

```bash
# 清理所有緩存
docker builder prune -a
docker system prune -a

# 重新構建（不使用緩存）
docker build --no-cache -t seanews-app:latest .
```

## 部署到 Zeabur

修復後的 Dockerfile 可以直接部署到 Zeabur：

1. **提交修復：**
```bash
git add Dockerfile
git commit -m "修復 Docker 構建：npm ci 改為安裝完整依賴以支持 Vite 構建"
git push
```

2. **Zeabur 會自動：**
   - 檢測到 Dockerfile
   - 執行多階段構建
   - Stage 1: 安裝依賴 → 構建前端 → 產生 dist/
   - Stage 2: 複製 dist/ + 運行 FastAPI
   - 啟動應用（不再 404）

3. **驗證部署：**
   - 訪問 Zeabur 提供的網址
   - 應該看到 React 登入頁面（不是 404）
   - 登入功能正常（不是 405）

## 技術總結

### 修復前 vs 修復後

| 階段 | 修復前 | 修復後 |
|------|--------|--------|
| **Stage 1 依賴** | `npm ci --only=production` | `npm ci` |
| **可用工具** | ❌ 缺少 Vite/React | ✅ 完整構建工具 |
| **構建結果** | ❌ 構建失敗，無 dist/ | ✅ 構建成功，生成 dist/ |
| **Stage 2 靜態文件** | ❌ 找不到 dist/ | ✅ 從 Stage 1 複製 dist/ |
| **應用訪問** | ❌ 404 Not Found | ✅ 正常顯示 React 應用 |
| **最終鏡像大小** | ~500MB | ~500MB (相同) |

### 為什麼鏡像大小不變？

多階段構建只保留最後一個 Stage 的內容：
- ✅ 保留：`dist/` 靜態文件（~5MB）
- ❌ 丟棄：`node_modules/`（~500MB）
- ❌ 丟棄：`src/` 源碼（~2MB）

所以即使 Stage 1 安裝了完整依賴，最終鏡像只包含構建產物。

## 檢查清單

部署前確認：

- [ ] Dockerfile 已修復（`npm ci` 而非 `npm ci --only=production`）
- [ ] Docker Desktop 已啟動
- [ ] `.env` 文件已配置
- [ ] 本地構建成功（`docker build` 無錯誤）
- [ ] 本地測試通過（`docker-test.bat` 全綠勾）
- [ ] 訪問 localhost:8787 看到登入頁面
- [ ] 登入功能正常（200 OK）
- [ ] 已提交到 Git（準備部署 Zeabur）

---

**最後更新：** 2026-01-13  
**修復分支：** bugfix/dist修復  
**狀態：** ✅ 已修復，準備測試
