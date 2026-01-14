# ==========================================
# Zeabur 優化的多階段構建 Dockerfile
# 針對 Vite + FastAPI 全棧應用
# Stage 1: 構建前端
# Stage 2: 運行後端 + 服務前端靜態文件
# ==========================================

# ============ Stage 1: 前端構建 ============
FROM node:20-alpine AS frontend-builder

# Zeabur 構建階段環境變量（若需要在構建時使用環境變量）
ARG BUILDTIME_ENV_EXAMPLE
ARG VITE_API_URL
ENV VITE_API_URL=${VITE_API_URL}

WORKDIR /app

# 複製 package.json 和 package-lock.json
COPY package*.json ./

# 安裝前端依賴
# 使用 npm ci 以獲得更快速、更可靠的依賴安裝
RUN npm ci --prefer-offline --no-audit

# 複製前端源碼
COPY src ./src
COPY index.html ./
COPY vite.config.js ./
COPY public ./public

# 構建前端靜態文件（生產模式）
RUN npm run build

# ============ Stage 2: 後端運行 ============
FROM python:3.11-slim

WORKDIR /app

# 安裝系統依賴和清理
# 僅安裝運行時必需的包以減小映像大小
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 複製 Python 依賴文件
COPY server/requirements.txt ./server/requirements.txt

# 安裝 Python 依賴
# 優化：使用單一 RUN 指令減少層數
# 使用 --no-cache-dir 減小映像大小
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r server/requirements.txt

# 複製後端代碼
COPY server ./server

# 從前端構建階段複製構建產物
COPY --from=frontend-builder /app/dist ./dist

# 創建必要的目錄並設置權限
RUN mkdir -p /app/server/exports && \
    chmod -R 755 /app/server/exports

# 切換到 server 目錄
WORKDIR /app/server

# 暴露端口（Zeabur 會自動檢測並映射）
# 使用標準端口 8000，但會通過 PORT 環境變量覆蓋
EXPOSE 8000

# 健康檢查（Zeabur 支持）
# 使用 PORT 環境變量以適應 Zeabur 的動態端口分配
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:${PORT:-8000}/api/health || exit 1

# Python 優化環境變量
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app/server

# Zeabur 會自動注入以下環境變量，這裡設置默認值
# PORT - Zeabur 會自動設置，本地默認 8000
ENV PORT=8000

# 啟動命令
# 使用 sh -c 以支持環境變量展開
# Zeabur 會自動使用 PORT 環境變量
CMD sh -c "python -m uvicorn agno_api:app --host 0.0.0.0 --port ${PORT} --log-level info"
