import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat_core/chat_core.dart';

import '../../../di/injection.dart';

part 'typing_event.dart';
part 'typing_state.dart';

class TypingBloc extends Bloc<TypingEvent, TypingState> {
  TypingBloc({required this.channelId}) : super(const TypingState()) {
    on<TypingStarted>(_onTypingStarted);
    on<TypingStopped>(_onTypingStopped);
    on<TypingUsersUpdated>(_onTypingUsersUpdated);
  }

  final String channelId;
  Timer? _debounceTimer;

  Future<void> _onTypingStarted(
    TypingStarted event,
    Emitter<TypingState> emit,
  ) async {
    sl<WsClient>().send({
      'type': WsEventType.typingStart,
      'channel_id': event.channelId,
    });

    // Reset debounce — auto-stop after 3 seconds of no activity
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      add(TypingStopped(event.channelId));
    });
  }

  Future<void> _onTypingStopped(
    TypingStopped event,
    Emitter<TypingState> emit,
  ) async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    sl<WsClient>().send({
      'type': WsEventType.typingStop,
      'channel_id': event.channelId,
    });
  }

  Future<void> _onTypingUsersUpdated(
    TypingUsersUpdated event,
    Emitter<TypingState> emit,
  ) async {
    final current = List<String>.from(state.typingUsernames);
    if (event.isTyping) {
      if (!current.contains(event.username)) {
        current.add(event.username);
      }
    } else {
      current.remove(event.username);
    }
    emit(state.copyWith(typingUsernames: current));
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
