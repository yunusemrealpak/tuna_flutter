import 'package:flutter/material.dart';

/// Common emoji reactions available to the user.
const _kDefaultEmojis = ['👍', '❤️', '😂', '😮', '😢', '🔥', '👏', '🎉'];

/// A bottom-sheet that lets the user pick an emoji reaction.
/// Call [showReactionPicker] to display it.
Future<String?> showReactionPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _ReactionPickerSheet(),
  );
}

class _ReactionPickerSheet extends StatelessWidget {
  const _ReactionPickerSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _kDefaultEmojis.map((emoji) {
              return GestureDetector(
                onTap: () => Navigator.pop(context, emoji),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
