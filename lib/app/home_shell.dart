import 'package:flutter/material.dart' show Material;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/cart/cart_provider.dart';
import '../features/cart/cart_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/widgets/vimart_bottom_nav.dart';
import '../features/order/orders_screen.dart';
import '../features/profile/profile_screen.dart';
import '../core/i18n/app_strings.dart';
import 'design.dart';
import 'motion.dart';
import 'nav_provider.dart';

/// Khung chính của app với thanh điều hướng dưới dạng "viên thuốc" nổi.
/// Chỉ số tab lấy từ [bottomNavIndexProvider] để chuyển tab được từ mọi nơi.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _screens = [
    HomeScreen(),
    CartScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(bottomNavIndexProvider);
    final cartCount = ref.watch(cartCountProvider);
    final s = ref.watch(stringsProvider);

    return Material(
      color: context.c.background,
      child: Column(
        children: [
          Expanded(child: _SharedAxisTabs(index: index, children: _screens)),
          VimartBottomNav(
            currentIndex: index,
            cartCount: cartCount,
            labels: [s.navHome, s.cart, s.orders, s.account],
            onTap: (i) => ref.read(bottomNavIndexProvider.notifier).go(i),
          ),
        ],
      ),
    );
  }
}

/// Chuyển tab kiểu **shared-axis** (trượt ngang theo hướng + mờ vào) — thể hiện
/// quan hệ ngang hàng giữa các tab. Vẫn dùng [IndexedStack] nên state mỗi tab
/// được giữ nguyên (không dựng lại). Tôn trọng Giảm chuyển động (hiện thẳng).
class _SharedAxisTabs extends StatefulWidget {
  const _SharedAxisTabs({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_SharedAxisTabs> createState() => _SharedAxisTabsState();
}

class _SharedAxisTabsState extends State<_SharedAxisTabs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: AppMotion.page, value: 1);
  double _dir = 1; // +1: tab mới ở bên phải trượt vào; -1: bên trái

  @override
  void didUpdateWidget(covariant _SharedAxisTabs old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _dir = widget.index > old.index ? 1 : -1;
      if (context.reduceMotion) {
        _c.value = 1;
      } else {
        _c.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = IndexedStack(index: widget.index, children: widget.children);
    return AnimatedBuilder(
      animation: _c,
      child: RepaintBoundary(child: content),
      builder: (_, child) {
        final t = AppMotion.enter.transform(_c.value);
        final dx = (1 - t) * 26 * _dir; // trượt 26px theo hướng chuyển tab
        return Opacity(
          opacity: _c.value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(dx, 0), child: child),
        );
      },
    );
  }
}
