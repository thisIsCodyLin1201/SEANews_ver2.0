# Zeabur 部署指南

本指南說明如何將 SEANews 應用部署到 Zeabur 平台。

## 📋 目錄

- [Zeabur 平台特點](#zeabur-平台特點)
- [部署前準備](#部署前準備)
- [部署步驟](#部署步驟)
- [環境變量配置](#環境變量配置)
- [Dockerfile 優化說明](#dockerfile-優化說明)
- [故障排查](#故障排查)

## 🌟 Zeabur 平台特點

### 核心優勢
1. **一鍵部署**：從 GitHub 直接部署，自動 CI/CD
2. **按量計費**：只為實際使用的資源付費
3. **自動識別**：智能檢測項目類型和框架
4. **環境變量管理**：Web 界面輕鬆管理配置
5. **域名生成**：自動提供 HTTPS 域名
6. **多環境隔離**：支持開發、測試、生產環境

### 技術支持
- ✅ Python (FastAPI, Flask, Django)
- ✅ Node.js (Vite, Next.js, Express)
- ✅ 多階段 Docker 構建
- ✅ 自動環境變量注入
- ✅ 健康檢查
- ✅ 動態端口分配

## 📦 部署前準備

### 1. 確認項目結構
確保項目包含以下文件：
- ✅ `Dockerfile` - 已優化為 Zeabur 專用版本
- ✅ `zbpack.json` - Zeabur 配置文件
- ✅ `.dockerignore` - 排除不必要的文件
- ✅ `server/requirements.txt` - Python 依賴
- ✅ `package.json` - Node.js 依賴

### 2. 推送代碼到 GitHub
```bash
git add .
git commit -m "chore: 準備 Zeabur 部署"
git push origin main
```

### 3. 準備環境變量
確保您有以下環境變量的值：
- `OPENAI_API_KEY` - OpenAI API 密鑰
- `OPENAI_MODEL` - 使用的模型名稱
- `SMTP_SERVER` - SMTP 服務器（郵件功能）
- `SMTP_PORT` - SMTP 端口
- `EMAIL_ADDRESS` - 發件郵箱
- `EMAIL_PASSWORD` - 郵箱密碼或應用密碼
- `APP_USERNAME` - 應用登錄用戶名
- `APP_PASSWORD` - 應用登錄密碼
- `APP_SECRET_KEY` - JWT 密鑰

## 🚀 部署步驟

### 方法 1: 通過 Zeabur Dashboard（推薦）

#### 步驟 1：創建項目
1. 訪問 [Zeabur Dashboard](https://zeabur.com/dashboard)
2. 點擊 "Create Project"
3. 選擇區域（建議選擇離用戶最近的區域）

#### 步驟 2：添加服務
1. 在項目中點擊 "Add Service"
2. 選擇 "Deploy your source code"
3. 連接 GitHub 並授權 Zeabur
4. 選擇 `SEANews_ver2.0` 倉庫
5. 選擇要部署的分支（如 `main`）

#### 步驟 3：配置環境變量
1. 點擊服務設置
2. 進入 "Environment Variables"
3. 添加以下環境變量：

```env
OPENAI_API_KEY=sk-proj-...
OPENAI_MODEL=gpt-5.2-2025-12-11
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
EMAIL_ADDRESS=your-email@gmail.com
EMAIL_PASSWORD=your-app-password
APP_USERNAME=CathaySEA
APP_PASSWORD=CathaySEA
APP_SECRET_KEY=cathay-sea-news-secret-key-2026
```

**注意**：不要設置 `PORT` 環境變量，Zeabur 會自動管理。

#### 步驟 4：觸發部署
1. Zeabur 會自動檢測到 Dockerfile
2. 開始構建過程（約 3-5 分鐘）
3. 構建完成後自動部署

#### 步驟 5：配置域名
1. 在服務設置中找到 "Domains"
2. Zeabur 會自動生成一個域名（如 `seanews.zeabur.app`）
3. 可選：添加自定義域名

### 方法 2: 使用 Deploy Button

在 README.md 中添加部署按鈕：

```markdown
[![Deploy on Zeabur](https://zeabur.com/button.svg)](https://zeabur.com/templates/your-template-id)
```

### 方法 3: 使用 Zeabur CLI

```bash
# 安裝 Zeabur CLI
npm install -g @zeabur/cli

# 登錄
zeabur auth login

# 部署
zeabur deploy
```

## 🔧 環境變量配置

### 必需的環境變量

| 變量名 | 說明 | 示例值 |
|--------|------|--------|
| `OPENAI_API_KEY` | OpenAI API 密鑰 | `sk-proj-...` |
| `OPENAI_MODEL` | OpenAI 模型 | `gpt-5.2-2025-12-11` |
| `APP_USERNAME` | 登錄用戶名 | `CathaySEA` |
| `APP_PASSWORD` | 登錄密碼 | `YourSecurePassword` |
| `APP_SECRET_KEY` | JWT 密鑰 | `your-secret-key-here` |

### 可選的環境變量（郵件功能）

| 變量名 | 說明 | 示例值 |
|--------|------|--------|
| `SMTP_SERVER` | SMTP 服務器 | `smtp.gmail.com` |
| `SMTP_PORT` | SMTP 端口 | `587` |
| `EMAIL_ADDRESS` | 發件郵箱 | `your-email@gmail.com` |
| `EMAIL_PASSWORD` | 郵箱密碼 | `your-app-password` |

### Zeabur 自動管理的變量

以下變量由 Zeabur 自動設置，**不需要手動配置**：

- `PORT` - 服務端口（Zeabur 動態分配）
- `ZEABUR_SERVICE_ID` - 服務 ID
- `ZEABUR_ENVIRONMENT` - 環境名稱
- `ZEABUR_GIT_COMMIT_SHA` - Git 提交 SHA
- `ZEABUR_GIT_BRANCH` - Git 分支名稱

## 📝 Dockerfile 優化說明

### Zeabur 專用優化

本項目的 Dockerfile 已針對 Zeabur 平台優化：

#### 1. 動態端口支持
```dockerfile
# 使用 PORT 環境變量（Zeabur 自動設置）
CMD sh -c "python -m uvicorn agno_api:app --host 0.0.0.0 --port ${PORT} --log-level info"
```

#### 2. 構建階段環境變量
```dockerfile
# 支持 Zeabur 的 ARG 注入
ARG BUILDTIME_ENV_EXAMPLE
ARG VITE_API_URL
```

#### 3. 健康檢查適配
```dockerfile
# 使用動態 PORT 環境變量
HEALTHCHECK CMD curl -f http://localhost:${PORT:-8000}/api/health || exit 1
```

#### 4. 映像大小優化
- 使用 `alpine` 基礎映像（前端）
- 使用 `slim` Python 映像（後端）
- 清理 apt 緩存
- `--no-cache-dir` pip 安裝
- 合併 RUN 指令減少層數

#### 5. 網絡優化移除
Zeabur 提供穩定的國際網絡，**移除了**：
- ❌ 阿里雲 PyPI 鏡像
- ❌ 清華 PyPI 鏡像
- ❌ 多鏡像回退邏輯

直接使用官方 PyPI，構建更快更可靠。

### 與本地 Docker 的差異

| 特性 | 本地 Docker | Zeabur |
|------|-------------|--------|
| 端口 | 固定 8787 | 動態（通過 PORT 變量） |
| PyPI 源 | 多鏡像回退 | 直接官方源 |
| 環境變量 | 需要 .env 文件 | Web 界面管理 |
| HTTPS | 需要手動配置 | 自動提供 |
| 域名 | localhost | 自動生成 .zeabur.app |

## 🔍 部署驗證

### 1. 檢查構建日誌
在 Zeabur Dashboard 中：
1. 選擇服務
2. 點擊 "Logs" 標籤
3. 查看構建和運行日誌

預期看到：
```
[OK] 新聞資料庫已初始化
INFO: Application startup complete
INFO: Uvicorn running on http://0.0.0.0:8000
```

### 2. 測試健康檢查
```bash
curl https://your-domain.zeabur.app/api/health
# 預期輸出: {"ok":true}
```

### 3. 測試前端訪問
訪問 `https://your-domain.zeabur.app`，應該看到登錄頁面。

### 4. 測試 API 端點
```bash
# 測試登錄
curl -X POST https://your-domain.zeabur.app/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"CathaySEA","password":"CathaySEA"}'
```

## ⚠️ 故障排查

### 問題 1：構建失敗 "Cannot find module"

**原因**：Node.js 依賴安裝失敗

**解決方案**：
1. 檢查 `package.json` 是否正確
2. 在環境變量中添加 `NPM_CONFIG_LOGLEVEL=verbose`
3. 查看詳細構建日誌

### 問題 2：Python 依賴安裝超時

**原因**：網絡問題或依賴版本衝突

**解決方案**：
```bash
# 在本地測試依賴安裝
pip install -r server/requirements.txt

# 如果失敗，更新 requirements.txt 中的版本
```

### 問題 3：容器啟動後立即退出

**原因**：模塊導入錯誤或端口綁定問題

**解決方案**：
1. 檢查日誌中的錯誤信息
2. 確認 `PYTHONPATH` 設置正確
3. 驗證 `WORKDIR` 路徑
4. 確保沒有手動設置 `PORT` 環境變量

### 問題 4：健康檢查失敗

**原因**：端口不匹配或服務未啟動

**解決方案**：
1. 確認 Dockerfile 中使用 `${PORT}` 變量
2. 檢查 uvicorn 是否正常啟動
3. 延長 `--start-period` 時間

### 問題 5：前端無法連接後端 API

**原因**：CORS 或 API 路徑配置錯誤

**解決方案**：
1. 檢查 `src/App.jsx` 中的 `apiBase` 配置
2. 確認後端 CORS 設置允許前端域名
3. 查看瀏覽器控制台的網絡請求

### 問題 6：環境變量未生效

**原因**：環境變量設置位置錯誤

**解決方案**：
1. 在 Zeabur Dashboard 的服務設置中添加
2. **不要**在 Dockerfile 中硬編碼敏感信息
3. 重新部署服務以應用新的環境變量

## 📊 監控和日誌

### 查看實時日誌
```bash
# 通過 Zeabur Dashboard
1. 選擇服務
2. 點擊 "Logs"
3. 實時查看應用日誌
```

### 查看服務指標
在 Dashboard 中可以看到：
- CPU 使用率
- 內存使用量
- 網絡流量
- 請求延遲

### 日誌級別
應用使用 `--log-level info`，可通過環境變量調整：
```env
LOG_LEVEL=debug  # 更詳細的日誌
```

## 🔄 更新和回滾

### 自動部署
Zeabur 會在以下情況自動重新部署：
- Git 倉庫有新提交推送到選定分支
- 環境變量更改
- 手動觸發重新部署

### 手動觸發部署
1. 在 Dashboard 中選擇服務
2. 點擊 "Redeploy" 按鈕

### 回滾到之前的版本
1. 在 "Deployments" 標籤查看歷史部署
2. 選擇要回滾的版本
3. 點擊 "Rollback"

## 💰 成本優化

### 資源使用建議
- **開發環境**：0.25 vCPU, 256MB RAM
- **測試環境**：0.5 vCPU, 512MB RAM  
- **生產環境**：1 vCPU, 1GB RAM（可根據負載調整）

### 節省成本技巧
1. **使用睡眠模式**：不活躍時自動暫停
2. **優化依賴**：移除不必要的 Python 包
3. **啟用緩存**：減少構建時間
4. **監控使用量**：定期檢查資源使用情況

## 🔐 安全最佳實踐

### 1. 環境變量管理
- ✅ 使用 Zeabur 環境變量功能
- ❌ 不要在代碼中硬編碼密鑰
- ❌ 不要提交 `.env` 文件到 Git

### 2. API 密鑰
- 定期輪換 OPENAI_API_KEY
- 使用強密碼作為 APP_SECRET_KEY
- 限制 API 密鑰的權限範圍

### 3. 訪問控制
- 配置 IP 白名單（如需要）
- 啟用應用級別的身份驗證
- 定期審查訪問日誌

## 📚 參考資源

- [Zeabur 官方文檔](https://zeabur.com/docs)
- [Zeabur Python 部署指南](https://zeabur.com/docs/guides/python)
- [Zeabur Vite 部署指南](https://zeabur.com/docs/guides/nodejs/vite)
- [Zeabur Dockerfile 部署](https://zeabur.com/docs/deploy/dockerfile)
- [Zeabur 環境變量](https://zeabur.com/docs/deploy/variables)

## 🆘 獲取幫助

如果遇到問題：
1. 查看 [Zeabur 文檔](https://zeabur.com/docs)
2. 加入 [Zeabur Discord](https://zeabur.com/dc)
3. 查看 [GitHub Issues](https://github.com/zeabur/zeabur)
4. 聯繫 Zeabur 支持團隊

## ✅ 部署檢查清單

部署前確認：
- [ ] 代碼已推送到 GitHub
- [ ] Dockerfile 已更新為 Zeabur 版本
- [ ] zbpack.json 已創建
- [ ] .dockerignore 已配置
- [ ] 所有環境變量已準備好
- [ ] 本地測試通過

部署後驗證：
- [ ] 構建成功完成
- [ ] 容器正常運行
- [ ] 健康檢查通過
- [ ] 前端頁面可訪問
- [ ] API 端點正常響應
- [ ] 登錄功能正常
- [ ] 日誌無錯誤信息

---

**部署愉快！** 🚀

如有問題，請查看故障排查部分或聯繫技術支持。
