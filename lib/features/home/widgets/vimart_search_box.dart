import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';

import '../../../app/design.dart';
import '../../../app/motion.dart';
import '../home_ui.dart';

/// Ô tìm kiếm tự dựng hoàn toàn:
/// - Vỏ ngoài: Container + BoxDecoration (bo góc, viền, nền trắng).
/// - Nhập liệu: EditableText (widget nền tảng — KHÔNG dùng TextField/SearchBar ăn sẵn).
/// - Bấm vào bất kỳ đâu trong ô sẽ focus để gõ (GestureDetector).
class VimartSearchBox extends StatefulWidget {
  const VimartSearchBox({
    super.key,
    required this.onSubmitted,
    required this.hint,
    this.onChanged,
    this.onFocusChange,
    this.controller,
  });

  /// Gọi khi người dùng nhấn Enter/Search trên bàn phím.
  final ValueChanged<String> onSubmitted;

  /// Gọi mỗi khi nội dung đổi (dùng để tìm-khi-gõ, nên debounce ở phía gọi).
  final ValueChanged<String>? onChanged;

  /// Gọi khi ô nhận / mất focus (để hiện gợi ý lịch sử tìm kiếm).
  final ValueChanged<bool>? onFocusChange;

  /// Controller ngoài (tùy chọn) để đặt lại text từ lịch sử tìm kiếm.
  final TextEditingController? controller;

  /// Gợi ý trong ô tìm kiếm (đa ngôn ngữ).
  final String hint;

  static const double boxHeight = 46;
  static const double areaHeight = 8 + boxHeight + 10; // padding trên + ô + padding dưới

  @override
  State<VimartSearchBox> createState() => _VimartSearchBoxState();
}

class _VimartSearchBoxState extends State<VimartSearchBox> {
  late final TextEditingController _controller = widget.controller ?? TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(() {
      final has = _controller.text.isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _focusNode.addListener(() {
      setState(() {});
      widget.onFocusChange?.call(_focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
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
        child: AnimatedContainer(
          duration: AppMotion.dur(context, AppMotion.base),
          curve: AppMotion.emphasized,
          height: VimartSearchBox.boxHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: context.c.surface,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: focused ? context.c.brand : context.c.border,
              width: focused ? 1.4 : 1,
            ),
            // Quầng sáng mềm khi focus -> báo ô đang hoạt động.
            boxShadow: focused
                ? [BoxShadow(color: context.c.brand.withValues(alpha: 0.16), blurRadius: 12, offset: const Offset(0, 3))]
                : null,
          ),
          child: Row(
            children: [
              Icon(Icons.search, size: 20, color: context.c.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Placeholder mờ dần khi bắt đầu gõ (không biến mất "bụp").
                    AnimatedOpacity(
                      opacity: _hasText ? 0 : 1,
                      duration: AppMotion.dur(context, AppMotion.fast),
                      child: Text(widget.hint,
                          style: AppType.body.copyWith(color: context.c.textMuted)),
                    ),
                    EditableText(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: AppType.body.copyWith(color: context.c.textPrimary),
                      cursorColor: context.c.brand,
                      backgroundCursorColor: context.c.border,
                      maxLines: 1,
                      textInputAction: TextInputAction.search,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                    ),
                  ],
                ),
              ),
              // Nút xóa nở/thu theo lò xo khi có/không có chữ.
              AnimatedSwitcher(
                duration: AppMotion.dur(context, AppMotion.base),
                transitionBuilder: (c, a) => ScaleTransition(
                  scale: CurvedAnimation(parent: a, curve: AppMotion.pop),
                  child: FadeTransition(opacity: a, child: c),
                ),
                child: _hasText
                    ? GestureDetector(
                        key: const ValueKey('clear'),
                        onTap: _clear,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(Icons.close, size: 18, color: context.c.textSecondary),
                        ),
                      )
                    : const SizedBox(key: ValueKey('empty')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
