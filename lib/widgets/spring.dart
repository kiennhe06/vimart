import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../app/motion.dart';

/// Nội suy một giá trị vô hướng tới [value] bằng **spring physics** (mô phỏng
/// lò xo). Khi đích đổi giữa chừng, vận tốc hiện tại được mang theo nên chuyển
/// động không "khựng" — đây là cảm giác "sống" theo lực của ngôn ngữ chuyển động
/// ViMart. Tôn trọng Giảm chuyển động: nhảy thẳng tới đích, không mô phỏng.
///
/// Dùng cho: nhấn–nhả (scale), badge/pop, bump giá trị, chọn phân loại…
class Springy extends StatefulWidget {
  const Springy({
    super.key,
    required this.value,
    required this.builder,
    this.spring = AppMotion.smooth,
    this.child,
  });

  /// Giá trị đích. Đổi giá trị này để khởi động mô phỏng lò xo tới đích mới.
  final double value;

  /// Đặc tả lò xo (độ cứng/giảm chấn) — chọn từ [AppMotion.snappy/smooth/bouncy/gentle].
  final SpringDescription spring;

  /// Dựng UI từ giá trị đã nội suy. [child] được truyền lại để tránh dựng lại phần tĩnh.
  final ValueWidgetBuilder<double> builder;

  /// Phần con không phụ thuộc giá trị (tối ưu: không dựng lại mỗi frame).
  final Widget? child;

  @override
  State<Springy> createState() => _SpringyState();
}

class _SpringyState extends State<Springy> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController.unbounded(vsync: this, value: widget.value);

  @override
  void didUpdateWidget(covariant Springy old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _animateTo(widget.value);
  }

  void _animateTo(double target) {
    // Giảm chuyển động (trợ năng) -> hiện thẳng trạng thái cuối.
    if (context.reduceMotion) {
      _c.stop();
      _c.value = target;
      return;
    }
    // Mang theo vận tốc hiện tại -> đổi hướng mượt, không khựng.
    _c.animateWith(SpringSimulation(widget.spring, _c.value, target, _c.velocity));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (ctx, child) => widget.builder(ctx, _c.value, child),
    );
  }
}

/// Rút gọn phổ biến nhất: co giãn theo lò xo quanh tâm. [scale] là giá trị đích
/// (1.0 = kích thước gốc). Bọc quanh phần tử cần "nảy" khi giá trị đổi.
class SpringScale extends StatelessWidget {
  const SpringScale({
    super.key,
    required this.scale,
    required this.child,
    this.spring = AppMotion.bouncy,
    this.alignment = Alignment.center,
  });

  final double scale;
  final SpringDescription spring;
  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Springy(
      value: scale,
      spring: spring,
      child: child,
      builder: (_, v, child) =>
          Transform.scale(scale: v, alignment: alignment, child: child),
    );
  }
}
