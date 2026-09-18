import 'package:flutter/material.dart';

/// Bảng màu thương hiệu ViMart. Màu cam chủ đạo (gợi cảm giác sàn TMĐT sôi động).
/// Luôn ưu tiên dùng qua Theme.of(context).colorScheme để 2 chế độ sáng/tối đều đẹp.
class AppColors {
  static const Color brand = Color(0xFFF4511E); // cam đỏ
  static const Color brandDark = Color(0xFFC63F0F);
  static const Color accent = Color(0xFFFFB300); // vàng (sao đánh giá)
  static const Color success = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFD32F2F);
}

/// Bo góc & khoảng cách chuẩn để giao diện nhất quán.
class AppSizes {
  static const double radius = 12;
  static const double gap = 12;
  static const double pagePadding = 16;
}

ThemeData buildLightTheme() => _buildTheme(Brightness.light);
ThemeData buildDarkTheme() => _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor:
        brightness == Brightness.light ? const Color(0xFFF5F5F7) : null,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
      ),
    ),
  );
}
