import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Icon sticker 3D (SVG) dùng chung toàn app.
///
/// [name] là tên file trong `assets/icons/ui/` (không kèm đuôi `.svg`).
/// Các sticker đã có màu/gradient riêng nên mặc định vẽ nguyên bản; truyền
/// [colorFilter] khi cần làm xám (ví dụ trạng thái chưa chọn/vô hiệu).
class StickerIcon extends StatelessWidget {
  const StickerIcon(this.name, {super.key, this.size = 24, this.colorFilter});

  final String name;
  final double size;
  final ColorFilter? colorFilter;

  /// Ma trận xám (luma) tái dùng cho trạng thái mờ/không hoạt động.
  static const ColorFilter grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/ui/$name.svg',
      width: size,
      height: size,
      colorFilter: colorFilter,
    );
  }
}
