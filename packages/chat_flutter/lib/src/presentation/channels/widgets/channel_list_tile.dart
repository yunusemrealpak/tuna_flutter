import 'package:chat_core/chat_core.dart';
import 'package:flutter/material.dart';

class ChannelListTile extends StatelessWidget {
  const ChannelListTile({
    super.key,
    required this.channel,
    required this.onTap,
  });

  final Channel channel;
  final VoidCallback onTap;

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.month}/${dateTime.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = channel.name.isNotEmpty
        ? channel.name[0].toUpperCase()
        : '?';
    final lastMessage = channel.lastMessage;
    final hasUnread = channel.unreadCount > 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          initial,
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              channel.name,
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (lastMessage != null)
            Text(
              _formatTimestamp(lastMessage.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: hasUnread
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
        ],
      ),
      subtitle: lastMessage != null
          ? Text(
              lastMessage.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                color: hasUnread
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.outline,
              ),
            )
          : const Text(
              'No messages yet',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
      trailing: hasUnread
          ? Container(
              constraints: const BoxConstraints(minWidth: 20),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                channel.unreadCount > 99 ? '99+' : '${channel.unreadCount}',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
