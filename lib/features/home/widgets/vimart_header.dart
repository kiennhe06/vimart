import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../widgets/pressable.dart';
import '../home_ui.dart';

/// Header trang chủ kiểu grocery: lời chào + tên app + nút tròn (yêu thích / thông báo).
class VimartHeader extends ConsumerWidget {
  const VimartHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(HomeDims.pagePadding, 6, HomeDims.pagePadding, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.greeting, style: AppType.caption.copyWith(color: context.c.textSecondary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('ViMart', style: AppType.h1.copyWith(color: context.c.brand)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.c.brandSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(s.freshBadge,
                          style: TextStyle(color: context.c.brand, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _CircleButton(icon: Icons.favorite_border, onTap: () => context.push('/favorites')),
          const SizedBox(width: 10),
          _CircleButton(icon: Icons.notifications_none_rounded, onTap: () {}),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: context.c.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: context.c.border),
          boxShadow: AppShadow.soft(context.c.shadow),
        ),
        child: Icon(icon, size: 22, color: context.c.textPrimary),
      ),
    );
  }
}
