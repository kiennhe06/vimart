# Hướng dẫn file — "file này để làm gì?"

Giải thích vai trò các file/thư mục chính. Không giải thích từng dòng code.

## BACKEND (`server/`)

### Nền tảng
| File | Vai trò |
|------|---------|
| `src/server.js` | Điểm khởi chạy: kiểm tra DB rồi mở cổng 4100 |
| `src/app.js` | Cấu hình Express (middleware, gắn routes, bắt lỗi) |
| `src/routes.js` | Gom tất cả API các module dưới `/api` |
| `src/config/env.js` | Đọc & kiểm tra biến môi trường từ `.env` |
| `.env` / `.env.example` | Cấu hình: cổng, DB, JWT, VNPay (xem .env.example để biết cần gì) |

### Database
| File | Vai trò |
|------|---------|
| `src/db/schema.sql` | **Thiết kế toàn bộ bảng** (users, products, orders...) |
| `src/db/pool.js` | Kết nối PostgreSQL + hàm `query` và `withTransaction` |
| `src/db/migrate.js` | Chạy schema.sql để tạo bảng |
| `src/db/seed.js` | Nạp dữ liệu mẫu + tài khoản test |

### Tiện ích & middleware
| File | Vai trò |
|------|---------|
| `src/utils/response.js` | Chuẩn hóa response `{success, data}` |
| `src/utils/token.js` | Tạo & kiểm tra JWT |
| `src/utils/AppError.js` | Lớp lỗi nghiệp vụ có kèm mã HTTP |
| `src/utils/asyncHandler.js` | Bọc controller để tự bắt lỗi async |
| `src/middlewares/auth.middleware.js` | Kiểm đăng nhập & phân quyền |
| `src/middlewares/validate.middleware.js` | Kiểm dữ liệu đầu vào (Zod) |
| `src/middlewares/error.middleware.js` | Bắt mọi lỗi, trả response chuẩn |

### Các module nghiệp vụ (`src/modules/<tên>/`)
| Module | Chức năng |
|--------|-----------|
| `auth/` | Đăng ký, đăng nhập, đổi mật khẩu, lấy thông tin bản thân |
| `user/` | Cập nhật hồ sơ, sổ địa chỉ nhận hàng |
| `shop/` | Mở shop, xem/sửa shop |
| `category/` | Danh mục sản phẩm |
| `product/` | Sản phẩm: tìm/lọc, chi tiết, CRUD cho người bán |
| `cart/` | Giỏ hàng (gộp theo shop) |
| `order/` | Đặt hàng, danh sách & chi tiết đơn, đổi trạng thái |
| `payment/` | VNPay (tạo link, xác nhận chữ ký) + mock-pay dev |
| `review/` | Đánh giá sản phẩm sau khi nhận hàng |
| `favorite/` | Sản phẩm yêu thích |
| `admin/` | Thống kê, quản lý người dùng, xem tất cả đơn |

> Mỗi module thường có `*.routes.js`, `*.controller.js`, `*.service.js`, `*.schema.js`.
> Logic quan trọng nằm ở `*.service.js`.

---

## FRONTEND (`lib/`)

### Nền tảng
| File | Vai trò |
|------|---------|
| `main.dart` | Điểm khởi chạy app |
| `app/theme.dart` | Màu sắc, font, bo góc (giao diện nhất quán) |
| `app/router.dart` | Khai báo màn hình + bảo vệ route cần đăng nhập |
| `app/home_shell.dart` | Khung có thanh điều hướng dưới (4 tab) |
| `core/constants.dart` | **Địa chỉ backend** (`kApiBaseUrl`) |
| `core/api/api_client.dart` | Gọi API, tự gắn token, dịch lỗi sang tiếng Việt |
| `core/storage/token_storage.dart` | Lưu token đăng nhập trên máy |
| `core/format.dart` | Định dạng tiền (89.000₫), ngày, nhãn trạng thái |
| `core/providers.dart` | Provider dùng chung (ApiClient, lưu trữ) |

### Model (`lib/models/`)
Khai báo cấu trúc dữ liệu: `user.dart`, `address.dart`, `category.dart`, `product.dart`, `cart.dart`, `order.dart`. Chỉ có `fromJson` + getter tiện ích.

### Widget dùng chung (`lib/widgets/`)
| File | Vai trò |
|------|---------|
| `async_view.dart` | Hiển thị 4 trạng thái: loading / lỗi / rỗng / có dữ liệu |
| `login_required_view.dart` | Nhắc đăng nhập ở các tab cần quyền |

### Các feature (`lib/features/<tên>/`)
| Feature | Màn hình / vai trò |
|---------|--------------------|
| `auth/` | `login_screen`, `register_screen`, `auth_provider` (trạng thái đăng nhập) |
| `catalog/` | `home_screen` (trang chủ), `product_detail_screen`, `shop_screen`, thẻ sản phẩm |
| `cart/` | `cart_screen` + `cart_provider` (đồng bộ giỏ với server) |
| `checkout/` | `checkout_screen` (chọn địa chỉ, thanh toán, đặt hàng) |
| `address/` | `addresses_screen` + provider sổ địa chỉ |
| `order/` | `orders_screen` (đơn của tôi), `order_detail_screen` (kèm hành động) |
| `favorite/` | `favorites_screen` + provider yêu thích |
| `seller/` | `seller_products_screen`, `product_form_screen`, `seller_orders_screen` |
| `profile/` | `profile_screen` (tài khoản, lối vào kênh bán) |
