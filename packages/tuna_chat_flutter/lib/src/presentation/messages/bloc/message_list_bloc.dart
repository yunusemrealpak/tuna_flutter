import 'package:bloc/bloc.dart';
import 'package:tuna_chat/tuna_chat.dart';

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
    on<MessageListThreadLoadRequested>(_onThreadLoad);
    on<MessageListReactionAdded>(_onReactionAdded);
    on<MessageListReactionRemoved>(_onReactionRemoved);
    on<MessageListMarkAsReadRequested>(_onMarkAsRead);
    on<MessageListReadReceiptReceived>(_onReadReceiptReceived);
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

    // ── T111: Upload attachment first (if any) ─────────────────────────────
    List<Attachment>? attachments;
    if (event.fileBytes != null && event.fileName != null) {
      final uploadResult = await _sl<MessageRepository>().uploadFile(
        event.channelId,
        event.fileBytes!,
        event.fileName!,
      );
      uploadResult.fold(
        (failure) {
          // Upload failed — mark message as failed immediately.
          final stateNow = state;
          if (stateNow is MessageListLoaded) {
            final updated = stateNow.messages.map((m) {
              if (m.id == tempId) return m.copyWith(status: MessageStatus.failed);
              return m;
            }).toList();
            emit(stateNow.copyWith(messages: updated, isSending: false));
          }
          return;
        },
        (attachment) => attachments = [attachment],
      );
      // If upload failed we already emitted; bail out.
      if (attachments == null && event.fileBytes != null) return;
    }

    final result = await _sl<MessageRepository>().sendMessage(
      event.channelId,
      text: event.text,
      parentId: event.parentId,
      idempotencyKey: tempId,
      attachments: attachments,
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

  Future<void> _onThreadLoad(
    MessageListThreadLoadRequested event,
    Emitter<MessageListState> emit,
  ) async {
    emit(MessageListLoading());
    final result = await _sl<MessageRepository>().getThreadMessages(
      event.channelId,
      event.parentId,
      limit: _pageSize,
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

  Future<void> _onReactionAdded(
    MessageListReactionAdded event,
    Emitter<MessageListState> emit,
  ) async {
    final current = state;
    if (current is! MessageListLoaded) return;

    final updated = Map<String, List<Reaction>>.from(current.reactions);
    final existing = List<Reaction>.from(updated[event.messageId] ?? []);

    // Deduplicate by (userId, type) — same user can't add same reaction twice.
    final alreadyExists = existing.any(
      (r) => r.userId == event.userId && r.type == event.type,
    );
    if (alreadyExists) return;

    existing.add(Reaction(
      id: '${event.messageId}_${event.userId}_${event.type}',
      messageId: event.messageId,
      channelId: '',
      userId: event.userId,
      type: event.type,
      createdAt: DateTime.now().toUtc(),
    ));
    updated[event.messageId] = existing;
    emit(current.copyWith(reactions: updated));
  }

  Future<void> _onReactionRemoved(
    MessageListReactionRemoved event,
    Emitter<MessageListState> emit,
  ) async {
    final current = state;
    if (current is! MessageListLoaded) return;

    final updated = Map<String, List<Reaction>>.from(current.reactions);
    final existing = List<Reaction>.from(updated[event.messageId] ?? []);
    existing.removeWhere(
      (r) => r.userId == event.userId && r.type == event.type,
    );
    updated[event.messageId] = existing;
    emit(current.copyWith(reactions: updated));
  }

  Future<void> _onMarkAsRead(
    MessageListMarkAsReadRequested event,
    Emitter<MessageListState> emit,
  ) async {
    // Fire-and-forget — don't update UI state on completion.
    // Errors are silently ignored to avoid disrupting the message stream.
    try {
      await _sl<ChannelRepository>().markAsRead(
        event.channelId,
        event.lastMessageId,
      );
    } catch (_) {}
  }

  Future<void> _onReadReceiptReceived(
    MessageListReadReceiptReceived event,
    Emitter<MessageListState> emit,
  ) async {
    final current = state;
    if (current is! MessageListLoaded) return;

    // Mark sent messages as read only up to event.messageId.
    // ULIDs are lexicographically sortable by creation time, so string
    // comparison correctly identifies messages that were sent before or at
    // the point the other user read up to.
    final updated = current.messages.map((m) {
      if (!m.id.startsWith('tmp_') &&
          m.status == MessageStatus.sent &&
          m.id.compareTo(event.messageId) <= 0) {
        return m.copyWith(status: MessageStatus.read);
      }
      return m;
    }).toList();
    emit(current.copyWith(messages: updated));
  }
}
