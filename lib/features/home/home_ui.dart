import 'package:flutter/widgets.dart';

/// Token brand cố định cho phần trang chủ (dựng tay). Bề mặt/nền/chữ/viền dùng
/// `context.c` (theme-aware) — xem [lib/app/design.dart]. Ở đây chỉ giữ các màu
/// brand/accent bất biến theo theme + bảng pastel danh mục.
class HomeColors {
  const HomeColors._();

  static const Color brand = Color(0xFF1EA65A); // xanh lá tươi (chủ đạo)
  static const Color brandDark = Color(0xFF158048);
  /// Pastel sáng dùng làm "giếng ảnh" (media well) — giữ sáng cả ở dark.
  static const Color brandSoft = Color(0xFFE7F6EE);
  static const Color star = Color(0xFFF5A524); // vàng đánh giá
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

/// Kích thước dùng chung ở trang chủ — khớp thang [AppSpace]/[AppRadius].
class HomeDims {
  const HomeDims._();
  static const double pagePadding = 18;
  static const double gridGap = 14;
  static const double radiusCard = 20;
  static const double radiusPill = 16;
}
