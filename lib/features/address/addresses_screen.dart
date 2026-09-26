import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design.dart';
import '../../app/theme.dart';
import '../../core/i18n/app_strings.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/app_skeleton.dart';
import '../../widgets/async_view.dart';
import '../../widgets/entrance.dart';
import '../../widgets/pressable.dart';
import 'address_form_sheet.dart';
import 'address_provider.dart';

/// Màn hình quản lý sổ địa chỉ nhận hàng.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(addressesProvider);
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.addressBook)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(context, ref),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addShort, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: AsyncView(
        value: async,
        loading: const SkeletonList(count: 3),
        onRetry: () => ref.invalidate(addressesProvider),
        data: (addresses) {
          if (addresses.isEmpty) {
            return EmptyView(message: s.noAddresses, icon: Icons.location_off_outlined);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            itemCount: addresses.length,
            itemBuilder: (_, i) {
              final a = addresses[i];
              return FadeSlideIn(
                index: i,
                child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.c.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.c.border),
                  boxShadow: AppShadow.soft(context.c.shadow),
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
                                  child: Text(s.defaultLabel,
                                      style: const TextStyle(fontSize: 11, color: AppColors.brand, fontWeight: FontWeight.w700)),
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
                    Pressable(
                      scale: 0.85,
                      onTap: () async {
                        try {
                          await ref.read(addressRepositoryProvider).remove(a.id);
                          ref.invalidate(addressesProvider);
                        } catch (e) {
                          if (context.mounted) {
                            showAppSnack(context, e.toString(), type: AppSnackType.error);
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
              ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openAdd(BuildContext context, WidgetRef ref) async {
    final ok = await showAddAddressSheet(context);
    if (ok) ref.invalidate(addressesProvider);
  }
}
