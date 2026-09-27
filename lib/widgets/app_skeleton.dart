import 'package:flutter/material.dart';

import '../app/design.dart';
import '../app/motion.dart';

/// Màu khối skeleton theo theme (base tối/sáng + vệt sáng quét).
({Color base, Color hi}) _skeletonColors(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return dark
      ? (base: const Color(0xFF232E29), hi: const Color(0xFF2E3B35))
      : (base: const Color(0xFFE9EDEB), hi: const Color(0xFFF5F8F7));
}

/// Một khối skeleton (hộp/đường/tròn) có hiệu ứng quét sáng (shimmer).
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: shape == BoxShape.circle ? width : height,
        decoration: BoxDecoration(
          color: _skeletonColors(context).base,
          shape: shape,
          borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Băng sáng quét ngang qua con (chỉ hoạt động khi không giảm chuyển động).
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});
  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: AppMotion.ambientLoop)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return widget.child;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) {
          final sk = _skeletonColors(context);
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [sk.base, sk.hi, sk.base],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(_c.value * 2 - 1),
            ).createShader(bounds),
            child: child,
          );
        },
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.slide);
  final double slide;
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * slide, 0, 0);
}

/// Đường skeleton (dòng chữ giả).
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.width, this.height = 12});
  final double? width;
  final double height;
  @override
  Widget build(BuildContext context) => Skeleton(width: width, height: height, radius: 6);
}

/// Thẻ sản phẩm giả — khớp bố cục [ProductTile] (tỉ lệ ảnh 0.66).
class ProductTileSkeleton extends StatelessWidget {
  const ProductTileSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: AppRadius.brLg,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(child: Skeleton(width: double.infinity, radius: 14)),
          const SizedBox(height: 10),
          const SkeletonLine(width: double.infinity),
          const SizedBox(height: 6),
          const SkeletonLine(width: 80),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonLine(width: 60, height: 14),
              Skeleton(width: 30, height: 30, shape: BoxShape.circle),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lưới skeleton sản phẩm — dùng khi trang chủ / shop / yêu thích đang tải.
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({super.key, this.count = 6, this.padding = const EdgeInsets.all(16)});
  final int count;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.66,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: count,
      itemBuilder: (_, _) => const ProductTileSkeleton(),
    );
  }
}

/// Thẻ danh sách giả — dùng cho giỏ/đơn/địa chỉ đang tải.
class ListCardSkeleton extends StatelessWidget {
  const ListCardSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: AppRadius.brLg,
      ),
      child: Row(
        children: [
          const Skeleton(width: 48, height: 48, shape: BoxShape.circle),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLine(width: 160, height: 13),
                SizedBox(height: 8),
                SkeletonLine(width: 100, height: 11),
              ],
            ),
          ),
          const SkeletonLine(width: 54, height: 14),
        ],
      ),
    );
  }
}

/// Danh sách nhiều [ListCardSkeleton].
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 5, this.padding = const EdgeInsets.all(16)});
  final int count;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (_, _) => const ListCardSkeleton(),
    );
  }
}
