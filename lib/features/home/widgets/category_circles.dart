import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../../../models/category.dart';
import '../home_ui.dart';

/// Hàng danh mục dạng vòng tròn nhiều màu (cuộn ngang) — phong cách grocery.
/// Mục "Tất cả" đứng đầu; mục đang chọn có viền xanh nổi bật.
class CategoryCircles extends StatelessWidget {
  const CategoryCircles({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelect;

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
          _item(index: 0, id: null, label: 'Tất cả', icon: Icons.grid_view_rounded),
          for (int i = 0; i < categories.length; i++)
            _item(
              index: i + 1,
              id: categories[i].id,
              label: categories[i].name,
              icon: _iconFor(categories[i].slug),
            ),
        ],
      ),
    );
  }

  Widget _item({required int index, required int? id, required String label, required IconData icon}) {
    final selected = selectedId == id;
    final tint = kCategoryTints[index % kCategoryTints.length];
    final ink = kCategoryInk[index % kCategoryInk.length];
    return GestureDetector(
      onTap: () => onSelect(id),
      child: Container(
        width: 74,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: tint,
                shape: BoxShape.circle,
                border: selected ? Border.all(color: HomeColors.brand, width: 2.4) : null,
              ),
              child: Icon(icon, color: ink, size: 26),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? HomeColors.brand : HomeColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
