import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design.dart';
import '../../widgets/sticker_icon.dart';
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
import '../../widgets/rolling_number.dart';
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
      return EmptyView(message: s.emptyCart, sticker: 'cart');
    }

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
        _Footer(cart: cart),
      ],
    );
  }
}

/// Ô chọn tròn (checkbox) cho từng món / shop / tất cả.
class _CheckDot extends StatelessWidget {
  const _CheckDot({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.85,
      child: AnimatedContainer(
        duration: AppMotion.dur(context, AppMotion.fast),
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.brand : context.c.surface,
          border: Border.all(
            color: selected ? AppColors.brand : context.c.border,
            width: 1.6,
          ),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, size: 15, color: Color(0xFFFFFFFF))
            : null,
      ),
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
    final selected = ref.watch(cartSelectionProvider);
    final shopVariantIds = shop.items.map((e) => e.variantId).toList();
    final allSelected = shopVariantIds.every(selected.contains);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: context.c.shadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CheckDot(
                selected: allSelected,
                onTap: () => ref
                    .read(cartSelectionProvider.notifier)
                    .setMany(shopVariantIds, !allSelected),
              ),
              const SizedBox(width: 10),
              CircleAvatar(radius: 16, backgroundColor: context.c.surface,
                  child: const StickerIcon('shop', size: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shop.shopName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(s.deliveryIn15, style: TextStyle(color: context.c.textSecondary, fontSize: 12)),
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
    final selected = ref.watch(cartSelectionProvider).contains(item.variantId);
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
        child: const StickerIcon('trash', size: 26),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
        children: [
          _CheckDot(
            selected: selected,
            onTap: () => ref.read(cartSelectionProvider.notifier).toggle(item.variantId),
          ),
          const SizedBox(width: 10),
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
                Text(item.variantName, style: TextStyle(color: context.c.textSecondary, fontSize: 12)),
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
        _circle(context, 'minus', onDecrease),
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
        _circle(context, 'plus', canIncrease ? onIncrease : null),
      ],
    );
  }

  Widget _circle(BuildContext context, String sticker, VoidCallback? onTap) {
    return Pressable(
      onTap: onTap,
      scale: 0.82,
      child: StickerIcon(sticker, size: 32, colorFilter: onTap == null ? StickerIcon.grayscale : null),
    );
  }
}

/// Thanh dưới cùng: chọn-tất-cả + tổng tiền (phần đã chọn) + nút thanh toán.
class _Footer extends ConsumerWidget {
  const _Footer({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final selected = ref.watch(cartSelectionProvider);
    final sum = ref.watch(selectedCartSummaryProvider);

    final allVariantIds = [
      for (final shop in cart.shops)
        for (final item in shop.items) item.variantId,
    ];
    final allSelected = allVariantIds.isNotEmpty && allVariantIds.every(selected.contains);
    final shipping = sum.shopCount * 30000;
    final total = sum.subtotal + shipping;
    final hasSelection = sum.count > 0;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: context.c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: context.c.shadow, blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row(s.subtotal, formatVnd(sum.subtotal)),
            const SizedBox(height: 6),
            _row(s.shippingFee, formatVnd(shipping)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
            Row(
              children: [
                // Chọn / bỏ chọn tất cả.
                _CheckDot(
                  selected: allSelected,
                  onTap: () => ref
                      .read(cartSelectionProvider.notifier)
                      .setMany(allVariantIds, !allSelected),
                ),
                const SizedBox(width: 8),
                Text(s.selectAll, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                Text(s.total, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(width: 8),
                // Tổng tiền "cuộn" tới giá trị mới khi đổi lựa chọn/số lượng.
                RollingNumber(
                  value: total,
                  format: formatVnd,
                  style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: hasSelection ? () => context.push('/checkout') : null,
              child: Text(s.checkoutItems(sum.count)),
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
