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

/// Khung chính của app.
/// Thanh điều hướng dưới cùng được DỰNG LẠI TỪ ĐẦU (VimartBottomNav) — không dùng
/// NavigationBar/BottomNavigationBar. Dùng IndexedStack để giữ trạng thái từng tab.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    CartScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartCountProvider);

    // Material cung cấp DefaultTextStyle chuẩn (tránh gạch chân vàng debug khi
    // Text không có ancestor Material). Đây là widget nền tảng, không phải component UI ăn sẵn.
    return Material(
      color: HomeColors.background,
      child: Column(
        children: [
          Expanded(child: IndexedStack(index: _index, children: _screens)),
          VimartBottomNav(
            currentIndex: _index,
            cartCount: cartCount,
            onTap: (i) => setState(() => _index = i),
          ),
        ],
      ),
    );
  }
}
