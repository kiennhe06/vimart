import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../models/product.dart';
import '../home_ui.dart';

/// Card sản phẩm tự dựng hoàn toàn (KHÔNG dùng Card):
/// Container(bo góc + bóng) > Column [ ảnh vuông bo góc trên, khối chữ ].
class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product});

  final ProductCard product;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: HomeColors.surface,
          borderRadius: BorderRadius.circular(HomeDims.radiusCard),
          boxShadow: const [
            BoxShadow(color: HomeColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh vuông, bo tròn 2 góc trên
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(HomeDims.radiusCard)),
                child: _ProductImage(url: product.imageUrl),
              ),
            ),
            // Khối thông tin
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 34,
                    child: Text(
                      product.name,
                      style: HomeText.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(formatVnd(product.minPrice), style: HomeText.price),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const _Star(size: 12),
                      const SizedBox(width: 3),
                      Text(
                        product.ratingCount > 0 ? product.ratingAvg.toStringAsFixed(1) : 'Mới',
                        style: HomeText.meta,
                      ),
                      const Spacer(),
                      Text('Đã bán ${product.soldCount}', style: HomeText.meta),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ảnh sản phẩm: nền tải + xử lý lỗi, tự viết (không dùng thư viện ngoài).
class _ProductImage extends StatelessWidget {
  const _ProductImage({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _fallback();
    return Image.network(
      url!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const ColoredBox(color: Color(0xFFF0F0F3)),
      errorBuilder: (context, error, stack) => _fallback(),
    );
  }

  Widget _fallback() => const ColoredBox(color: Color(0xFFEDEDF1));
}

/// Ngôi sao đánh giá tự vẽ bằng CustomPaint.
class _Star extends StatelessWidget {
  const _Star({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _StarPainter());
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = HomeColors.star;
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = size.width / 2;
    final inner = outer * 0.42;
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
