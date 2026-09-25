import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../home_ui.dart';

/// Thanh điều hướng dưới cùng dạng "viên thuốc" nổi — mỗi mục là 1 vòng tròn.
/// Mục đang chọn: vòng tròn tô màu xanh nhạt + viền xanh + icon xanh.
/// (Tự dựng bằng Container + Row + GestureDetector — không dùng NavigationBar.)
class VimartBottomNav extends StatelessWidget {
  const VimartBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.labels,
    this.cartCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;

  /// Nhãn (đã dịch) cho từng mục — dùng làm Semantics label cho icon.
  final List<String> labels;

  static const List<IconData> _icons = [
    Icons.home_rounded,
    Icons.shopping_cart_rounded,
    Icons.receipt_long_rounded,
    Icons.person_rounded,
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
            for (int i = 0; i < _icons.length; i++)
              _NavCircle(
                icon: _icons[i],
                label: i < labels.length ? labels[i] : '',
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
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
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
            child: Icon(icon, size: 24, color: selected ? HomeColors.brand : HomeColors.textSecondary),
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
      ),
    );
  }
}
