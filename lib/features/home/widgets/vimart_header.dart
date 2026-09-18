import 'package:flutter/widgets.dart';

import '../home_ui.dart';

/// Header tự dựng bằng Container + Align + Text (KHÔNG dùng AppBar).
/// Logo "ViMart" màu cam, căn giữa. Chiều cao cố định 52.
class VimartHeader extends StatelessWidget {
  const VimartHeader({super.key});

  static const double height = 52;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: HomeColors.background,
      ),
      child: const Text('ViMart', style: HomeText.logo),
    );
  }
}
