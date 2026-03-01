import '../../core/type_defs.dart';

enum PresenceStatus { online, offline }

class UserPresence {
  const UserPresence({
    required this.userId,
    required this.status,
    this.lastSeenAt,
  });

  final String userId;
  final PresenceStatus status;
  final DateTime? lastSeenAt;

  factory UserPresence.fromJson(Map<String, dynamic> json) => UserPresence(
        userId: json['user_id'] as String,
        status: (json['status'] as String) == 'online'
            ? PresenceStatus.online
            : PresenceStatus.offline,
        lastSeenAt: json['last_seen_at'] != null
            ? DateTime.parse(json['last_seen_at'] as String)
            : null,
      );
}

abstract class PresenceRepository {
  FutureEither<List<UserPresence>> getPresence(List<String> userIds);

  FutureEither<void> updatePresence(PresenceStatus status);
}
