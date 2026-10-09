import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/design.dart';
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

  static const String _iconBase = 'assets/icons/categories';
  static const String _allAsset = '$_iconBase/all.svg';

  /// Đường dẫn SVG icon theo slug danh mục (không khớp thì dùng "all").
  String _assetFor(String slug) {
    if (slug.contains('dien-thoai')) return '$_iconBase/phone.svg';
    if (slug.contains('thoi-trang')) return '$_iconBase/fashion.svg';
    if (slug.contains('gia-dung')) return '$_iconBase/home.svg';
    if (slug.contains('sach')) return '$_iconBase/books.svg';
    if (slug.contains('lam-dep')) return '$_iconBase/beauty.svg';
    if (slug.contains('do-an') || slug.contains('an')) return '$_iconBase/food.svg';
    return _allAsset;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: HomeDims.pagePadding - 4),
        children: [
          _item(context, index: 0, id: null, label: allLabel, asset: _allAsset),
          for (int i = 0; i < categories.length; i++)
            _item(
              context,
              index: i + 1,
              id: categories[i].id,
              label: categories[i].name,
              asset: _assetFor(categories[i].slug),
            ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, {required int index, required int? id, required String label, required String asset}) {
    final selected = selectedId == id;
    final tint = kCategoryTints[index % kCategoryTints.length];
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
                  color: selected ? context.c.brand : const Color(0x00000000),
                  width: 2.4,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: context.c.brand.withValues(alpha: 0.22), blurRadius: 10, offset: const Offset(0, 3))]
                    : null,
              ),
              child: SvgPicture.asset(
                asset,
                width: 46,
                height: 46,
                // Sticker đã có màu riêng nên vẽ nguyên bản, không tô đè.
              ),
            ),
            const SizedBox(height: 7),
            AnimatedDefaultTextStyle(
              duration: AppMotion.dur(context, AppMotion.base),
              curve: AppMotion.emphasized,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? context.c.brand : context.c.textSecondary,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
