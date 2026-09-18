# Kiến trúc ViMart (giải thích đơn giản)

## App gồm 3 phần

```
┌─────────────┐     HTTP (JSON)     ┌─────────────┐     SQL      ┌────────────┐
│  Flutter    │ ◄─────────────────► │  Node.js    │ ◄──────────► │ PostgreSQL │
│  (điện thoại)│    /api/...         │  (máy chủ)  │              │ (dữ liệu)  │
└─────────────┘                     └─────────────┘              └────────────┘
       ▲                                   │
       │                                   │ (khi thanh toán)
       │                                   ▼
       │                             ┌─────────────┐
       └──── mở trình duyệt ───────► │   VNPay     │
                                     └─────────────┘
```

### 1. Frontend (Flutter) — "bộ mặt" người dùng thấy
- Hiển thị màn hình, nhận thao tác của người dùng.
- **Không** tự xử lý dữ liệu quan trọng — mọi thứ hỏi backend qua API.
- Giữ "vé đăng nhập" (JWT token) trong máy để không phải đăng nhập lại mỗi lần mở app.

### 2. Backend (Node.js) — "cái bếp phía sau"
- Nhận yêu cầu từ app, kiểm tra hợp lệ, xử lý nghiệp vụ, đọc/ghi database, rồi trả kết quả.
- Kiểm tra đăng nhập & phân quyền (khách / người bán / admin).
- Tính tiền đơn, **trừ tồn kho**, tách đơn theo shop, ký thanh toán VNPay.

### 3. Database (PostgreSQL) — "kho lưu trữ"
- Lưu toàn bộ: tài khoản, shop, sản phẩm, giỏ hàng, đơn hàng, đánh giá...
- Các bảng liên kết với nhau bằng khóa ngoại (foreign key).

---

## Dữ liệu đi qua hệ thống thế nào? (ví dụ: đặt hàng)

1. Người mua bấm **"Đặt hàng"** trên app.
2. App gọi `POST /api/orders/checkout` kèm token + địa chỉ + phương thức thanh toán.
3. Backend kiểm tra token → lấy giỏ hàng từ DB → **tách theo shop** → với mỗi shop:
   - tạo 1 đơn, tính tiền (hàng + ship),
   - **trừ tồn kho** (nếu không đủ → hủy toàn bộ, báo lỗi),
   - lưu chi tiết đơn (ảnh chụp giá lúc mua).
4. Tất cả bước trên nằm trong **1 transaction** — lỗi giữa chừng thì hoàn tác hết.
5. Xóa giỏ hàng, tạo bản ghi thanh toán, trả kết quả về app.
6. Nếu chọn VNPay → app xin link thanh toán → mở trình duyệt → VNPay báo kết quả về backend (`/payments/vnpay/return`), backend **kiểm tra chữ ký** rồi cập nhật đơn "đã thanh toán".

---

## Backend tổ chức theo "module"

Mỗi tính năng là 1 thư mục trong `server/src/modules/`, gồm 4 loại file:

| File | Vai trò |
|------|---------|
| `*.routes.js` | Khai báo đường dẫn API (URL nào gọi hàm nào) |
| `*.controller.js` | Nhận request → gọi service → trả response |
| `*.service.js` | Chứa logic nghiệp vụ + truy vấn database |
| `*.schema.js` | Kiểm tra dữ liệu đầu vào (dùng Zod) |

Luồng 1 request: **routes → middleware (auth/validate) → controller → service → database**.

## Frontend tổ chức theo "feature"

Mỗi tính năng là 1 thư mục trong `lib/features/`, thường gồm:

| File | Vai trò |
|------|---------|
| `*_repository.dart` | Gọi API, đổi JSON thành model |
| `*_provider.dart` / `*_providers.dart` | Quản lý trạng thái (Riverpod) |
| `*_screen.dart` | Màn hình giao diện |

Widget **không** gọi API trực tiếp — luôn đi qua provider → repository → `ApiClient`.

---

## Phân quyền hoạt động thế nào?

- Khi đăng nhập, backend tạo **JWT token** chứa `id` + `role`.
- App gửi token này ở header `Authorization: Bearer <token>` mỗi request.
- Middleware `authRequired` kiểm token; `adminOnly` chặn nếu không phải admin.
- "Người bán" không phải một role riêng — bất kỳ ai **mở shop** thì trở thành người bán. Quyền thao tác trên 1 đơn/sản phẩm được kiểm bằng cách so `shop.owner_id` với người đang đăng nhập.
