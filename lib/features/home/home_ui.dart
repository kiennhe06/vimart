import 'package:flutter/widgets.dart';

/// Bộ token màu & typography — phong cách "grocery" tươi sáng, xanh lá chủ đạo.
/// Dùng chung cho phần trang chủ (dựng tay). Các màn khác dùng theme ở app/theme.dart.
class HomeColors {
  const HomeColors._();

  static const Color brand = Color(0xFF1EA65A); // xanh lá tươi (chủ đạo)
  static const Color brandDark = Color(0xFF158048);
  static const Color brandSoft = Color(0xFFE7F6EE); // nền xanh nhạt
  static const Color accent = Color(0xFFFF7A45); // cam nhấn (khuyến mãi/giá sale)
  static const Color background = Color(0xFFF4F6F5); // nền tổng thể (trắng ngả)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1B2430);
  static const Color textSecondary = Color(0xFF8B93A1);
  static const Color border = Color(0xFFECEFF1);
  static const Color star = Color(0xFFFFB020);
  static const Color shadow = Color(0x12000000);
}

/// Màu pastel cho các vòng tròn danh mục (xoay vòng theo thứ tự).
const List<Color> kCategoryTints = [
  Color(0xFFE7F6EE), // mint
  Color(0xFFFFEDE2), // peach
  Color(0xFFEDE9FE), // lavender
  Color(0xFFFDF3D3), // lemon
  Color(0xFFE2F0FF), // sky
  Color(0xFFFFE7EE), // rose
];
const List<Color> kCategoryInk = [
  Color(0xFF1EA65A),
  Color(0xFFFF7A45),
  Color(0xFF7C5CFC),
  Color(0xFFE0A81E),
  Color(0xFF2B8AF0),
  Color(0xFFF0498A),
];

class HomeText {
  const HomeText._();

  static const TextStyle logo = TextStyle(
    color: HomeColors.brand, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5);
  static const TextStyle greeting = TextStyle(
    color: HomeColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500);
  static const TextStyle sectionTitle = TextStyle(
    color: HomeColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3);
  static const TextStyle searchHint = TextStyle(color: HomeColors.textSecondary, fontSize: 15);
  static const TextStyle searchInput = TextStyle(color: HomeColors.textPrimary, fontSize: 15);
  static const TextStyle chip = TextStyle(
    color: HomeColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600);
  static const TextStyle productName = TextStyle(
    color: HomeColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700, height: 1.25);
  static const TextStyle price = TextStyle(
    color: HomeColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800);
  static const TextStyle meta = TextStyle(color: HomeColors.textSecondary, fontSize: 12);
  static const TextStyle navActive = TextStyle(
    color: HomeColors.brand, fontSize: 11, fontWeight: FontWeight.w700);
  static const TextStyle navInactive = TextStyle(
    color: HomeColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500);
}

class HomeDims {
  const HomeDims._();
  static const double pagePadding = 18;
  static const double gridGap = 14;
  static const double radiusCard = 20;
  static const double radiusPill = 16;
}
