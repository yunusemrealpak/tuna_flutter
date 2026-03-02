part of 'message_list_bloc.dart';

abstract class MessageListState {}

class MessageListInitial extends MessageListState {}

class MessageListLoading extends MessageListState {}

class MessageListLoaded extends MessageListState {
  final List<Message> messages;
  final bool hasOlder;
  final String? nextCursor;
  final bool isSending;

  /// Reactions keyed by messageId. Each entry is a list of [Reaction] objects
  /// accumulated from WS events since the channel was opened.
  final Map<String, List<Reaction>> reactions;

  MessageListLoaded({
    required this.messages,
    required this.hasOlder,
    this.nextCursor,
    this.isSending = false,
    Map<String, List<Reaction>>? reactions,
  }) : reactions = reactions ?? const {};

  MessageListLoaded copyWith({
    List<Message>? messages,
    bool? hasOlder,
    String? nextCursor,
    bool? isSending,
    Map<String, List<Reaction>>? reactions,
  }) =>
      MessageListLoaded(
        messages: messages ?? this.messages,
        hasOlder: hasOlder ?? this.hasOlder,
        nextCursor: nextCursor ?? this.nextCursor,
        isSending: isSending ?? this.isSending,
        reactions: reactions ?? this.reactions,
      );
}

class MessageListError extends MessageListState {
  final String message;
  MessageListError(this.message);
}
