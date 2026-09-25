import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Token chuyển động dùng chung cho toàn app + tôn trọng "giảm chuyển động".
///
/// Nguyên tắc: mọi widget động lấy thời lượng qua [AppMotion.dur] để khi người
/// dùng bật Reduce Motion (trợ năng) thì hiệu ứng thu về 0 — hiện thẳng trạng
/// thái cuối, không giật, không mất usability.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 360);
  static const Duration page = Duration(milliseconds: 280);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve pop = Curves.easeOutBack; // nảy nhẹ cho micro-interaction

  /// Thời lượng có tôn trọng giảm chuyển động (trả [Duration.zero] khi bật).
  static Duration dur(BuildContext context, Duration d) =>
      context.reduceMotion ? Duration.zero : d;
}

extension MotionContext on BuildContext {
  /// True khi hệ thống bật giảm chuyển động hoặc đang dùng trình đọc màn hình.
  bool get reduceMotion {
    final mq = MediaQuery.maybeOf(this);
    return mq != null && (mq.disableAnimations || mq.accessibleNavigation);
  }
}

/// Rung phản hồi gọn — mỗi ngữ cảnh một cường độ phù hợp.
class AppHaptics {
  AppHaptics._();

  /// Chạm nhẹ (chọn tab, bấm nút phụ, đổi số lượng).
  static void light() => HapticFeedback.selectionClick();

  /// Chạm vừa (mở, xác nhận nhẹ).
  static void medium() => HapticFeedback.lightImpact();

  /// Thành công (thêm giỏ, đặt hàng, thích).
  static void success() => HapticFeedback.mediumImpact();

  /// Cảnh báo.
  static void warning() => HapticFeedback.heavyImpact();

  /// Lỗi.
  static void error() => HapticFeedback.vibrate();
}
