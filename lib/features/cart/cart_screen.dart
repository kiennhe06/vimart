import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/i18n/app_strings.dart';
import '../../models/cart.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/app_skeleton.dart';
import '../../widgets/async_view.dart';
import '../../widgets/entrance.dart';
import '../../widgets/login_required_view.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/pressable.dart';
import '../auth/auth_provider.dart';
import 'cart_provider.dart';

/// Giỏ hàng phong cách grocery: nhóm theo shop, mỗi món có bộ tăng/giảm tròn,
/// và thanh thanh toán lớn ở dưới.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;
    final cartAsync = ref.watch(cartProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.cart)),
      body: !isLoggedIn
          ? LoginRequiredView(message: s.loginToViewCart)
          : AsyncView(
              value: cartAsync,
              loading: const SkeletonList(count: 4),
              onRetry: () => ref.invalidate(cartProvider),
              data: (cart) => _buildCart(context, cart, s),
            ),
    );
  }

  Widget _buildCart(BuildContext context, Cart cart, AppStrings s) {
    if (cart.isEmpty) {
      return EmptyView(message: s.emptyCart, icon: Icons.shopping_cart_outlined);
    }
    final shippingTotal = cart.shops.length * 30000;
    final total = cart.subtotal + shippingTotal;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              for (final (i, shop) in cart.shops.indexed)
                FadeSlideIn(index: i, child: _ShopGroup(shop: shop)),
            ],
          ),
        ),
        _Footer(subtotal: cart.subtotal, shipping: shippingTotal, total: total, count: cart.itemCount),
      ],
    );
  }
}

/// Khối 1 shop: header (tên shop + thời gian giao) + các món.
class _ShopGroup extends ConsumerWidget {
  const _ShopGroup({required this.shop});
  final CartShop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 16, backgroundColor: AppColors.brandSoft,
                  child: Icon(Icons.storefront_rounded, size: 18, color: AppColors.brand)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shop.shopName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(s.deliveryIn15, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          for (final item in shop.items) _CartItemRow(item: item),
        ],
      ),
    );
  }
}

/// 1 món trong giỏ: ảnh + tên + phân loại + giá + bộ tăng/giảm tròn.
class _CartItemRow extends ConsumerWidget {
  const _CartItemRow({required this.item});
  final CartItem item;

  Future<void> _change(BuildContext context, WidgetRef ref, int qty) async {
    try {
      if (qty <= 0) {
        await ref.read(cartProvider.notifier).remove(item.cartItemId);
      } else {
        await ref.read(cartProvider.notifier).updateQuantity(item.cartItemId, qty);
      }
    } catch (e) {
      if (context.mounted) showAppSnack(context, e.toString(), type: AppSnackType.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Vuốt sang trái để xóa nhanh.
    return Dismissible(
      key: ValueKey(item.cartItemId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        AppHaptics.warning();
        ref.read(cartProvider.notifier).remove(item.cartItemId);
      },
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.danger),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 64, height: 64, color: AppColors.brandSoft,
              child: NetworkImageBox(url: item.imageUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(item.variantName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(formatVnd(item.price),
                    style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
          ),
          _QtyStepper(
            qty: item.quantity,
            canIncrease: item.quantity < item.stock,
            onDecrease: () => _change(context, ref, item.quantity - 1),
            onIncrease: () => _change(context, ref, item.quantity + 1),
          ),
        ],
        ),
      ),
    );
  }
}

/// Bộ tăng/giảm số lượng dạng nút tròn (− viền, + nền xanh).
class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });
  final int qty;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _circle(context, Icons.remove_rounded, onDecrease, filled: false),
        SizedBox(
          width: 30,
          child: AnimatedSwitcher(
            duration: AppMotion.dur(context, AppMotion.fast),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Text('$qty',
                key: ValueKey(qty),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
        _circle(context, Icons.add_rounded, canIncrease ? onIncrease : null, filled: true),
      ],
    );
  }

  Widget _circle(BuildContext context, IconData icon, VoidCallback? onTap, {required bool filled}) {
    return Pressable(
      onTap: onTap,
      scale: 0.82,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? (onTap == null ? Colors.grey.shade200 : AppColors.brand) : Colors.white,
          border: filled ? null : Border.all(color: const Color(0xFFDDE1E6)),
        ),
        child: Icon(icon, size: 18, color: filled ? Colors.white : AppColors.brand),
      ),
    );
  }
}

/// Thanh dưới cùng: tổng tiền + nút thanh toán lớn.
class _Footer extends ConsumerWidget {
  const _Footer({required this.subtotal, required this.shipping, required this.total, required this.count});
  final int subtotal, shipping, total, count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row(s.subtotal, formatVnd(subtotal)),
            const SizedBox(height: 6),
            _row(s.shippingFee, formatVnd(shipping)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.total, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: total),
                  duration: AppMotion.dur(context, AppMotion.slow),
                  curve: AppMotion.enter,
                  builder: (context, value, _) => Text(
                    formatVnd(value),
                    style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => context.push('/checkout'),
              child: Text(s.checkoutItems(count)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: highlight ? null : Colors.grey.shade700,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w500, fontSize: highlight ? 16 : 14)),
        Text(value, style: TextStyle(color: highlight ? AppColors.brand : null,
            fontWeight: FontWeight.w800, fontSize: highlight ? 18 : 14)),
      ],
    );
  }
}
