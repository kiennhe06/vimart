import 'package:flutter/widgets.dart';

import '../home_ui.dart';

/// Danh sách lựa chọn sắp xếp (key khớp với backend).
const Map<String, String> kSortOptions = {
  'newest': 'Mới nhất',
  'best_selling': 'Bán chạy',
  'price_asc': 'Giá thấp → cao',
  'price_desc': 'Giá cao → thấp',
  'rating': 'Đánh giá cao',
};

/// Dòng "Mới nhất ▾" — nút mở menu sort. Tự dựng bằng Row + Icon vẽ tay.
class SortControl extends StatelessWidget {
  const SortControl({super.key, required this.currentSort, required this.menuOpen, required this.onTap});

  final String currentSort;
  final bool menuOpen;
  final VoidCallback onTap;

  static const double height = 44;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: HomeDims.pagePadding),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SortLinesIcon(),
            const SizedBox(width: 8),
            Text(kSortOptions[currentSort] ?? 'Mới nhất', style: HomeText.sortLabel),
            const SizedBox(width: 4),
            // Mũi tên xoay khi menu mở
            _Chevron(open: menuOpen),
          ],
        ),
      ),
    );
  }
}

/// Menu sort dạng overlay: Container bo góc + bóng đổ, Column các item.
/// Item đang chọn: nền cam nhạt + chữ cam + dấu tích.
class SortMenu extends StatelessWidget {
  const SortMenu({super.key, required this.currentSort, required this.onSelect});

  final String currentSort;
  final ValueChanged<String> onSelect;

  static const double width = 210;
  static const double itemHeight = 48;

  @override
  Widget build(BuildContext context) {
    final entries = kSortOptions.entries.toList();
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: HomeColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HomeColors.border),
        boxShadow: const [
          BoxShadow(color: HomeColors.shadow, blurRadius: 24, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < entries.length; i++)
            _menuItem(
              key: entries[i].key,
              label: entries[i].value,
              selected: entries[i].key == currentSort,
              isFirst: i == 0,
              isLast: i == entries.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required String key,
    required String label,
    required bool selected,
    required bool isFirst,
    required bool isLast,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelect(key),
      child: Container(
        height: itemHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? HomeColors.selectedBg : HomeColors.surface,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(13) : Radius.zero,
            bottom: isLast ? const Radius.circular(13) : Radius.zero,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: selected
                    ? HomeText.sortLabel.copyWith(color: HomeColors.primaryOrange)
                    : HomeText.sortLabel.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            if (selected) const _CheckDot(),
          ],
        ),
      ),
    );
  }
}

/// Icon 3 gạch (sort) tự vẽ bằng CustomPaint.
class _SortLinesIcon extends StatelessWidget {
  const _SortLinesIcon();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(18, 18), painter: _SortLinesPainter());
  }
}

class _SortLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HomeColors.textSecondary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final widths = [1.0, 0.7, 0.4];
    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.22 + i * 0.28);
      canvas.drawLine(Offset(0, y), Offset(size.width * widths[i], y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mũi tên chevron tự vẽ, xoay 180° khi menu mở.
class _Chevron extends StatelessWidget {
  const _Chevron({required this.open});
  final bool open;
  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: open ? 0.5 : 0,
      duration: const Duration(milliseconds: 150),
      child: CustomPaint(size: const Size(14, 14), painter: _ChevronPainter()),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HomeColors.textPrimary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.38)
      ..lineTo(size.width * 0.5, size.height * 0.66)
      ..lineTo(size.width * 0.8, size.height * 0.38);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dấu tích tròn nhỏ cho item đang chọn.
class _CheckDot extends StatelessWidget {
  const _CheckDot();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(16, 16), painter: _CheckDotPainter());
  }
}

class _CheckDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HomeColors.primaryOrange
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.76)
      ..lineTo(size.width * 0.84, size.height * 0.26);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
