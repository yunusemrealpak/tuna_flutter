part of 'message_list_bloc.dart';

abstract class MessageListState {}

class MessageListInitial extends MessageListState {}

class MessageListLoading extends MessageListState {}

class MessageListLoaded extends MessageListState {
  final List<Message> messages;
  final bool hasOlder;
  final String? nextCursor;
  final bool isSending;

  MessageListLoaded({
    required this.messages,
    required this.hasOlder,
    this.nextCursor,
    this.isSending = false,
  });

  MessageListLoaded copyWith({
    List<Message>? messages,
    bool? hasOlder,
    String? nextCursor,
    bool? isSending,
  }) =>
      MessageListLoaded(
        messages: messages ?? this.messages,
        hasOlder: hasOlder ?? this.hasOlder,
        nextCursor: nextCursor ?? this.nextCursor,
        isSending: isSending ?? this.isSending,
      );
}

class MessageListError extends MessageListState {
  final String message;
  MessageListError(this.message);
}
