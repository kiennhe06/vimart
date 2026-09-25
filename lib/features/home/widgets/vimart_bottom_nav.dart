import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../home_ui.dart';

/// Một mục trong thanh điều hướng.
class NavItemData {
  const NavItemData({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Thanh điều hướng dưới cùng dạng "viên thuốc" nổi — mỗi mục là 1 vòng tròn.
/// Mục đang chọn: vòng tròn tô màu xanh nhạt + viền xanh + icon xanh.
/// (Tự dựng bằng Container + Row + GestureDetector — không dùng NavigationBar.)
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
    return Padding(
      padding: EdgeInsets.only(left: 18, right: 18, top: 6, bottom: 8 + bottomInset),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: HomeColors.surface,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: HomeColors.border),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 22, offset: Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < _items.length; i++)
              _NavCircle(
                data: _items[i],
                selected: i == currentIndex,
                badgeCount: i == 1 ? cartCount : 0,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavCircle extends StatelessWidget {
  const _NavCircle({
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? HomeColors.brandSoft : HomeColors.surface,
              border: Border.all(
                color: selected ? HomeColors.brand : HomeColors.border,
                width: selected ? 2 : 1.2,
              ),
            ),
            child: Icon(data.icon, size: 24, color: selected ? HomeColors.brand : HomeColors.textSecondary),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: HomeColors.brand,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: HomeColors.surface, width: 2),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
