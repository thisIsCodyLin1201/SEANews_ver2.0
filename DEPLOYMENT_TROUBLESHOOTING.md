# 🔍 部署问题排查指南

## 当前配置状态

### ✅ 已完成的配置

1. **前端 API 地址智能切换** (`src/App.jsx`)
   ```javascript
   const apiBase = import.meta.env.DEV 
     ? (import.meta.env.VITE_API_URL || 'http://localhost:8787')
     : '';  // 生产环境使用相对路径
   ```

2. **后端静态文件服务** (`server/agno_api.py`)
   - 已添加 `FileResponse` 和 `StaticFiles` 导入
   - 已配置 `/assets` 静态资源路由
   - 已配置 SPA 回退路由（所有非 API 请求返回 `index.html`）

3. **后端动态端口支持** (`package.json`)
   ```json
   "start:prod": "cd server && python -m uvicorn agno_api:app --host 0.0.0.0 --port ${PORT:-8787}"
   ```

4. **CORS 配置** (`server/agno_api.py`)
   ```python
   app.add_middleware(
       CORSMiddleware,
       allow_origins=["*"],
       allow_methods=["*"],
       allow_headers=["*"],
   )
   ```

---

## 🚨 登录错误排查步骤

### 问题描述
登录时出现错误，前端无法成功调用 `/api/auth/login`

### 可能原因及解决方案

#### 1️⃣ **前端未正确构建**

**症状**: 访问部署地址显示空白或 404

**检查**:
```bash
# 本地测试构建
npm run build

# 检查 dist 目录是否存在
ls dist/

# 应该看到:
# - index.html
# - assets/
```

**解决**:
```bash
# Zeabur 构建命令设置为:
npm install && npm run build
```

---

#### 2️⃣ **后端未启动或端口错误**

**症状**: API 请求返回 404 或连接超时

**检查 Zeabur 日志**:
```
启动成功应显示:
INFO:     Uvicorn running on http://0.0.0.0:XXXX
INFO:     Application startup complete.
```

**解决**:
确保 Zeabur 启动命令为:
```bash
cd server && uvicorn agno_api:app --host 0.0.0.0 --port $PORT
```

或使用 `npm run start:prod`（需要先安装依赖）

---

#### 3️⃣ **环境变量未设置**

**症状**: 登录总是失败，或后端报错

**必须在 Zeabur 设置的环境变量**:
```env
OPENAI_API_KEY=你的key
OPENAI_MODEL=gpt-5.2-2025-12-11
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
EMAIL_ADDRESS=你的邮箱
EMAIL_PASSWORD=你的密码
APP_USERNAME=CathaySEA
APP_PASSWORD=CathaySEA
APP_SECRET_KEY=cathay-sea-news-secret-key-2026
```

**不需要设置**:
- `PORT` (Zeabur 自动注入)
- `VITE_API_URL` (生产环境不需要)

---

#### 4️⃣ **路由冲突**

**症状**: API 请求返回 HTML 而不是 JSON

**原因**: 静态文件服务的 `/{full_path:path}` 路由捕获了 API 请求

**检查**: `server/agno_api.py` 文件末尾的路由顺序
```python
# ✅ 正确顺序（API 路由必须在前）
@app.post("/api/auth/login")  # 在前
# ... 其他 API 路由

# 静态文件服务（在最后）
@app.get("/{full_path:path}")  # 在后
```

---

#### 5️⃣ **前后端部署方式不匹配**

**情况 A: 单服务部署（推荐）**
- 前端构建后由后端提供
- 前端使用空字符串 `apiBase = ''`
- 所有请求同域名，无 CORS 问题

**Zeabur 配置**:
```bash
# 构建命令
npm install && npm run build && cd server && pip install -r requirements.txt

# 启动命令
cd server && uvicorn agno_api:app --host 0.0.0.0 --port $PORT
```

**情况 B: 前后端分离部署**
- 前端和后端分别部署
- 前端需要设置 `VITE_API_URL` 指向后端域名
- 需要确保 CORS 配置正确

