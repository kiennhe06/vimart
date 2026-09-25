import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_provider.dart';
import '../../widgets/login_required_view.dart';
import '../auth/auth_provider.dart';
import '../seller/seller_repository.dart';

/// Tab Tài khoản — phong cách grocery: thẻ hồ sơ bo tròn + menu dạng thẻ,
/// mỗi mục có icon chip màu pastel.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final s = ref.watch(stringsProvider);
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(s.account)),
        body: LoginRequiredView(message: s.loginToManage),
      );
    }
    final user = auth.user!;
    final localeCode = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.account)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Thẻ hồ sơ
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                Container(
                  width: 58, height: 58,
                  decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      _badge(user.isAdmin ? s.roleAdmin : (user.hasShop ? s.roleSeller : s.roleBuyer)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nhóm: tiện ích cá nhân
          _menuCard([
            _MenuRow(Icons.favorite_rounded, const Color(0xFFFFEDE2), const Color(0xFFFF7A45),
                s.favoriteProducts, () => context.push('/favorites')),
            _MenuRow(Icons.location_on_rounded, const Color(0xFFE2F0FF), const Color(0xFF2B8AF0),
                s.addressBook, () => context.push('/addresses')),
            // Đổi ngôn ngữ
            _MenuRow(Icons.language_rounded, const Color(0xFFEDE9FE), const Color(0xFF7C5CFC),
                s.language, () => ref.read(localeProvider.notifier).toggle(),
                trailingText: localeCode == 'en' ? 'English' : 'Tiếng Việt'),
          ]),

          const SizedBox(height: 14),
          _sectionLabel(s.sellerChannel),
          _menuCard(
            user.hasShop
                ? [
                    _MenuRow(Icons.inventory_2_rounded, AppColors.brandSoft, AppColors.brand,
                        s.myShopProducts, () => context.push('/seller/products')),
                    _MenuRow(Icons.receipt_long_rounded, const Color(0xFFFDF3D3), const Color(0xFFE0A81E),
                        s.myShopOrders, () => context.push('/seller/orders')),
                  ]
                : [
                    _MenuRow(Icons.storefront_rounded, AppColors.brandSoft, AppColors.brand,
                        s.openShop, () => _openShopDialog(context, ref)),
                  ],
          ),

          const SizedBox(height: 14),
          _menuCard([
            _MenuRow(Icons.logout_rounded, const Color(0xFFFDECEC), AppColors.danger,
                s.logout, () => _confirmLogout(context, ref), danger: true),
          ]),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      );

  Widget _badge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: const TextStyle(color: AppColors.brand, fontSize: 12, fontWeight: FontWeight.w700)),
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.grey, fontSize: 13)),
      );

  Widget _menuCard(List<_MenuRow> rows) {
    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              const Padding(padding: EdgeInsets.only(left: 64), child: Divider(height: 1)),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final s = ref.read(stringsProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.logout),
        content: Text(s.logoutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.no)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.logout)),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/');
    }
  }

  Future<void> _openShopDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mở shop bán hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên shop')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Giới thiệu (không bắt buộc)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().length < 2) return;
              try {
                await ref.read(sellerRepositoryProvider).createShop(
                    name: nameCtrl.text.trim(), description: descCtrl.text.trim());
                await ref.read(authProvider.notifier).refreshUser();
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Tạo shop'),
          ),
        ],
      ),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mở shop thành công!')));
    }
  }
}

/// Một dòng menu: icon chip màu + nhãn + mũi tên.
class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.tint, this.ink, this.label, this.onTap,
      {this.danger = false, this.trailingText});
  final IconData icon;
  final Color tint;
  final Color ink;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: ink, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: danger ? AppColors.danger : null)),
            ),
            if (trailingText != null)
              Text(trailingText!,
                  style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
