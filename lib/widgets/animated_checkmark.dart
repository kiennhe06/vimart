import 'package:flutter/material.dart';

import '../app/motion.dart';
import '../app/theme.dart';

/// Dấu tích tự vẽ (nét chạy) trong vòng tròn nảy nhẹ — cho dialog thành công.
class AnimatedCheck extends StatefulWidget {
  const AnimatedCheck({super.key, this.size = 72, this.color = AppColors.brand});
  final double size;
  final Color color;

  @override
  State<AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<AnimatedCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (context.reduceMotion) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _CheckPainter(progress: _c.value, color: widget.color),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;

    // Vòng tròn nền nảy vào (0 -> 0.55).
    final circleT = Curves.easeOutBack.transform((progress / 0.55).clamp(0, 1));
    final bg = Paint()..color = color.withValues(alpha: 0.14);
    canvas.drawCircle(center, r * circleT, bg);

    // Nét tích chạy (0.35 -> 1).
    final checkT = ((progress - 0.35) / 0.65).clamp(0.0, 1.0);
    if (checkT <= 0) return;

    final p1 = Offset(size.width * 0.28, size.height * 0.52);
    final p2 = Offset(size.width * 0.44, size.height * 0.68);
    final p3 = Offset(size.width * 0.74, size.height * 0.34);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(p1.dx, p1.dy);
    // Đoạn 1: p1->p2 chiếm nửa đầu, đoạn 2: p2->p3 nửa sau.
    if (checkT < 0.5) {
      final t = checkT / 0.5;
      path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
    } else {
      final t = (checkT - 0.5) / 0.5;
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
    }
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress || old.color != color;
}
