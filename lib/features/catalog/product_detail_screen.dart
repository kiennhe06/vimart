import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../models/product.dart';
import '../../widgets/async_view.dart';
import '../../widgets/network_image_box.dart';
import '../auth/auth_provider.dart';
import '../cart/cart_provider.dart';
import '../favorite/favorite_provider.dart';
import 'catalog_providers.dart';

/// Trang chi tiết sản phẩm: chọn phân loại, thêm vào giỏ, xem đánh giá.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int? _selectedVariantId;
  bool _adding = false;

  Future<void> _addToCart(Variant variant) async {
    if (!ref.read(authProvider).isLoggedIn) {
      _promptLogin();
      return;
    }
    setState(() => _adding = true);
    try {
      await ref.read(cartProvider.notifier).add(variant.id, 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm vào giỏ hàng')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _promptLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Vui lòng đăng nhập để mua hàng'),
        action: SnackBarAction(label: 'Đăng nhập', onPressed: () => context.push('/login')),
      ),
    );
  }

  Future<void> _addFavorite() async {
    if (!ref.read(authProvider).isLoggedIn) {
      _promptLogin();
      return;
    }
    try {
      await ref.read(favoriteRepositoryProvider).add(widget.productId);
      ref.invalidate(favoritesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã thêm vào yêu thích')));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: _addFavorite),
        ],
      ),
      body: AsyncView(
        value: async,
        onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
        data: (product) => _buildContent(product),
      ),
    );
  }

  Widget _buildContent(ProductDetail product) {
    final selected = product.variants.firstWhere(
      (v) => v.id == _selectedVariantId,
      orElse: () => product.variants.isNotEmpty
          ? product.variants.first
          : Variant(id: 0, name: '-', price: 0, stock: 0),
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: NetworkImageBox(url: product.imageUrl),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatVnd(selected.price),
                        style: const TextStyle(color: AppColors.brand, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(product.ratingCount > 0
                            ? '${product.ratingAvg.toStringAsFixed(1)} (${product.ratingCount} đánh giá)'
                            : 'Chưa có đánh giá'),
                        const Spacer(),
                        Text('Đã bán ${product.soldCount}', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const Divider(height: 32),
                    // Chọn phân loại
                    const Text('Phân loại', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.variants.map((v) {
                        return ChoiceChip(
                          label: Text('${v.name} ${v.inStock ? '' : '(hết)'}'),
                          selected: selected.id == v.id,
                          onSelected: v.inStock ? (_) => setState(() => _selectedVariantId = v.id) : null,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 4),
                    Text('Còn lại: ${selected.stock}', style: const TextStyle(color: Colors.grey)),
                    const Divider(height: 32),
                    // Shop
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.storefront)),
                      title: Text(product.shop.name),
                      subtitle: const Text('Xem shop'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/shop/${product.shop.id}'),
                    ),
                    const Divider(height: 32),
                    // Mô tả
                    const Text('Mô tả sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(product.description?.isNotEmpty == true
                        ? product.description!
                        : 'Chưa có mô tả.'),
                    const Divider(height: 32),
                    // Đánh giá
                    Text('Đánh giá (${product.reviews.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (product.reviews.isEmpty)
                      const Text('Chưa có đánh giá nào.', style: TextStyle(color: Colors.grey))
                    else
                      ...product.reviews.map(_ReviewTile.new),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Nút thêm vào giỏ
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: (_adding || !selected.inStock) ? null : () => _addToCart(selected),
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(selected.inStock ? 'Thêm vào giỏ hàng' : 'Hết hàng'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Một dòng đánh giá.
class _ReviewTile extends StatelessWidget {
  const _ReviewTile(this.review);
  final Review review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(review.userName ?? 'Người dùng', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(Icons.star,
                      size: 14, color: i < review.rating ? AppColors.accent : Colors.grey.shade300),
                ),
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
