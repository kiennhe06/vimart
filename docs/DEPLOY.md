# Triển khai ViMart

ViMart gồm 3 phần:

- **Backend + Web admin** (`server/`): Node/Express, phục vụ cả REST API lẫn website tĩnh trong `server/public`. Đây là phần cần deploy lên server.
- **PostgreSQL**: cơ sở dữ liệu.
- **App Flutter** (`lib/`): build ra APK/IPA cài lên điện thoại, trỏ `kApiBaseUrl` (trong `lib/core/constants.dart`) về URL backend đã deploy.

## 1) Chạy toàn bộ bằng Docker (local hoặc 1 server bất kỳ)

```bash
# Build + chạy backend + Postgres
docker compose --profile full up --build -d

# Tạo bảng + dữ liệu mẫu (chạy 1 lần). LƯU Ý: db:migrate sẽ DROP bảng cũ.
docker compose --profile full run --rm app npm run db:migrate
docker compose --profile full run --rm app npm run db:seed
```

Mặc định `docker compose up` (không có `--profile full`) chỉ chạy Postgres — tiện cho dev local khi backend chạy bằng `npm run dev` trên máy.

Backend sẽ ở `http://localhost:4100` (API `/api/...`, web admin ở `/`).

### Biến môi trường (truyền qua shell hoặc file `.env` cạnh docker-compose)

| Biến | Bắt buộc | Ghi chú |
|------|----------|---------|
| `JWT_SECRET` | nên đổi | chuỗi ngẫu nhiên dài |
| `API_BASE_URL` | khi deploy thật | URL công khai của backend |
| `VNP_TMN_CODE`, `VNP_HASH_SECRET` | để bật VNPay | lấy ở https://sandbox.vnpayment.vn |
| `VNP_RETURN_URL` | khi deploy thật | `<API_BASE_URL>/api/payments/vnpay/return` |

`DATABASE_URL` đã được compose tự trỏ vào service `db`.

## 2) Deploy lên Render / Railway (gợi ý)

Phần này cần **tài khoản hosting của bạn**.

1. Tạo một **PostgreSQL** managed (Render/Railway đều có) → copy `DATABASE_URL`.
2. Tạo một **Web Service** từ repo này:
   - Root directory: `server`
   - Dockerfile: `server/Dockerfile` (hoặc để nền tảng tự nhận).
   - Env: `DATABASE_URL`, `JWT_SECRET`, `API_BASE_URL` (URL service), `VNP_*` nếu dùng VNPay.
3. Chạy migrate/seed một lần (shell của service): `npm run db:migrate && npm run db:seed`.
4. Trỏ app Flutter: sửa `kApiBaseUrl` trong `lib/core/constants.dart` thành `<API_BASE_URL>/api`, rồi `flutter build apk`.

> Lưu ý: `db:migrate` hiện xoá-tạo lại bảng (dev). Trước khi deploy production thật nên chuyển sang migration tăng dần (không DROP).
