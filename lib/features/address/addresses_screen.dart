import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../widgets/async_view.dart';
import 'address_provider.dart';

/// Màn hình quản lý sổ địa chỉ nhận hàng.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(addressesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sổ địa chỉ')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(context, ref),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: AsyncView(
        value: async,
        onRetry: () => ref.invalidate(addressesProvider),
        data: (addresses) {
          if (addresses.isEmpty) {
            return const EmptyView(message: 'Chưa có địa chỉ nào', icon: Icons.location_off_outlined);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            itemCount: addresses.length,
            itemBuilder: (_, i) {
              final a = addresses[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.location_on_rounded, color: AppColors.brand, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(a.recipientName, style: const TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(width: 8),
                              if (a.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.brandSoft, borderRadius: BorderRadius.circular(20)),
                                  child: const Text('Mặc định',
                                      style: TextStyle(fontSize: 11, color: AppColors.brand, fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(a.phone, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(a.fullAddress, style: const TextStyle(fontSize: 13, height: 1.35)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        try {
                          await ref.read(addressRepositoryProvider).remove(a.id);
                          ref.invalidate(addressesProvider);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        }
                      },
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(11)),
                        child: const Icon(Icons.delete_rounded, color: AppColors.danger, size: 18),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openAdd(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final line = TextEditingController();
    final province = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm địa chỉ'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _f(name, 'Tên người nhận'),
              _f(phone, 'Số điện thoại', keyboard: TextInputType.phone),
              _f(line, 'Số nhà, đường'),
              _f(province, 'Tỉnh/Thành phố'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await ref.read(addressRepositoryProvider).add(
                      recipientName: name.text.trim(),
                      phone: phone.text.trim(),
                      line: line.text.trim(),
                      province: province.text.trim(),
                      isDefault: true,
                    );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (ok == true) ref.invalidate(addressesProvider);
  }

  Widget _f(TextEditingController c, String label, {TextInputType? keyboard}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: TextFormField(
          controller: c,
          keyboardType: keyboard,
          decoration: InputDecoration(labelText: label),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
        ),
      );
}
