# ==========================================
# 多階段構建 Dockerfile
# Stage 1: 構建前端
# Stage 2: 運行後端 + 服務前端靜態文件
# ==========================================

# ============ Stage 1: 前端構建 ============
FROM node:20-alpine AS frontend-builder

WORKDIR /app

# 複製 package.json 和 package-lock.json
COPY package*.json ./

# 安裝前端依賴（包含 devDependencies，因為需要 Vite 等構建工具）
RUN npm ci

# 複製前端源碼
COPY src ./src
COPY index.html ./
COPY vite.config.js ./
COPY public ./public

# 構建前端靜態文件
RUN npm run build

# ============ Stage 2: 後端運行 ============
FROM python:3.11-slim

WORKDIR /app

# 安裝系統依賴
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 複製 Python 依賴文件
COPY server/requirements.txt ./server/

# 配置 pip 使用可靠的鏡像源並安裝依賴
# 嘗試順序：阿里雲鏡像 -> 清華鏡像 -> 官方 PyPI
RUN pip config set global.timeout 120 && \
    pip install --no-cache-dir --upgrade pip && \
    (pip install --no-cache-dir -r server/requirements.txt -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com || \
     pip install --no-cache-dir -r server/requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host pypi.tuna.tsinghua.edu.cn || \
     pip install --no-cache-dir -r server/requirements.txt || \
     (echo "Failed to install requirements from all sources" && exit 1))

# 複製後端代碼
COPY server ./server

# 從前端構建階段複製構建產物
COPY --from=frontend-builder /app/dist ./dist

# 創建必要的目錄
RUN mkdir -p server/exports

# 暴露端口
EXPOSE 8787

# 健康檢查（增加啟動等待時間，因為可能需要初始化）
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8787/api/health || exit 1

# 設置環境變量
ENV PORT=8787
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# 啟動命令（使用更穩健的配置）
CMD ["python", "-m", "uvicorn", "server.agno_api:app", "--host", "0.0.0.0", "--port", "8787", "--log-level", "info"]
