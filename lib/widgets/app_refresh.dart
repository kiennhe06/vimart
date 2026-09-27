import 'package:flutter/material.dart';

import '../app/motion.dart';
import '../app/theme.dart';

/// Pull-to-refresh thống nhất toàn app: màu thương hiệu, độ dời nhất quán, và
/// **rung nhẹ** ngay khi kích hoạt (phản hồi xúc giác đúng khoảnh khắc kéo-thả).
class AppRefresh extends StatelessWidget {
  const AppRefresh({super.key, required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.brand,
      displacement: 28,
      onRefresh: () {
        AppHaptics.light();
        return onRefresh();
      },
      child: child,
    );
  }
}
