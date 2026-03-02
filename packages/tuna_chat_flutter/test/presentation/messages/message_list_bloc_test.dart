import 'package:bloc_test/bloc_test.dart';
import 'package:tuna_chat/tuna_chat.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:tuna_chat_flutter/src/presentation/messages/bloc/message_list_bloc.dart';

import 'message_list_bloc_test.mocks.dart';

@GenerateMocks([MessageRepository])
void main() {
  late MockMessageRepository mockMessageRepo;
  late GetIt sl;

  final tNow = DateTime(2024, 6, 1, 12, 0);

  Message makeMessage(String id, {String channelId = 'ch-1'}) => Message(
        id: id,
        channelId: channelId,
        senderId: 'user-1',
        text: 'Hello from $id',
        status: MessageStatus.sent,
        createdAt: tNow,
        updatedAt: tNow,
      );

  setUp(() {
    sl = GetIt.asNewInstance();
    mockMessageRepo = MockMessageRepository();
    sl.registerSingleton<MessageRepository>(mockMessageRepo);
  });

  tearDown(() async {
    await sl.reset();
  });

  MessageListBloc buildBloc() => MessageListBloc.withServiceLocator(sl);

  group('MessageListLoadRequested', () {
    final tMessages = [makeMessage('msg-1'), makeMessage('msg-2')];

    blocTest<MessageListBloc, MessageListState>(
      'emits [Loading, Loaded] with messages on success',
      build: buildBloc,
      setUp: () {
        when(mockMessageRepo.getMessages(
          any,
          cursor: anyNamed('cursor'),
          limit: anyNamed('limit'),
          direction: anyNamed('direction'),
        )).thenAnswer((_) async => Right((
              messages: tMessages,
              nextCursor: null,
            )));
      },
      act: (bloc) => bloc.add(MessageListLoadRequested('ch-1')),
      expect: () => [
        isA<MessageListLoading>(),
        predicate<MessageListState>(
          (s) =>
              s is MessageListLoaded &&
              s.messages.length == 2 &&
              !s.hasOlder,
          'Loaded with 2 messages, no older',
        ),
      ],
    );

    blocTest<MessageListBloc, MessageListState>(
      'emits [Loading, Error] on failure',
      build: buildBloc,
      setUp: () {
        when(mockMessageRepo.getMessages(
          any,
          cursor: anyNamed('cursor'),
          limit: anyNamed('limit'),
          direction: anyNamed('direction'),
        )).thenAnswer(
          (_) async => const Left(NetworkFailure(message: 'Network error')),
        );
      },
      act: (bloc) => bloc.add(MessageListLoadRequested('ch-1')),
      expect: () => [
        isA<MessageListLoading>(),
        isA<MessageListError>(),
      ],
    );

    blocTest<MessageListBloc, MessageListState>(
      'emits [Loading, Loaded] with hasOlder=true when nextCursor present',
      build: buildBloc,
      setUp: () {
        when(mockMessageRepo.getMessages(
          any,
          cursor: anyNamed('cursor'),
          limit: anyNamed('limit'),
          direction: anyNamed('direction'),
        )).thenAnswer((_) async => Right((
              messages: tMessages,
              nextCursor: 'cursor-abc',
            )));
      },
      act: (bloc) => bloc.add(MessageListLoadRequested('ch-1')),
      expect: () => [
        isA<MessageListLoading>(),
        predicate<MessageListState>(
          (s) =>
              s is MessageListLoaded &&
              s.hasOlder &&
              s.nextCursor == 'cursor-abc',
          'Loaded with hasOlder=true',
        ),
      ],
    );
  });

  group('MessageListSendRequested', () {
    final existingMessage = makeMessage('msg-existing');
    final sentMessage = makeMessage('msg-sent');

    blocTest<MessageListBloc, MessageListState>(
      'optimistically adds message then replaces with server response',
      build: buildBloc,
      seed: () => MessageListLoaded(
        messages: [existingMessage],
        hasOlder: false,
      ),
      setUp: () {
        when(mockMessageRepo.sendMessage(
          any,
          text: anyNamed('text'),
          parentId: anyNamed('parentId'),
          idempotencyKey: anyNamed('idempotencyKey'),
        )).thenAnswer((_) async => Right(sentMessage));
      },
      act: (bloc) => bloc.add(
        MessageListSendRequested(channelId: 'ch-1', text: 'Hello!'),
      ),
      expect: () => [
        // Optimistic add (isSending: true)
        predicate<MessageListState>(
          (s) =>
              s is MessageListLoaded &&
              s.messages.length == 2 &&
              s.isSending,
          'Optimistic: 2 messages, isSending=true',
        ),
        // After server response (replace temp with real)
        predicate<MessageListState>(
          (s) =>
              s is MessageListLoaded &&
              s.messages.length == 2 &&
              !s.isSending &&
              s.messages.any((m) => m.id == 'msg-sent'),
          'After send: real message in list, isSending=false',
        ),
      ],
    );

    blocTest<MessageListBloc, MessageListState>(
      'marks message as failed on send error',
      build: buildBloc,
      seed: () => MessageListLoaded(
        messages: [existingMessage],
        hasOlder: false,
      ),
      setUp: () {
        when(mockMessageRepo.sendMessage(
          any,
          text: anyNamed('text'),
          parentId: anyNamed('parentId'),
          idempotencyKey: anyNamed('idempotencyKey'),
        )).thenAnswer(
          (_) async => const Left(NetworkFailure(message: 'Network error')),
        );
      },
      act: (bloc) => bloc.add(
        MessageListSendRequested(channelId: 'ch-1', text: 'Hello!'),
      ),
      expect: () => [
        // Optimistic add
        predicate<MessageListState>(
          (s) => s is MessageListLoaded && s.isSending,
          'Optimistic send in progress',
        ),
        // Failed
        predicate<MessageListState>(
          (s) =>
              s is MessageListLoaded &&
              !s.isSending &&
              s.messages.any((m) => m.status == MessageStatus.failed),
          'Message marked as failed',
        ),
      ],
    );
  });

  group('MessageListMessageReceived', () {
    final existingMessage = makeMessage('msg-1');
    final newMessage = makeMessage('msg-new');

    blocTest<MessageListBloc, MessageListState>(
      'appends new message to list',
      build: buildBloc,
      seed: () => MessageListLoaded(
        messages: [existingMessage],
        hasOlder: false,
      ),
      act: (bloc) => bloc.add(MessageListMessageReceived(newMessage)),
      expect: () => [
        predicate<MessageListState>(
          (s) =>
              s is MessageListLoaded &&
              s.messages.length == 2 &&
              s.messages.last.id == 'msg-new',
          'New message appended',
        ),
      ],
    );

    blocTest<MessageListBloc, MessageListState>(
      'does not add duplicate message',
      build: buildBloc,
      seed: () => MessageListLoaded(
        messages: [existingMessage],
        hasOlder: false,
      ),
      act: (bloc) => bloc.add(MessageListMessageReceived(existingMessage)),
      expect: () => [],
    );
  });

  group('MessageListMessageUpdated', () {
    final original = makeMessage('msg-1');
    final updated = original.copyWith(text: 'Updated text');

    blocTest<MessageListBloc, MessageListState>(
      'replaces message in list',
      build: buildBloc,
      seed: () => MessageListLoaded(
        messages: [original, makeMessage('msg-2')],
        hasOlder: false,
      ),
      act: (bloc) => bloc.add(MessageListMessageUpdated(updated)),
      expect: () => [
        predicate<MessageListState>(
          (s) =>
              s is MessageListLoaded &&
              s.messages.first.text == 'Updated text',
          'Message text updated',
        ),
      ],
    );
  });

  group('MessageListMessageDeleted', () {
    final msg1 = makeMessage('msg-1');
    final msg2 = makeMessage('msg-2');

    blocTest<MessageListBloc, MessageListState>(
      'removes message from list',
      build: buildBloc,
      seed: () => MessageListLoaded(
        messages: [msg1, msg2],
        hasOlder: false,
      ),
      act: (bloc) => bloc.add(MessageListMessageDeleted('msg-1')),
      expect: () => [
        predicate<MessageListState>(
          (s) =>
              s is MessageListLoaded &&
              s.messages.length == 1 &&
              s.messages.first.id == 'msg-2',
          'msg-1 removed',
        ),
      ],
    );

    blocTest<MessageListBloc, MessageListState>(
      'does nothing for non-existent message id',
      build: buildBloc,
      seed: () => MessageListLoaded(
        messages: [msg1, msg2],
        hasOlder: false,
      ),
      act: (bloc) => bloc.add(MessageListMessageDeleted('msg-nonexistent')),
      expect: () => [
        predicate<MessageListState>(
          (s) => s is MessageListLoaded && s.messages.length == 2,
          'list unchanged',
        ),
      ],
    );
  });

  group('MessageListLoadOlderRequested', () {
    final recentMessages = [makeMessage('msg-5'), makeMessage('msg-6')];
    final olderMessages = [makeMessage('msg-3'), makeMessage('msg-4')];

    blocTest<MessageListBloc, MessageListState>(
      'prepends older messages to list',
      build: buildBloc,
      seed: () => MessageListLoaded(
        messages: recentMessages,
        hasOlder: true,
        nextCursor: 'cursor-prev',
      ),
      setUp: () {
        when(mockMessageRepo.getMessages(
          any,
          cursor: anyNamed('cursor'),
          limit: anyNamed('limit'),
          direction: anyNamed('direction'),
        )).thenAnswer((_) async => Right((
              messages: olderMessages,
              nextCursor: null,
            )));
      },
      act: (bloc) => bloc.add(MessageListLoadOlderRequested()),
      expect: () => [
        predicate<MessageListState>(
          (s) =>
              s is MessageListLoaded &&
              s.messages.length == 4 &&
              s.messages.first.id == 'msg-3' &&
              !s.hasOlder,
          'Older messages prepended, hasOlder=false',
        ),
      ],
    );

    blocTest<MessageListBloc, MessageListState>(
      'does nothing when hasOlder is false',
      build: buildBloc,
      seed: () => MessageListLoaded(
        messages: recentMessages,
        hasOlder: false,
      ),
      act: (bloc) => bloc.add(MessageListLoadOlderRequested()),
      expect: () => [],
    );
  });
}
