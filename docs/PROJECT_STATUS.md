# Trạng thái dự án ViMart (hiện tại)

_Ảnh chụp trạng thái đã xác minh từ source + Git. Lịch sử chi tiết: `docs/PROGRESS.md`.
Hướng mở rộng chưa làm: `docs/FUTURE.md`._

Branch khảo sát: `feat/category-sticker-icons` · Remote: `kiennhe06/vimart`.

## ✅ Tính năng đã có (xác minh từ source)

Module backend: `server/src/modules/` · Feature mobile: `lib/features/` · Tab web admin: `server/public/js/app.js`.

**Người mua (mobile):**
- Đăng nhập / đăng ký (JWT) — `auth`
- Trang chủ: tìm kiếm + lịch sử, danh mục, sắp xếp, lưới SP — `home`, `catalog`
- Chi tiết SP: variant, số lượng, đánh giá, chat shop — `catalog`
- Giỏ hàng: nhóm theo shop, stepper, vuốt xóa, **chọn món để thanh toán (checkbox)** — `cart`
- Thanh toán: địa chỉ, voucher, COD/VNPay, chỉ thanh toán món đã chọn — `checkout`, `order`
- Sổ địa chỉ (tỉnh/phường từ API) — `address`
- Đơn hàng + chi tiết + lịch sử trạng thái — `order`
- Trả hàng / hoàn tiền — `return`
- Yêu thích — `favorite`
- Chat mua↔bán real-time (WebSocket) — `chat`
- Thông báo + badge — `notification`
- Flash sale (giá sale theo khung giờ) — `flash`
- Hồ sơ: đổi ngôn ngữ (vi/en), theme sáng/tối — `profile`

**Người bán (mobile):** mở shop, quản lý SP (CRUD + upload ảnh + variant), đơn của shop — `seller`, `shop`, `upload`.

**Admin (web `localhost:4100`):** Dashboard (doanh thu, biểu đồ, bán chạy, sắp hết hàng, CSV) · Sản phẩm · Người dùng · Đơn hàng · **Chat CSKH real-time + badge chưa đọc** · Đánh giá (trả lời) · Vouchers · Flash sale · Trả hàng · Danh mục — module `admin`.

**Nền tảng:** zod validate, JWT, `withTransaction`, response envelope, `AppError` · VNPay mock-pay · upload ảnh (`multer`) · Dockerize + Render (`docker-compose.yml`, `render.yaml`) · seed + tài khoản test · i18n vi/en · theme sáng/tối · hệ icon sticker 3D (`assets/icons/`, `lib/widgets/sticker_icon.dart`).

## 🧪 Kiểm thử (xác minh)

- `flutter test`: **22/22 pass** (`test/`, `test/widgets/`).
- `make be-test`: **47/47 pass** (`server/test/`, DB `vimart_test`).
- `flutter analyze`: sạch.

## 🔧 Thay đổi gần đây (từ Git log — xác minh)

- Hệ icon **sticker 3D** đồng bộ toàn app (danh mục, nav, header, flash, trạng thái rỗng, các màn chức năng).
- Giỏ: **chọn từng món để thanh toán** (mobile + backend `variantIds`).
- Admin chat: **badge chưa đọc + toast real-time** ở mọi tab; WS kết nối toàn cục.
- Web admin: tĩnh `Cache-Control: no-store` (hết kẹt cache); nav gom **6 nhóm dropdown**.

## 🐞 Lỗi đã sửa — dễ tái diễn (ghi để tránh lặp)

- **CircularDependencyError khi login:** `AuthNotifier` invalidate provider đang
  watch `authProvider` → vòng lặp. Cách tránh: KHÔNG invalidate ngược provider watch auth.
- **Màn trắng (blank) do layout:** đặt Material button làm sibling không-flex của
  `Expanded` trong `Row` → đo với width vô hạn → vỡ. Cách tránh: dùng layout dọc / full-width.
- **flutter_svg không render filter blur:** bóng icon phải fake bằng radial gradient,
  KHÔNG dùng `feGaussianBlur`/`feDropShadow`.
- **Web admin chạy bản cũ:** cache tĩnh + `?v=` không đổi → đã đặt `no-store`; nếu
  còn kẹt, hard reload (Cmd+Shift+R) hoặc bump `?v=`.
- **Dropdown bị cắt:** `.tabs { overflow }` clip dropdown con → để `.tabs` wrap, không overflow ẩn.

## ❓ Chưa xác minh / cần người dùng xác nhận

- Trạng thái deploy thực tế trên Render (file cấu hình có, chưa xác minh đã deploy).
- VNPay: chỉ có luồng **mock-pay** (dev) — tích hợp cổng thật chưa xác minh.
- `docs/PROGRESS.md` ghi mốc 18/09/2026 → phần trước đó có thể cũ so với trạng thái này.
