import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../widgets/login_required_view.dart';
import '../auth/auth_provider.dart';
import '../seller/seller_repository.dart';

/// Tab Tài khoản: thông tin người dùng + lối vào các tính năng cá nhân & kênh bán.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tài khoản')),
        body: const LoginRequiredView(message: 'Đăng nhập để quản lý tài khoản'),
      );
    }
    final user = auth.user!;

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        children: [
          // Thẻ thông tin người dùng
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.brand.withValues(alpha: 0.08),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.brand,
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(user.email, style: const TextStyle(color: Colors.grey)),
                      if (user.isAdmin)
                        const Text('Quản trị viên', style: TextStyle(color: AppColors.brand)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          _tile(Icons.favorite_border, 'Sản phẩm yêu thích', () => context.push('/favorites')),
          _tile(Icons.location_on_outlined, 'Sổ địa chỉ', () => context.push('/addresses')),

          const Divider(),
          _sectionLabel('Kênh người bán'),
          if (user.hasShop) ...[
            _tile(Icons.inventory_2_outlined, 'Sản phẩm của shop', () => context.push('/seller/products')),
            _tile(Icons.receipt_long_outlined, 'Đơn hàng của shop', () => context.push('/seller/orders')),
          ] else
            _tile(Icons.storefront_outlined, 'Mở shop bán hàng', () => _openShopDialog(context, ref)),

          if (user.isAdmin) ...[
            const Divider(),
            _sectionLabel('Quản trị'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Trang quản trị (thống kê, duyệt shop...) dùng qua API admin. '
                  'Xem docs/FUTURE.md để phát triển giao diện admin.',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          ],

          const Divider(),
          _tile(Icons.logout, 'Đăng xuất', () => _confirmLogout(context, ref), color: AppColors.danger),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap, {Color? color}) => ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      );

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn muốn đăng xuất khỏi tài khoản?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đăng xuất')),
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
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                    );
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
