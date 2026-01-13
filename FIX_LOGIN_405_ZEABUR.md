# 🔧 修復 Zeabur 部署 405 登入錯誤

## 問題描述

在 Zeabur 部署後，點擊登入按鈕會出現 405 錯誤，無論是否輸入密碼都返回「連線失敗，請稍後再試」。

## 問題根源

之前的靜態文件服務配置使用了：
1. `@app.get("/")` 路由
2. `@app.middleware("http")` 中間件處理 SPA 路由

這種方式在某些情況下會干擾 FastAPI 的路由匹配機制，導致 POST `/api/auth/login` 請求被誤判為 405。

## 解決方案

✅ **使用 `StaticFiles` 的 `html=True` 參數**

```python
# ✅ 正確方案（不會 405）
@app.post("/api/auth/login")  # API 路由
async def login(...): ...

# 在所有 API 路由之後
app.mount("/", StaticFiles(directory="dist", html=True), name="static")
```

### 為什麼這樣可以解決問題？

1. **`app.mount()` 的優先級低於明確定義的路由**
   - POST `/api/auth/login` 會先匹配到 API 路由，直接處理
   - 只有未匹配的請求才會到 StaticFiles

2. **`html=True` 自動處理 SPA 路由回退**
   - 當請求的文件不存在時，自動返回 `index.html`
   - 不需要額外的中間件或通配路由

3. **避免路由衝突**
   - 移除了 `@app.get("/")` 和 `spa_middleware`
   - 消除了可能導致 405 的路由重疊問題

## 修改內容

### server/agno_api.py

**關鍵修改：**

1. **合併 startup 事件處理器**
   ```python
   @app.on_event("startup")
   async def startup_event():
       """應用啟動時的初始化任務"""
       # 預加載示例 PDF
       preload_sample_pdfs()
       
       # 配置靜態文件服務（必須在所有 API 路由之後）
       dist_path = Path(__file__).parent.parent / "dist"
       if dist_path.exists() and dist_path.is_dir():
           app.mount("/", StaticFiles(directory=str(dist_path), html=True), name="static")
   ```

2. **增強 CORS 配置**
   ```python
   app.add_middleware(
       CORSMiddleware,
       allow_origins=["*"],
       allow_credentials=True,  # ✅ 新增
       allow_methods=["*"],
       allow_headers=["*"],
       expose_headers=["*"],    # ✅ 新增
   )
   ```

3. **移除衝突的路由和中間件**
   - ❌ 移除 `@app.get("/")` 路由
   - ❌ 移除 `@app.middleware("http")` 的 spa_middleware
   - ❌ 移除重複的 `@app.on_event("startup")` 處理器

**修改前的問題：**
- 有兩個 `@app.on_event("startup")` 處理器會衝突
- 使用中間件方式處理 SPA 路由會干擾 API 路由
- CORS 配置不夠完整

**修改後的優勢：**
- 單一的 startup 處理器，邏輯清晰
- `StaticFiles` 的 `html=True` 參數自動處理 SPA 回退
- 完整的 CORS 支持，包括 credentials 和 preflight 請求

## 部署步驟

### 1. 提交代碼

```bash
git add server/agno_api.py
git commit -m "fix: 修復登入 405 錯誤 - 使用 StaticFiles html=True"
git push origin bugfix/登入按鍵問題
```

### 2. 在 Zeabur 重新部署

Zeabur 會自動檢測到代碼變更並重新部署。

### 3. 驗證修復

1. 打開 Zeabur 部署的網站
2. 輸入帳號密碼
3. 點擊登入按鈕
4. 應該能夠正常登入，不再出現 405 錯誤

## 技術細節

### FastAPI 路由優先級

FastAPI 的路由匹配順序：
1. 明確定義的路由（如 `@app.post("/api/auth/login")`）
2. 掛載的子應用（`app.mount()`）
3. 中間件處理

使用 `app.mount()` 確保 API 路由優先級最高，不會被靜態文件服務干擾。

