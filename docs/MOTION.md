# ViMart Motion & Interaction Language

> Không phải "một bộ animation". Đây là **cách ViMart giao tiếp với người dùng
> qua chuyển động** — một ngôn ngữ có nguyên tắc, vật lý, phân cấp, nhịp và phản
> hồi nhất quán. Mọi màn hình nói cùng một "giọng".

Nguồn code: [`lib/app/motion.dart`](../lib/app/motion.dart) (token + spring + haptic),
[`lib/widgets/spring.dart`](../lib/widgets/spring.dart) (physics engine).

---

## 1. Bốn nguyên tắc

| # | Nguyên tắc | Nghĩa | Hệ quả kỹ thuật |
|---|-----------|-------|-----------------|
| 1 | **Tức thì** (Responsive) | Chạm là UI nhúc nhích < 100ms, kể cả khi dữ liệu đang tải | Press feedback bằng transform; optimistic UI; skeleton thay spinner |
| 2 | **Có chủ đích** (Purposeful) | Mỗi chuyển động = một ý nghĩa (đổi trạng thái / quan hệ không gian / xác nhận) | Không animation trang trí; mỗi hiệu ứng map 1 sự kiện |
| 3 | **Liên tục** (Continuous) | Phần tử không "biến mất/hiện ra" — chúng di chuyển, biến hình, kế thừa vị trí | Hero/shared-element, container transform, shared-axis |
| 4 | **Nhường nhịn** (Deferential) | Nhanh, không chặn thao tác; ưu tiên rõ ràng hơn phô diễn | Exit nhanh hơn enter; **reduced-motion là mặc định hạng nhất** |

**Reduced-motion:** mọi hiệu ứng đi qua `AppMotion.dur(context, …)` / `context.reduceMotion`.
Khi bật Giảm chuyển động (trợ năng) → app hiện **thẳng trạng thái cuối**, không giật, không mất chức năng. Đây là ràng buộc bất di bất dịch.

---

## 2. Phân cấp chuyển động (Hierarchy)

Mỗi tương tác chỉ có **một động tác chính**. Nhiều thứ nảy cùng lúc = nhiễu.

- **Primary** — thứ người dùng vừa chạm. Rõ nhất (scale, biến hình, di chuyển).
- **Secondary** — thứ phản ứng theo, nhẹ & trễ ~40–80ms (badge giỏ nảy, tổng tiền cuộn).
- **Ambient** — nền/chờ, rất tiết chế (shimmer skeleton, splash "thở").

Quy tắc: 1 primary + tối đa 1–2 secondary mỗi màn tại một thời điểm.

---

## 3. Thang thời lượng (timing scale)

| Token | ms | Dùng cho |
|-------|----|----------|
| `fast` | 120 | Micro-feedback (đổi số, nhấn nhả) — ngưỡng "cảm giác lập tức" |
| `base` | 220 | Chuyển trạng thái trong cùng màn |
| `slow` | 360 | Chuyển động lớn/nhấn mạnh (đếm tổng tiền) |
| `page` | 280 | Chuyển cảnh giữa trang |
| `staggerStep` | 55 | Đơn vị so le khi nhiều phần tử vào |

**Exit nhanh hơn enter** (quy tắc): vào `base`, ra `fast`.
So le có trần: `AppMotion.stagger(context, index, max: 6)` để danh sách dài không chờ lâu.

---

## 4. Đường cong & Vật lý (curves & springs)

**Curves** (cho `Animated*`/`Tween`):
- `enter` = easeOutCubic (vào mượt, dừng êm)
- `exit` = easeInCubic (biến mất dứt khoát)
- `emphasized` = Cubic(.2,0,0,1) (biến hình/chọn)
- `pop` = easeOutBack (nảy nhẹ có chủ đích)

**Springs** (physics thật, qua `Springy`/`AnimationController.animateWith`) — dùng khi cần cảm giác "sống" theo lực; **mang theo vận tốc** khi đổi đích giữa chừng:

| Spring | Tính chất | Dùng cho |
|--------|-----------|----------|
| `snappy` | tới đích nhanh, **không vượt** | nhấn/nhả, đóng/mở panel, chọn |
| `smooth` | mượt, gần như không vượt | chuyển trạng thái chung |
| `bouncy` | nảy nhẹ có kiểm soát | khoảnh khắc "thưởng": thêm giỏ, thích, thành công |
| `gentle` | chậm, đằm | phần tử lớn/ambient |

---

## 5. Feedback taxonomy (thị giác + xúc giác cùng kể một chuyện)

