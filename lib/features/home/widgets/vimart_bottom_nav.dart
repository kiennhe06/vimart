import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/cart_anchor.dart';
import '../../../app/design.dart';
import '../../../app/motion.dart';
import '../../../widgets/pressable.dart';

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

  static const List<String> _icons = [
    'assets/icons/nav/home.svg',
    'assets/icons/nav/cart.svg',
    'assets/icons/nav/orders.svg',
    'assets/icons/nav/profile.svg',
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.only(left: 18, right: 18, top: 6, bottom: 8 + bottomInset),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: context.c.surface,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: context.c.border),
          boxShadow: [BoxShadow(color: context.c.shadow, blurRadius: 22, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < _icons.length; i++)
              _NavCircle(
                asset: _icons[i],
                label: i < labels.length ? labels[i] : '',
                selected: i == currentIndex,
                badgeCount: i == 1 ? cartCount : 0,
                // Đích cho hiệu ứng "bay vào giỏ".
                anchorKey: i == 1 ? cartIconKey : null,
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
    required this.asset,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
    this.anchorKey,
  });

  final String asset;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  /// GlobalKey đánh dấu icon giỏ (đích của hiệu ứng bay vào giỏ).
  final Key? anchorKey;

  /// Ma trận xám (luma) để làm mờ sticker ở tab chưa chọn.
  static const ColorFilter _grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Pressable(
        onTap: onTap,
        scale: 0.9,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              key: anchorKey,
              duration: AppMotion.dur(context, AppMotion.base),
              curve: AppMotion.emphasized,
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? context.c.brandSoft : context.c.surface,
                border: Border.all(
                  color: selected ? context.c.brand : context.c.border,
                  width: selected ? 2 : 1.2,
                ),
              ),
              child: AnimatedScale(
                scale: selected ? 1.12 : 1.0,
                duration: AppMotion.dur(context, AppMotion.base),
                curve: AppMotion.pop,
                // Tab chọn: sticker màu đầy đủ. Chưa chọn: xám + hơi mờ.
                child: AnimatedOpacity(
                  opacity: selected ? 1 : 0.55,
                  duration: AppMotion.dur(context, AppMotion.base),
                  child: SvgPicture.asset(
                    asset,
                    width: 30,
                    height: 30,
                    colorFilter: selected ? null : _grayscale,
                  ),
                ),
              ),
            ),
            // Badge giỏ hàng: hiện/ẩn bằng scale (pop) + số nhảy khi đổi.
            Positioned(
              right: -2,
              top: -2,
              child: AnimatedScale(
                scale: badgeCount > 0 ? 1 : 0,
                duration: AppMotion.dur(context, AppMotion.base),
                curve: AppMotion.pop,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.c.brand,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.c.surface, width: 2),
                  ),
                  child: AnimatedSwitcher(
                    duration: AppMotion.dur(context, AppMotion.fast),
                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      key: ValueKey(badgeCount),
                      style: TextStyle(
                          color: context.c.onBrand, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
