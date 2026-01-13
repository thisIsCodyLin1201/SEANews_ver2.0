# 🔧 405 错误修复说明

## 问题原因

**405 Method Not Allowed** 错误是因为静态文件路由配置问题：

```python
# ❌ 错误配置（之前）
@app.get("/{full_path:path}")  # 只允许 GET 方法
async def serve_spa(full_path: str):
    # 这个路由会拦截所有路径，包括 /api/auth/login
    # 当前端发送 POST /api/auth/login 时
    # FastAPI 发现这个路径有路由，但方法不匹配（GET vs POST）
    # 所以返回 405
```

虽然 API 路由 `@app.post("/api/auth/login")` 在前面定义，但 FastAPI 的路由匹配机制会：
1. 先检查路径是否匹配
2. 再检查方法是否匹配
3. 通配路由 `/{full_path:path}` 会匹配所有路径
4. 但它只支持 GET 方法，所以 POST 请求返回 405

## 修复方案

```python
# ✅ 正确配置（现在）
@app.get("/")
async def serve_index():
    # 根路径单独处理
    return FileResponse(dist_path / "index.html")

@app.get("/{full_path:path}")
async def serve_spa(full_path: str):
    # 明确跳过 API 路径
    if full_path.startswith("api/"):
        raise HTTPException(status_code=404)
    
    # 处理静态文件和 SPA 路由
    # ...
```

关键改进：
1. ✅ 根路径 `/` 单独处理
2. ✅ SPA 路由明确跳过 `api/` 开头的路径
3. ✅ 更清晰的错误处理

## 部署步骤

### 1. 提交代码
```bash
git add .
git commit -m "fix: 修复 405 登录错误 - 优化静态文件路由配置"
git push origin bugfix/部屬調整
```

### 2. Zeabur 重新部署
- 代码推送后 Zeabur 会自动重新构建
- 或者在 Zeabur 控制台手动触发部署

### 3. 验证修复

部署完成后，测试以下场景：

**✅ 应该成功**:
- 访问根路径 `/` → 200，显示前端页面
- POST `/api/auth/login` → 200，返回 token
- GET `/assets/xxx.js` → 200，返回静态文件

**✅ 预期错误**:
- GET `/api/auth/login` → 405（方法不允许，这是正确的）
- POST `/api/not-exist` → 404（API 不存在）

### 4. 本地测试（可选）

在提交前可以本地验证：

```bash
# 构建前端
npm run build

# 启动后端
npm run start:prod

# 在另一个终端测试
bash test-api.sh
```

## 技术细节

### FastAPI 路由优先级

FastAPI 路由匹配顺序：
1. **精确路径优先**（如 `/api/auth/login`）
2. **参数路径次之**（如 `/users/{id}`）
3. **通配路径最后**（如 `/{full_path:path}`）

但是，如果多个路由匹配同一路径，会按以下规则：
- 检查 HTTP 方法是否匹配
- 如果方法不匹配，返回 405
- 如果路径不匹配，返回 404

### 为什么需要跳过 api/ 路径

即使 API 路由定义在前，通配路由 `/{full_path:path}` 仍然会"看到"所有路径。
为了避免混淆，明确在 SPA 路由中跳过 `api/` 开头的路径：

```python
if full_path.startswith("api/"):
    raise HTTPException(status_code=404, detail="API not found")
```

这样：
- 正确的 API 请求会被前面的路由处理
- 错误的 API 路径会得到明确的 404
- 不会因为 GET/POST 方法不匹配而返回 405

## 测试脚本

使用 `test-api.sh` 脚本测试：

```bash
# 测试本地
bash test-api.sh http://localhost:8787

# 测试部署环境
bash test-api.sh https://你的域名
```

预期输出：
```
1️⃣ 测试根路径 GET /
状态码: 200

2️⃣ 测试登录 API POST /api/auth/login
{"success":true,"token":"..."}
状态码: 200

3️⃣ 测试错误方法 GET /api/auth/login（预期 405）
状态码: 405

4️⃣ 测试不存在的 API /api/not-exist
状态码: 404

5️⃣ 测试静态资源 /assets/*
状态码: 200
```

## 总结

修复后的配置：
- ✅ 解决了 405 错误
- ✅ API 路由正常工作
- ✅ 静态文件服务正常
- ✅ SPA 路由回退正常
- ✅ 错误处理更清晰

现在可以安全部署了！🚀
