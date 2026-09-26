import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design.dart';
import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/i18n/app_strings.dart';
import '../../models/product.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/app_refresh.dart';
import '../../widgets/app_skeleton.dart';
import '../../widgets/async_view.dart';
import '../../widgets/entrance.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/pressable.dart';
import 'seller_repository.dart';

/// Màn quản lý sản phẩm của shop — thẻ bo tròn, có ảnh + nút sửa/xóa mềm.
class SellerProductsScreen extends ConsumerWidget {
  const SellerProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myProductsProvider);
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.myShopProducts)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/seller/products/new'),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addProduct, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: AppRefresh(
        onRefresh: () => ref.refresh(myProductsProvider.future),
        child: AsyncView(
          value: async,
          loading: const SkeletonList(count: 5, padding: EdgeInsets.fromLTRB(16, 12, 16, 90)),
          onRetry: () => ref.invalidate(myProductsProvider),
          data: (products) {
            if (products.isEmpty) {
              return ListView(children: [
                const SizedBox(height: 120),
                EmptyView(message: s.sellerNoProducts, icon: Icons.inventory_2_outlined),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: products.length,
              itemBuilder: (_, i) => FadeSlideIn(index: i, child: _ProductRow(product: products[i])),
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
    final s = ref.watch(stringsProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.c.border),
        boxShadow: AppShadow.soft(context.c.shadow),
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
                Text('${formatVnd(product.minPrice)} • ${s.sold(product.soldCount)}',
                    style: TextStyle(color: context.c.textSecondary, fontSize: 12)),
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
    return Pressable(
      onTap: onTap,
      scale: 0.85,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, size: 19, color: fg),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final s = ref.read(stringsProvider);
    final ok = await showAppDialog<bool>(
      context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteProduct),
        content: Text(s.deleteProductConfirm(product.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(sellerRepositoryProvider).deleteProduct(product.id);
        ref.invalidate(myProductsProvider);
        if (context.mounted) {
          showAppSnack(context, s.deleted, type: AppSnackType.success);
        }
      } catch (e) {
        if (context.mounted) {
          showAppSnack(context, e.toString(), type: AppSnackType.error);
        }
      }
    }
  }
}
