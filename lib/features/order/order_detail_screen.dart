import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design.dart';
import '../../widgets/sticker_icon.dart';
import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/i18n/app_strings.dart';
import '../../widgets/app_busy.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_feedback.dart';
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
      appBar: AppBar(title: Text(ref.watch(stringsProvider).orderDetail)),
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
      final str = ref.read(stringsProvider);
      final ok = await showAppDialog<bool>(
        context,
        builder: (ctx) => AlertDialog(
          title: Text(str.confirm),
          content: Text(confirmText),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(str.no)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(str.agree)),
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
      if (mounted) showAppSnack(context, e.toString(), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _refresh() {
    ref.invalidate(orderDetailProvider(order.summary.id));
    ref.invalidate(myOrdersProvider);
    ref.invalidate(shopOrdersProvider);
  }

  /// Thẻ hiển thị yêu cầu trả hàng (khi đã gửi).
  Widget _returnCard(ReturnRequest r) {
    final str = ref.watch(stringsProvider);
    final color = switch (r.status) {
      'approved' => AppColors.brand,
      'rejected' => Colors.red.shade400,
      _ => const Color(0xFFF59E0B),
    };
    return _card(str.returnStatusLabel, [
      Row(
        children: [
          Expanded(
            child: Text(str.returnReasonText(r.reason),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(str.returnStatusText(r.status),
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
      if (r.note != null && r.note!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(r.note!, style: TextStyle(color: context.c.textSecondary)),
        ),
      if (r.adminNote != null && r.adminNote!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(r.adminNote!,
              style: TextStyle(color: context.c.textSecondary, fontStyle: FontStyle.italic)),
        ),
    ]);
  }

  /// Mở form yêu cầu trả hàng (chọn lý do + mô tả).
  Future<void> _openReturnSheet() async {
    final str = ref.read(stringsProvider);
    const reasons = ['defective', 'wrong_item', 'not_as_described', 'other'];
    String reason = reasons.first;
    final noteCtrl = TextEditingController();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(str.requestReturn,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Text(str.returnReason, style: TextStyle(color: context.c.textSecondary)),
              const SizedBox(height: 6),
              RadioGroup<String>(
                groupValue: reason,
                onChanged: (v) => setSheet(() => reason = v!),
                child: Column(
                  children: [
                    for (final r in reasons)
                      RadioListTile<String>(
                        value: r,
                        title: Text(str.returnReasonText(r)),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: str.returnNote,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(str.send2),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final note = noteCtrl.text.trim();
    noteCtrl.dispose();
    if (submitted != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(orderRepositoryProvider).requestReturn(order.summary.id, reason, note);
      _refresh();
      if (mounted) showAppSnack(context, str.returnSent, type: AppSnackType.success);
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = order.summary;
    final str = ref.watch(stringsProvider);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(
                children: [
                  Text(str.orderCode(s.code), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  OrderStatusChip(status: s.status),
                ],
              ),
              const SizedBox(height: 12),
              // Địa chỉ
              _card(str.recipient, [
                Text('${order.recipientName} • ${order.recipientPhone}'),
                const SizedBox(height: 4),
                Text(order.addressText, style: TextStyle(color: context.c.textSecondary)),
              ]),
              // Sản phẩm
              _card(s.shopName ?? str.productsLabel, [
                for (final item in order.items) _itemRow(item),
              ]),
              // Tổng tiền
              _card(str.paymentLabel, [
                _row(str.subtotal, formatVnd(order.subtotal)),
                _row(str.shippingFee, formatVnd(order.shippingFee)),
                if (order.discount > 0) _row(str.discount, '-${formatVnd(order.discount)}'),
                const Divider(),
                _row(str.total, formatVnd(s.total), highlight: true),
                const SizedBox(height: 4),
                _row(str.method, s.paymentMethod == 'cod' ? 'COD' : 'VNPay'),
                _row(str.statusLabel, s.isPaid ? str.paidFull : str.unpaid),
              ]),
              // Lịch sử trạng thái đơn
              if (order.history.isNotEmpty)
                _card(str.orderHistory, [
                  for (int i = 0; i < order.history.length; i++)
                    _historyRow(order.history[i], i == order.history.length - 1),
                ]),
              // Trả hàng / hoàn tiền
              if (order.returnRequest != null)
                _returnCard(order.returnRequest!)
              else if (order.summary.status == 'completed')
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _openReturnSheet,
                    icon: const StickerIcon('return', size: 20),
                    label: Text(str.requestReturn),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                  ),
                ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: AppMotion.dur(context, AppMotion.fast),
          child: _busy
              ? const LinearProgressIndicator(key: ValueKey('busy'))
              : const SizedBox(width: double.infinity, key: ValueKey('idle')),
        ),
        // Bộ nút hành động đổi theo trạng thái -> co giãn mượt khi buttons thay đổi.
        AnimatedSize(
          duration: AppMotion.dur(context, AppMotion.base),
          curve: AppMotion.emphasized,
          child: _actions(),
        ),
      ],
    );
  }

  /// Nút hành động thay đổi theo vai trò + trạng thái.
  Widget _actions() {
    final status = order.summary.status;
    final str = ref.watch(stringsProvider);
    final buttons = <Widget>[];

    if (widget.isSeller) {
      if (status == 'pending') {
        buttons.add(_btn(str.confirmOrder, () => _doAction('confirm')));
        buttons.add(_btnOutline(str.reject, () => _doAction('reject', confirmText: str.rejectConfirm)));
      } else if (status == 'confirmed') {
        buttons.add(_btn(str.ship, () => _doAction('ship')));
      }
    } else {
      if (status == 'pending') {
        buttons.add(_btnOutline(str.cancelOrder, () => _doAction('cancel', confirmText: str.cancelOrderConfirm)));
      } else if (status == 'shipping') {
        buttons.add(_btn(str.received, () => _doAction('received', confirmText: str.receivedConfirm)));
      } else if (status == 'completed') {
        for (final item in order.items.where((i) => !i.reviewed && i.productId != null)) {
          buttons.add(_btnOutline(str.reviewProductLabel(item.productName), () => _openReview(item)));
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
    final done = await showAppDialog<bool>(
      context,
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

  /// Một mốc timeline: chấm màu + đường nối + nhãn trạng thái + thời gian.
  Widget _historyRow(OrderStatusEvent e, bool isLast) {
    final str = ref.watch(stringsProvider);
    final color = switch (e.toStatus) {
      'completed' => AppColors.brand,
      'cancelled' => Colors.red.shade400,
      'confirmed' || 'shipping' => AppColors.accent,
      _ => Colors.grey,
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: Colors.grey.withValues(alpha: 0.3))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(str.orderStatus(e.toStatus),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (e.createdAt != null)
                    Text(formatDateTime(e.createdAt!),
                        style: TextStyle(fontSize: 12, color: context.c.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
      if (mounted) showAppSnack(context, e.toString(), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final str = ref.watch(stringsProvider);
    return AlertDialog(
      title: Text(str.reviewProductTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              final on = star <= _rating;
              return IconButton(
                icon: AnimatedScale(
                  scale: on ? 1.15 : 1.0,
                  duration: AppMotion.dur(context, AppMotion.base),
                  curve: AppMotion.pop,
                  child: StickerIcon('star', size: 26, colorFilter: on ? null : StickerIcon.grayscale),
                ),
                onPressed: () {
                  AppHaptics.light();
                  setState(() => _rating = star);
                },
              );
            }),
          ),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: InputDecoration(hintText: str.reviewHint),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(str.cancel)),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: BusySwitch(busy: _saving, spinnerSize: 20, child: Text(str.send)),
        ),
      ],
    );
  }
}
