import 'package:flutter/widgets.dart';

import '../app/cart_anchor.dart';
import '../app/motion.dart';
import 'network_image_box.dart';

/// Hiệu ứng **"bay vào giỏ"**: một ảnh sản phẩm thu nhỏ bay theo đường cong từ
/// [from] tới icon giỏ hàng (gắn [cartIconKey]) rồi thu lại và tan vào.
///
/// Đây là hiện thân của nguyên tắc **Liên tục**: sản phẩm không "biến mất rồi
/// hiện số" — nó di chuyển trong không gian tới giỏ, xác nhận rõ ràng hành động
/// và dẫn mắt người dùng tới nơi cần nhìn. Bỏ qua khi bật Giảm chuyển động.
void flyToCart(BuildContext context, {required Rect from, String? imageUrl, Color? color}) {
  if (context.reduceMotion) return;
  final overlay = Overlay.maybeOf(context);
  final targetCtx = cartIconKey.currentContext;
  if (overlay == null || targetCtx == null) return;
  final targetBox = targetCtx.findRenderObject() as RenderBox?;
  if (targetBox == null || !targetBox.attached) return;
  final to = targetBox.localToGlobal(targetBox.size.center(Offset.zero));

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _FlyingItem(
      from: from,
      to: to,
      imageUrl: imageUrl,
      color: color,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _FlyingItem extends StatefulWidget {
  const _FlyingItem({
    required this.from,
    required this.to,
    required this.onDone,
    this.imageUrl,
    this.color,
  });

  final Rect from;
  final Offset to;
  final VoidCallback onDone;
  final String? imageUrl;
  final Color? color;

  @override
  State<_FlyingItem> createState() => _FlyingItemState();
}

class _FlyingItemState extends State<_FlyingItem> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 640))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        })
        ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Bézier bậc hai: cong lên rồi rơi xuống giỏ (cảm giác "ném" tự nhiên).
  Offset _bezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = _c.value;
        final ease = Curves.easeInOutCubic.transform(t);
        final p0 = widget.from.center;
        final p2 = widget.to;
        // Điểm điều khiển đẩy lên trên -> quỹ đạo vòng cung.
        final control = Offset((p0.dx + p2.dx) / 2, (p0.dy < p2.dy ? p0.dy : p2.dy) - 120);
        final pos = _bezier(p0, control, p2, ease);
        final startSize = widget.from.shortestSide.clamp(40.0, 120.0);
        final size = startSize * (1 - 0.72 * ease); // thu nhỏ dần khi tới giỏ
        final opacity = t < 0.82 ? 1.0 : (1 - (t - 0.82) / 0.18);
        return Positioned(
          left: pos.dx - size / 2,
          top: pos.dy - size / 2,
          width: size,
          height: size,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: widget.color ?? const Color(0xFFE7F6EE),
                borderRadius: BorderRadius.circular(size * 0.28),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              clipBehavior: Clip.antiAlias,
              child: NetworkImageBox(url: widget.imageUrl),
            ),
          ),
        );
      },
    );
  }
}
