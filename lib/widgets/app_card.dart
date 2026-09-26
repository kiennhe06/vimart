import 'package:flutter/widgets.dart';

import '../app/design.dart';
import 'pressable.dart';

/// Thẻ bề mặt dùng chung — MỘT nơi định nghĩa "card" cho toàn app (thay cho việc
/// lặp `Container(decoration: BoxDecoration(surface + border + shadow))` khắp nơi).
///
/// Mặc định: nền `surface`, viền hairline `border`, bo `AppRadius.lg`, bóng rất
/// nhẹ (tiết chế — không "over-shadow"). Truyền [onTap] để có phản hồi nhấn.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.base),
    this.margin,
    this.radius = AppRadius.lg,
    this.onTap,
    this.elevated = true,
    this.pressScale = 0.98,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;

  /// Có bóng nhẹ (true) hay phẳng hoàn toàn chỉ viền (false).
  final bool elevated;
  final double pressScale;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final box = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.border),
        boxShadow: elevated ? AppShadow.soft(c.shadow) : null,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Pressable(onTap: onTap, scale: pressScale, child: box);
  }
}
