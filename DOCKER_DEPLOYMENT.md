# 🐳 Docker 部署指南

## 問題診斷

### 根本原因
Zeabur 使用 **Caddy 靜態文件伺服器** 部署時，只能提供靜態 HTML/CSS/JS 文件，**無法處理後端 API 請求**（如 POST `/api/auth/login`）。

這就是為什麼會出現 **405 Method Not Allowed** 錯誤：
- ❌ Caddy 只支持 GET 請求來提供靜態文件
- ❌ POST 請求到 `/api/auth/login` 被 Caddy 拒絕
- ✅ 需要運行 **FastAPI 後端伺服器** 來處理 API 請求

## 解決方案

使用 **Docker** 正確部署完整應用（前端 + 後端）。

---

## 🚀 部署方式

### 方式 1: 使用 Docker Compose（推薦）

#### 1. 準備環境變量

創建 `.env` 文件：
```env
OPENAI_API_KEY=sk-your-openai-api-key
OPENAI_MODEL=gpt-4o-mini
APP_USERNAME=CathaySEA
APP_PASSWORD=CathaySEA
```

#### 2. 構建並啟動

```bash
# 構建並啟動服務
docker-compose up -d

# 查看日誌
docker-compose logs -f

# 停止服務
docker-compose down
```

#### 3. 訪問應用

打開瀏覽器訪問：`http://localhost:8787`

---

### 方式 2: 使用 Dockerfile 手動部署

#### 1. 構建鏡像

```bash
docker build -t seanews-app:latest .
```

#### 2. 運行容器

```bash
docker run -d \
  --name seanews \
  -p 8787:8787 \
  -e OPENAI_API_KEY=sk-your-openai-api-key \
  -e OPENAI_MODEL=gpt-4o-mini \
  -e APP_USERNAME=CathaySEA \
  -e APP_PASSWORD=CathaySEA \
  seanews-app:latest
```

#### 3. 查看日誌

```bash
docker logs -f seanews
```

#### 4. 停止容器

```bash
docker stop seanews
docker rm seanews
```

---

## 📦 Zeabur 部署配置

### 方法 A: 使用 Dockerfile 部署（推薦）

1. **將代碼推送到 Git**
   ```bash
   git add Dockerfile .dockerignore
   git commit -m "添加 Docker 配置"
   git push
   ```

2. **在 Zeabur 控制台設置環境變量**
   - `OPENAI_API_KEY`: 你的 OpenAI API 金鑰
   - `OPENAI_MODEL`: gpt-4o-mini
   - `APP_USERNAME`: CathaySEA
   - `APP_PASSWORD`: CathaySEA
   - `PORT`: 8787（Zeabur 會自動設置）

3. **Zeabur 會自動檢測到 Dockerfile 並構建**
   - 前端會在構建階段編譯
   - 後端 FastAPI 服務器會正確運行
   - 靜態文件由 FastAPI 的 StaticFiles 提供

### 方法 B: 修改 Procfile（備選）

如果不想使用 Docker，可以修改 `Procfile`：

```procfile
web: npm run build && cd server && uvicorn agno_api:app --host 0.0.0.0 --port $PORT
```

但這樣每次部署都會重新構建前端，較慢且不推薦。

---

## 🔍 驗證部署

### 1. 檢查健康狀態

```bash
curl http://localhost:8787/api/health
# 應該返回: {"ok": true}
```

### 2. 測試登入 API

```bash
curl -X POST http://localhost:8787/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"CathaySEA","password":"CathaySEA"}'
```

應該返回：
```json
{
  "success": true,
  "token": "some-token-string"
}
```

### 3. 查看容器日誌

部署成功後應該看到：
```
✅ 檢測到 XX 個 API 路由
✅ 靜態文件服務已啟用 (html=True): /app/dist
INFO:     Uvicorn running on http://0.0.0.0:8787 (Press CTRL+C to quit)
```

---

