import 'package:flutter/widgets.dart';

import '../../../models/category.dart';
import '../home_ui.dart';

/// Thanh chọn danh mục cuộn ngang. Mỗi chip tự dựng bằng Container + GestureDetector
/// (KHÔNG dùng ChoiceChip/FilterChip). Chip đang chọn đổi nền + màu chữ.
class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Category> categories;
  final int? selectedId; // null = "Tất cả"
  final ValueChanged<int?> onSelect;

  static const double height = 50;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: HomeDims.pagePadding - 4, vertical: 6),
        children: [
          _chip(label: 'Tất cả', selected: selectedId == null, onTap: () => onSelect(null)),
          for (final c in categories)
            _chip(label: c.name, selected: selectedId == c.id, onTap: () => onSelect(c.id)),
        ],
      ),
    );
  }

  Widget _chip({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? HomeColors.selectedBg : HomeColors.surface,
          borderRadius: BorderRadius.circular(HomeDims.radiusPill),
          border: Border.all(
            color: selected ? HomeColors.primaryOrange : HomeColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const _CheckMark(color: HomeColors.primaryOrange, size: 14),
              const SizedBox(width: 6),
            ],
            Text(label, style: selected ? HomeText.chipSelected : HomeText.chip),
          ],
        ),
      ),
    );
  }
}

/// Dấu tích "✓" tự vẽ bằng CustomPaint (không dùng Icon dựng sẵn cho chi tiết nhỏ này).
class _CheckMark extends StatelessWidget {
  const _CheckMark({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _CheckPainter(color));
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
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
  bool shouldRepaint(covariant _CheckPainter oldDelegate) => oldDelegate.color != color;
}
