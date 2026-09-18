import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../home_ui.dart';

/// Một mục trong thanh điều hướng.
class NavItemData {
  const NavItemData({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Thanh điều hướng dưới cùng — tự dựng bằng Container + Row + GestureDetector
/// (KHÔNG dùng BottomNavigationBar/NavigationBar).
/// Mục đang chọn: icon + chữ cam, có "viên thuốc" nền cam nhạt bao quanh icon.
class VimartBottomNav extends StatelessWidget {
  const VimartBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;

  static const List<NavItemData> _items = [
    NavItemData(icon: Icons.home_rounded, label: 'Trang chủ'),
    NavItemData(icon: Icons.shopping_cart_rounded, label: 'Giỏ hàng'),
    NavItemData(icon: Icons.receipt_long_rounded, label: 'Đơn hàng'),
    NavItemData(icon: Icons.person_rounded, label: 'Tài khoản'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: HomeColors.surface,
        border: Border(top: BorderSide(color: HomeColors.border)),
        boxShadow: [BoxShadow(color: HomeColors.shadow, blurRadius: 16, offset: Offset(0, -2))],
      ),
      padding: EdgeInsets.only(top: 8, bottom: 8 + bottomInset, left: 8, right: 8),
      child: Row(
        children: [
          for (int i = 0; i < _items.length; i++)
            Expanded(
              child: _NavItem(
                data: _items[i],
                selected: i == currentIndex,
                badgeCount: i == 1 ? cartCount : 0,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final NavItemData data;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = selected ? HomeColors.primaryOrange : HomeColors.textSecondary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Viên thuốc nền cam nhạt khi được chọn
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 52,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? HomeColors.selectedBg : const Color(0x00000000),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(data.icon, size: 22, color: color),
              ),
              // Badge số lượng giỏ hàng
              if (badgeCount > 0)
                Positioned(
                  right: 2,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: HomeColors.primaryOrange,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: HomeColors.surface, width: 1.5),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(data.label, style: selected ? HomeText.navActive : HomeText.navInactive),
        ],
      ),
    );
  }
}
