import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({
    super.key,
    required this.typingUsernames,
  });

  final List<String> typingUsernames;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _dotAnimations = List.generate(3, (i) {
      final start = i * 0.2;
      final end = start + 0.4;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _buildText() {
    final names = widget.typingUsernames;
    if (names.isEmpty) return '';
    if (names.length == 1) return '${names[0]} is typing';
    if (names.length == 2) return '${names[0]} and ${names[1]} are typing';
    return 'Several people are typing';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsernames.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Text(
              _buildText(),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 4),
            ...List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _dotAnimations[i],
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -4 * _dotAnimations[i].value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
