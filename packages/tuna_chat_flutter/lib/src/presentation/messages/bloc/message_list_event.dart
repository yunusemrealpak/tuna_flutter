part of 'message_list_bloc.dart';

abstract class MessageListEvent {}

class MessageListLoadRequested extends MessageListEvent {
  final String channelId;
  MessageListLoadRequested(this.channelId);
}

class MessageListLoadOlderRequested extends MessageListEvent {}

class MessageListSendRequested extends MessageListEvent {
  final String channelId;
  final String text;
  final String? parentId;
  MessageListSendRequested({
    required this.channelId,
    required this.text,
    this.parentId,
  });
}

class MessageListMessageReceived extends MessageListEvent {
  final Message message;
  MessageListMessageReceived(this.message);
}

class MessageListMessageUpdated extends MessageListEvent {
  final Message message;
  MessageListMessageUpdated(this.message);
}

class MessageListMessageDeleted extends MessageListEvent {
  final String messageId;
  MessageListMessageDeleted(this.messageId);
}

/// Dispatched when a `reaction.new` WS event arrives for this channel.
class MessageListReactionAdded extends MessageListEvent {
  final String messageId;
  final String userId;
  final String type;
  MessageListReactionAdded({
    required this.messageId,
    required this.userId,
    required this.type,
  });
}

/// Dispatched when a `reaction.deleted` WS event arrives for this channel.
class MessageListReactionRemoved extends MessageListEvent {
  final String messageId;
  final String userId;
  final String type;
  MessageListReactionRemoved({
    required this.messageId,
    required this.userId,
    required this.type,
  });
}

/// Loads thread replies for [parentId] within [channelId].
class MessageListThreadLoadRequested extends MessageListEvent {
  final String channelId;
  final String parentId;
  MessageListThreadLoadRequested({
    required this.channelId,
    required this.parentId,
  });
}

/// Marks all messages in the channel as read for the current user.
/// Also calls the backend read receipt endpoint.
class MessageListMarkAsReadRequested extends MessageListEvent {
  final String channelId;
  final String lastMessageId;
  MessageListMarkAsReadRequested({
    required this.channelId,
    required this.lastMessageId,
  });
}

/// Dispatched when a `message.read` WS event arrives — another user read
/// this channel. Updates status of the current user's sent messages to read.
class MessageListReadReceiptReceived extends MessageListEvent {
  final String channelId;
  final String userId;
  MessageListReadReceiptReceived({
    required this.channelId,
    required this.userId,
  });
}
