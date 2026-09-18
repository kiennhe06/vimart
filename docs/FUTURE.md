# Hướng phát triển tiếp (chưa làm trong bản MVP)

Ghi lại ý tưởng mở rộng để không làm phình phạm vi hiện tại. Ưu tiên hoàn thiện luồng lõi trước.

## Theo đề bài — "Bước 2 & 3"
- **Mã giảm giá (voucher):** áp mã khi thanh toán, voucher của shop và của sàn, kiểm tra hạn dùng & số lượt.
- **Flash sale:** giảm giá theo khung giờ, tự bật/tắt đúng giờ.
- **Trả hàng / hoàn tiền:** người mua yêu cầu trả, shop/admin duyệt, VNPay hoàn tiền.
- **Chat real-time** giữa người mua và shop (Socket.io).
- **Thông báo đẩy** khi đơn đổi trạng thái / có khuyến mãi.
- **Theo dõi shop** (follow) + đánh giá shop.
- **Duyệt shop & duyệt sản phẩm** trước khi lên sàn (admin).
- **Banner quảng cáo** trang chủ + thông báo chung (admin).
- **Nhật ký hoạt động** (audit log) cho admin.

## Kỹ thuật nên nâng cấp
- **Giao diện Admin trong app** (hiện admin dùng qua API): dashboard thống kê, quản lý người dùng/đơn.
- **Upload ảnh sản phẩm** thật lên Cloudinary thay vì dán URL.
- **Phí vận chuyển động** theo địa chỉ/khối lượng thay vì cố định 30k/shop.
- **Tự động hủy đơn** nếu quá lâu không thanh toán (job nền).
- **Phân trang / cuộn vô hạn** cho danh sách sản phẩm (backend đã trả `pagination`, app hiện lấy 50 sản phẩm/lần).
- **Quản lý phân loại (variant) theo id** khi sửa sản phẩm (hiện sửa = xóa & tạo lại toàn bộ variant).
- **Refresh token** cho JWT (hiện token sống 7 ngày, hết hạn phải đăng nhập lại).
- **Đổi mật khẩu / quên mật khẩu** trên giao diện app (backend đã có API đổi mật khẩu).
- **Test tự động** cho Flutter (widget test) và test tích hợp backend (hiện có script e2e thủ công).

## Ngoài phạm vi đồ án (chỉ ghi nhận)
- Ví điện tử nội bộ, theo dõi giao hàng bằng bản đồ GPS, gợi ý sản phẩm bằng AI, đăng nhập Google/Facebook.
