import 'package:flutter/widgets.dart';

import '../app/motion.dart';

/// Bọc bất kỳ phần tử bấm được để có phản hồi "nhấn lún" mượt.
///
/// - Thu nhỏ về [scale] khi nhấn (transform, KHÔNG đẩy layout xung quanh).
/// - Rung nhẹ khi nhả (tùy chọn).
/// - Tôn trọng giảm chuyển động (khi bật thì không scale).
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

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _setDown(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    final pressed = _down && enabled && !context.reduceMotion;

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: enabled ? (_) => _setDown(true) : null,
      onTapUp: enabled ? (_) => _setDown(false) : null,
      onTapCancel: enabled ? () => _setDown(false) : null,
      onTap: enabled
          ? () {
              if (widget.haptic) AppHaptics.light();
              widget.onTap?.call();
            }
          : null,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: pressed ? widget.scale : 1.0,
        duration: AppMotion.dur(context, AppMotion.fast),
        curve: AppMotion.emphasized,
        child: widget.child,
      ),
    );
  }
}
