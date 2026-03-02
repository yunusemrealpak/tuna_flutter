import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat_core/chat_core.dart';

import '../../../di/injection.dart';

part 'typing_event.dart';
part 'typing_state.dart';

class TypingBloc extends Bloc<TypingEvent, TypingState> {
  /// Creates a [TypingBloc] using the global service locator.
  TypingBloc({required String channelId})
      : this.withDependencies(channelId: channelId, wsClient: sl<WsClient>());

  /// Creates a [TypingBloc] with an explicit [WsClient]. Useful for testing.
  TypingBloc.withDependencies({
    required this.channelId,
    required WsClient wsClient,
  })  : _wsClient = wsClient,
        super(const TypingState()) {
    on<TypingStarted>(_onTypingStarted);
    on<TypingStopped>(_onTypingStopped);
    on<TypingUsersUpdated>(_onTypingUsersUpdated);
  }

  final String channelId;
  final WsClient _wsClient;
  Timer? _debounceTimer;

  Future<void> _onTypingStarted(
    TypingStarted event,
    Emitter<TypingState> emit,
  ) async {
    _wsClient.send({
      'type': WsEventType.typingStart,
      'channel_id': event.channelId,
    });

    // Reset debounce — auto-stop after 3 seconds of no activity.
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
    _wsClient.send({
      'type': WsEventType.typingStop,
      'channel_id': event.channelId,
    });
  }

  Future<void> _onTypingUsersUpdated(
    TypingUsersUpdated event,
    Emitter<TypingState> emit,
  ) async {
    final current = Map<String, String>.from(state.typingUsers);
    if (event.isTyping) {
      // Only add if we have a username to display.
      if (event.username != null) {
        current[event.userId] = event.username!;
      }
    } else {
      // Remove by userId — no username needed for removal.
      current.remove(event.userId);
    }
    emit(state.copyWith(typingUsers: current));
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
