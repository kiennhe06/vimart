# Technical Decisions — ViMart

> Quyết định kỹ thuật **gốc** (10 mục, có lý do + đánh đổi) nằm ở **`docs/DECISIONS.md`** —
> đó là nguồn chính, đọc trước. File này chỉ (a) tóm tắt để tra nhanh và (b) ghi
> các quyết định **phát sinh gần đây** chưa có trong DECISIONS.md.

## Tóm tắt từ `docs/DECISIONS.md` (đã xác minh)

1. Backend JavaScript (ESM), không TypeScript.
2. SQL thuần (`pg`), không ORM.
3. Flutter: Riverpod + go_router + Dio.
4. Auth JWT tự quản (không Firebase). Payload `{ id, role }`.
5. Mỗi sản phẩm có ≥1 variant; giá & tồn kho ở variant.
6. Đơn hàng tách theo shop khi thanh toán.
7. Phí ship cố định 30.000₫/shop.
8. VNPay có endpoint "mock-pay" (chỉ dev).
9. Backend cổng **4100**.
10. Ảnh sản phẩm dùng URL (có thêm upload `multer`).

## Quyết định gần đây (xác minh từ Git history của phiên này)

### A. Checkout theo lựa chọn — `variantIds` (tùy chọn)
`POST /api/orders/checkout` nhận thêm `variantIds` (mảng). Bỏ trống = thanh toán cả
giỏ (tương thích ngược); có giá trị = chỉ đặt + xóa khỏi giỏ các variant đã chọn.
File: `server/src/modules/order/order.{schema,service}.js`,
`lib/features/cart/cart_provider.dart` (`cartSelectionProvider`).
_Lý do:_ cho người mua chọn món như Shopee mà không phá API cũ.

### B. Hệ icon sticker 3D qua `flutter_svg`
Icon nhiều màu (gradient + viền trắng + gloss + bóng) bundle SVG, render bằng
`lib/widgets/sticker_icon.dart`. **KHÔNG dùng filter blur** (`feGaussianBlur`/
`feDropShadow`) vì flutter_svg không render được → bóng fake bằng radial gradient.
Trạng thái inactive dùng `ColorFilter.matrix` (grayscale).
_Lý do:_ Material Icons chỉ 1 màu; cần icon duotone đồng bộ, render ổn trên mobile.

### C. Web admin: static `Cache-Control: no-store` (dev)
`server/src/app.js` phục vụ `public/` với `no-store` (tắt etag/lastModified) +
versioning `?v=` trong `index.html`.
_Lý do:_ trước đây trình duyệt giữ `app.js` cũ do cache → tính năng mới không hiện.

### D. Web admin nav: gom 6 nhóm dropdown (`<details name>`)
Thay 10 tab ngang (bị tràn) bằng 6 nhóm: Tổng quan · Đơn hàng · Sản phẩm ·
Khuyến mãi · Khách hàng · Tin nhắn. `.tabs` cho wrap (không overflow ẩn) để dropdown
không bị cắt. File: `server/public/js/app.js`, `server/public/css/styles.css`.

## Ghi chú

- Khi phát sinh quyết định kỹ thuật mới: thêm vào đây (hoặc `docs/DECISIONS.md` nếu
  là quyết định nền tảng). Không bịa lý do — chỉ ghi điều xác minh được từ code/Git.
