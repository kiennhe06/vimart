import 'package:flutter/material.dart';

import 'design.dart';
import 'motion.dart';

/// Màu brand cố định (theme-invariant) — tiện dùng ở nơi không cần đổi theo tối/sáng.
/// Với bề mặt/nền/chữ/viền hãy dùng `context.c` (theme-aware) thay cho lớp này.
class AppColors {
  static const Color brand = Color(0xFF1EA65A);
  static const Color brandDark = Color(0xFF158048);
  static const Color brandSoft = Color(0xFFE7F6EE);
  static const Color accent = Color(0xFFF5A524); // vàng (sao đánh giá)
  static const Color promo = Color(0xFFF2683C); // cam nhấn khuyến mãi
  static const Color success = Color(0xFF15A05A);
  static const Color danger = Color(0xFFE5484D);
}

/// Bo góc & khoảng cách chuẩn — giữ tương thích; nội dung khớp [AppRadius]/[AppSpace].
class AppSizes {
  static const double radius = AppRadius.lg;
  static const double radiusSmall = AppRadius.sm;
  static const double gap = 14;
  static const double pagePadding = 18;
}

ThemeData buildLightTheme() => _buildTheme(Brightness.light);
ThemeData buildDarkTheme() => _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final cx = isLight ? AppCx.light : AppCx.dark;

  final colorScheme =
      ColorScheme.fromSeed(seedColor: AppColors.brand, brightness: brightness).copyWith(
    primary: cx.brand,
    onPrimary: cx.onBrand,
    secondary: AppColors.brandDark,
    surface: cx.surface,
    onSurface: cx.textPrimary,
    error: cx.danger,
  );

  const pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.iOS: _FadeThroughPageTransitions(),
      TargetPlatform.android: _FadeThroughPageTransitions(),
      TargetPlatform.macOS: _FadeThroughPageTransitions(),
    },
  );

  // Typography scale (color kế thừa onSurface) — nguồn: AppType.
  final baseText = (isLight ? Typography.blackMountainView : Typography.whiteMountainView);
  final textTheme = baseText.copyWith(
    displaySmall: AppType.display,
    headlineMedium: AppType.h1,
    headlineSmall: AppType.h2,
    titleLarge: AppType.h3,
    titleMedium: AppType.title,
    bodyLarge: AppType.body,
    bodyMedium: AppType.body,
    bodySmall: AppType.bodySm,
    labelLarge: AppType.label,
    labelSmall: AppType.caption,
  ).apply(bodyColor: cx.textPrimary, displayColor: cx.textPrimary);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    extensions: [cx],
    textTheme: textTheme,
    pageTransitionsTheme: pageTransitions,
    scaffoldBackgroundColor: cx.background,
    appBarTheme: AppBarTheme(
      backgroundColor: cx.background,
      foregroundColor: cx.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: AppType.h2.copyWith(color: cx.textPrimary),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cx.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cx.surface,
      hintStyle: TextStyle(color: cx.textMuted),
      border: OutlineInputBorder(
        borderRadius: AppRadius.brLg,
        borderSide: BorderSide(color: cx.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.brLg,
        borderSide: BorderSide(color: cx.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.brLg,
        borderSide: BorderSide(color: cx.brand, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.base, vertical: 15),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cx.brand,
        foregroundColor: cx.onBrand,
        elevation: 0,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: cx.brand,
        foregroundColor: cx.onBrand,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: cx.brand,
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: cx.brand, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: cx.brand),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      side: BorderSide.none,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: cx.border, thickness: 1),
  );
}

/// Chuyển trang mờ dần + phóng nhẹ (fade-through) — êm, đồng bộ mọi nền tảng.
/// Tôn trọng giảm chuyển động: khi bật thì không hiệu ứng.
class _FadeThroughPageTransitions extends PageTransitionsBuilder {
  const _FadeThroughPageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (context.reduceMotion) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.emphasized,
      reverseCurve: AppMotion.exit,
    );
    return FadeTransition(
      opacity: curved,
      child: Transform.scale(scale: 0.98 + 0.02 * curved.value, child: child),
    );
  }
}
