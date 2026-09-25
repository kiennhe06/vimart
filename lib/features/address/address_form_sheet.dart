import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/i18n/app_strings.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/pressable.dart';
import 'address_provider.dart';
import 'vn_location_api.dart';

/// Mở form thêm địa chỉ — bottom sheet đẹp, DÙNG CHUNG ở Checkout & Sổ địa chỉ.
/// Tỉnh/Thành và Phường/Xã CHỌN từ API địa giới VN (v2, 2 cấp) thay vì gõ tay.
/// Trả về true nếu đã lưu thành công.
Future<bool> showAddAddressSheet(BuildContext context) async {
  final ok = await showAppSheet<bool>(context, builder: (_) => const _AddressFormSheet());
  return ok ?? false;
}

class _AddressFormSheet extends ConsumerStatefulWidget {
  const _AddressFormSheet();
  @override
  ConsumerState<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _line = TextEditingController();
  LocationUnit? _province;
  LocationUnit? _ward;
  bool _saving = false;
  bool _showLocError = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _line.dispose();
    super.dispose();
  }

  String? _req(String? v, String msg) => (v == null || v.trim().isEmpty) ? msg : null;

  Future<void> _pickProvince() async {
    final picked = await _pick(ref.read(stringsProvider).chooseProvince, provincesProvider);
    if (picked != null && mounted) {
      setState(() {
        _province = picked;
        _ward = null; // đổi tỉnh -> reset phường/xã
      });
    }
  }

  Future<void> _pickWard() async {
    if (_province == null) return;
    final picked = await _pick(ref.read(stringsProvider).chooseWard, wardsProvider(_province!.code));
    if (picked != null && mounted) setState(() => _ward = picked);
  }

  Future<LocationUnit?> _pick(String title, FutureProvider<List<LocationUnit>> provider) {
    return showAppSheet<LocationUnit>(
      context,
      builder: (_) => _LocationPickerSheet(title: title, provider: provider),
    );
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    final locOk = _province != null && _ward != null;
    if (!locOk) setState(() => _showLocError = true);
    if (!formOk || !locOk) return;

    final s = ref.read(stringsProvider);
    setState(() => _saving = true);
    try {
      await ref.read(addressRepositoryProvider).add(
            recipientName: _name.text.trim(),
            phone: _phone.text.trim(),
            line: _line.text.trim(),
            ward: _ward!.name,
            province: _province!.name,
            isDefault: true,
          );
      if (mounted) {
        showAppSnack(context, s.addressSaved, type: AppSnackType.success);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Handle(),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: AppColors.brand, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s.addAddress,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _field(_name, s.recipientName, Icons.person_outline_rounded,
                  validator: (v) => _req(v, s.required)),
              const SizedBox(height: 12),
              _field(_phone, s.phone, Icons.phone_outlined,
                  keyboard: TextInputType.phone, validator: (v) => _req(v, s.required)),
              const SizedBox(height: 12),
              // Tỉnh/Thành + Phường/Xã: chọn từ danh sách (API).
              _selectField(
                icon: Icons.public_rounded,
                value: _province?.name,
                hint: s.chooseProvince,
                error: _showLocError && _province == null,
                onTap: _pickProvince,
              ),
              const SizedBox(height: 12),
              _selectField(
                icon: Icons.holiday_village_outlined,
                value: _ward?.name,
                hint: _province == null ? s.chooseProvinceFirst : s.chooseWard,
                enabled: _province != null,
                error: _showLocError && _ward == null,
                onTap: _pickWard,
              ),
              const SizedBox(height: 12),
              _field(_line, s.streetLineFull, Icons.home_outlined,
                  validator: (v) => _req(v, s.required)),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(s.saveAddress),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      validator: validator,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), isDense: true),
    );
  }

  /// Ô "chọn" trông giống ô nhập, mở bottom sheet danh sách khi bấm.
  Widget _selectField({
    required IconData icon,
    required String? value,
    required String hint,
    required VoidCallback onTap,
    bool enabled = true,
    bool error = false,
  }) {
    final borderColor = error
        ? AppColors.danger
        : (enabled ? const Color(0xFFECEFF1) : const Color(0xFFECEFF1));
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Pressable(
        onTap: enabled ? onTap : null,
        haptic: enabled,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radius),
            border: Border.all(color: borderColor, width: error ? 1.4 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF8B93A1)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value ?? hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: value == null ? const Color(0xFF8B93A1) : Colors.black87,
                    fontWeight: value == null ? FontWeight.w400 : FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.expand_more_rounded, color: Color(0xFF8B93A1)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet danh sách đơn vị hành chính có ô tìm kiếm.
class _LocationPickerSheet extends ConsumerStatefulWidget {
  const _LocationPickerSheet({required this.title, required this.provider});
  final String title;
  final FutureProvider<List<LocationUnit>> provider;
  @override
  ConsumerState<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<_LocationPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final async = ref.watch(widget.provider);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.72,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            const _Handle(),
            Row(
              children: [
                Expanded(
                  child: Text(widget.title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: s.search,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => _ErrorRetry(
                  message: s.loadListError,
                  retryLabel: s.retry,
                  onRetry: () => ref.invalidate(widget.provider),
                ),
                data: (all) {
                  final list = _query.isEmpty
                      ? all
                      : all.where((e) => e.name.toLowerCase().contains(_query)).toList();
                  if (list.isEmpty) {
                    return Center(child: Text(s.noProducts, style: const TextStyle(color: Colors.grey)));
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => ListTile(
                      title: Text(list[i].name),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      onTap: () => Navigator.pop(context, list[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 44,
          height: 4,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFDDE1E6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.retryLabel, required this.onRetry});
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 44, color: Colors.grey),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}
