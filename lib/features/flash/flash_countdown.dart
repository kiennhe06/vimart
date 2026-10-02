import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design.dart';
import '../../core/i18n/app_strings.dart';

/// Đồng hồ đếm ngược tới thời điểm kết thúc flash sale (cập nhật mỗi giây).
class FlashCountdown extends ConsumerStatefulWidget {
  const FlashCountdown({super.key, required this.endsAt, this.compact = false});
  final DateTime endsAt;
  final bool compact;

  @override
  ConsumerState<FlashCountdown> createState() => _FlashCountdownState();
}

class _FlashCountdownState extends ConsumerState<FlashCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final left = widget.endsAt.difference(DateTime.now());
    final ended = left.isNegative;
    final label = ended
        ? s.flashEnded
        : '${s.flashEndsIn} ${_two(left.inHours)}:${_two(left.inMinutes % 60)}:${_two(left.inSeconds % 60)}';

    final box = Container(
      padding: EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 10, vertical: widget.compact ? 3 : 4),
      decoration: BoxDecoration(
        color: context.c.promo.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: widget.compact ? 13 : 15, color: context.c.promo),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: context.c.promo,
                  fontWeight: FontWeight.w700,
                  fontSize: widget.compact ? 11 : 13)),
        ],
      ),
    );
    return box;
  }
}
