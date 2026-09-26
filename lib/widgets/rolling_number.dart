import 'package:flutter/material.dart';

import '../app/motion.dart';
import 'spring.dart';

/// Con số "cuộn" tới giá trị mới theo spring physics thay vì đổi cứng — dùng cho
/// giá, tổng tiền, số lượng. Chỉ chạy khi giá trị **đổi** (không đếm từ 0 mỗi lần
/// mở màn), nên mỗi lần cuộn đều mang ý nghĩa "giá trị vừa thay đổi".
///
/// Reduced-motion: [Springy] nhảy thẳng tới đích -> hiện số cuối tức thì.
class RollingNumber extends StatelessWidget {
  const RollingNumber({
    super.key,
    required this.value,
    this.style,
    this.format,
    this.spring = AppMotion.smooth,
    this.textAlign,
  });

  /// Giá trị đích (số nguyên — tiền/đếm).
  final int value;
  final TextStyle? style;

  /// Hàm định dạng (vd tiền tệ). Mặc định in số thô.
  final String Function(int)? format;
  final SpringDescription spring;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final fmt = format ?? (v) => '$v';
    return Springy(
      value: value.toDouble(),
      spring: spring,
      builder: (_, v, _) => Text(fmt(v.round()), style: style, textAlign: textAlign),
    );
  }
}
