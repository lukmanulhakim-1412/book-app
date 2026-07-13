# Stage 1: Builder
FROM node:20 AS builder
WORKDIR /app
COPY package*.json bun.lockb ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Final
FROM nginx:alpine
# Install curl for healthcheck
RUN apk add --no-cache curl

# Copy built static files to Nginx
COPY --from=builder /app/dist /usr/share/nginx/html
# Copy health check script
COPY health_check.sh /usr/local/bin/health_check.sh
RUN chmod +x /usr/local/bin/health_check.sh

EXPOSE 80
# Use default nginx command
CMD ["nginx", "-g", "daemon off;"]