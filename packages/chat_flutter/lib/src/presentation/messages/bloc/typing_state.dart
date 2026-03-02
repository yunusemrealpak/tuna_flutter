part of 'typing_bloc.dart';

class TypingState {
  // userId → username mapping; enables removal by userId even without username.
  final Map<String, String> typingUsers;

  const TypingState({this.typingUsers = const {}});

  List<String> get typingUsernames => typingUsers.values.toList();

  TypingState copyWith({Map<String, String>? typingUsers}) =>
      TypingState(typingUsers: typingUsers ?? this.typingUsers);
}
