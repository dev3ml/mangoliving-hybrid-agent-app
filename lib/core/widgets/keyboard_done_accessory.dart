import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// iOS-style toolbar that sits immediately above the keyboard with a Done
/// control to dismiss focus without submitting.
class KeyboardDoneAccessory extends StatefulWidget {
  const KeyboardDoneAccessory({
    super.key,
    required this.focusNode,
    required this.child,
  });

  final FocusNode focusNode;
  final Widget child;

  @override
  State<KeyboardDoneAccessory> createState() => _KeyboardDoneAccessoryState();
}

class _KeyboardDoneAccessoryState extends State<KeyboardDoneAccessory>
    with WidgetsBindingObserver {
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_sync);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(KeyboardDoneAccessory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;
    oldWidget.focusNode.removeListener(_sync);
    widget.focusNode.addListener(_sync);
    _sync();
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_sync);
    WidgetsBinding.instance.removeObserver(this);
    _remove();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _entry?.markNeedsBuild();
  }

  void _sync() {
    if (!mounted) return;
    if (widget.focusNode.hasFocus) {
      _insert();
      _entry?.markNeedsBuild();
    } else {
      _remove();
    }
  }

  void _insert() {
    if (_entry != null) return;
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _entry = OverlayEntry(builder: (BuildContext context) {
      return _KeyboardDoneBar(onDone: widget.focusNode.unfocus);
    });
    overlay.insert(_entry!);
  }

  void _remove() {
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _KeyboardDoneBar extends StatelessWidget {
  const _KeyboardDoneBar({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final ui.FlutterView view = View.of(context);
    final double keyboardHeight =
        view.viewInsets.bottom / view.devicePixelRatio;
    if (keyboardHeight <= 0) {
      return const SizedBox.shrink();
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      right: 16,
      bottom: keyboardHeight + 8,
      child: Material(
        color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFF2C2C2E),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onDone,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Text(
              'Done',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
