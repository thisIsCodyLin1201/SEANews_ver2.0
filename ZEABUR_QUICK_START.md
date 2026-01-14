# 🚀 Zeabur 快速部署指南

5 分鐘內將 SEANews 部署到 Zeabur 雲端平台！

## 📋 前置要求

- ✅ GitHub 帳號
- ✅ Zeabur 帳號（[免費註冊](https://zeabur.com)）
- ✅ OpenAI API Key

## 🏃 快速步驟

### 步驟 1：準備代碼（1 分鐘）

```bash
# 確保在正確的分支
git checkout bugfix/部屬重新修復

# 推送到 GitHub
git push origin bugfix/部屬重新修復
```

### 步驟 2：創建 Zeabur 項目（30 秒）

1. 訪問 [Zeabur Dashboard](https://zeabur.com/dashboard)
2. 點擊 **"Create Project"**
3. 選擇區域（建議：香港或新加坡）

### 步驟 3：連接 GitHub（30 秒）

1. 點擊 **"Add Service"**
2. 選擇 **"Deploy your source code"**
3. 授權 GitHub（如果還沒授權）
4. 選擇 `SEANews_ver2.0` 倉庫
5. 選擇 `bugfix/部屬重新修復` 分支

### 步驟 4：配置環境變量（2 分鐘）

點擊服務 → **"Environment Variables"** → 添加以下變量：

```env
OPENAI_API_KEY=sk-proj-你的密鑰
OPENAI_MODEL=gpt-5.2-2025-12-11
APP_USERNAME=CathaySEA
APP_PASSWORD=你的密碼
APP_SECRET_KEY=cathay-sea-news-secret-key-2026
```

**可選**（郵件功能）：
```env
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
EMAIL_ADDRESS=your-email@gmail.com
EMAIL_PASSWORD=your-app-password
```

⚠️ **重要**：不要設置 `PORT`，Zeabur 會自動管理！

### 步驟 5：部署（2-3 分鐘）

1. 環境變量保存後，Zeabur 自動開始構建
2. 等待構建完成（綠色 ✓ 表示成功）
3. 點擊自動生成的域名

### 步驟 6：驗證（30 秒）

訪問你的應用：

1. 打開 Zeabur 提供的域名（如 `https://your-app.zeabur.app`）
2. 應該看到登錄頁面
3. 使用配置的用戶名密碼登錄
4. 測試發送新聞搜索請求

## ✅ 驗證清單

部署成功後檢查：

- [ ] 前端頁面正常顯示
- [ ] 登錄功能正常
- [ ] API 健康檢查：訪問 `https://your-app.zeabur.app/api/health` 應返回 `{"ok":true}`
- [ ] 可以發送新聞搜索請求
- [ ] AI 回覆正常

## 🎉 完成！

恭喜！你的應用已經成功部署到 Zeabur。

### 下一步

1. **配置自定義域名**（可選）
   - 在 Zeabur 服務設置 → Domains
   - 添加你的域名
   - 配置 DNS CNAME 記錄

2. **監控日誌**
   - 點擊服務 → Logs
   - 查看實時運行日誌

3. **設置監控告警**
   - 在 Zeabur 項目設置中配置
   - 設置資源使用告警

## 🔄 更新應用

每次推送代碼到 GitHub，Zeabur 會自動重新部署：

```bash
# 修改代碼
git add .
git commit -m "你的更新說明"
git push origin bugfix/部屬重新修復

# Zeabur 自動檢測並重新部署
```

## 🆘 遇到問題？

### 構建失敗
- 查看構建日誌
- 確認所有環境變量已設置
- 檢查 GitHub 分支是否正確

### 無法訪問
- 確認容器正在運行（綠色狀態）
- 檢查健康檢查是否通過
- 查看容器日誌

### API 錯誤
- 確認 OPENAI_API_KEY 正確
- 檢查 API 配額是否用完
- 查看後端日誌

詳細故障排查：[ZEABUR_DEPLOYMENT.md](./ZEABUR_DEPLOYMENT.md#故障排查)

## 📚 深入了解

- [完整部署指南](./ZEABUR_DEPLOYMENT.md) - 詳細說明和最佳實踐
- [版本對比](./DOCKERFILE_COMPARISON.md) - Dockerfile 優化說明
- [適配總結](./ZEABUR_ADAPTATION_SUMMARY.md) - 完整更改清單

## 💡 小貼士

1. **環境變量更新後**需要手動重新部署（點擊 "Redeploy"）
2. **自動部署**僅在 Git push 時觸發
3. **日誌保留**有限，建議定期檢查
4. **免費額度**適合開發測試，生產環境建議升級計劃
5. **數據庫**需要持久化請使用 Zeabur 的 Volumes 功能

## 🎯 估算成本

假設使用情況：
- CPU: 0.5 vCPU
- 內存: 512MB
- 24/7 運行

**預估**：約 $5-10/月（具體以 Zeabur 實際計費為準）

提示：開發環境可以啟用睡眠模式以節省成本。

---

**部署愉快！** 🚀

如有問題歡迎查看詳細文檔或聯繫支援。
