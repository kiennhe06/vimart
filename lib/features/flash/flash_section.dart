import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/design.dart';
import '../../core/format.dart';
import '../../core/i18n/app_strings.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/pressable.dart';
import 'flash_countdown.dart';
import 'flash_providers.dart';

/// Dải "⚡ Flash Sale" trên trang chủ (đợt đang chạy gần kết thúc nhất).
/// Ẩn hoàn toàn khi không có đợt nào.
class FlashSaleSection extends ConsumerWidget {
  const FlashSaleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeFlashProvider);
    return async.maybeWhen(
      data: (sales) {
        if (sales.isEmpty) return const SizedBox.shrink();
        final sale = sales.first;
        final s = ref.watch(stringsProvider);
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.c.promo.withValues(alpha: 0.14), context.c.promo.withValues(alpha: 0.03)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.c.promo.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SvgPicture.asset('assets/icons/ui/bolt.svg', width: 22, height: 22),
                  const SizedBox(width: 6),
                  Text(s.flashSaleTitle,
                      style: TextStyle(
                          color: context.c.promo, fontWeight: FontWeight.w800, fontSize: 16)),
                  const Spacer(),
                  if (sale.endsAt != null) FlashCountdown(endsAt: sale.endsAt!, compact: true),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 168,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sale.items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _FlashCard(sale.items[i]),
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _FlashCard extends StatelessWidget {
  const _FlashCard(this.p);
  final FlashProduct p;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => context.push('/product/${p.productId}'),
      child: SizedBox(
        width: 108,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 108,
                    height: 108,
                    child: NetworkImageBox(url: p.imageUrl, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.c.promo,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12), bottomRight: Radius.circular(10)),
                    ),
                    child: Text('-${p.discountPercent}%',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(formatVnd(p.salePrice),
                style: TextStyle(
                    color: context.c.promo, fontWeight: FontWeight.w800, fontSize: 14)),
            Text(formatVnd(p.price),
                style: TextStyle(
                    color: context.c.textSecondary,
                    fontSize: 11,
                    decoration: TextDecoration.lineThrough)),
          ],
        ),
      ),
    );
  }
}
