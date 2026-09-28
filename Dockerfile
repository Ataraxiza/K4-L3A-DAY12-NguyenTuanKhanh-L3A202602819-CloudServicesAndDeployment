# ═══════════════════════════════════════════════════════════════════
# CP2 — Production Dockerfile
# ═══════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────
# 2.1 — Builder stage
# ───────────────────────────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /app

# Nếu requirements có package cần compile native extension,
# builder có thể cài compiler/build tools ở đây.
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

# 2.2 — Copy dependency definition trước source code
COPY requirements.txt .

RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ───────────────────────────────────────────────────────────────────
# Runtime stage
# ───────────────────────────────────────────────────────────────────
FROM python:3.11-slim AS runtime

WORKDIR /app

# Chỉ copy dependencies đã build từ builder.
# Không copy compiler/build-essential.
COPY --from=builder /install /usr/local

# Copy source code SAU dependency layer để tận dụng Docker cache.
COPY app ./app
COPY utils ./utils

# 2.3 — Không chạy bằng root
RUN useradd --create-home --uid 10001 appuser

USER appuser

# 2.4 — PORT
ENV PORT=8000

EXPOSE 8000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health').read()" || exit 1

# Cloud platform có thể override PORT.
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
