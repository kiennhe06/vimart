# ViMart 🛒

[![CI](https://github.com/kiennhe06/vimart/actions/workflows/ci.yml/badge.svg)](https://github.com/kiennhe06/vimart/actions/workflows/ci.yml)
[![CodeQL](https://github.com/kiennhe06/vimart/actions/workflows/codeql.yml/badge.svg)](https://github.com/kiennhe06/vimart/actions/workflows/codeql.yml)

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

## ✅ Chất lượng & kiểm thử (automation)

Local và CI chạy **cùng bộ lệnh** qua `Makefile` (một nguồn sự thật). Xem `make help`.

```bash
make setup          # cài deps 2 phía + bật git hook (chạy 1 lần)
make check          # cổng đầy đủ: format-check + lint + test (giống hệt CI)

make be-test        # test backend (node:test + Postgres, DB vimart_test)
make be-coverage    # test backend + báo cáo coverage (c8)
make app-test       # test Flutter (unit + widget)
make app-coverage   # test Flutter + coverage (lcov)
make lint           # eslint (backend/web) + flutter analyze
```

- **CI** (`.github/workflows/ci.yml`): concurrency (hủy run cũ), quyền tối thiểu, **path-filter** (chỉ chạy job liên quan), cache (npm + Flutter), **coverage** (c8 + lcov, tải lên artifact), action **ghim theo SHA**. Job `backend` (Postgres service) + `flutter` + cổng tổng hợp `CI passed`.
- **Bảo mật/deps:** CodeQL (`codeql.yml`), Dependency review trên PR (`dependency-review.yml`), **Dependabot** (npm + pub + github-actions) hằng tuần.
- **Release:** đẩy tag `v*` → tự build APK và tạo GitHub Release kèm file (`release.yml`).
- **Đóng góp:** có sẵn PR template + issue templates (`.github/`).
- **Git hook**: `pre-commit` chạy format-check + lint; `pre-push` chạy test. Bật bằng `make setup` (hoặc `make hooks`). Bỏ qua khi cần: `git commit/push --no-verify`.
- **DB test tách riêng** `vimart_test` — bộ test tự tạo lại schema + seed; sẽ **từ chối chạy** nếu `DATABASE_URL` không trỏ tới `vimart_test` (tránh xóa nhầm dữ liệu dev).
- Postgres: máy đã cài Homebrew Postgres là đủ; hoặc `make db-up` để dùng Docker (`docker-compose.yml`, cùng phiên bản 16 với CI).

## 📚 Tài liệu (đọc để hiểu dự án)

- [docs/README.md](docs/README.md) — cài đặt & cách chạy chi tiết
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — kiến trúc, luồng dữ liệu
- [docs/FILE_GUIDE.md](docs/FILE_GUIDE.md) — vai trò từng file
- [docs/PROGRESS.md](docs/PROGRESS.md) — tiến độ & kiểm thử
- [docs/DECISIONS.md](docs/DECISIONS.md) — các quyết định kỹ thuật
- [docs/FUTURE.md](docs/FUTURE.md) — hướng phát triển tiếp
