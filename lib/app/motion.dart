import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// # ViMart Motion Language
///
/// Đây là **nguồn sự thật duy nhất** cho chuyển động trong ViMart. Mọi hiệu ứng
/// đi qua đây để app có một "giọng nói" nhất quán — không phải các animation rời rạc.
///
/// ## 4 nguyên tắc
/// 1. **Tức thì (Responsive):** phản hồi chạm < 100ms. Người dùng chạm là UI phải
///    "nhúc nhích" ngay, kể cả khi dữ liệu còn đang tải.
/// 2. **Có chủ đích (Purposeful):** mỗi chuyển động ánh xạ một ý nghĩa — trạng thái
///    đổi, quan hệ không gian, hay xác nhận hành động. Không có động tác trang trí.
/// 3. **Liên tục (Continuous):** phần tử không "biến mất/hiện ra"; chúng di chuyển,
///    biến hình, kế thừa vị trí (shared element, container transform, shared-axis).
/// 4. **Nhường nhịn (Deferential):** nhanh, không chặn thao tác; luôn hiện thẳng
///    trạng thái cuối khi bật Giảm chuyển động (trợ năng).
///
/// ## Hierarchy (phân cấp chuyển động)
/// Mỗi tương tác có **một** động tác chính. Các phần tử liên quan phản ứng phụ
/// (nhẹ hơn, trễ hơn); nền chỉ chuyển động môi trường (ambient) rất tiết chế.
/// - **Primary:** thứ người dùng vừa chạm (scale/biến hình/di chuyển rõ).
/// - **Secondary:** thứ phản ứng theo (badge nảy, tổng tiền cuộn) — trễ ~40–80ms.
/// - **Ambient:** trạng thái chờ/nền (shimmer, splash "thở").
class AppMotion {
  AppMotion._();

  // --- Thang thời lượng (curve-based, cho Animated* / Tween) ---------------
  /// Micro-feedback tức thì (đổi số, nhấn nhả). Ngưỡng "cảm giác lập tức".
  static const Duration fast = Duration(milliseconds: 120);

  /// Chuyển trạng thái tiêu chuẩn trong cùng một màn.
  static const Duration base = Duration(milliseconds: 220);

  /// Chuyển động lớn/nhấn mạnh (đếm tổng tiền, biến hình lớn).
  static const Duration slow = Duration(milliseconds: 360);

  /// Chuyển cảnh giữa các trang.
  static const Duration page = Duration(milliseconds: 280);

  /// Khoảnh khắc "thưởng" (vẽ ✓, pháo giấy, tim nở) — dài hơn để cảm nhận được.
  static const Duration celebrate = Duration(milliseconds: 600);

  /// Vòng lặp môi trường (ambient): shimmer skeleton, logo splash "thở".
  static const Duration ambientLoop = Duration(milliseconds: 1200);

  /// Ảnh mờ dần khi tải xong (bỏ hiệu ứng "pop" cứng).
  static const Duration imageFade = Duration(milliseconds: 320);

  /// Đơn vị so le (stagger) khi nhiều phần tử vào cùng lúc.
  static const Duration staggerStep = Duration(milliseconds: 55);

  // --- Curves (đường cong chuẩn của ViMart) --------------------------------
  /// Vào: giảm tốc mượt (bắt đầu nhanh, dừng êm).
  static const Curve enter = Curves.easeOutCubic;

  /// Ra: tăng tốc (biến mất dứt khoát, nhanh hơn lúc vào — quy tắc exit-faster).
  static const Curve exit = Curves.easeInCubic;

  /// Nhấn mạnh (Material emphasized): dùng cho biến hình/chọn.
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Nảy nhẹ có chủ đích (thêm giỏ, thích, badge) — KHÔNG lạm dụng.
  static const Curve pop = Curves.easeOutBack;

  // --- Spring physics (xương sống chuyển động vật lý) ----------------------
  // Dùng khi cần cảm giác "sống" theo lực (nhấn nhả, pop, kéo–thả). Chạy qua
  // [AnimationController.animateWith] hoặc widget [Springy]. Reduced-motion sẽ
  // nhảy thẳng tới đích (xem [Springy] / [Pressable]).

  /// Tới đích nhanh, dứt khoát, KHÔNG vượt (critically damped). Cho nhấn/nhả,
  /// đóng/mở panel — nơi cần chính xác, không "rung".
  static const SpringDescription snappy =
      SpringDescription(mass: 1, stiffness: 520, damping: 30);

  /// Mượt, gần như không vượt — chuyển trạng thái chung.
  static const SpringDescription smooth =
      SpringDescription(mass: 1, stiffness: 320, damping: 26);

  /// Nảy nhẹ có kiểm soát — khoảnh khắc "thưởng" (thêm giỏ, thích, thành công).
  static const SpringDescription bouncy =
      SpringDescription(mass: 1, stiffness: 380, damping: 15);

  /// Chậm, đằm — phần tử lớn/ambient.
  static const SpringDescription gentle =
      SpringDescription(mass: 1.4, stiffness: 180, damping: 24);

  /// Thời lượng có tôn trọng Giảm chuyển động (trả [Duration.zero] khi bật).
  static Duration dur(BuildContext context, Duration d) =>
      context.reduceMotion ? Duration.zero : d;

  /// Độ trễ so le cho phần tử thứ [index] khi vào theo danh sách (giới hạn để
  /// danh sách dài không chờ lâu). Trả [Duration.zero] khi giảm chuyển động.
  static Duration stagger(
    BuildContext context,
    int index, {
    int max = 6,
    Duration step = staggerStep,
  }) {
    if (context.reduceMotion) return Duration.zero;
    final i = index < 0 ? 0 : (index > max ? max : index);
    return step * i;
  }
}

extension MotionContext on BuildContext {
  /// True khi hệ thống bật Giảm chuyển động hoặc đang dùng trình đọc màn hình.
  bool get reduceMotion {
    final mq = MediaQuery.maybeOf(this);
    return mq != null && (mq.disableAnimations || mq.accessibleNavigation);
  }
}

/// Rung phản hồi (haptic) — mỗi ngữ cảnh một cường độ. Là một phần của "feedback
/// taxonomy": chuyển động thị giác + rung phải cùng kể một câu chuyện.
class AppHaptics {
  AppHaptics._();

  /// Chạm nhẹ (chọn tab, đổi số lượng, chọn phân loại).
  static void light() => HapticFeedback.selectionClick();

  /// Chạm vừa (mở panel, xác nhận nhẹ).
  static void medium() => HapticFeedback.lightImpact();

  /// Thành công (thêm giỏ, đặt hàng, thích).
  static void success() => HapticFeedback.mediumImpact();

  /// Cảnh báo (xóa, thao tác cần chú ý).
  static void warning() => HapticFeedback.heavyImpact();

  /// Lỗi.
  static void error() => HapticFeedback.vibrate();
}
