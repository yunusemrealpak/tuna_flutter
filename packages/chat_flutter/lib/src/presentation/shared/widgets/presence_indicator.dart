import 'package:flutter/material.dart';

class PresenceIndicator extends StatelessWidget {
  const PresenceIndicator({
    super.key,
    required this.isOnline,
    this.size = 12.0,
  });

  final bool isOnline;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline
            ? const Color(0xFF4CAF50)
            : const Color(0xFF9E9E9E),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
    );
  }
}
