import 'package:flutter/material.dart';

/// # ViMart Design System — tokens
///
/// Nguồn sự thật DUY NHẤT cho spacing, radius, typography và màu semantic.
/// Thay cho việc rải magic-number và định nghĩa màu trùng lặp ở nhiều nơi.
///
/// - Spacing/Radius: thang cố định (đừng chế số lẻ).
/// - Typography: thang có tên theo vai trò (không đặt fontSize tuỳ hứng).
/// - Màu: lấy qua `context.c` (theme-aware) để tự đúng ở cả Sáng lẫn Tối.

/// Thang khoảng cách 4pt — dùng cho mọi padding/margin/gap.
abstract final class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

/// Thang bo góc — nhất quán "mềm" nhưng không quá tròn.
abstract final class AppRadius {
  static const double sm = 12; // chip, nút nhỏ, ô nhập
  static const double md = 16; // thẻ nhỏ, ảnh
  static const double lg = 20; // thẻ chính, sheet
  static const double xl = 26; // panel lớn, ảnh hero
  static const double pill = 999; // viên thuốc / tròn

  static const Radius rMd = Radius.circular(md);
  static BorderRadius get brSm => BorderRadius.circular(sm);
  static BorderRadius get brMd => BorderRadius.circular(md);
  static BorderRadius get brLg => BorderRadius.circular(lg);
  static BorderRadius get brXl => BorderRadius.circular(xl);
}

/// Thang typography theo vai trò (color kế thừa từ ngữ cảnh — KHÔNG gán màu ở đây).
/// Ít cỡ chữ, phân cấp bằng size + weight + height, không phải bằng màu.
abstract final class AppType {
  static const TextStyle display =
      TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.5);
  static const TextStyle h1 =
      TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.3);
  static const TextStyle h2 =
      TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.25, letterSpacing: -0.2);
  static const TextStyle h3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3);
  static const TextStyle title = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3);
  static const TextStyle body = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.45);
  static const TextStyle bodySm =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4);
  static const TextStyle label =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: 0.1);
  static const TextStyle caption =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.3);
  static const TextStyle price =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.2);
}

/// Bóng đổ chuẩn — tiết chế, chỉ để nâng bề mặt, không "đổ bóng khắp nơi".
class AppShadow {
  AppShadow._();
  static List<BoxShadow> card(Color c) =>
      [BoxShadow(color: c, blurRadius: 16, offset: const Offset(0, 6))];
  static List<BoxShadow> soft(Color c) =>
      [BoxShadow(color: c, blurRadius: 10, offset: const Offset(0, 3))];
}

/// Bộ màu semantic theme-aware. Lấy qua `context.c`. Đăng ký ở cả 2 theme
/// (sáng/tối) trong theme.dart — dark KHÔNG phải đảo màu, là bảng riêng.
@immutable
class AppCx extends ThemeExtension<AppCx> {
  const AppCx({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.brand,
    required this.brandSoft,
    required this.onBrand,
    required this.star,
    required this.promo,
    required this.success,
    required this.danger,
    required this.shadow,
  });

  final Color background; // nền tổng thể
  final Color surface; // bề mặt thẻ/panel
  final Color surfaceAlt; // bề mặt nâng cao hơn (elevated)
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted; // rất phụ (đủ tương phản)
  final Color border;
  final Color brand;
  final Color brandSoft; // nền brand nhạt
  final Color onBrand; // chữ/icon trên nền brand
  final Color star; // vàng đánh giá
  final Color promo; // cam khuyến mãi
  final Color success;
  final Color danger;
  final Color shadow;

  /// Sáng — tươi, nền trắng ngả, chữ phụ đã tăng tương phản (a11y).
  static const AppCx light = AppCx(
    background: Color(0xFFF4F6F5),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1B2430),
    textSecondary: Color(0xFF667085), // ~4.6:1 trên trắng
    textMuted: Color(0xFF98A2B3),
    border: Color(0xFFE7EAE8),
    brand: Color(0xFF1EA65A),
    brandSoft: Color(0xFFE7F6EE),
    onBrand: Color(0xFFFFFFFF),
    star: Color(0xFFF5A524),
    promo: Color(0xFFF2683C),
    success: Color(0xFF15A05A),
    danger: Color(0xFFE5484D),
    shadow: Color(0x14000000),
  );

  /// Tối — nền xanh-đen tinh tế (không phải đen tuyền), brand sáng hơn để đủ
  /// tương phản, bậc bề mặt rõ (background < surface < surfaceAlt).
  static const AppCx dark = AppCx(
    background: Color(0xFF0F1613),
    surface: Color(0xFF18211D),
    surfaceAlt: Color(0xFF1F2A25),
    textPrimary: Color(0xFFEDF2EF),
    textSecondary: Color(0xFFA4B0AA),
    textMuted: Color(0xFF71807A),
    border: Color(0xFF2A332F),
    brand: Color(0xFF34C878),
    brandSoft: Color(0xFF16281F),
    onBrand: Color(0xFF06130C),
    star: Color(0xFFFBB43C),
    promo: Color(0xFFFF8A5B),
    success: Color(0xFF34C878),
    danger: Color(0xFFF16569),
    shadow: Color(0x66000000),
  );

  @override
  AppCx copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? brand,
    Color? brandSoft,
    Color? onBrand,
    Color? star,
    Color? promo,
    Color? success,
    Color? danger,
    Color? shadow,
  }) {
    return AppCx(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      brand: brand ?? this.brand,
      brandSoft: brandSoft ?? this.brandSoft,
      onBrand: onBrand ?? this.onBrand,
      star: star ?? this.star,
      promo: promo ?? this.promo,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppCx lerp(ThemeExtension<AppCx>? other, double t) {
    if (other is! AppCx) return this;
    return AppCx(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      star: Color.lerp(star, other.star, t)!,
      promo: Color.lerp(promo, other.promo, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// Truy cập màu semantic theo ngữ cảnh: `context.c.surface`, `context.c.textSecondary`…
extension AppCxContext on BuildContext {
  AppCx get c => Theme.of(this).extension<AppCx>() ?? AppCx.light;
}
