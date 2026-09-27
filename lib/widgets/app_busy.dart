import 'package:flutter/material.dart';

import '../app/motion.dart';
import '../app/theme.dart';

/// Chỉ báo "đang xử lý" thống nhất toàn app (thay cho các `CircularProgressIndicator`
/// thô rải rác) — cùng màu thương hiệu, cùng độ dày, cùng kích thước theo ngữ cảnh.
class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key, this.size = 24, this.color, this.strokeWidth = 2.4});

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color ?? AppColors.brand,
      ),
    );
  }
}

/// Chuyển đổi mượt giữa nội dung nút và spinner khi [busy] — chuẩn hoá mọi nút
/// có trạng thái "đang gửi" (đăng nhập, đặt hàng, lưu…). Cross-fade + scale nhẹ.
class BusySwitch extends StatelessWidget {
  const BusySwitch({
    super.key,
    required this.busy,
    required this.child,
    this.spinnerSize = 22,
    this.spinnerColor = Colors.white,
  });

  final bool busy;
  final Widget child;
  final double spinnerSize;
  final Color spinnerColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.dur(context, AppMotion.base),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      transitionBuilder: (c, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(a), child: c),
      ),
      child: busy
          ? AppSpinner(
              key: const ValueKey('busy'),
              size: spinnerSize,
              color: spinnerColor,
            )
          : KeyedSubtree(key: const ValueKey('child'), child: child),
    );
  }
}
