import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/i18n/app_strings.dart';
import '../../models/product.dart';
import '../../widgets/app_busy.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/async_view.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/pressable.dart';
import '../auth/auth_provider.dart';
import '../cart/cart_provider.dart';
import '../favorite/favorite_provider.dart';
import 'catalog_providers.dart';

/// Trang chi tiết sản phẩm — phong cách grocery: ảnh lớn nền pastel,
/// giá nổi bật, chọn phân loại, bộ tăng/giảm số lượng và nút thêm vào giỏ.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int? _selectedVariantId;
  int _qty = 1;
  bool _adding = false;
  bool _fav = false;

  Future<void> _addToCart(Variant variant) async {
    if (!ref.read(authProvider).isLoggedIn) {
      _promptLogin();
      return;
    }
    setState(() => _adding = true);
    try {
      await ref.read(cartProvider.notifier).add(variant.id, _qty);
      if (mounted) showAppSnack(context, ref.read(stringsProvider).addedToCart, type: AppSnackType.success);
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _promptLogin() {
    final s = ref.read(stringsProvider);
    showAppSnack(
      context,
      s.loginToBuy,
      type: AppSnackType.warning,
      action: SnackBarAction(label: s.login, onPressed: () => context.push('/login')),
    );
  }

  Future<void> _addFavorite() async {
    if (!ref.read(authProvider).isLoggedIn) return _promptLogin();
    setState(() => _fav = true); // phản hồi tức thì (heart pop)
    AppHaptics.success();
    try {
      await ref.read(favoriteRepositoryProvider).add(widget.productId);
      ref.invalidate(favoritesProvider);
      if (mounted) showAppSnack(context, ref.read(stringsProvider).addedFavorite, type: AppSnackType.success);
    } catch (e) {
      if (mounted) {
        setState(() => _fav = false);
        showAppSnack(context, e.toString(), type: AppSnackType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productDetailProvider(widget.productId));
    return Scaffold(
      body: AsyncView(
        value: async,
        onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
        data: _buildContent,
      ),
    );
  }

  Widget _buildContent(ProductDetail product) {
    final s = ref.watch(stringsProvider);
    final selected = product.variants.firstWhere(
      (v) => v.id == _selectedVariantId,
      orElse: () => product.variants.isNotEmpty
          ? product.variants.first
          : Variant(id: 0, name: '-', price: 0, stock: 0),
    );

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              // Ảnh lớn nền pastel + nút back/favorite
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.brandSoft,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Row(
                            children: [
                              _circleBtn(Icons.arrow_back_ios_new_rounded, () => context.pop()),
                              const Spacer(),
                              _favBtn(),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 250,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Hero(
                              tag: 'product-image-${widget.productId}',
                              child: NetworkImageBox(url: product.imageUrl, fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Nội dung
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F6F5),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.25)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 18, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              product.ratingCount > 0
                                  ? '${product.ratingAvg.toStringAsFixed(1)} (${product.ratingCount})'
                                  : s.noReviews,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 12),
                            Text(s.sold(product.soldCount), style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        AnimatedSwitcher(
                          duration: AppMotion.dur(context, AppMotion.base),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Text(
                            formatVnd(selected.price),
                            key: ValueKey(selected.price),
                            style: const TextStyle(
                                color: AppColors.brand, fontSize: 26, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Shop
                        _shopChip(context, product),
                        const SizedBox(height: 18),
                        Text(s.options, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: product.variants.map((v) => _variantChip(v, selected)).toList(),
                        ),
                        const SizedBox(height: 6),
                        Text(s.remaining(selected.stock), style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 20),
                        Text(s.description, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(product.description?.isNotEmpty == true ? product.description! : s.noDescription,
                            style: const TextStyle(height: 1.5, color: Color(0xFF4B5563))),
                        const SizedBox(height: 20),
                        Text(s.reviewsWithCount(product.reviews.length),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 8),
                        if (product.reviews.isEmpty)
                          Text(s.noReviewYet, style: const TextStyle(color: Colors.grey))
                        else
                          ...product.reviews.map(_ReviewTile.new),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _bottomBar(selected),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }

  /// Nút yêu thích — chạm để "thích", tim nở từ viền → đặc đỏ.
  Widget _favBtn() {
    return Pressable(
      onTap: _fav ? null : _addFavorite,
      haptic: false,
      child: Container(
        width: 44, height: 44,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: AppMotion.dur(context, AppMotion.base),
          transitionBuilder: (c, a) =>
              ScaleTransition(scale: CurvedAnimation(parent: a, curve: AppMotion.pop), child: c),
          child: Icon(
            _fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(_fav),
            size: 20,
            color: _fav ? AppColors.danger : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _shopChip(BuildContext context, ProductDetail product) {
    return Pressable(
      onTap: () => context.push('/shop/${product.shop.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const CircleAvatar(radius: 18, backgroundColor: AppColors.brandSoft,
                child: Icon(Icons.storefront_rounded, color: AppColors.brand, size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Text(product.shop.name, style: const TextStyle(fontWeight: FontWeight.w700))),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _variantChip(Variant v, Variant selected) {
    final isSel = selected.id == v.id;
    return Pressable(
      onTap: v.inStock ? () => setState(() => _selectedVariantId = v.id) : null,
      child: AnimatedContainer(
        duration: AppMotion.dur(context, AppMotion.base),
        curve: AppMotion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? AppColors.brand : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSel ? AppColors.brand : const Color(0xFFECEFF1)),
          boxShadow: isSel
              ? [BoxShadow(color: AppColors.brand.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Text(
          '${v.name}${v.inStock ? '' : ref.read(stringsProvider).outSuffix}',
          style: TextStyle(
            color: isSel ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(Variant selected) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)],
        ),
        child: Row(
          children: [
            // Bộ tăng/giảm số lượng
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _stepBtn(Icons.remove_rounded, _qty > 1 ? () => setState(() => _qty--) : null),
                  SizedBox(
                    width: 28,
                    child: AnimatedSwitcher(
                      duration: AppMotion.dur(context, AppMotion.fast),
                      transitionBuilder: (c, a) =>
                          ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
                      child: Text('$_qty',
                          key: ValueKey(_qty),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  _stepBtn(Icons.add_rounded,
                      _qty < selected.stock ? () => setState(() => _qty++) : null),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: (_adding || !selected.inStock) ? null : () => _addToCart(selected),
                child: BusySwitch(
                  busy: _adding,
                  child: Text(selected.inStock
                      ? ref.read(stringsProvider).addToCartWith(formatVnd(selected.price * _qty))
                      : ref.read(stringsProvider).outOfStock),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) {
    return Pressable(
      onTap: onTap,
      scale: 0.85,
      child: Container(
        width: 44, height: 44, alignment: Alignment.center,
        child: Icon(icon, size: 20, color: onTap == null ? Colors.grey.shade400 : AppColors.brand),
      ),
    );
  }
}

class _ReviewTile extends ConsumerWidget {
  const _ReviewTile(this.review);
  final Review review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(review.userName ?? ref.watch(stringsProvider).user, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Row(
                children: List.generate(5, (i) => Icon(Icons.star_rounded,
                    size: 14, color: i < review.rating ? AppColors.accent : Colors.grey.shade300)),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text(review.comment!)),
        ],
      ),
    );
  }
}
