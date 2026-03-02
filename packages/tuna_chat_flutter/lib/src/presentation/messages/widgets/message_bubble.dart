import 'package:tuna_chat/tuna_chat.dart';
import 'package:flutter/material.dart';

import 'reaction_bar.dart';
import 'reaction_picker.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.senderName,
    this.reactions = const [],
    this.currentUserId,
    this.onReplyTap,
    this.onReactionAdd,
    this.onReactionRemove,
  });

  final Message message;
  final bool isMe;
  final String? senderName;
  final List<Reaction> reactions;
  final String? currentUserId;

  /// Called when the user taps the thread reply count link. Null hides the
  /// thread link (used for replies inside a thread page).
  final VoidCallback? onReplyTap;

  final void Function(String type)? onReactionAdd;
  final void Function(String type)? onReactionRemove;

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const Icon(Icons.access_time, size: 12, color: Colors.grey);
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 12, color: Colors.grey);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 12, color: Colors.grey);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 12, color: Colors.blue);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 12, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bubbleColor = isMe
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMe
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    final metaColor = isMe
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
        : theme.colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) const SizedBox(width: 4),
          Flexible(
            child: GestureDetector(
              onLongPress: () async {
                if (onReactionAdd == null) return;
                final picked = await showReactionPicker(context);
                if (picked != null) {
                  onReactionAdd!(picked);
                }
              },
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe && senderName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              senderName!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        Text(
                          message.isDeleted ? '[Deleted]' : message.text,
                          style: TextStyle(
                            color: textColor,
                            fontStyle: message.isDeleted
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(message.createdAt.toLocal()),
                              style:
                                  TextStyle(fontSize: 10, color: metaColor),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              _buildStatusIcon(message.status),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // ── Reaction bar ──────────────────────────────────────
                  if (reactions.isNotEmpty && onReactionAdd != null)
                    ReactionBar(
                      reactions: reactions,
                      currentUserId: currentUserId,
                      onAdd: onReactionAdd!,
                      onRemove: onReactionRemove ?? (_) {},
                    ),
                  // ── Thread reply count ────────────────────────────────
                  if (message.replyCount > 0 && onReplyTap != null)
                    GestureDetector(
                      onTap: onReplyTap,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(top: 4, left: 4, right: 4),
                        child: Text(
                          '${message.replyCount} '
                          '${message.replyCount == 1 ? 'reply' : 'replies'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
