import 'package:flutter/material.dart';

import '../app/motion.dart';

/// Mở dialog với hiệu ứng scale(0.96→1) + mờ dần, thay cho showDialog phẳng.
/// Tôn trọng giảm chuyển động (khi bật thì dùng showDialog thường).
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  if (context.reduceMotion) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: AppMotion.base,
    pageBuilder: (ctx, _, _) => builder(ctx),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: AppMotion.emphasized,
        reverseCurve: AppMotion.exit,
      );
      return FadeTransition(
        opacity: anim,
        child: Transform.scale(scale: 0.96 + 0.04 * curved.value, child: child),
      );
    },
  );
}

/// Bottom sheet với bo góc trên đồng bộ. showModalBottomSheet đã tự trượt mượt.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: builder,
  );
}
