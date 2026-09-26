import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../app/motion.dart';

/// Bọc bất kỳ phần tử bấm được để có phản hồi "nhấn lún" theo **spring physics**.
///
/// - Thu nhỏ về [scale] khi nhấn rồi bật về 1.0 khi nhả, dùng lò xo [AppMotion.snappy]
///   (tới đích chính xác, không rung) — mang theo vận tốc nên nhấn/nhả liên tiếp mượt.
/// - Chỉ biến đổi transform (KHÔNG đẩy layout xung quanh).
/// - Rung nhẹ khi nhả (tùy chọn) — một phần của feedback taxonomy.
/// - Tôn trọng Giảm chuyển động (khi bật thì giữ nguyên kích thước).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.96,
    this.haptic = true,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final HitTestBehavior behavior;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  // Bắt đầu ở 1.0 (kích thước gốc); lò xo đưa về [scale] khi nhấn.
  late final AnimationController _c =
      AnimationController.unbounded(vsync: this, value: 1.0);

  void _to(double target) {
    if (context.reduceMotion) {
      _c.stop();
      _c.value = 1.0; // không "lún" khi giảm chuyển động
      return;
    }
    _c.animateWith(SpringSimulation(AppMotion.snappy, _c.value, target, _c.velocity));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: enabled ? (_) => _to(widget.scale) : null,
      onTapUp: enabled ? (_) => _to(1.0) : null,
      onTapCancel: enabled ? () => _to(1.0) : null,
      onTap: enabled
          ? () {
              if (widget.haptic) AppHaptics.light();
              widget.onTap?.call();
            }
          : null,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) => Transform.scale(scale: _c.value, child: child),
      ),
    );
  }
}