### StaticFiles `html=True` 參數

當設置 `html=True` 時：
- 請求 `/` → 返回 `index.html`
- 請求 `/about` → 返回 `index.html`（SPA 路由）
- 請求 `/assets/main.js` → 返回實際文件
- 請求 `/api/auth/login` → 不匹配，交由 API 路由處理 ✅

### CORS 配置

CORS 中間件配置正確，允許所有來源和方法：
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## 環境變量

確保 `.env` 文件包含：
```env
APP_USERNAME=CathaySEA
APP_PASSWORD=CathaySEA
OPENAI_API_KEY=your_openai_api_key
```

Zeabur 環境變量配置：
- `APP_USERNAME`: CathaySEA
- `APP_PASSWORD`: CathaySEA
- `OPENAI_API_KEY`: 你的 OpenAI API 金鑰

## 相關文件

- [FINAL_FIX_405.md](./FINAL_FIX_405.md) - 之前的 405 錯誤修復文檔
- [FIX_405_ERROR.md](./FIX_405_ERROR.md) - 另一個 405 錯誤修復方案
- [server/agno_api.py](./server/agno_api.py) - 後端 API 實現

## 測試檢查清單

### 本地測試

使用提供的測試腳本：

**Windows:**
```bash
test-login-api.bat
```

**Linux/Mac:**
```bash
chmod +x test-login-api.sh
./test-login-api.sh
```

測試項目：
- [x] 健康檢查 `/api/health` 返回 200
- [ ] OPTIONS 預檢請求返回 200（CORS）
- [ ] POST `/api/auth/login` 正確憑證返回 200 + token
- [ ] POST `/api/auth/login` 錯誤憑證返回 200 + error
- [ ] POST `/api/auth/login` 空憑證返回 200 + error
- [ ] 前端登入流程完整測試

### 生產環境測試（Zeabur）

部署後測試：
- [ ] 訪問網站首頁正常載入
- [ ] 開發者工具檢查無 CORS 錯誤
- [ ] 登入按鈕點擊無 405 錯誤
- [ ] 正確密碼能成功登入
- [ ] 錯誤密碼顯示錯誤訊息
- [ ] 登入後功能正常運作

### 調試方法

**查看 Zeabur 日誌：**
```bash
# 在 Zeabur 控制台查看應用日誌
# 應該能看到：
✅ 檢測到 XX 個 API 路由
✅ 靜態文件服務已啟用 (html=True): /app/dist
```

**瀏覽器開發者工具：**
1. 打開 Network 標籤
2. 點擊登入按鈕
3. 檢查 `/api/auth/login` 請求：
   - Method: POST
   - Status: 200（不是 405）
   - Response: `{"success": true, "token": "..."}`

**CORS 預檢檢查：**
1. 清除瀏覽器緩存
2. 刷新頁面
3. 查看是否有 OPTIONS 請求
4. 檢查 Response Headers:
   - `Access-Control-Allow-Origin: *`
   - `Access-Control-Allow-Methods: *`
   - `Access-Control-Allow-Headers: *`

## 預期結果

✅ 登入成功後應該能看到主應用界面
✅ 不再出現 405 錯誤
✅ 所有 API 請求正常工作
✅ 前端路由正常切換

## 故障排除

如果仍然出現問題：

1. **檢查 Zeabur 日誌**
   ```bash
   # 查看部署日誌
   ```

2. **檢查瀏覽器控制台**
   - 查看網絡請求
   - 檢查 Response Headers
   - 確認請求方法是 POST

3. **檢查環境變量**
   - 確認 Zeabur 環境變量已設置
   - 重新部署後環境變量生效

4. **清除瀏覽器緩存**
   - Ctrl + Shift + R 強制刷新
   - 或清除瀏覽器緩存

## 總結

此修復採用了 FastAPI 推薦的最佳實踐，使用 `StaticFiles` 的 `html=True` 參數來處理 SPA 應用，避免了路由衝突和 405 錯誤。這是最穩定和可靠的解決方案。
