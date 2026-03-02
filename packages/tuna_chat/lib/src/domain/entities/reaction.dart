import 'package:equatable/equatable.dart';

class Reaction extends Equatable {
  const Reaction({
    required this.id,
    required this.messageId,
    required this.channelId,
    required this.userId,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String messageId;
  final String channelId;
  final String userId;

  /// The reaction type string, e.g. 'like', '👍', 'heart'.
  final String type;
  final DateTime createdAt;

  @override
  List<Object> get props => [id, messageId, channelId, userId, type, createdAt];

  factory Reaction.fromJson(Map<String, dynamic> json) => Reaction(
        id: json['id'] as String,
        messageId: json['message_id'] as String,
        channelId: json['channel_id'] as String,
        userId: json['user_id'] as String,
        type: json['type'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'message_id': messageId,
        'channel_id': channelId,
        'user_id': userId,
        'type': type,
        'created_at': createdAt.toIso8601String(),
      };
}