## 📋 Dockerfile 架構說明

### 多階段構建

```dockerfile
# Stage 1: 前端構建
FROM node:20-alpine AS frontend-builder
# 安裝依賴 → 構建前端 → 產生 dist/

# Stage 2: 後端運行
FROM python:3.11-slim
# 安裝 Python 依賴
# 複製後端代碼
# 複製前端構建產物（dist/）
# 運行 uvicorn 伺服器
```

### 優勢

1. **完整應用部署**
   - ✅ 前端靜態文件
   - ✅ 後端 API 服務器
   - ✅ 單一容器，簡化部署

2. **正確的路由處理**
   - API 請求（/api/*）→ FastAPI 處理
   - 靜態文件請求 → StaticFiles 處理
   - SPA 路由 → 返回 index.html

3. **生產環境優化**
   - 多階段構建，減小鏡像大小
   - 使用 slim 基礎鏡像
   - 健康檢查配置

---

## 🐛 常見問題排查

### 問題 1: 構建失敗

**錯誤：** `npm ci` 或 `pip install` 失敗

**解決：**
```bash
# 清理 Docker 緩存
docker builder prune -a

# 重新構建
docker-compose build --no-cache
```

### 問題 2: 無法訪問 API

**錯誤：** 登入仍然 405

**檢查：**
```bash
# 1. 確認容器正在運行
docker ps

# 2. 查看容器日誌
docker logs seanews

# 3. 進入容器檢查
docker exec -it seanews sh
ls -la /app/dist  # 確認前端文件存在
curl localhost:8787/api/health  # 測試 API
```

### 問題 3: 環境變量未生效

**檢查：**
```bash
# 查看容器環境變量
docker exec seanews env | grep OPENAI_API_KEY
```

**解決：**
- 確保 `.env` 文件存在且正確
- 或在 `docker run` 時使用 `-e` 明確設置

---

## 🎯 部署檢查清單

### 本地測試
- [ ] `docker-compose up` 成功啟動
- [ ] 訪問 `http://localhost:8787` 看到登入頁面
- [ ] 登入功能正常（不再 405）
- [ ] 健康檢查 `/api/health` 返回 200

### Zeabur 部署
- [ ] 推送 Dockerfile 到 Git
- [ ] Zeabur 檢測到 Dockerfile
- [ ] 設置所有環境變量
- [ ] 構建成功（查看日誌）
- [ ] 應用正常運行
- [ ] 登入功能測試通過

---

## 📊 性能優化建議

### 1. 鏡像大小優化

當前配置已使用：
- `node:20-alpine` - 輕量級 Node.js
- `python:3.11-slim` - 輕量級 Python
- 多階段構建 - 只保留必要文件

### 2. 啟動速度優化

```dockerfile
# 使用依賴緩存
COPY server/requirements.txt ./server/
RUN pip install --no-cache-dir -r server/requirements.txt
# 後才複製代碼，充分利用 Docker 緩存層
```

### 3. 生產環境配置

```bash
# 設置生產環境變量
ENV PYTHONUNBUFFERED=1  # 即時輸出日誌
ENV PORT=8787
```

---

## 🔗 相關文件

- [Dockerfile](./Dockerfile) - Docker 鏡像構建配置
- [.dockerignore](./.dockerignore) - Docker 忽略文件
- [docker-compose.yml](./docker-compose.yml) - Docker Compose 配置
- [LOGIN_FIX_CHECKLIST.md](./LOGIN_FIX_CHECKLIST.md) - 登入修復檢查清單

---

## ✅ 總結

使用 Docker 部署後：
- ✅ **前端靜態文件** 正確服務
- ✅ **後端 API** 正常處理請求
- ✅ **登入功能** 不再 405 錯誤
- ✅ **單一容器** 包含完整應用
- ✅ **易於部署** 到任何支持 Docker 的平台

**最後更新：** 2026-01-13  
**Docker 版本：** v1.0
