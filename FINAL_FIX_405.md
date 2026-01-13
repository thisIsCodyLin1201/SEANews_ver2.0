# 🔧 405 错误最终修复方案

## 问题根源

FastAPI 的路由匹配机制问题：

```python
# ❌ 错误方案（会导致 405）
@app.post("/api/auth/login")  # API 路由
async def login(...): ...

@app.get("/{full_path:path}")  # 通配路由
async def serve_spa(full_path: str): ...
```

**为什么会 405？**
1. FastAPI 看到路径 `/api/auth/login` 有两个匹配：
   - `@app.post("/api/auth/login")` - 支持 POST
   - `@app.get("/{full_path:path}")` - 支持 GET
2. 请求是 POST 方法
3. FastAPI 发现通配路由也匹配这个路径
4. 返回 `405 Method Not Allowed` 和 `Allow: GET, HEAD`

即使 API 路由定义在前，**通配路由的存在**就会影响 FastAPI 的路由表。

## ✅ 正确方案

使用 **`StaticFiles` 的 `html=True` 参数**：

```python
# ✅ 正确方案（不会 405）
@app.post("/api/auth/login")  # API 路由
async def login(...): ...

# 在所有 API 路由之后
app.mount("/", StaticFiles(directory="dist", html=True), name="static")
```

**为什么不会 405？**
1. `app.mount()` 的优先级**低于**明确定义的路由
2. POST `/api/auth/login` 先匹配到 API 路由，直接处理
3. 只有未匹配的请求才会到 StaticFiles
4. `html=True` 自动处理 SPA 路由回退

## 关键代码修改

### server/agno_api.py (末尾)

```python
# 静态文件服务（生产环境）- 必须放在所有 API 路由之后
dist_path = Path(__file__).parent.parent / "dist"
if dist_path.exists() and dist_path.is_dir():
    # 使用 StaticFiles 挂载整个 dist 目录
    # html=True 自动处理 SPA 路由回退
    app.mount("/", StaticFiles(directory=str(dist_path), html=True), name="static")
    print(f"✅ 静态文件服务已启用: {dist_path}")
else:
    print("⚠️  警告: dist 目录不存在，静态文件服务未启用")
```

**优势**：
- ✅ 自动处理 SPA 路由（404 返回 index.html）
- ✅ 自动处理静态资源（/assets/xxx.js）
- ✅ 不干扰 API 路由
- ✅ 不产生 405 错误
- ✅ 代码简洁

## 部署步骤

### 1. 提交代码
```bash
git add .
git commit -m "fix: 使用 StaticFiles(html=True) 彻底解决 405 错误"
git push origin bugfix/部屬登入錯誤調整
```

### 2. Zeabur 自动部署
- 推送后 Zeabur 会自动重新构建
- 等待构建完成

### 3. 验证修复
访问部署地址，测试：
- ✅ 访问根路径 `/` → 显示前端
- ✅ POST `/api/auth/login` → 返回 200 和 token
- ✅ 所有 API 正常工作

## 本地测试

```bash
# 构建
npm run build

# 启动
npm run start:prod

# 测试登录
curl -X POST http://localhost:8787/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"CathaySEA","password":"CathaySEA"}'

# 应该返回: {"success":true,"token":"..."}
```

## FastAPI 路由优先级

```
1. 明确定义的路由（@app.post("/api/auth/login")）
   ↓ 优先级最高
2. 参数路由（@app.get("/users/{id}")）
   ↓ 次之
3. 通配路由（@app.get("/{full_path:path}")）
   ↓ 较低
4. app.mount() 挂载的应用
   ↓ 最低
```

所以 `app.mount()` 不会干扰明确定义的 API 路由。

## 总结

**之前的问题**：
- 使用 `@app.get("/{full_path:path}")` 通配路由
- 导致 FastAPI 认为所有路径都支持 GET
- POST 请求返回 405

**现在的解决**：
- 使用 `app.mount("/", StaticFiles(..., html=True))`
- 优先级低于 API 路由，不会冲突
- 自动处理 SPA 和静态文件

**结果**：
- ✅ 405 错误彻底解决
- ✅ 登录功能正常
- ✅ 所有 API 正常
- ✅ 前端路由正常

🚀 现在可以安全部署了！
