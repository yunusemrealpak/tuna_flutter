import 'package:tuna_chat/tuna_chat.dart';
import 'package:flutter/material.dart';

/// Displays a row of reaction chips grouped by type.
/// Each chip shows the emoji/type and count. Tapping a chip toggles the
/// reaction for [currentUserId].
class ReactionBar extends StatelessWidget {
  const ReactionBar({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.onAdd,
    required this.onRemove,
  });

  final List<Reaction> reactions;
  final String? currentUserId;
  final void Function(String type) onAdd;
  final void Function(String type) onRemove;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    // Group reactions by type.
    final grouped = <String, List<Reaction>>{};
    for (final r in reactions) {
      grouped.putIfAbsent(r.type, () => []).add(r);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: grouped.entries.map((entry) {
          final type = entry.key;
          final group = entry.value;
          final iMeReacted =
              currentUserId != null &&
              group.any((r) => r.userId == currentUserId);

          return GestureDetector(
            onTap: () => iMeReacted ? onRemove(type) : onAdd(type),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: iMeReacted
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: iMeReacted
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      )
                    : null,
              ),
              child: Text(
                '${entry.key} ${group.length}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
