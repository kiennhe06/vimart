import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';

import '../home_ui.dart';

/// Ô tìm kiếm tự dựng hoàn toàn:
/// - Vỏ ngoài: Container + BoxDecoration (bo góc, viền, nền trắng).
/// - Nhập liệu: EditableText (widget nền tảng — KHÔNG dùng TextField/SearchBar ăn sẵn).
/// - Bấm vào bất kỳ đâu trong ô sẽ focus để gõ (GestureDetector).
class VimartSearchBox extends StatefulWidget {
  const VimartSearchBox({super.key, required this.onSubmitted});

  /// Gọi khi người dùng nhấn Enter/Search trên bàn phím.
  final ValueChanged<String> onSubmitted;

  static const double boxHeight = 46;
  static const double areaHeight = 8 + boxHeight + 10; // padding trên + ô + padding dưới

  @override
  State<VimartSearchBox> createState() => _VimartSearchBoxState();
}

class _VimartSearchBoxState extends State<VimartSearchBox> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onSubmitted('');
  }

  @override
  Widget build(BuildContext context) {
    final bool focused = _focusNode.hasFocus;
    return Padding(
      padding: const EdgeInsets.fromLTRB(HomeDims.pagePadding, 8, HomeDims.pagePadding, 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _focusNode.requestFocus(),
        child: Container(
          height: VimartSearchBox.boxHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: HomeColors.surface,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: focused ? HomeColors.brand : HomeColors.border,
              width: focused ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 20, color: HomeColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Placeholder tự vẽ (chỉ hiện khi chưa gõ gì)
                    if (!_hasText)
                      const Text('Tìm sản phẩm...', style: HomeText.searchHint),
                    EditableText(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: HomeText.searchInput,
                      cursorColor: HomeColors.brand,
                      backgroundCursorColor: HomeColors.border,
                      maxLines: 1,
                      textInputAction: TextInputAction.search,
                      onSubmitted: widget.onSubmitted,
                    ),
                  ],
                ),
              ),
              if (_hasText)
                GestureDetector(
                  onTap: _clear,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.close, size: 18, color: HomeColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
