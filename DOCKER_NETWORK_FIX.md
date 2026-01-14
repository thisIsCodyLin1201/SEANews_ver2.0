# Docker 構建網絡問題解決方案

## ❌ 錯誤描述
```
ERROR: Could not find a version that satisfies the requirement agno==2.3.18
Connection refused when trying to connect to PyPI
```

## 🔧 解決方案

### 方案 1：使用中國 PyPI 鏡像（推薦）✅

Dockerfile 已更新為自動嘗試多個鏡像源：
1. 阿里雲鏡像（最快）
2. 清華大學鏡像（備用）
3. 官方 PyPI（最後備用）

**直接重新構建即可：**
```bash
docker build -t seanews:latest .
```

---

### 方案 2：檢查 Docker 網絡設置

#### Windows (Docker Desktop)

1. **檢查 DNS 設置**
   - 打開 Docker Desktop
   - Settings → Docker Engine
   - 添加 DNS 配置：
   ```json
   {
     "dns": ["8.8.8.8", "8.8.4.4", "114.114.114.114"]
   }
   ```
   - 點擊 "Apply & Restart"

2. **檢查代理設置**
   如果使用公司網絡/VPN：
   - Settings → Resources → Proxies
   - 設置 HTTP/HTTPS 代理（如果適用）

3. **重啟 Docker Desktop**
   ```powershell
   # 完全重啟 Docker
   Stop-Service docker
   Start-Service docker
   ```

---

### 方案 3：使用宿主機網絡構建

**Windows PowerShell：**
```powershell
# 使用宿主機網絡構建
$env:DOCKER_BUILDKIT=1
docker build --network=host -t seanews:latest .
```

**或使用 docker-compose：**
```bash
docker-compose build --network=host
```

---

### 方案 4：手動下載依賴（離線安裝）

如果網絡持續有問題，可以預先下載所有依賴：

```bash
# 1. 在本地下載所有依賴
pip download -r server/requirements.txt -d ./pip-packages

# 2. 修改 Dockerfile，從本地安裝
# 在 Dockerfile 中添加：
# COPY ./pip-packages /tmp/pip-packages
# RUN pip install --no-index --find-links=/tmp/pip-packages -r server/requirements.txt
```

---

### 方案 5：臨時修改 requirements.txt

如果 `agno` 無法安裝，可以嘗試：

```bash
# 檢查 agno 是否有其他版本可用
pip index versions agno

# 或嘗試不固定版本
# 將 agno==2.3.18 改為 agno>=2.3.0
```

---

## 🧪 測試網絡連接

### 測試 Docker 容器網絡
```bash
# 運行測試容器
docker run --rm python:3.11-slim sh -c "pip install --index-url https://mirrors.aliyun.com/pypi/simple/ requests && python -c 'import requests; print(requests.get(\"https://pypi.org\").status_code)'"
```

### 測試 PyPI 鏡像可用性
```bash
# 測試阿里雲鏡像
curl -I https://mirrors.aliyun.com/pypi/simple/

# 測試清華鏡像
curl -I https://pypi.tuna.tsinghua.edu.cn/simple/

# 測試官方 PyPI
curl -I https://pypi.org/simple/
```

---

## 🚀 推薦執行步驟

### 步驟 1：清理舊構建緩存
```bash
# 清理 Docker 構建緩存
docker builder prune -a -f

# 清理所有未使用的資源
docker system prune -a -f
```

### 步驟 2：重新構建（使用新的 Dockerfile）
```bash
# 使用更新後的 Dockerfile 構建
docker build -t seanews:latest .

# 或使用 docker-compose
docker-compose build
```

### 步驟 3：查看詳細日誌
```bash
# 查看完整構建日誌
docker build -t seanews:latest . --progress=plain --no-cache
```

---

## 📊 常見錯誤對照表

| 錯誤信息 | 原因 | 解決方案 |
|---------|------|----------|
| `Connection refused` | Docker 容器無法訪問外網 | 檢查 DNS/代理設置 |
| `No matching distribution` | 套件不存在或版本錯誤 | 檢查 requirements.txt |
| `Read timed out` | 網絡超時 | 使用國內鏡像源 |
| `SSL: CERTIFICATE_VERIFY_FAILED` | SSL 證書問題 | 使用 `--trusted-host` |
| `Could not find a version` | PyPI 連接問題 | 使用鏡像源 |

---

## 🔍 診斷命令

```bash
# 1. 檢查 Docker 版本
docker --version
docker-compose --version

# 2. 檢查 Docker 網絡
docker network ls
docker network inspect bridge

# 3. 測試容器內網絡
docker run --rm python:3.11-slim ping -c 4 pypi.org

# 4. 查看 DNS 設置
docker run --rm python:3.11-slim cat /etc/resolv.conf

# 5. 測試 pip 安裝
docker run --rm python:3.11-slim pip install --index-url https://mirrors.aliyun.com/pypi/simple/ requests
```

---

## ✅ 成功指標

構建成功應該看到：
```
Successfully installing agno-2.3.18 fastapi-0.115.6 uvicorn-0.32.1 ...
Successfully built seanews:latest
```

---

## 🆘 仍然失敗？

如果以上方案都不行，請提供以下信息：

1. **Docker 版本**
   ```bash
   docker --version
   docker info
   ```

2. **網絡環境**
   - 是否在公司網絡/VPN？
   - 是否有代理服務器？
   - 地區（中國大陸/海外）？

3. **詳細錯誤日誌**
   ```bash
   docker build -t seanews:latest . --progress=plain --no-cache 2>&1 | tee build.log
   ```

4. **測試直接安裝**
   ```bash
   # 在本地測試是否能安裝
   pip install agno==2.3.18
   ```

---

## 📝 臨時解決方案（應急用）

如果急需運行，可以先移除有問題的依賴：

```bash
# 1. 備份 requirements.txt
cp server/requirements.txt server/requirements.txt.bak

# 2. 創建最小依賴版本（移除 agno）
cat > server/requirements.txt << EOF
fastapi==0.115.6
uvicorn[standard]==0.32.1
python-dotenv==1.0.1
openai>=1.0.0
openpyxl>=3.1.0
EOF

# 3. 構建
docker build -t seanews:minimal .

# 注意：這樣會失去 agno 相關功能
```

---

## 🎯 最佳實踐

1. **使用多階段構建緩存**
   ```dockerfile
   # 使用構建緩存加速
   RUN --mount=type=cache,target=/root/.cache/pip \
       pip install -r requirements.txt
   ```

2. **固定基礎鏡像版本**
   ```dockerfile
   FROM python:3.11.7-slim
   # 而不是 python:3.11-slim
   ```

3. **定期更新依賴**
   ```bash
   pip list --outdated
   pip install --upgrade pip
   ```

---

## 相關文件

- [Dockerfile](../Dockerfile) - 已更新的構建文件
- [docker-compose.yml](../docker-compose.yml) - 已更新的編排文件
- [DOCKER_DEPLOYMENT_GUIDE.md](./DOCKER_DEPLOYMENT_GUIDE.md) - 完整部署指南
