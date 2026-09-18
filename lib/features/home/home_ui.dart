import 'package:flutter/widgets.dart';

/// Bộ màu & typography tập trung cho giao diện Trang chủ (dựng lại từ đầu).
/// Khai báo 1 nơi, không hard-code màu rải rác trong widget.
class HomeColors {
  const HomeColors._();

  static const Color primaryOrange = Color(0xFFF4511E); // cam thương hiệu
  static const Color background = Color(0xFFF4F4F6); // nền tổng thể (xám rất nhạt)
  static const Color surface = Color(0xFFFFFFFF); // nền card / ô / thanh
  static const Color textPrimary = Color(0xFF1E1E24); // chữ chính (gần đen)
  static const Color textSecondary = Color(0xFF8B8B92); // chữ phụ (xám)
  static const Color border = Color(0xFFE7E7EC); // viền mảnh
  static const Color selectedBg = Color(0xFFFDE7DE); // nền item đang chọn (cam nhạt)
  static const Color star = Color(0xFFFFB300); // sao đánh giá (vàng)
  static const Color barrier = Color(0x33000000); // lớp mờ khi mở menu
  static const Color shadow = Color(0x14000000); // bóng đổ nhẹ
}

/// Kiểu chữ dùng chung.
class HomeText {
  const HomeText._();

  static const TextStyle logo = TextStyle(
    color: HomeColors.primaryOrange,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.2,
  );

  static const TextStyle searchHint = TextStyle(
    color: HomeColors.textSecondary,
    fontSize: 15,
  );

  static const TextStyle searchInput = TextStyle(
    color: HomeColors.textPrimary,
    fontSize: 15,
  );

  static const TextStyle chip = TextStyle(
    color: HomeColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle chipSelected = TextStyle(
    color: HomeColors.primaryOrange,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle sortLabel = TextStyle(
    color: HomeColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle productName = TextStyle(
    color: HomeColors.textPrimary,
    fontSize: 13,
    height: 1.3,
  );

  static const TextStyle price = TextStyle(
    color: HomeColors.primaryOrange,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle meta = TextStyle(
    color: HomeColors.textSecondary,
    fontSize: 11,
  );

  static const TextStyle navActive = TextStyle(
    color: HomeColors.primaryOrange,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle navInactive = TextStyle(
    color: HomeColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
}

/// Khoảng cách & bo góc chuẩn.
class HomeDims {
  const HomeDims._();

  static const double pagePadding = 16; // padding trái/phải trang
  static const double gridGap = 12; // khoảng cách giữa 2 card
  static const double radiusCard = 14;
  static const double radiusPill = 12;
}
