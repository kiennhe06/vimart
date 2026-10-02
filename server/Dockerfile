# ViMart backend + web admin (API phục vụ cả website tĩnh trong /public).
# Build context: ./server
FROM node:20-alpine

WORKDIR /app

# Cài dependencies theo lockfile (chỉ production).
COPY package*.json ./
RUN npm ci --omit=dev

# Mã nguồn + website tĩnh (admin/web bán hàng).
COPY src ./src
COPY public ./public

ENV NODE_ENV=production
# Server đọc PORT từ env (mặc định 4100).
EXPOSE 4100

CMD ["node", "src/server.js"]
