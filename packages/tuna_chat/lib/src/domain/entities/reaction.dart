import 'package:equatable/equatable.dart';

/// An emoji reaction on a [Message].
///
/// Each user can add at most one reaction of each [type] to a given message.
/// Reactions are broadcast in real time via [WsEventType.reactionNew] and
/// [WsEventType.reactionDeleted] WebSocket events.
class Reaction extends Equatable {
  const Reaction({
    required this.id,
    required this.messageId,
    required this.channelId,
    required this.userId,
    required this.type,
    required this.createdAt,
  });

  /// Internal ULID of this reaction.
  final String id;

  /// ID of the message this reaction belongs to.
  final String messageId;

  /// ID of the channel containing the message.
  final String channelId;

  /// ID of the user who added this reaction.
  final String userId;

  /// The reaction type string, e.g. `'like'`, `'👍'`, `'heart'`.
  final String type;

  /// When this reaction was created.
  final DateTime createdAt;

  @override
  List<Object> get props => [id, messageId, channelId, userId, type, createdAt];

  /// Deserializes a [Reaction] from the TunaChat API JSON response.
  factory Reaction.fromJson(Map<String, dynamic> json) => Reaction(
        id: json['id'] as String,
        messageId: json['message_id'] as String,
        channelId: json['channel_id'] as String,
        userId: json['user_id'] as String,
        type: json['type'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  /// Serializes this reaction to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'message_id': messageId,
        'channel_id': channelId,
        'user_id': userId,
        'type': type,
        'created_at': createdAt.toIso8601String(),
      };
}
