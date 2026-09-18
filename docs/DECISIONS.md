# Các quyết định kỹ thuật

Ghi lại những lựa chọn ảnh hưởng tới kiến trúc / cách app hoạt động, khi đề bài không nói rõ.

## 1. Backend viết bằng JavaScript (ESM), không dùng TypeScript
**Lý do:** Người dùng đang học lập trình và ưu tiên code đơn giản, chạy được ngay. JavaScript bỏ bước biên dịch (`tsc`), dễ đọc và chạy thẳng bằng Node. Có thể nâng lên TypeScript sau nếu cần.

## 2. Truy vấn database bằng SQL thuần (thư viện `pg`), không dùng ORM (Prisma/Sequelize)
**Lý do:** Học viên thấy được SQL thật → hiểu bản chất. Ít phụ thuộc, dễ kiểm soát. `schema.sql` là một nơi duy nhất để xem toàn bộ thiết kế bảng.

## 3. State management Flutter dùng Riverpod + điều hướng go_router + gọi API bằng Dio
**Lý do:** Đây là stack chuẩn của nhóm (theo playbook nội bộ) và cũng là khuyến nghị trong quy tắc frontend. Dùng API hiện đại của Riverpod 3 (`Notifier`, `AsyncNotifier`, `FutureProvider`).

## 4. Xác thực bằng JWT tự quản, KHÔNG dùng Firebase Auth
**Lý do:** Đề bài yêu cầu backend Node + PostgreSQL tự lưu tài khoản (mã hóa mật khẩu bằng bcrypt). Firebase sẽ tách dữ liệu người dùng ra khỏi PostgreSQL, không phù hợp yêu cầu.

## 5. Mỗi sản phẩm luôn có ít nhất 1 "phân loại" (variant); giá & tồn kho nằm ở variant
**Lý do:** Giữ dữ liệu nhất quán (không có 2 nơi lưu giá). Sản phẩm không có nhiều phiên bản thì dùng 1 variant tên "Mặc định". Nhờ vậy giỏ hàng và đơn hàng luôn tham chiếu tới variant, xử lý tồn kho đơn giản.

## 6. Đơn hàng tách theo shop khi thanh toán
**Lý do:** Giống Shopee — 1 lần đặt nhiều shop sẽ tạo nhiều đơn, nối với nhau bằng `group_code`. Mỗi shop tự xử lý đơn của mình. Thanh toán VNPay tính trên cả nhóm.

## 7. Phí vận chuyển cố định 30.000₫/shop
**Lý do:** Đề bài không yêu cầu tính phí ship theo khoảng cách. Chọn phí cố định cho đơn giản; có thể thay bằng logic thật sau (ghi ở `FUTURE.md`).

## 8. Có endpoint "mock-pay" cho VNPay (chỉ môi trường dev)
**Lý do:** VNPay sandbox cần đăng ký tài khoản để lấy `TMN_CODE`/`HASH_SECRET`. Để nhóm chạy thử luồng thanh toán ngay mà chưa cần tài khoản thật, backend có `POST /api/payments/mock-pay` đánh dấu đơn đã thanh toán. Khi có mã sandbox thật (điền vào `.env`), app sẽ tự dùng luồng VNPay thật (mở cổng thanh toán). Endpoint mock bị chặn ở môi trường production.

## 9. Backend chạy ở cổng 4100 (không phải 4000)
**Lý do:** Cổng 4000 trên máy phát triển đang bị **Firebase Emulator Suite** chiếm (giữ IPv4 loopback). Đổi sang 4100 để tránh xung đột. Muốn đổi lại: sửa `PORT` trong `server/.env` và `kApiBaseUrl` trong `lib/core/constants.dart`.

## 10. Ảnh sản phẩm dùng URL (chưa upload trực tiếp)
**Lý do:** Giữ phạm vi gọn cho bản MVP. Người bán dán link ảnh. Dữ liệu mẫu dùng ảnh từ picsum.photos. Việc upload ảnh (Cloudinary) để ở `FUTURE.md`.
