import 'package:flutter/widgets.dart';

import '../app/motion.dart';

/// Hiệu ứng "trồi lên" khi phần tử xuất hiện: mờ dần + trượt nhẹ từ dưới.
///
/// [index] tạo hiệu ứng so le (stagger) cho danh sách — mục sau xuất hiện trễ
/// hơn một chút. Tôn trọng giảm chuyển động (hiện thẳng trạng thái cuối).
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0, this.dy = 12});

  final Widget child;
  final int index;
  final double dy;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;

    final delayMs = (index * 40).clamp(0, 320);
    final totalMs = AppMotion.base.inMilliseconds + delayMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: totalMs),
      curve: Interval(delayMs / totalMs, 1, curve: AppMotion.enter),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, dy * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
