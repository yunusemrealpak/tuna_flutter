import 'package:bloc/bloc.dart';
import 'package:chat_core/chat_core.dart';

import '../../../di/injection.dart';

part 'message_list_event.dart';
part 'message_list_state.dart';

class MessageListBloc extends Bloc<MessageListEvent, MessageListState> {
  /// Creates a [MessageListBloc] using the global [sl] service locator.
  MessageListBloc() : this.withServiceLocator(sl);

  /// Creates a [MessageListBloc] with a custom [GetIt] instance.
  /// Useful for testing.
  MessageListBloc.withServiceLocator(this._sl) : super(MessageListInitial()) {
    on<MessageListLoadRequested>(_onLoad);
    on<MessageListLoadOlderRequested>(_onLoadOlder);
    on<MessageListSendRequested>(_onSend);
    on<MessageListMessageReceived>(_onMessageReceived);
    on<MessageListMessageUpdated>(_onMessageUpdated);
    on<MessageListMessageDeleted>(_onMessageDeleted);
  }

  final GetIt _sl;
  static const int _pageSize = 50;

  Future<void> _onLoad(
    MessageListLoadRequested event,
    Emitter<MessageListState> emit,
  ) async {
    emit(MessageListLoading());
    final result = await _sl<MessageRepository>().getMessages(
      event.channelId,
      limit: _pageSize,
      direction: 'before',
    );
    result.fold(
      (failure) => emit(MessageListError(failure.message)),
      (data) => emit(MessageListLoaded(
        messages: data.messages,
        hasOlder: data.nextCursor != null,
        nextCursor: data.nextCursor,
      )),
    );
  }

  Future<void> _onLoadOlder(
    MessageListLoadOlderRequested event,
    Emitter<MessageListState> emit,
  ) async {
    final current = state;
    if (current is! MessageListLoaded || !current.hasOlder) return;

    final cursor = current.nextCursor ??
        (current.messages.isNotEmpty ? current.messages.first.id : null);
    if (cursor == null) return;

    if (current.messages.isEmpty) return;
    final channelId = current.messages.first.channelId;

    final result = await _sl<MessageRepository>().getMessages(
      channelId,
      cursor: cursor,
      limit: _pageSize,
      direction: 'before',
    );
    result.fold(
      (failure) => emit(MessageListError(failure.message)),
      (data) => emit(current.copyWith(
        messages: [...data.messages, ...current.messages],
        hasOlder: data.nextCursor != null,
        nextCursor: data.nextCursor,
      )),
    );
  }

  Future<void> _onSend(
    MessageListSendRequested event,
    Emitter<MessageListState> emit,
  ) async {
    final current = state;
    if (current is! MessageListLoaded) return;

    final tempId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toUtc();
    final optimisticMessage = Message(
      id: tempId,
      channelId: event.channelId,
      senderId: 'me',
      text: event.text,
      status: MessageStatus.sending,
      createdAt: now,
      updatedAt: now,
    );

    emit(current.copyWith(
      messages: [...current.messages, optimisticMessage],
      isSending: true,
    ));

    final result = await _sl<MessageRepository>().sendMessage(
      event.channelId,
      text: event.text,
      idempotencyKey: tempId,
    );

    final stateAfterSend = state;
    if (stateAfterSend is! MessageListLoaded) return;

    result.fold(
      (failure) {
        final updatedMessages = stateAfterSend.messages.map((m) {
          if (m.id == tempId) {
            return m.copyWith(status: MessageStatus.failed);
          }
          return m;
        }).toList();
        emit(stateAfterSend.copyWith(
          messages: updatedMessages,
          isSending: false,
        ));
      },
      (sentMessage) {
        final updatedMessages = stateAfterSend.messages.map((m) {
          if (m.id == tempId) return sentMessage;
          return m;
        }).toList();
        emit(stateAfterSend.copyWith(
          messages: updatedMessages,
          isSending: false,
        ));
      },
    );
  }

  Future<void> _onMessageReceived(
    MessageListMessageReceived event,
    Emitter<MessageListState> emit,
  ) async {
    final current = state;
    if (current is! MessageListLoaded) return;

    final exists = current.messages.any((m) => m.id == event.message.id);
    if (exists) return;

    emit(current.copyWith(
      messages: [...current.messages, event.message],
    ));
  }

  Future<void> _onMessageUpdated(
    MessageListMessageUpdated event,
    Emitter<MessageListState> emit,
  ) async {
    final current = state;
    if (current is! MessageListLoaded) return;

    final updatedMessages = current.messages.map((m) {
      return m.id == event.message.id ? event.message : m;
    }).toList();

    emit(current.copyWith(messages: updatedMessages));
  }

  Future<void> _onMessageDeleted(
    MessageListMessageDeleted event,
    Emitter<MessageListState> emit,
  ) async {
    final current = state;
    if (current is! MessageListLoaded) return;

    final updatedMessages =
        current.messages.where((m) => m.id != event.messageId).toList();

    emit(current.copyWith(messages: updatedMessages));
  }
}
