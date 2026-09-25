import 'package:flutter/material.dart' show Material;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/cart/cart_provider.dart';
import '../features/cart/cart_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/home_ui.dart';
import '../features/home/widgets/vimart_bottom_nav.dart';
import '../features/order/orders_screen.dart';
import '../features/profile/profile_screen.dart';
import '../core/i18n/app_strings.dart';
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
      color: HomeColors.background,
      child: Column(
        children: [
          Expanded(child: IndexedStack(index: index, children: _screens)),
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
