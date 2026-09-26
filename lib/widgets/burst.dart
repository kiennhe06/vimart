import 'dart:math';

import 'package:flutter/widgets.dart';

import '../app/motion.dart';

const List<Color> _kConfettiColors = [
  Color(0xFF1EA65A), // brand
  Color(0xFFFF7A45), // cam
  Color(0xFF7C5CFC), // tím
  Color(0xFFE0A81E), // vàng
  Color(0xFF2B8AF0), // xanh
  Color(0xFFF0498A), // hồng
];

/// Bắn một chùm hạt tỏa tròn tại [center] (tọa độ toàn màn) — dùng cho khoảnh
/// khắc "thích" (tim nở kèm chùm hạt). Tự gỡ khi xong. Bỏ qua khi Giảm chuyển động.
void burstAt(BuildContext context, Offset center, {Color color = const Color(0xFFFF4D67), int count = 12}) {
  if (context.reduceMotion) return;
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _RadialBurst(center: center, color: color, count: count, onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _RadialBurst extends StatefulWidget {
  const _RadialBurst({required this.center, required this.color, required this.count, required this.onDone});
  final Offset center;
  final Color color;
  final int count;
  final VoidCallback onDone;

  @override
  State<_RadialBurst> createState() => _RadialBurstState();
}

class _RadialBurstState extends State<_RadialBurst> with SingleTickerProviderStateMixin {
  late final List<_P> _particles;
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        })
        ..forward();

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    _particles = List.generate(widget.count, (i) {
      final angle = (i / widget.count) * 2 * pi + rnd.nextDouble() * 0.5;
      return _P(angle: angle, dist: 34 + rnd.nextDouble() * 34, size: 4 + rnd.nextDouble() * 4);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            painter: _RadialPainter(_particles, widget.center, widget.color, _c.value),
          ),
        ),
      ),
    );
  }
}

class _RadialPainter extends CustomPainter {
  _RadialPainter(this.particles, this.center, this.color, this.t);
  final List<_P> particles;
  final Offset center;
  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final ease = Curves.easeOutCubic.transform(t);
    final paint = Paint()..color = color.withValues(alpha: (1 - t).clamp(0.0, 1.0));
    for (final p in particles) {
      final pos = center + Offset(cos(p.angle), sin(p.angle)) * p.dist * ease;
      canvas.drawCircle(pos, p.size * (1 - 0.4 * t), paint);
    }
  }

  @override
  bool shouldRepaint(_RadialPainter old) => old.t != t;
}

/// Chùm pháo giấy nhiều màu tỏa ra rồi rơi nhẹ — nhúng trong dialog thành công
/// (khoảnh khắc "thưởng"). Kích thước [size]; chạy một lần. Giảm chuyển động: ẩn.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.size = 180, this.count = 26});
  final double size;
  final int count;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final List<_C> _pieces;
  late final AnimationController _c =
      AnimationController(vsync: this, duration: AppMotion.celebrate);
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    _pieces = List.generate(widget.count, (i) {
      final angle = -pi / 2 + (rnd.nextDouble() - 0.5) * pi * 1.3; // hướng lên & tỏa
      return _C(
        angle: angle,
        speed: 0.5 + rnd.nextDouble() * 0.6,
        color: _kConfettiColors[i % _kConfettiColors.length],
        size: 5 + rnd.nextDouble() * 5,
        rot: rnd.nextDouble() * pi,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!context.reduceMotion) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return SizedBox(width: widget.size, height: widget.size);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(painter: _ConfettiPainter(_pieces, _c.value)),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_C> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height / 2);
    final reach = size.width * 0.6;
    for (final p in pieces) {
      // Tỏa ra theo góc + trọng lực kéo xuống dần.
      final dx = cos(p.angle) * p.speed * reach * t;
      final dy = sin(p.angle) * p.speed * reach * t + (reach * 0.9 * t * t);
      final pos = origin + Offset(dx, dy);
      final opacity = (1 - t).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.rot + t * 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

class _P {
  _P({required this.angle, required this.dist, required this.size});
  final double angle, dist, size;
}

class _C {
  _C({required this.angle, required this.speed, required this.color, required this.size, required this.rot});
  final double angle, speed, size, rot;
  final Color color;
}