| Sự kiện | Thị giác | Haptic |
|---------|----------|--------|
| Chạm nút/tab | Nhấn lún scale (snappy) | `light` (selectionClick) |
| Mở panel/sheet | Scale-in + fade | `medium` |
| Thêm giỏ / thích / đặt hàng | Morph ✓ / tim nở / ✓ vẽ nét (bouncy) | `success` |
| Xóa (swipe) | Trượt + nền cảnh báo | `warning` |
| Lỗi | Snackbar đỏ + (rung) | `error` |

Haptic đi cùng động tác **primary**, không rải khắp nơi.

---

## 6. Choreography — các "câu" chuyển động chuẩn

> (Mục này mô tả các mẫu áp dụng đồng bộ toàn app — xem mục 7 để biết đã áp ở đâu.)

- **Container / shared-element:** thẻ sản phẩm → trang chi tiết bằng `Hero` (ảnh kế thừa vị trí). Trang mở bằng fade-through + phóng nhẹ.
- **Shared-axis (lateral):** chuyển tab bottom-nav trượt theo trục X có hướng (không cross-fade phẳng) — thể hiện quan hệ ngang hàng.
- **Enter theo danh sách:** fade + trượt-lên, so le `stagger`.
- **Đổi giá trị:** số (giá/tổng/số lượng) **cuộn/nảy**, không đổi cứng.
- **State transition** (loading→data→empty/error): một cổng chung, cross-fade + pop, skeleton cho lúc chờ.
- **Optimistic + xác nhận:** hành động phản hồi ngay (nút đổi trạng thái), rồi chốt bằng ✓/haptic khi server trả về.

---

## 7. Bản đồ áp dụng (đã triển khai)

**Nền tảng dùng chung** ([`lib/widgets/`](../lib/widgets/)):
- `spring.dart` — `Springy`/`SpringScale`: engine lò xo (mang vận tốc).
- `pressable.dart` — nhấn-lún spring (`snappy`), có ở mọi phần tử bấm được.
- `rolling_number.dart` — số cuộn theo spring khi giá trị đổi.
- `app_busy.dart` — `AppSpinner` + `BusySwitch` (nút "đang gửi" thống nhất).
- `app_refresh.dart` — pull-to-refresh thương hiệu + haptic.
- `fly_to_cart.dart` — ảnh bay vào giỏ (đường Bézier).
- `burst.dart` — `burstAt` (chùm hạt tim) + `ConfettiBurst` (pháo giấy thành công).
- `app_skeleton.dart`, `entrance.dart`, `app_feedback.dart`, `animated_checkmark.dart`,
  `app_dialog.dart`, `async_view.dart`, `network_image_box.dart` — có sẵn, đã đưa về token.

**Theo màn:**
| Vùng | Chuyển động |
|------|-------------|
| Chuyển tab (bottom nav) | Shared-axis (trượt ngang theo hướng + mờ vào), giữ state |
| Thẻ sản phẩm | Hero ảnh, quick-add `+`→✓, **ảnh bay vào giỏ** |
| Chi tiết SP | Hero, giá slide-replace, số lượng pop, **fly-to-cart**, **tim nở + chùm hạt** |
| Giỏ hàng | Vuốt-xóa, **tổng tiền cuộn** (RollingNumber), qty pop |
| Thanh toán | Nút→spinner (BusySwitch), dialog ✓ vẽ nét + **pháo giấy** |
| Đơn hàng | Status chip đổi màu/nhãn mượt, busy-bar & action-bar co giãn, sao review pop |
| Tìm kiếm (home) | Ô focus viền+quầng, placeholder mờ, nút xóa spring; category ring/label animate |
| Địa chỉ (form) | Select field animate enable/disable + viền lỗi |
| Seller form | Variant rows co giãn (AnimatedSize), nút lưu BusySwitch |
| Auth | Nút BusySwitch, toggle ẩn/hiện mật khẩu cross-fade |
| Toàn cục | Page transition fade-through, skeleton shimmer, `showAppSnack`, pull-to-refresh |

**Quy ước "đổi giá trị":** *tích lũy* (tổng tiền, số lượng) → **cuộn** (`RollingNumber`);
*thay thế* (giá theo phân loại) → **slide-replace** (`AnimatedSwitcher` trượt).

**Kiểm thử:** `test/motion_test.dart` phủ `AppMotion.dur`, `Pressable` (không đổi layout),
`Springy` (nhảy đích khi giảm chuyển động), `RollingNumber`.
