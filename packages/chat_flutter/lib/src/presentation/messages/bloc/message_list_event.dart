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
  MessageListSendRequested({required this.channelId, required this.text});
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
