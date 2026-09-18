# Tiến độ dự án ViMart

_Cập nhật: 18/09/2026_

## ✅ Đã làm xong

### Backend (Node.js + Express + PostgreSQL)
- Kiến trúc module (routes / controller / service / schema) + middleware (auth, validate, error).
- Kết nối PostgreSQL bằng `pg`, có transaction; `schema.sql` đầy đủ 12 bảng.
- **Xác thực & phân quyền:** đăng ký, đăng nhập (JWT + bcrypt), lấy thông tin bản thân, đổi mật khẩu, phân quyền customer/admin/chủ shop.
- **Người dùng:** cập nhật hồ sơ, sổ địa chỉ (CRUD, địa chỉ mặc định).
- **Shop:** mở shop, xem/sửa shop, trang shop công khai.
- **Danh mục + Sản phẩm:** tìm/lọc (từ khóa, danh mục, giá, sao), sắp xếp, phân trang, chi tiết kèm phân loại + đánh giá; CRUD cho người bán.
- **Giỏ hàng:** thêm/sửa/xóa, gộp theo shop, kiểm tra tồn kho.
- **Đơn hàng:** đặt hàng tách theo shop, trừ kho trong transaction, danh sách/chi tiết, đổi trạng thái đúng luồng (người mua: hủy/nhận; người bán: xác nhận/giao/từ chối), hoàn kho khi hủy.
- **Thanh toán:** VNPay (ký & kiểm tra chữ ký HMAC-SHA512) + COD + mock-pay cho dev.
- **Đánh giá:** chỉ sau khi đơn hoàn thành, tự cập nhật điểm trung bình sản phẩm.
- **Yêu thích** và **Admin** (thống kê, quản lý người dùng, xem tất cả đơn).
- **Dữ liệu mẫu** (seed) + 4 tài khoản test.

### Frontend (Flutter + Riverpod + go_router + Dio)
- Cấu trúc theo feature, tách UI ↔ provider ↔ repository ↔ ApiClient.
- Lưu token, tự đăng nhập lại khi mở app; bảo vệ route cần đăng nhập.
- Màn hình: Đăng nhập/Đăng ký, Trang chủ (tìm/lọc/sắp xếp), Chi tiết sản phẩm, Trang shop, Giỏ hàng, Thanh toán (địa chỉ + COD/VNPay), Đơn hàng (theo trạng thái) + chi tiết đơn (kèm hành động), Yêu thích, Sổ địa chỉ, Tài khoản.
- Kênh người bán: quản lý sản phẩm (thêm/sửa/xóa, nhiều phân loại), đơn của shop.
- Giao diện sáng/tối, 4 trạng thái (loading/lỗi/rỗng/data), pull-to-refresh, lỗi tiếng Việt thân thiện.

## 🧪 Đã kiểm thử
- **Backend:** script e2e (`server`) chạy **27/27 test PASS** — full luồng: đăng nhập → duyệt → giỏ nhiều shop → đặt hàng → shop xử lý → nhận hàng → đánh giá → VNPay(mock) → admin.
- **Flutter:** `flutter analyze` → **No issues found**; `flutter test` → PASS.
- **Chạy thật:** app chạy trên **iOS Simulator (iPhone 16)**, kết nối backend, hiển thị dữ liệu thật, mở được trang chi tiết sản phẩm. (Đã xác minh bằng ảnh chụp màn hình.)

## 🐛 Đã sửa trong quá trình làm
- Đổi cổng backend 4000 → **4100** (cổng 4000 bị Firebase Emulator chiếm).
- Gỡ `cached_network_image` (kéo theo `material_ui` không tương thích meta của SDK) → dùng `Image.network` qua widget `NetworkImageBox`.
- Hạ `go_router` 18 → 14 (bản 18 kéo `material_ui`/`cupertino_ui` cần meta mới hơn Flutter 3.44).

## 🔜 Còn lại / phát triển tiếp
Xem `docs/FUTURE.md`. Nổi bật: voucher, flash sale, trả hàng/hoàn tiền, chat real-time, thông báo đẩy, giao diện admin trong app, upload ảnh Cloudinary, phân trang cuộn vô hạn, VNPay sandbox thật.
