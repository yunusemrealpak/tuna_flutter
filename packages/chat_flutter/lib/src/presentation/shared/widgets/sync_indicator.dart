import 'package:flutter/material.dart';

class SyncIndicator extends StatefulWidget {
  const SyncIndicator({
    super.key,
    required this.isSyncing,
  });

  final bool isSyncing;

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.isSyncing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SyncIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSyncing != oldWidget.isSyncing) {
      if (widget.isSyncing) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSyncing) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: _controller,
            child: Icon(
              Icons.sync,
              size: 14,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Syncing...',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
