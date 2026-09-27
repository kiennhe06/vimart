import 'package:flutter/material.dart';

import '../app/design.dart';
import 'pressable.dart';

/// Mục chọn dùng trong bottom sheet (chọn theme, sắp xếp, phương thức…).
/// Component dùng chung — icon + nhãn + dấu tích khi đang chọn.
class AppSheetOption extends StatelessWidget {
  const AppSheetOption({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.base, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? c.brandSoft : c.surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: selected ? c.brand : c.border, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: selected ? c.brand : c.textSecondary),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(label,
                  style: AppType.title.copyWith(
                      color: selected ? c.brand : c.textPrimary)),
            ),
            if (selected) Icon(Icons.check_circle_rounded, size: 22, color: c.brand),
          ],
        ),
      ),
    );
  }
}
