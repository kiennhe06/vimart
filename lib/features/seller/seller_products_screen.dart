import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../models/product.dart';
import '../../widgets/async_view.dart';
import '../../widgets/network_image_box.dart';
import 'seller_repository.dart';

/// Màn quản lý sản phẩm của shop — thẻ bo tròn, có ảnh + nút sửa/xóa mềm.
class SellerProductsScreen extends ConsumerWidget {
  const SellerProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myProductsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm của shop')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/seller/products/new'),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm sản phẩm', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: () => ref.refresh(myProductsProvider.future),
        child: AsyncView(
          value: async,
          onRetry: () => ref.invalidate(myProductsProvider),
          data: (products) {
            if (products.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                EmptyView(message: 'Shop chưa có sản phẩm nào.\nBấm "Thêm sản phẩm" để đăng bán.',
                    icon: Icons.inventory_2_outlined),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: products.length,
              itemBuilder: (_, i) => _ProductRow(product: products[i]),
            );
          },
        ),
      ),
    );
  }
}

class _ProductRow extends ConsumerWidget {
  const _ProductRow({required this.product});
  final ProductCard product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 58, height: 58, color: AppColors.brandSoft,
              child: NetworkImageBox(url: product.imageUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 4),
                Text('${formatVnd(product.minPrice)} • Đã bán ${product.soldCount}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          _iconBtn(Icons.edit_rounded, AppColors.brandSoft, AppColors.brand,
              () => context.push('/seller/products/edit/${product.id}')),
          const SizedBox(width: 8),
          _iconBtn(Icons.delete_rounded, const Color(0xFFFDECEC), AppColors.danger,
              () => _confirmDelete(context, ref)),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, size: 19, color: fg),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Xóa "${product.name}"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(sellerRepositoryProvider).deleteProduct(product.id);
        ref.invalidate(myProductsProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }
}
