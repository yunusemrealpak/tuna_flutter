part of 'typing_bloc.dart';

class TypingState {
  final List<String> typingUsernames;

  const TypingState({this.typingUsernames = const []});

  TypingState copyWith({List<String>? typingUsernames}) =>
      TypingState(typingUsernames: typingUsernames ?? this.typingUsernames);
}