**前端环境变量**:
```env
VITE_API_URL=https://你的后端域名
```

---

## 🔧 本地测试生产模式

### 1. 构建前端
```bash
npm run build
```

### 2. 启动后端（生产模式）
```bash
# 方式 1: 直接启动
cd server
uvicorn agno_api:app --host 0.0.0.0 --port 8787

# 方式 2: 使用 npm script
npm run start:prod
```

### 3. 访问测试
```bash
# 打开浏览器访问
http://localhost:8787

# 应该能看到前端页面
# API 应该正常工作
```

### 4. 检查控制台
```
浏览器 F12 → Network 标签
- 查看 /api/auth/login 请求
- Status 应该是 200
- Response 应该是 JSON: {"success": true, "token": "..."}
```

---

## 📝 Zeabur 部署完整流程

### 步骤 1: 准备代码
```bash
git add .
git commit -m "feat: 完整部署配置"
git push origin main
```

### 步骤 2: Zeabur 创建服务
1. 登录 Zeabur
2. 创建新服务
3. 连接 Git 仓库
4. 选择分支（main）

### 步骤 3: 配置环境变量
在 Zeabur 服务设置中添加所有必要的环境变量（参考上面）

### 步骤 4: 配置构建和启动
**构建命令**:
```bash
npm install && npm run build && cd server && pip install -r requirements.txt
```

**启动命令**（选择其一）:
```bash
# 方式 1: 直接启动（推荐）
cd server && uvicorn agno_api:app --host 0.0.0.0 --port $PORT

# 方式 2: 使用 Procfile
# (Zeabur 会自动检测 Procfile)
```

### 步骤 5: 部署并检查
1. 点击"部署"
2. 查看构建日志
3. 等待部署完成
4. 访问分配的域名
5. 测试登录功能

---

## 🐛 常见错误及解决

### 错误 1: "连线失败"
**原因**: 前端无法连接后端
**解决**: 
- 检查后端是否正常启动
- 检查 Zeabur 日志中的端口号
- 确认没有防火墙阻挡

### 错误 2: "登入失败"
**原因**: 用户名或密码错误
**解决**: 
- 检查 Zeabur 环境变量中的 `APP_USERNAME` 和 `APP_PASSWORD`
- 确保值与前端输入一致

### 错误 3: 404 Not Found
**原因**: 路由配置问题
**解决**:
- 检查 `server/agno_api.py` 中 API 路由是否在静态文件路由之前
- 确认前端构建成功（`dist` 目录存在）

### 错误 4: CORS 错误
**原因**: 跨域配置问题
**解决**:
- 确认 CORS 中间件已配置 `allow_origins=["*"]`
- 如果是分离部署，确认后端域名在允许列表中

### 错误 5: 500 Internal Server Error
**原因**: 后端代码错误或环境变量缺失
**解决**:
- 查看 Zeabur 后端日志
- 检查所有必需的环境变量是否已设置
- 确认 `requirements.txt` 中的依赖已安装

---

## ✅ 部署验证清单

部署完成后，依次检查以下项目：

- [ ] 前端页面能正常访问
- [ ] 登录功能正常
- [ ] 能查看新闻列表
- [ ] 能生成新新闻
- [ ] Excel 导出功能正常
- [ ] 邮件发送功能正常
- [ ] 所有 API 请求返回正确
- [ ] 无 CORS 错误
- [ ] 无控制台错误

---

## 📞 需要帮助？

如果以上步骤都无法解决问题：

1. **收集信息**:
   - Zeabur 构建日志
   - Zeabur 运行时日志
   - 浏览器控制台错误
   - Network 请求详情

2. **本地复现**:
   ```bash
   npm run build
   npm run start:prod
   # 访问 http://localhost:8787
   ```

3. **对比差异**:
   - 本地能工作，部署不行 → 环境变量或构建问题
   - 本地也不行 → 代码问题

4. **逐步排查**:
   - 先确认后端能启动
   - 再确认前端能访问
   - 最后测试 API 功能
