part of 'typing_bloc.dart';

abstract class TypingEvent {}

class TypingStarted extends TypingEvent {
  final String channelId;
  TypingStarted(this.channelId);
}

class TypingStopped extends TypingEvent {
  final String channelId;
  TypingStopped(this.channelId);
}

class TypingUsersUpdated extends TypingEvent {
  final String channelId;
  final String userId;
  // username is present in typing_start events but absent in typing_stop.
  final String? username;
  final bool isTyping;

  TypingUsersUpdated({
    required this.channelId,
    required this.userId,
    this.username,
    required this.isTyping,
  });
}
