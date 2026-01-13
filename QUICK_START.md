# 🚀 快速部署指南

## 問題診斷：Zeabur 405 錯誤根因

### ❌ 原因
Zeabur 使用 **Caddy 靜態伺服器** 部署，只能提供靜態文件（HTML/CSS/JS），**無法處理後端 API 請求**（如 POST `/api/auth/login`）。

### ✅ 解決方案
使用 **Docker** 部署完整應用（前端 + FastAPI 後端）。

---

## 🐳 Docker 快速部署

### 方案 1: Docker Compose（最簡單）

```bash
# 1. 創建 .env 文件
cat > .env << EOF
OPENAI_API_KEY=sk-your-api-key
OPENAI_MODEL=gpt-4o-mini
APP_USERNAME=CathaySEA
APP_PASSWORD=CathaySEA
EOF

# 2. 一鍵啟動
docker-compose up -d

# 3. 訪問應用
# 打開 http://localhost:8787
```

### 方案 2: 純 Docker

```bash
# 1. 構建鏡像
docker build -t seanews-app .

# 2. 運行容器
docker run -d \
  --name seanews \
  -p 8787:8787 \
  --env-file .env \
  seanews-app:latest

# 3. 訪問應用
# 打開 http://localhost:8787
```

### 方案 3: 自動化測試腳本

**Windows:**
```bash
docker-test.bat
```

**Linux/Mac:**
```bash
chmod +x docker-test.sh && ./docker-test.sh
```

---

## 📦 Zeabur 部署（使用 Docker）

### 步驟 1: 推送代碼

```bash
git add Dockerfile .dockerignore docker-compose.yml
git commit -m "添加 Docker 配置以修復 405 錯誤"
git push origin bugfix/dockerfile
```

### 步驟 2: Zeabur 設置

1. **在 Zeabur 控制台連接 Git 倉庫**
2. **設置環境變量：**
   - `OPENAI_API_KEY`: sk-your-api-key
   - `OPENAI_MODEL`: gpt-4o-mini
   - `APP_USERNAME`: CathaySEA
   - `APP_PASSWORD`: CathaySEA

3. **Zeabur 會自動檢測 Dockerfile 並構建**

### 步驟 3: 驗證部署

1. 打開 Zeabur 提供的網址
2. 應該看到登入頁面
3. 輸入帳號密碼點擊登入
4. **不再出現 405 錯誤** ✅

---

## 🔍 驗證清單

### 本地測試
```bash
# 健康檢查
curl http://localhost:8787/api/health
# 應返回: {"ok": true}

# 登入測試
curl -X POST http://localhost:8787/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"CathaySEA","password":"CathaySEA"}'
# 應返回: {"success": true, "token": "..."}
```

### 日誌檢查
```bash
# Docker Compose
docker-compose logs -f

# 純 Docker
docker logs -f seanews
```

應該看到：
```
✅ 檢測到 XX 個 API 路由
✅ 靜態文件服務已啟用 (html=True): /app/dist
INFO:     Uvicorn running on http://0.0.0.0:8787
```

---

## 📂 新增文件說明

| 文件 | 用途 |
|------|------|
| `Dockerfile` | Docker 鏡像構建配置（多階段構建） |
| `.dockerignore` | Docker 構建時忽略的文件 |
| `docker-compose.yml` | Docker Compose 配置（一鍵啟動） |
| `docker-test.sh` | 自動化測試腳本（Linux/Mac） |
| `docker-test.bat` | 自動化測試腳本（Windows） |
| `DOCKER_DEPLOYMENT.md` | 詳細 Docker 部署文檔 |

---

## 🎯 常用命令

### Docker Compose
```bash
docker-compose up -d          # 啟動
docker-compose logs -f        # 查看日誌
docker-compose down           # 停止
docker-compose restart        # 重啟
docker-compose ps             # 查看狀態
```

### Docker
```bash
docker ps                     # 查看運行中的容器
docker logs -f seanews        # 查看日誌
docker stop seanews           # 停止容器
docker start seanews          # 啟動容器
docker restart seanews        # 重啟容器
docker exec -it seanews sh    # 進入容器
```

---

## 🐛 常見問題

### Q: 構建失敗
```bash
# 清理 Docker 緩存
docker system prune -a
docker-compose build --no-cache
```

### Q: 端口被占用
```bash
# 修改 docker-compose.yml 中的端口
ports:
  - "8788:8787"  # 改用 8788
```

### Q: 環境變量未生效
```bash
# 檢查環境變量
docker exec seanews env | grep OPENAI
```

### Q: 仍然 405 錯誤
1. 確認使用了 Dockerfile 部署（不是 Caddy）
2. 檢查日誌是否有 "Uvicorn running"
3. 測試 `/api/health` 端點

---

## 📚 詳細文檔

- [DOCKER_DEPLOYMENT.md](./DOCKER_DEPLOYMENT.md) - 完整 Docker 部署指南
- [LOGIN_FIX_CHECKLIST.md](./LOGIN_FIX_CHECKLIST.md) - 登入修復檢查清單
- [README.md](./README.md) - 專案說明

---

## ✅ 部署檢查清單

- [ ] `.env` 文件已創建並配置正確
- [ ] Docker 已安裝並運行
- [ ] `docker-compose up` 成功啟動
- [ ] 訪問 `http://localhost:8787` 看到登入頁面
- [ ] 登入功能正常（200 OK，不是 405）
- [ ] 健康檢查通過：`curl http://localhost:8787/api/health`

---

**最後更新:** 2026-01-13  
**分支:** bugfix/dockerfile  
**狀態:** ✅ 準備部署
