import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../widgets/async_view.dart';
import 'seller_repository.dart';

/// Màn hình quản lý sản phẩm của shop (người bán).
class SellerProductsScreen extends ConsumerWidget {
  const SellerProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myProductsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm của shop')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/seller/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('Thêm sản phẩm'),
      ),
      body: RefreshIndicator(
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
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];
                return Card(
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text('${formatVnd(p.minPrice)} • Đã bán ${p.soldCount}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => context.push('/seller/products/edit/${p.id}'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                          onPressed: () => _confirmDelete(context, ref, p.id, p.name),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, int id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Xóa "$name"? Hành động này không thể hoàn tác.'),
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
        await ref.read(sellerRepositoryProvider).deleteProduct(id);
        ref.invalidate(myProductsProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }
}
