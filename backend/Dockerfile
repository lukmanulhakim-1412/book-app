# Stage 1: Builder
FROM python:3.11-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
  libpq-dev \
  python3-dev \
  default-libmysqlclient-dev \
  build-essential \
  pkg-config \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create virtual environment and install dependencies
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
  pip install --no-cache-dir -r requirements.txt

# Stage 2: Final
FROM python:3.11-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
  libpq5 \
  curl \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV TZ=Asia/Jakarta
WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy source code
COPY . .
# Ensure health check is executable
RUN chmod +x /app/health_check.sh

EXPOSE 5001

CMD ["python", "app.py"]