import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/i18n/app_strings.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_feedback.dart';
import 'address_provider.dart';

/// Mở form thêm địa chỉ — bottom sheet đẹp, DÙNG CHUNG ở Checkout & Sổ địa chỉ.
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
  final _ward = TextEditingController();
  final _district = TextEditingController();
  final _province = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _line, _ward, _district, _province]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _req(String? v, String msg) => (v == null || v.trim().isEmpty) ? msg : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final s = ref.read(stringsProvider);
    setState(() => _saving = true);
    try {
      await ref.read(addressRepositoryProvider).add(
            recipientName: _name.text.trim(),
            phone: _phone.text.trim(),
            line: _line.text.trim(),
            ward: _ward.text.trim().isEmpty ? null : _ward.text.trim(),
            district: _district.text.trim().isEmpty ? null : _district.text.trim(),
            province: _province.text.trim().isEmpty ? null : _province.text.trim(),
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
              // Thanh kéo
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE1E6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Tiêu đề có chip icon
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
              _field(_line, s.streetLineFull, Icons.home_outlined,
                  validator: (v) => _req(v, s.required)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field(_ward, s.ward, Icons.map_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_district, s.district, Icons.location_city_outlined)),
                ],
              ),
              const SizedBox(height: 12),
              _field(_province, s.province, Icons.public_rounded,
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        isDense: true,
      ),
    );
  }
}
