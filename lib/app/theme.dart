import 'package:flutter/material.dart';

/// Bảng màu ViMart — phong cách "grocery" tươi sáng, xanh lá chủ đạo.
/// Luôn ưu tiên dùng qua Theme.of(context).colorScheme để đồng bộ sáng/tối.
class AppColors {
  static const Color brand = Color(0xFF1EA65A); // xanh lá tươi
  static const Color brandDark = Color(0xFF158048);
  static const Color brandSoft = Color(0xFFE7F6EE);
  static const Color accent = Color(0xFFFFB020); // vàng (sao đánh giá)
  static const Color promo = Color(0xFFFF7A45); // cam nhấn khuyến mãi
  static const Color success = Color(0xFF1EA65A);
  static const Color danger = Color(0xFFE5484D);
}

/// Bo góc & khoảng cách chuẩn (mềm mại, đồng bộ).
class AppSizes {
  static const double radius = 18;
  static const double radiusSmall = 12;
  static const double gap = 14;
  static const double pagePadding = 18;
}

ThemeData buildLightTheme() => _buildTheme(Brightness.light);
ThemeData buildDarkTheme() => _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: brightness,
  ).copyWith(
    primary: AppColors.brand,
    secondary: AppColors.brandDark,
  );

  final isLight = brightness == Brightness.light;

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isLight ? const Color(0xFFF4F6F5) : null,
    appBarTheme: AppBarTheme(
      backgroundColor: isLight ? const Color(0xFFF4F6F5) : colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isLight ? Colors.white : null,
      hintStyle: const TextStyle(color: Color(0xFF8B93A1)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        borderSide: BorderSide(color: isLight ? const Color(0xFFECEFF1) : Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        borderSide: BorderSide(color: isLight ? const Color(0xFFECEFF1) : Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brand,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.brand, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.brand),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      side: BorderSide.none,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFECEFF1), thickness: 1),
  );
}
