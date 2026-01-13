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

# 安裝前端依賴
RUN npm ci --only=production

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

# 安裝系統依賴（如果需要）
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 複製 Python 依賴文件
COPY server/requirements.txt ./server/

# 安裝 Python 依賴
RUN pip install --no-cache-dir -r server/requirements.txt

# 複製後端代碼
COPY server ./server

# 從前端構建階段複製構建產物
COPY --from=frontend-builder /app/dist ./dist

# 複製環境變量文件（可選，建議在運行時注入）
# COPY .env .env

# 暴露端口
EXPOSE 8787

# 健康檢查
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8787/api/health || exit 1

# 設置環境變量
ENV PORT=8787
ENV PYTHONUNBUFFERED=1

# 啟動命令
CMD ["python", "-m", "uvicorn", "server.agno_api:app", "--host", "0.0.0.0", "--port", "8787"]
