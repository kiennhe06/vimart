import 'package:flutter/material.dart';

import '../app/motion.dart';
import '../app/theme.dart';

/// Loại phản hồi — quyết định icon, màu và rung.
enum AppSnackType { success, error, warning, info }

/// Hiển thị SnackBar nổi có icon + màu ngữ nghĩa + rung phù hợp.
/// Thay cho `ScaffoldMessenger...SnackBar(Text(...))` thô để phản hồi nhất quán.
void showAppSnack(
  BuildContext context,
  String message, {
  AppSnackType type = AppSnackType.info,
  SnackBarAction? action,
}) {
  switch (type) {
    case AppSnackType.success:
      AppHaptics.success();
    case AppSnackType.error:
      AppHaptics.error();
    case AppSnackType.warning:
      AppHaptics.warning();
    case AppSnackType.info:
      AppHaptics.light();
  }

  final (icon, color) = switch (type) {
    AppSnackType.success => (Icons.check_circle_rounded, AppColors.brand),
    AppSnackType.error => (Icons.error_rounded, AppColors.danger),
    AppSnackType.warning => (Icons.warning_rounded, AppColors.promo),
    AppSnackType.info => (Icons.info_rounded, const Color(0xFF323A44)),
  };

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: type == AppSnackType.error ? 4 : 2),
      action: action == null
          ? null
          : SnackBarAction(
              label: action.label,
              textColor: Colors.white,
              onPressed: action.onPressed,
            ),
    ),
  );
}
