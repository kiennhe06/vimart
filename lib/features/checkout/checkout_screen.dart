import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/motion.dart';
import '../../widgets/sticker_icon.dart';
import '../../app/nav_provider.dart';
import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/i18n/app_strings.dart';
import '../../models/address.dart';
import '../../widgets/animated_checkmark.dart';
import '../../widgets/app_busy.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/burst.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/app_skeleton.dart';
import '../../widgets/async_view.dart';
import '../address/address_form_sheet.dart';
import '../address/address_provider.dart';
import '../../models/cart.dart';
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

  final _voucherCtrl = TextEditingController();
  AppliedVoucher? _voucher;
  bool _applyingVoucher = false;

  @override
  void dispose() {
    _voucherCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyVoucher() async {
    final code = _voucherCtrl.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _applyingVoucher = true);
    try {
      final voucher = await ref.read(orderRepositoryProvider).applyVoucher(code);
      setState(() => _voucher = voucher);
      if (mounted) {
        showAppSnack(context, ref.read(stringsProvider).voucherApplied(voucher.code),
            type: AppSnackType.success);
      }
    } catch (e) {
      setState(() => _voucher = null);
      if (mounted) showAppSnack(context, e.toString(), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _applyingVoucher = false);
    }
  }

  void _removeVoucher() {
    setState(() {
      _voucher = null;
      _voucherCtrl.clear();
    });
  }

  Future<void> _placeOrder() async {
    if (_addressId == null) {
      showAppSnack(context, ref.read(stringsProvider).selectAddress, type: AppSnackType.warning);
      return;
    }
    setState(() => _placing = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      final result = await repo.checkout(
        addressId: _addressId!,
        paymentMethod: _paymentMethod,
        voucherCode: _voucher?.code,
        variantIds: ref.read(cartSelectionProvider).toList(),
      );
      _voucher = null;
      await ref.read(cartProvider.notifier).reload();
      ref.invalidate(myOrdersProvider);

      if (_paymentMethod == 'vnpay') {
        await _handleVnpay(repo, result);
      } else {
        if (mounted) _showSuccess(ref.read(stringsProvider).codSuccess);
      }
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), type: AppSnackType.error);
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
        _showSuccess(ref.read(stringsProvider).vnpayOpened);
      }
    } catch (_) {
      // Chưa cấu hình VNPay thật -> giả lập thanh toán để chạy được luồng demo.
      await repo.mockPay(result.groupCode);
      ref.invalidate(myOrdersProvider);
      if (mounted) {
        _showSuccess(ref.read(stringsProvider).mockPaySuccess);
      }
    }
  }

  void _showSuccess(String message) {
    final s = ref.read(stringsProvider);
    AppHaptics.success();
    showAppDialog(
      context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        // ✓ vẽ nét + pháo giấy tỏa ra: khoảnh khắc "thưởng" khi đặt hàng xong.
        icon: SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: const [
              ConfettiBurst(size: 96),
              AnimatedCheck(size: 64),
            ],
          ),
        ),
        title: Text(s.done),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(bottomNavIndexProvider.notifier).go(0); // về tab Trang chủ
              context.go('/');
            },
            child: Text(s.backHome),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(bottomNavIndexProvider.notifier).go(2); // sang tab Đơn hàng
              context.go('/');
            },
            child: Text(s.viewOrders),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final addressesAsync = ref.watch(addressesProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.checkout)),
      body: AsyncView(
        value: cartAsync,
        loading: const SkeletonList(count: 4),
        data: (cart) {
          // Chỉ thanh toán các món ĐÃ CHỌN ở giỏ (lọc theo variantId).
          final selected = ref.watch(cartSelectionProvider);
          final shops = [
            for (final shop in cart.shops)
              if (shop.items.any((i) => selected.contains(i.variantId)))
                CartShop(
                  shopId: shop.shopId,
                  shopName: shop.shopName,
                  items: shop.items.where((i) => selected.contains(i.variantId)).toList(),
                ),
          ];
          final selectedSubtotal = shops.fold<int>(
              0, (a, sh) => a + sh.items.fold<int>(0, (b, i) => b + i.lineTotal));
          final selectedCount = shops.fold<int>(
              0, (a, sh) => a + sh.items.fold<int>(0, (b, i) => b + i.quantity));
          final shippingTotal = shops.length * _shippingPerShop;
          final discount = (_voucher?.discount ?? 0).clamp(0, selectedSubtotal);
          final total = selectedSubtotal + shippingTotal - discount;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // Địa chỉ
                    _section(s.shippingAddress),
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
                    _section(s.productsSection(selectedCount)),
                    for (final shop in shops)
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
                    // Mã giảm giá
                    _section(s.discountCode),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _voucher == null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _voucherCtrl,
                                    textCapitalization: TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      hintText: s.enterVoucherHint,
                                      prefixIcon: const StickerIcon('tag', size: 22),
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onSubmitted: (_) => _applyVoucher(),
                                  ),
                                  const SizedBox(height: 10),
                                  FilledButton.tonal(
                                    onPressed: _applyingVoucher ? null : _applyVoucher,
                                    child: _applyingVoucher
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : Text(s.applyVoucher),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  const StickerIcon('check', size: 24),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_voucher!.code,
                                            style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('-${formatVnd(_voucher!.discount)}',
                                            style: const TextStyle(color: AppColors.accent)),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _removeVoucher,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(s.removeVoucher,
                                          style: const TextStyle(
                                              color: AppColors.accent, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Phương thức thanh toán
                    _section(s.paymentMethod),
                    Card(
                      child: RadioGroup<String>(
                        groupValue: _paymentMethod,
                        onChanged: (v) => setState(() => _paymentMethod = v!),
                        child: Column(
                          children: [
                            RadioListTile<String>(
                              value: 'cod',
                              title: Text(s.codOption),
                              secondary: const StickerIcon('truck', size: 26),
                            ),
                            RadioListTile<String>(
                              value: 'vnpay',
                              title: Text(s.vnpayOption),
                              secondary: const StickerIcon('wallet', size: 26),
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
                            _summaryRow(s.subtotal, selectedSubtotal),
                            _summaryRow(s.shippingFee, shippingTotal),
                            if (discount > 0) _summaryRow(s.discount, -discount),
                            const Divider(),
                            _summaryRow(s.total, total, highlight: true),
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
                    onPressed: (_placing || shops.isEmpty) ? null : _placeOrder,
                    child: BusySwitch(busy: _placing, child: Text(s.placeOrder(formatVnd(total)))),
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
    final added = await showAddAddressSheet(context);
    if (added) ref.invalidate(addressesProvider);
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
class _AddressPicker extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
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
            Padding(padding: const EdgeInsets.all(16), child: Text(s.noAddressYet)),
          for (final a in addresses)
            RadioListTile<int>(
              value: a.id,
              title: Text('${a.recipientName} • ${a.phone}'),
              subtitle: Text(a.fullAddress),
            ),
          TextButton.icon(
            onPressed: onAdd,
            icon: const StickerIcon('location', size: 22),
            label: Text(s.addNewAddress),
          ),
          ],
        ),
      ),
    );
  }
}

