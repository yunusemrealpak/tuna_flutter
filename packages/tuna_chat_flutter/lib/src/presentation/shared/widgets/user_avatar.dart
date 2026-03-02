import 'package:cached_network_image/cached_network_image.dart';
import 'package:tuna_chat/tuna_chat.dart';
import 'package:flutter/material.dart';

import 'presence_indicator.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.user,
    this.size = 40.0,
    this.showPresence = true,
    this.isOnline = false,
  });

  final User user;
  final double size;
  final bool showPresence;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : user.username[0].toUpperCase();

    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: user.avatarUrl != null
          ? CachedNetworkImageProvider(user.avatarUrl!)
          : null,
      child: user.avatarUrl == null
          ? Text(
              initial,
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );

    if (!showPresence) {
      return avatar;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: PresenceIndicator(isOnline: isOnline),
        ),
      ],
    );
  }
}
