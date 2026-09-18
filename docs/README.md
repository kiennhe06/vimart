# ViMart — Chợ online (kiểu Shopee)

App marketplace nhiều shop: người mua tìm hàng → bỏ giỏ → đặt hàng → thanh toán → shop xử lý đơn → nhận hàng → đánh giá.

- **Frontend:** Flutter (Riverpod + go_router + Dio)
- **Backend:** Node.js + Express (JavaScript ESM)
- **Database:** PostgreSQL (raw SQL với thư viện `pg`)
- **Thanh toán:** VNPay (sandbox) + COD, kèm chế độ "mock-pay" để chạy thử khi chưa có tài khoản VNPay

---

## 1. Cần cài sẵn gì?

| Công cụ | Ghi chú |
|---------|---------|
| Node.js ≥ 20 | Chạy backend |
| PostgreSQL ≥ 14 | Đang chạy ở `localhost:5432` |
| Flutter ≥ 3.12 | Chạy app |

Máy đã kiểm thử: Node 24, PostgreSQL 16, Flutter 3.44.

---

## 2. Chạy Backend

```bash
cd server
npm install
cp .env.example .env          # rồi mở .env chỉnh nếu cần
createdb vimart               # tạo database (nếu chưa có)
npm run db:reset              # tạo bảng + nạp dữ liệu mẫu
npm run dev                   # chạy server (có tự reload)
```

Server chạy ở **http://localhost:4100**. Kiểm tra: mở `http://localhost:4100/health`.

> **Vì sao port 4100?** Port 4000 trên máy đang bị Firebase Emulator chiếm. Xem `docs/DECISIONS.md`.

### Lệnh backend hữu ích
| Lệnh | Việc |
|------|------|
| `npm run dev` | Chạy server (tự reload khi sửa code) |
| `npm run db:migrate` | Tạo lại bảng (xóa dữ liệu cũ) |
| `npm run db:seed` | Tạo lại bảng + nạp dữ liệu mẫu |
| `npm run db:reset` | = migrate + seed |

---

## 3. Chạy App Flutter

```bash
# ở thư mục gốc dự án
flutter pub get
flutter run
```

> **Quan trọng — địa chỉ backend:** sửa trong `lib/core/constants.dart` (biến `kApiBaseUrl`):
> - iOS Simulator / máy tính: `http://localhost:4100/api`
> - **Android Emulator**: `http://10.0.2.2:4100/api`
> - Điện thoại thật: `http://<IP-LAN-máy-tính>:4100/api`

---

## 4. Tài khoản dùng thử (mật khẩu: `123456`)

| Email | Vai trò |
|-------|---------|
| `buyer@vimart.vn` | Người mua (đã có sẵn địa chỉ) |
| `seller1@vimart.vn` | Người bán — Shop Táo Xanh |
| `seller2@vimart.vn` | Người bán — Thời Trang GenZ |
| `admin@vimart.vn` | Quản trị viên |

> Một tài khoản người mua cũng có thể **mở shop** để vừa mua vừa bán (giống Shopee).

---

## 5. Các chức năng chính đã có

**Người mua:** đăng ký/đăng nhập, tìm & lọc sản phẩm, xem chi tiết + đánh giá, chọn phân loại, giỏ hàng gộp nhiều shop, sổ địa chỉ, đặt hàng, thanh toán COD/VNPay, theo dõi đơn theo trạng thái, hủy đơn, xác nhận đã nhận, đánh giá sản phẩm, yêu thích.

**Người bán:** mở shop, đăng/sửa/xóa sản phẩm (nhiều phân loại giá + tồn kho), xem đơn của shop, xác nhận/từ chối/giao hàng.

**Admin (qua API):** thống kê tổng, quản lý người dùng (khóa/mở), xem toàn bộ đơn.

Chi tiết luồng dữ liệu xem `docs/ARCHITECTURE.md`. Vai trò từng file xem `docs/FILE_GUIDE.md`.
Tình trạng & việc còn lại xem `docs/PROGRESS.md`.
