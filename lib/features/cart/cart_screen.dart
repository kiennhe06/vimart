import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../models/cart.dart';
import '../../widgets/async_view.dart';
import '../../widgets/login_required_view.dart';
import '../auth/auth_provider.dart';
import 'cart_provider.dart';

/// Tab Giỏ hàng: hiển thị các món gộp theo shop, chỉnh số lượng, và đi tới thanh toán.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: !isLoggedIn
          ? const LoginRequiredView(message: 'Đăng nhập để xem giỏ hàng của bạn')
          : AsyncView(
              value: cartAsync,
              onRetry: () => ref.invalidate(cartProvider),
              data: (cart) => _buildCart(context, ref, cart),
            ),
    );
  }

  Widget _buildCart(BuildContext context, WidgetRef ref, Cart cart) {
    if (cart.isEmpty) {
      return const EmptyView(message: 'Giỏ hàng đang trống', icon: Icons.shopping_cart_outlined);
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final shop in cart.shops) _ShopGroup(shop: shop),
            ],
          ),
        ),
        _CartFooter(cart: cart),
      ],
    );
  }
}

/// Nhóm các món của 1 shop.
class _ShopGroup extends StatelessWidget {
  const _ShopGroup({required this.shop});
  final CartShop shop;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront, size: 18),
                const SizedBox(width: 6),
                Text(shop.shopName, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            for (final item in shop.items) _CartItemRow(item: item),
          ],
        ),
      ),
    );
  }
}

/// Một dòng sản phẩm trong giỏ, có nút tăng/giảm và xóa.
class _CartItemRow extends ConsumerWidget {
  const _CartItemRow({required this.item});
  final CartItem item;

  Future<void> _changeQty(BuildContext context, WidgetRef ref, int qty) async {
    try {
      if (qty <= 0) {
        await ref.read(cartProvider.notifier).remove(item.cartItemId);
      } else {
        await ref.read(cartProvider.notifier).updateQuantity(item.cartItemId, qty);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis),
                Text('Phân loại: ${item.variantName}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(formatVnd(item.price),
                    style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  _QtyButton(icon: Icons.remove, onTap: () => _changeQty(context, ref, item.quantity - 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
                  ),
                  _QtyButton(
                    icon: Icons.add,
                    onTap: item.quantity < item.stock
                        ? () => _changeQty(context, ref, item.quantity + 1)
                        : null,
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _changeQty(context, ref, 0),
                child: const Text('Xóa', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: onTap == null ? Colors.grey.shade300 : null),
      ),
    );
  }
}

/// Thanh tổng tiền + nút mua hàng.
class _CartFooter extends StatelessWidget {
  const _CartFooter({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tạm tính', style: TextStyle(color: Colors.grey)),
                Text(formatVnd(cart.subtotal),
                    style: const TextStyle(
                        color: AppColors.brand, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => context.push('/checkout'),
              child: Text('Mua hàng (${cart.itemCount})'),
            ),
          ],
        ),
      ),
    );
  }
}
