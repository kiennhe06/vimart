# ViMart 🛒

Ứng dụng **chợ online nhiều shop (kiểu Shopee)** — đồ án tốt nghiệp.

- **App:** Flutter (Riverpod + go_router + Dio)
- **Server:** Node.js + Express
- **Database:** PostgreSQL
- **Thanh toán:** VNPay (sandbox) + COD

## Bắt đầu nhanh

```bash
# 1) Backend
cd server && npm install && cp .env.example .env
createdb vimart && npm run db:reset && npm run dev   # http://localhost:4100

# 2) App (mở terminal khác, ở thư mục gốc)
flutter pub get && flutter run
```

Tài khoản test (mật khẩu `123456`): `buyer@vimart.vn`, `seller1@vimart.vn`, `admin@vimart.vn`.

## 📚 Tài liệu (đọc để hiểu dự án)

- [docs/README.md](docs/README.md) — cài đặt & cách chạy chi tiết
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — kiến trúc, luồng dữ liệu
- [docs/FILE_GUIDE.md](docs/FILE_GUIDE.md) — vai trò từng file
- [docs/PROGRESS.md](docs/PROGRESS.md) — tiến độ & kiểm thử
- [docs/DECISIONS.md](docs/DECISIONS.md) — các quyết định kỹ thuật
- [docs/FUTURE.md](docs/FUTURE.md) — hướng phát triển tiếp
