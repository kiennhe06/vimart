# ViMart Design System

> Nguồn sự thật DUY NHẤT cho visual: spacing, radius, typography, màu semantic,
> theme (Sáng/Tối). Mọi màn hình "nói cùng một ngôn ngữ". Code: [`lib/app/design.dart`](../lib/app/design.dart), [`lib/app/theme.dart`](../lib/app/theme.dart).

## Nguyên tắc
- **Less but better**: mỗi thành phần phải tạo giá trị (thông tin / giảm thao tác / dẫn hiểu). Không thêm card/gradient/shadow để "giả cao cấp".
- **Hierarchy bằng cấu trúc**: phân cấp bằng size + weight + spacing + vị trí, không bằng màu.
- **Tiết chế**: bóng đổ nhẹ, viền 1px thay vì shadow nặng; không lạm dụng card.

## Spacing — `AppSpace` (thang 4pt)
`xs 4 · sm 8 · md 12 · base 16 · lg 20 · xl 24 · xxl 32 · xxxl 40`. Không dùng số lẻ.

## Radius — `AppRadius`
`sm 12` (chip/input) · `md 16` (thẻ nhỏ/ảnh) · `lg 20` (thẻ chính/sheet) · `xl 26` (panel/hero) · `pill 999`.

## Typography — `AppType` (màu kế thừa ngữ cảnh)
`display 28/800 · h1 22/800 · h2 18/800 · h3 16/700 · title 15/700 · body 14/500 · bodySm 13/500 · label 13/700 · caption 12/500 · price 16/800`. Ít cỡ chữ; phân cấp bằng weight/size.

## Màu semantic — `context.c` (theme-aware)
Lấy màu qua `context.c.<token>` để tự đúng ở **cả Sáng lẫn Tối**:

| Token | Vai trò |
|---|---|
| `background` | nền tổng thể |
| `surface` / `surfaceAlt` | bề mặt thẻ / bề mặt nâng cao |
| `textPrimary` / `textSecondary` / `textMuted` | 3 bậc chữ (đã chỉnh tương phản đạt a11y) |
| `border` | viền 1px |
| `brand` / `brandSoft` / `onBrand` | thương hiệu / nền brand nhạt / chữ trên brand |
| `star` `promo` `success` `danger` | ngữ nghĩa |
| `shadow` | bóng đổ theo theme |

**Dark KHÔNG phải đảo màu**: bảng riêng — nền xanh-đen (`#0F1613`), 3 bậc bề mặt rõ, brand sáng hơn (`#34C878`) để đủ tương phản.

## Theme
- `themeModeProvider` (lưu máy): **Theo hệ thống / Sáng / Tối** — đổi trong **Tài khoản → Giao diện**.
- Material theme (`buildLightTheme`/`buildDarkTheme`) dùng chung token: appbar, card (`CardTheme`), input, button, chip, divider, snackbar đều theme-aware. Bất kỳ `Card()` nào tự đúng dark.

## Component dùng chung (không copy-paste UI)
`Pressable` (nhấn spring) · `AppSpinner`/`BusySwitch` · `AppRefresh` · `RollingNumber` ·
`AppSheetOption` (mục chọn trong sheet) · `Skeleton`/`SkeletonGrid`/`SkeletonList` ·
`AsyncView`+`EmptyView`/`ErrorView` (4 trạng thái) · `showAppSnack` · `showAppDialog`/`showAppSheet` ·
`NetworkImageBox` · `FadeSlideIn`. Motion: xem [MOTION.md](MOTION.md).

## Quy tắc khi thêm màn mới
1. Màu qua `context.c`, KHÔNG hard-code `Colors.white`/grey.
2. Khoảng cách/bo góc/chữ qua `AppSpace`/`AppRadius`/`AppType`.
3. Ưu tiên `Card`/list/divider hơn là bọc mọi thứ thành card.
4. Bốn trạng thái: loading (skeleton) / data / empty / error — dùng `AsyncView`.
