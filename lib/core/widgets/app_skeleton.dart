import 'package:flutter/material.dart';

/// Soft pulsing placeholder used in place of “Loading…” copy.
class AppSkeletonBlock extends StatefulWidget {
  const AppSkeletonBlock({
    super.key,
    this.height = 14,
    this.width,
    this.radius = 10,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<AppSkeletonBlock> createState() => _AppSkeletonBlockState();
}

class _AppSkeletonBlockState extends State<AppSkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool light = Theme.of(context).brightness == Brightness.light;
    final Color base = light ? const Color(0xFFF3E7DE) : const Color(0xFF3A302A);
    final Color highlight = light ? const Color(0xFFFFF7F2) : const Color(0xFF4A3E36);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (BuildContext context, Widget? child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(base, highlight, _pulse.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// Page-shaped placeholder: a short line, then list rows or chat bubbles.
class AppSkeletonPage extends StatelessWidget {
  const AppSkeletonPage({
    super.key,
    this.count = 5,
    this.chat = false,
    this.shrinkWrap = false,
  });

  final int count;
  final bool chat;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final bool light = Theme.of(context).brightness == Brightness.light;
    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: <Widget>[
        const AppSkeletonBlock(width: 220, height: 12),
        const SizedBox(height: 16),
        for (int i = 0; i < count; i++) ...<Widget>[
          if (chat)
            Align(
              alignment: i.isEven ? Alignment.centerLeft : Alignment.centerRight,
              child: AppSkeletonBlock(
                width: i.isEven ? 220 : 160,
                height: 48,
                radius: 18,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: light ? Colors.white : const Color(0xFF241C18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: <Widget>[
                  AppSkeletonBlock(width: 40, height: 40, radius: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AppSkeletonBlock(width: 140, height: 14),
                        SizedBox(height: 8),
                        AppSkeletonBlock(height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (i != count - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
