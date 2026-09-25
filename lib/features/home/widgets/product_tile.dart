import 'package:flutter/material.dart' show Icons, ScaffoldMessenger, SnackBar, SnackBarAction, CircularProgressIndicator;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../models/product.dart';
import '../../auth/auth_provider.dart';
import '../../cart/cart_provider.dart';
import '../../catalog/catalog_repository.dart';
import '../home_ui.dart';

/// Thẻ sản phẩm phong cách grocery: ảnh nền mềm + tên + giá + nút "+" thêm nhanh.
class ProductTile extends ConsumerStatefulWidget {
  const ProductTile({super.key, required this.product, this.tint});
  final ProductCard product;
  final Color? tint;

  @override
  ConsumerState<ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends ConsumerState<ProductTile> {
  bool _adding = false;

  /// Thêm nhanh: lấy phân loại đầu tiên còn hàng rồi bỏ vào giỏ.
  Future<void> _quickAdd() async {
    if (!ref.read(authProvider).isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Vui lòng đăng nhập để mua hàng'),
        action: SnackBarAction(label: 'Đăng nhập', onPressed: () => context.push('/login')),
      ));
      return;
    }
    setState(() => _adding = true);
    try {
      final detail = await ref.read(catalogRepositoryProvider).getProduct(widget.product.id);
      final variant = detail.variants.firstWhere(
        (v) => v.inStock,
        orElse: () => detail.variants.isNotEmpty
            ? detail.variants.first
            : Variant(id: 0, name: '-', price: 0, stock: 0),
      );
      if (variant.id == 0) throw Exception('Sản phẩm tạm hết hàng');
      await ref.read(cartProvider.notifier).add(variant.id, 1);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã thêm vào giỏ hàng')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final tint = widget.tint ?? HomeColors.brandSoft;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/product/${p.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: HomeColors.surface,
          borderRadius: BorderRadius.circular(HomeDims.radiusCard),
          boxShadow: const [BoxShadow(color: HomeColors.shadow, blurRadius: 14, offset: Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh trên nền pastel bo tròn
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: _image(p.imageUrl),
              ),
            ),
            const SizedBox(height: 10),
            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: HomeText.productName),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 14, color: HomeColors.star),
                const SizedBox(width: 2),
                Text(p.ratingCount > 0 ? p.ratingAvg.toStringAsFixed(1) : 'Mới', style: HomeText.meta),
                Text('  •  Đã bán ${p.soldCount}', style: HomeText.meta),
              ],
            ),
            const SizedBox(height: 6),
            Text(formatVnd(p.minPrice), style: HomeText.price),
            const SizedBox(height: 8),
            _addBar(),
          ],
        ),
      ),
    );
  }

  Widget _image(String? url) {
    if (url == null || url.isEmpty) {
      return const Icon(Icons.image_not_supported_outlined, color: HomeColors.textSecondary);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (c, child, progress) => progress == null ? child : const SizedBox(),
      errorBuilder: (c, e, s) => const Icon(Icons.broken_image_outlined, color: HomeColors.textSecondary),
    );
  }

  /// Thanh "+" đầy chiều rộng ở đáy thẻ (thêm nhanh vào giỏ).
  Widget _addBar() {
    return GestureDetector(
      onTap: _adding ? null : _quickAdd,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: HomeColors.brandSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: _adding
            ? const SizedBox(
                height: 16, width: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: HomeColors.brand))
            : const Icon(Icons.add_rounded, color: HomeColors.brand, size: 22),
      ),
    );
  }
}
