import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../app/motion.dart';
import '../../../models/category.dart';
import '../../../widgets/pressable.dart';
import '../home_ui.dart';

/// Hàng danh mục dạng vòng tròn nhiều màu (cuộn ngang) — phong cách grocery.
/// Mục "Tất cả" đứng đầu; mục đang chọn có viền xanh nổi bật.
class CategoryCircles extends StatelessWidget {
  const CategoryCircles({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    required this.allLabel,
  });

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelect;
  final String allLabel;

  /// Icon gợi ý theo slug danh mục (không có thì dùng mặc định).
  IconData _iconFor(String slug) {
    if (slug.contains('dien-thoai')) return Icons.smartphone;
    if (slug.contains('thoi-trang')) return Icons.checkroom;
    if (slug.contains('gia-dung')) return Icons.chair_alt;
    if (slug.contains('sach')) return Icons.menu_book;
    if (slug.contains('lam-dep')) return Icons.spa;
    if (slug.contains('do-an') || slug.contains('an')) return Icons.restaurant;
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: HomeDims.pagePadding - 4),
        children: [
          _item(context, index: 0, id: null, label: allLabel, icon: Icons.grid_view_rounded),
          for (int i = 0; i < categories.length; i++)
            _item(
              context,
              index: i + 1,
              id: categories[i].id,
              label: categories[i].name,
              icon: _iconFor(categories[i].slug),
            ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, {required int index, required int? id, required String label, required IconData icon}) {
    final selected = selectedId == id;
    final tint = kCategoryTints[index % kCategoryTints.length];
    final ink = kCategoryInk[index % kCategoryInk.length];
    return Pressable(
      onTap: () => onSelect(id),
      scale: 0.9,
      child: Container(
        width: 74,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            // Vòng tròn: viền xanh + quầng nhẹ chạy vào khi được chọn.
            AnimatedContainer(
              duration: AppMotion.dur(context, AppMotion.base),
              curve: AppMotion.emphasized,
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tint,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? HomeColors.brand : const Color(0x00000000),
                  width: 2.4,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: HomeColors.brand.withValues(alpha: 0.22), blurRadius: 10, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Icon(icon, color: ink, size: 26),
            ),
            const SizedBox(height: 7),
            AnimatedDefaultTextStyle(
              duration: AppMotion.dur(context, AppMotion.base),
              curve: AppMotion.emphasized,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? HomeColors.brand : HomeColors.textSecondary,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
