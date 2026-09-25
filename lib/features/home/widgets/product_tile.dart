import 'package:flutter/material.dart'
    show Icons, CircularProgressIndicator, SnackBarAction, Colors;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/motion.dart';
import '../../../core/format.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../models/product.dart';
import '../../../widgets/app_feedback.dart';
import '../../../widgets/network_image_box.dart';
import '../../../widgets/pressable.dart';
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
  bool _justAdded = false;

  /// Thêm nhanh: lấy phân loại đầu tiên còn hàng rồi bỏ vào giỏ.
  Future<void> _quickAdd() async {
    final s = ref.read(stringsProvider);
    if (!ref.read(authProvider).isLoggedIn) {
      showAppSnack(
        context,
        s.loginToBuy,
        type: AppSnackType.warning,
        action: SnackBarAction(label: s.login, onPressed: () => context.push('/login')),
      );
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
      if (variant.id == 0) throw Exception(s.tempOutOfStock);
      await ref.read(cartProvider.notifier).add(variant.id, 1);
      if (mounted) {
        setState(() => _justAdded = true);
        showAppSnack(context, s.addedToCart, type: AppSnackType.success);
        Future.delayed(const Duration(milliseconds: 1100), () {
          if (mounted) setState(() => _justAdded = false);
        });
      }
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final s = ref.watch(stringsProvider);
    final tint = widget.tint ?? HomeColors.brandSoft;
    return Pressable(
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
            // Ảnh trên nền pastel bo tròn — Hero nối sang trang chi tiết.
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: Hero(
                  tag: 'product-image-${p.id}',
                  child: NetworkImageBox(url: p.imageUrl),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: HomeText.productName),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 14, color: HomeColors.star),
                const SizedBox(width: 2),
                Text(p.ratingCount > 0 ? p.ratingAvg.toStringAsFixed(1) : s.newLabel, style: HomeText.meta),
                Text('  •  ${s.sold(p.soldCount)}', style: HomeText.meta),
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

  /// Thanh "+" đầy chiều rộng ở đáy thẻ (thêm nhanh vào giỏ) — morph "+" → ✓.
  Widget _addBar() {
    final busy = _adding;
    return Pressable(
      onTap: (busy || _justAdded) ? null : _quickAdd,
      haptic: false, // haptic do showAppSnack(success) đảm nhiệm
      scale: 0.94,
      child: AnimatedContainer(
        duration: AppMotion.dur(context, AppMotion.base),
        curve: AppMotion.emphasized,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _justAdded ? HomeColors.brand : HomeColors.brandSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedSwitcher(
          duration: AppMotion.dur(context, AppMotion.fast),
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: busy
              ? const SizedBox(
                  key: ValueKey('load'),
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: HomeColors.brand),
                )
              : _justAdded
                  ? const Icon(Icons.check_rounded, key: ValueKey('ok'), color: Colors.white, size: 22)
                  : const Icon(Icons.add_rounded, key: ValueKey('add'), color: HomeColors.brand, size: 22),
        ),
      ),
    );
  }
}
