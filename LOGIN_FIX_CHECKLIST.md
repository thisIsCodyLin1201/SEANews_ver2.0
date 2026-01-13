# 🔍 登入 405 錯誤檢查清單

## ✅ 已修復的問題

1. **移除重複的 startup 事件處理器** ✅
   - 合併兩個 `@app.on_event("startup")` 為一個
   - 避免事件處理衝突

2. **使用正確的靜態文件配置** ✅
   - 使用 `app.mount("/", StaticFiles(html=True))`
   - 在 startup 事件中掛載（確保在所有路由之後）
   - 移除 `@app.get("/")` 路由
   - 移除 `spa_middleware` 中間件

3. **增強 CORS 配置** ✅
   - 添加 `allow_credentials=True`
   - 添加 `expose_headers=["*"]`
   - 確保支持 OPTIONS 預檢請求

## 🔧 關鍵修改點

### 1. server/agno_api.py - CORS 配置 (第 1242-1249 行)
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,    # ← 新增
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],      # ← 新增
)
```

### 2. server/agno_api.py - 合併 startup 事件 (第 1278-1298 行)
```python
@app.on_event("startup")
async def startup_event():
    """應用啟動時的初始化任務"""
    # 預加載示例 PDF
    preload_sample_pdfs()
    
    # 配置靜態文件服務（必須在所有 API 路由之後）
    dist_path = Path(__file__).parent.parent / "dist"
    if dist_path.exists() and dist_path.is_dir():
        try:
            api_routes = [r for r in app.routes if hasattr(r, 'path') and r.path.startswith('/api')]
            print(f"✅ 檢測到 {len(api_routes)} 個 API 路由")
            
            # 使用 StaticFiles 的 html=True 參數處理 SPA
            app.mount("/", StaticFiles(directory=str(dist_path), html=True), name="static")
            print(f"✅ 靜態文件服務已啟用 (html=True): {dist_path}")
        except Exception as e:
            print(f"⚠️  掛載靜態文件失敗: {e}")
```

### 3. server/agno_api.py - 登入路由 (第 1302 行)
```python
@app.post("/api/auth/login")
async def login(request: LoginRequest):
    # ... 登入邏輯
```

## 📋 部署前檢查

- [ ] 確認所有修改已保存
- [ ] 運行 `python -m py_compile server/agno_api.py` 確認無語法錯誤
- [ ] 本地測試：`python server/agno_api.py` 或 `uvicorn server.agno_api:app`
- [ ] 使用 `test-login-api.bat` 測試 API 端點
- [ ] 檢查 `.env` 文件包含必要的環境變量

## 🚀 部署步驟

### 1. 提交代碼
```bash
git add .
git commit -m "fix: 修復 Zeabur 登入 405 錯誤 - 完整版

- 合併重複的 startup 事件處理器
- 使用 StaticFiles html=True 處理靜態文件
- 增強 CORS 配置（credentials + expose_headers）
- 移除衝突的路由和中間件
- 添加 API 測試腳本"

git push origin bugfix/登入按鍵問題
```

### 2. 在 Zeabur 重新部署

部署會自動開始，或手動觸發重新部署。

### 3. 驗證部署

**檢查日誌：**
應該能看到：
```
✅ 檢測到 XX 個 API 路由
✅ 靜態文件服務已啟用 (html=True): /app/dist
```

**測試登入：**
1. 打開網站
2. F12 開發者工具 → Network
3. 輸入帳號密碼
4. 點擊登入
5. 檢查 `/api/auth/login` 請求：
   - ✅ Status: 200
   - ✅ Method: POST
   - ✅ Response: `{"success": true, "token": "..."}`
   - ❌ 不應該是 405

## 🐛 如果還是 405

### 檢查項目

1. **確認環境變量**
   ```bash
   # 在 Zeabur 控制台確認
   APP_USERNAME=CathaySEA
   APP_PASSWORD=CathaySEA
   OPENAI_API_KEY=sk-...
   ```

2. **確認構建成功**
   - 檢查 `dist/` 目錄是否存在
   - 確認 `npm run build` 成功執行

3. **查看完整請求**
   ```bash
   # 在瀏覽器開發者工具
   # Network → 點擊 login 請求 → Headers
   
   Request URL: https://your-app.zeabur.app/api/auth/login
   Request Method: POST
   Status Code: 應該是 200，不是 405
   ```

4. **檢查 CORS 預檢**
   ```bash
   # 應該會有一個 OPTIONS 請求
   Request Method: OPTIONS
   Status Code: 200
   ```

## 💡 技術原理

### 為什麼會 405？

**之前的問題：**
```python
# ❌ 問題配置
@app.middleware("http")
async def spa_middleware(request, call_next):
    # 這個中間件會攔截所有請求，包括 API
    # 如果處理不當，會導致路由匹配問題
```

**現在的解決方案：**
```python
# ✅ 正確配置
@app.on_event("startup")
async def startup_event():
    # 在 startup 時掛載靜態文件
    # 確保在所有 API 路由定義之後
    app.mount("/", StaticFiles(html=True))
```

### FastAPI 路由優先級

1. **明確定義的路由**（最高優先級）
   ```python
   @app.post("/api/auth/login")  # ← 優先匹配
   ```

2. **掛載的子應用**
   ```python
   app.mount("/", StaticFiles(...))  # ← 只處理未匹配的請求
   ```

3. **中間件**（最低優先級）
   ```python
   @app.middleware("http")  # ← 全局處理，容易干擾
   ```

### StaticFiles `html=True` 的作用

```python
app.mount("/", StaticFiles(directory="dist", html=True))
```

- 請求 `/` → 返回 `index.html` ✅
- 請求 `/about` → 返回 `index.html`（SPA 路由）✅
- 請求 `/assets/main.js` → 返回實際文件 ✅
- 請求 `/api/auth/login` → 不匹配，交給 API 路由 ✅

## 📚 相關文件

- [FIX_LOGIN_405_ZEABUR.md](./FIX_LOGIN_405_ZEABUR.md) - 詳細修復文檔
- [test-login-api.bat](./test-login-api.bat) - Windows 測試腳本
- [test-login-api.sh](./test-login-api.sh) - Linux/Mac 測試腳本
- [server/agno_api.py](./server/agno_api.py) - 後端主文件

## ✨ 預期結果

✅ 登入成功返回 token
✅ 錯誤密碼返回錯誤訊息
✅ 所有 API 端點正常工作
✅ SPA 路由導航正常
✅ 無 CORS 錯誤
✅ 無 405 錯誤

---

**最後更新：** 2026-01-13
**修復版本：** v2.0 - 完整修復版
