import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../models/address.dart';
import '../../widgets/async_view.dart';
import '../address/address_provider.dart';
import '../cart/cart_provider.dart';
import '../order/order_providers.dart';
import '../order/order_repository.dart';

/// Phí ship cố định mỗi shop (khớp với backend) — chỉ để hiển thị ước tính.
const int _shippingPerShop = 30000;

/// Màn hình thanh toán: chọn địa chỉ, phương thức trả tiền, và đặt hàng.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int? _addressId;
  String _paymentMethod = 'cod';
  bool _placing = false;

  Future<void> _placeOrder() async {
    if (_addressId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vui lòng chọn địa chỉ nhận hàng')));
      return;
    }
    setState(() => _placing = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      final result = await repo.checkout(addressId: _addressId!, paymentMethod: _paymentMethod);
      await ref.read(cartProvider.notifier).reload();
      ref.invalidate(myOrdersProvider);

      if (_paymentMethod == 'vnpay') {
        await _handleVnpay(repo, result);
      } else {
        if (mounted) _showSuccess('Đặt hàng thành công! Bạn sẽ trả tiền khi nhận hàng (COD).');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  /// Xử lý thanh toán VNPay. Nếu đã cấu hình sandbox thì mở trang VNPay;
  /// nếu chưa (chỉ chạy demo) thì dùng cơ chế giả lập của backend.
  Future<void> _handleVnpay(OrderRepository repo, CheckoutResult result) async {
    try {
      final url = await repo.createVnpayUrl(result.groupCode);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (mounted) {
        _showSuccess('Đã mở cổng VNPay. Sau khi thanh toán xong, kéo để làm mới đơn hàng.');
      }
    } catch (_) {
      // Chưa cấu hình VNPay thật -> giả lập thanh toán để chạy được luồng demo.
      await repo.mockPay(result.groupCode);
      ref.invalidate(myOrdersProvider);
      if (mounted) {
        _showSuccess('Thanh toán (giả lập) thành công! (Chưa cấu hình VNPay sandbox thật.)');
      }
    }
  }

  void _showSuccess(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
        title: const Text('Hoàn tất'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/');
            },
            child: const Text('Về trang chủ'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/orders');
            },
            child: const Text('Xem đơn hàng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: AsyncView(
        value: cartAsync,
        data: (cart) {
          final shippingTotal = cart.shops.length * _shippingPerShop;
          final total = cart.subtotal + shippingTotal;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // Địa chỉ
                    _section('Địa chỉ nhận hàng'),
                    AsyncView(
                      value: addressesAsync,
                      onRetry: () => ref.invalidate(addressesProvider),
                      data: (addresses) => _AddressPicker(
                        addresses: addresses,
                        selectedId: _addressId,
                        onSelect: (id) => setState(() => _addressId = id),
                        onAdd: _openAddAddress,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Sản phẩm
                    _section('Sản phẩm (${cart.itemCount})'),
                    for (final shop in cart.shops)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(shop.shopName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Divider(),
                              for (final item in shop.items)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text('${item.productName} (${item.variantName}) x${item.quantity}')),
                                      Text(formatVnd(item.lineTotal)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Phương thức thanh toán
                    _section('Phương thức thanh toán'),
                    Card(
                      child: RadioGroup<String>(
                        groupValue: _paymentMethod,
                        onChanged: (v) => setState(() => _paymentMethod = v!),
                        child: const Column(
                          children: [
                            RadioListTile<String>(
                              value: 'cod',
                              title: Text('Thanh toán khi nhận hàng (COD)'),
                              secondary: Icon(Icons.local_shipping_outlined),
                            ),
                            RadioListTile<String>(
                              value: 'vnpay',
                              title: Text('Ví VNPay'),
                              secondary: Icon(Icons.account_balance_wallet_outlined),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tổng tiền
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _summaryRow('Tạm tính', cart.subtotal),
                            _summaryRow('Phí vận chuyển', shippingTotal),
                            const Divider(),
                            _summaryRow('Tổng cộng', total, highlight: true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Nút đặt hàng
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton(
                    onPressed: (_placing || cart.isEmpty) ? null : _placeOrder,
                    child: _placing
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Đặt hàng • ${formatVnd(total)}'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openAddAddress() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddAddressSheet(),
    );
    if (added == true) ref.invalidate(addressesProvider);
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );

  Widget _summaryRow(String label, int value, {bool highlight = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(formatVnd(value),
                style: TextStyle(
                    color: highlight ? AppColors.brand : null,
                    fontWeight: highlight ? FontWeight.bold : null,
                    fontSize: highlight ? 18 : 14)),
          ],
        ),
      );
}

/// Danh sách chọn địa chỉ + nút thêm mới.
class _AddressPicker extends StatelessWidget {
  const _AddressPicker({
    required this.addresses,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
  });
  final List<Address> addresses;
  final int? selectedId;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    // Tự chọn địa chỉ mặc định lần đầu.
    if (selectedId == null && addresses.isNotEmpty) {
      final def = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
      WidgetsBinding.instance.addPostFrameCallback((_) => onSelect(def.id));
    }
    return Card(
      child: RadioGroup<int>(
        groupValue: selectedId,
        onChanged: (v) => onSelect(v!),
        child: Column(
          children: [
          if (addresses.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('Chưa có địa chỉ nào.')),
          for (final a in addresses)
            RadioListTile<int>(
              value: a.id,
              title: Text('${a.recipientName} • ${a.phone}'),
              subtitle: Text(a.fullAddress),
            ),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Thêm địa chỉ mới'),
          ),
          ],
        ),
      ),
    );
  }
}

/// Form thêm địa chỉ nhanh.
class _AddAddressSheet extends ConsumerStatefulWidget {
  const _AddAddressSheet();
  @override
  ConsumerState<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends ConsumerState<_AddAddressSheet> {
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(addressRepositoryProvider).add(
            recipientName: _name.text.trim(),
            phone: _phone.text.trim(),
            line: _line.text.trim(),
            ward: _ward.text.trim(),
            district: _district.text.trim(),
            province: _province.text.trim(),
            isDefault: true,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Thêm địa chỉ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _field(_name, 'Tên người nhận', required: true),
            _field(_phone, 'Số điện thoại', required: true, keyboard: TextInputType.phone),
            _field(_line, 'Số nhà, tên đường', required: true),
            _field(_ward, 'Phường/Xã'),
            _field(_district, 'Quận/Huyện'),
            _field(_province, 'Tỉnh/Thành phố'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Lưu địa chỉ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {bool required = false, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null : null,
      ),
    );
  }
}
