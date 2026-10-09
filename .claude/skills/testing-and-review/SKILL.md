---
name: testing-and-review
description: >-
  Kiểm tra và chống lỗi hồi quy cho ViMart. Dùng sau khi sửa code, trước khi nói
  "đã xong", hoặc khi cần chạy lint/test/build và xác minh giao diện. Xác định
  lệnh test/lint/build thật từ cấu hình; chạy test hồi quy; kiểm UI responsive /
  overflow / dropdown / navigation / trạng thái tương tác khi phù hợp; KHÔNG
  khẳng định đã test nếu chưa chạy; ghi lại lệnh đã chạy + kết quả + lỗi còn lại.
---

# Testing & Review — ViMart

## 1. Lệnh thật (từ `Makefile`, `pubspec.yaml`, `server/package.json`)

**Mobile (Flutter)** — chạy ở gốc repo:
```bash
flutter analyze          # phải SẠCH (0 issue) trước khi xong
flutter test             # test widget/unit (test/ + test/widgets/)
```

**Backend (Node/Express)** — DB test riêng `vimart_test`:
```bash
make be-test             # CÁCH ĐÚNG: set DATABASE_URL=...vimart_test + re-seed
# (đừng chạy `npm test` trần trong server/ — nó trỏ DB dev và fail do dữ liệu bẩn)
cd server && npm run lint && npm run format:check
```

**Web admin:** không có test tự động → kiểm thủ công trên trình duyệt (mục 3).

## 2. Chống hồi quy

- Sau mỗi thay đổi: chạy `flutter analyze` + `flutter test`; nếu đụng backend →
  `make be-test` (toàn bộ, không chỉ file vừa sửa).
- Sửa `lib/widgets/` dùng chung → chạy lại test liên quan (vd đổi bottom nav thì
  `test/widgets/bottom_nav_test.dart`).
- Nếu đổi hành vi được test (vd Icon → SvgPicture) → CẬP NHẬT test cho khớp,
  không xoá test.

## 3. Kiểm UI (khi thay đổi giao diện)

- **Mobile:** chạy app trên simulator/emulator, chụp màn hình các luồng chính
  (home, chi tiết SP, giỏ/checkout, trạng thái rỗng/lỗi). Lưu ý toạ độ simulator
  là **points** (không phải pixel ảnh chụp).
- **Web admin:** mở `http://localhost:4100`, kiểm **responsive / overflow /
  dropdown / navigation / active state / badge real-time**. Nhớ **hard reload**
  (Cmd+Shift+R) hoặc bump `?v=` sau khi sửa `app.js`/`styles.css`.
- Bật **Reduce Motion** → xác nhận app hiện thẳng trạng thái cuối, không giật.

## 4. Nguyên tắc báo cáo (trung thực)

- KHÔNG nói "đã test/đã chạy" nếu chưa thực sự chạy.
- Ghi lại: **lệnh đã chạy**, **kết quả thật** (vd "flutter test: 22/22 pass",
  "make be-test: 47/47 pass"), **lỗi còn tồn tại**, **bước kiểm thủ công cần làm**.
- Nếu test fail → báo kèm output, KHÔNG che giấu; sửa nguyên nhân gốc trước khi xong.

## 5. Mốc "Definition of Done"

1. `flutter analyze` sạch.
2. `flutter test` xanh (+ `make be-test` xanh nếu đụng backend).
3. Đã kiểm thị giác luồng bị ảnh hưởng (mobile và/hoặc web admin).
4. Đã cập nhật test cho hành vi mới + tài liệu nếu cần.
