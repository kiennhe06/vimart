import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../models/order.dart';
import '../../widgets/async_view.dart';
import '../auth/auth_provider.dart';
import '../catalog/catalog_providers.dart';
import 'order_providers.dart';
import 'order_repository.dart';
import 'orders_screen.dart' show OrderStatusChip;

/// Chi tiết 1 đơn hàng + các hành động theo vai trò (người mua / người bán).
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderDetailProvider(orderId));
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: AsyncView(
        value: async,
        onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        data: (order) {
          // Người bán nếu shop của họ chính là shop bán đơn này.
          final isSeller = user?.shop?.id == order.summary.shopId;
          return _OrderDetailBody(order: order, isSeller: isSeller);
        },
      ),
    );
  }
}

class _OrderDetailBody extends ConsumerStatefulWidget {
  const _OrderDetailBody({required this.order, required this.isSeller});
  final OrderDetail order;
  final bool isSeller;

  @override
  ConsumerState<_OrderDetailBody> createState() => _OrderDetailBodyState();
}

class _OrderDetailBodyState extends ConsumerState<_OrderDetailBody> {
  bool _busy = false;

  OrderDetail get order => widget.order;

  Future<void> _doAction(String action, {String? confirmText}) async {
    if (confirmText != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xác nhận'),
          content: Text(confirmText),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đồng ý')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(orderRepositoryProvider).action(order.summary.id, action);
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _refresh() {
    ref.invalidate(orderDetailProvider(order.summary.id));
    ref.invalidate(myOrdersProvider);
    ref.invalidate(shopOrdersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final s = order.summary;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(
                children: [
                  Text('Đơn ${s.code}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  OrderStatusChip(status: s.status),
                ],
              ),
              const SizedBox(height: 12),
              // Địa chỉ
              _card('Người nhận', [
                Text('${order.recipientName} • ${order.recipientPhone}'),
                const SizedBox(height: 4),
                Text(order.addressText, style: const TextStyle(color: Colors.grey)),
              ]),
              // Sản phẩm
              _card(s.shopName ?? 'Sản phẩm', [
                for (final item in order.items) _itemRow(item),
              ]),
              // Tổng tiền
              _card('Thanh toán', [
                _row('Tạm tính', formatVnd(order.subtotal)),
                _row('Phí vận chuyển', formatVnd(order.shippingFee)),
                if (order.discount > 0) _row('Giảm giá', '-${formatVnd(order.discount)}'),
                const Divider(),
                _row('Tổng cộng', formatVnd(s.total), highlight: true),
                const SizedBox(height: 4),
                _row('Phương thức', s.paymentMethod == 'cod' ? 'COD' : 'VNPay'),
                _row('Tình trạng', s.isPaid ? 'Đã thanh toán' : 'Chưa thanh toán'),
              ]),
            ],
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        _actions(),
      ],
    );
  }

  /// Nút hành động thay đổi theo vai trò + trạng thái.
  Widget _actions() {
    final status = order.summary.status;
    final buttons = <Widget>[];

    if (widget.isSeller) {
      if (status == 'pending') {
        buttons.add(_btn('Xác nhận đơn', () => _doAction('confirm')));
        buttons.add(_btnOutline('Từ chối', () => _doAction('reject', confirmText: 'Từ chối đơn này? Hàng sẽ được hoàn về kho.')));
      } else if (status == 'confirmed') {
        buttons.add(_btn('Giao hàng', () => _doAction('ship')));
      }
    } else {
      if (status == 'pending') {
        buttons.add(_btnOutline('Hủy đơn', () => _doAction('cancel', confirmText: 'Bạn chắc chắn muốn hủy đơn này?')));
      } else if (status == 'shipping') {
        buttons.add(_btn('Đã nhận hàng', () => _doAction('received', confirmText: 'Xác nhận bạn đã nhận được hàng?')));
      } else if (status == 'completed') {
        for (final item in order.items.where((i) => !i.reviewed && i.productId != null)) {
          buttons.add(_btnOutline('Đánh giá: ${item.productName}', () => _openReview(item)));
        }
      }
    }

    if (buttons.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(mainAxisSize: MainAxisSize.min, children: buttons),
      ),
    );
  }

  Future<void> _openReview(OrderItem item) async {
    final done = await showDialog<bool>(
      context: context,
      builder: (_) => _ReviewDialog(orderItemId: item.id, productId: item.productId!),
    );
    if (done == true) _refresh();
  }

  Widget _card(String title, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              ...children,
            ],
          ),
        ),
      );

  Widget _itemRow(OrderItem item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text('${item.productName} (${item.variantName}) x${item.quantity}')),
            Text(formatVnd(item.price * item.quantity)),
          ],
        ),
      );

  Widget _row(String label, String value, {bool highlight = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value,
                style: TextStyle(
                    color: highlight ? AppColors.brand : null,
                    fontWeight: highlight ? FontWeight.bold : null)),
          ],
        ),
      );

  Widget _btn(String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ElevatedButton(onPressed: _busy ? null : onTap, child: Text(label)),
      );

  Widget _btnOutline(String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton(onPressed: _busy ? null : onTap, child: Text(label)),
      );
}

/// Hộp thoại đánh giá sản phẩm (số sao + nhận xét).
class _ReviewDialog extends ConsumerStatefulWidget {
  const _ReviewDialog({required this.orderItemId, required this.productId});
  final int orderItemId;
  final int productId;

  @override
  ConsumerState<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<_ReviewDialog> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ref.read(orderRepositoryProvider).review(widget.orderItemId, _rating, _comment.text.trim());
      ref.invalidate(productDetailProvider(widget.productId));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đánh giá sản phẩm'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                icon: Icon(star <= _rating ? Icons.star : Icons.star_border, color: AppColors.accent),
                onPressed: () => setState(() => _rating = star),
              );
            }),
          ),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Nhận xét của bạn (không bắt buộc)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Gửi'),
        ),
      ],
    );
  }
}
