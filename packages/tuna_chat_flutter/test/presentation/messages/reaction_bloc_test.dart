import 'package:bloc_test/bloc_test.dart';
import 'package:tuna_chat/tuna_chat.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:tuna_chat_flutter/src/presentation/messages/bloc/message_list_bloc.dart';

import 'message_list_bloc_test.mocks.dart';
import 'reaction_bloc_test.mocks.dart';

@GenerateMocks([ChannelRepository, ReactionRepository])
void main() {
  late MockMessageRepository mockMessageRepo;
  late MockChannelRepository mockChannelRepo;
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
    mockChannelRepo = MockChannelRepository();
    sl.registerSingleton<MessageRepository>(mockMessageRepo);
    sl.registerSingleton<ChannelRepository>(mockChannelRepo);
  });

  tearDown(() async {
    await sl.reset();
  });

  MessageListBloc buildBloc() => MessageListBloc.withServiceLocator(sl);

  // ── Reaction events ────────────────────────────────────────────────────

  group('MessageListReactionAdded', () {
    final msg = makeMessage('msg-1');

    blocTest<MessageListBloc, MessageListState>(
      'adds reaction to state',
      build: buildBloc,
      seed: () => MessageListLoaded(messages: [msg], hasOlder: false),
      act: (bloc) => bloc.add(MessageListReactionAdded(
        messageId: 'msg-1',
        userId: 'user-2',
        type: '👍',
      )),
      expect: () => [
        predicate<MessageListState>(
          (s) =>
              s is MessageListLoaded &&
              (s.reactions['msg-1']?.length ?? 0) == 1 &&
              s.reactions['msg-1']!.first.type == '👍',
          'reaction added',
        ),
      ],
    );

    blocTest<MessageListBloc, MessageListState>(
      'ignores duplicate (same userId + type)',
      build: buildBloc,
      seed: () => MessageListLoaded(
        messages: [msg],
        hasOlder: false,
        reactions: {
          'msg-1': [
            Reaction(
              id: 'r1',
              messageId: 'msg-1',
              channelId: 'ch-1',
              userId: 'user-2',
              type: '👍',
              createdAt: tNow,
            )
          ],
        },
      ),
      act: (bloc) => bloc.add(MessageListReactionAdded(
        messageId: 'msg-1',
        userId: 'user-2',
        type: '👍',
      )),
      expect: () => [],
    );

    blocTest<MessageListBloc, MessageListState>(
      'allows same type from different user',
      build: buildBloc,
      seed: () => MessageListLoaded(
        messages: [msg],
        hasOlder: false,
        reactions: {
          'msg-1': [
            Reaction(
              id: 'r1',
              messageId: 'msg-1',
              channelId: 'ch-1',
              userId: 'user-2',
              type: '👍',
              createdAt: tNow,
            )
          ],
        },
      ),
      act: (bloc) => bloc.add(MessageListReactionAdded(
        messageId: 'msg-1',
        userId: 'user-3',
        type: '👍',
      )),
      expect: () => [
        predicate<MessageListState>(
          (s) =>
              s is MessageListLoaded &&
              (s.reactions['msg-1']?.length ?? 0) == 2,
          'two reactions from different users',
        ),
      ],
    );
  });

  group('MessageListReactionRemoved', () {
    final msg = makeMessage('msg-1');

    blocTest<MessageListBloc, MessageListState>(
      'removes reaction from state',
      build: buildBloc,
      seed: () => MessageListLoaded(
        messages: [msg],
        hasOlder: false,
        reactions: {
          'msg-1': [
            Reaction(
              id: 'r1',
              messageId: 'msg-1',
              channelId: 'ch-1',
              userId: 'user-2',
              type: '👍',
              createdAt: tNow,
            )
          ],
        },
      ),
      act: (bloc) => bloc.add(MessageListReactionRemoved(
        messageId: 'msg-1',
        userId: 'user-2',
        type: '👍',
      )),
      expect: () => [
        predicate<MessageListState>(
          (s) =>
              s is MessageListLoaded &&
              (s.reactions['msg-1']?.isEmpty ?? true),
          'reaction removed',
        ),
      ],
    );

    blocTest<MessageListBloc, MessageListState>(
      'does nothing when reaction not found',
      build: buildBloc,
      seed: () => MessageListLoaded(messages: [msg], hasOlder: false),
      act: (bloc) => bloc.add(MessageListReactionRemoved(
        messageId: 'msg-1',
        userId: 'user-2',
        type: '👍',
      )),
      expect: () => [
        predicate<MessageListState>(
          (s) =>
              s is MessageListLoaded &&
              (s.reactions['msg-1']?.isEmpty ?? true),
          'no change',
        ),
      ],
    );
  });

  // ── Read receipts ──────────────────────────────────────────────────────

  group('MessageListMarkAsReadRequested', () {
    final msg = makeMessage('msg-1');

    blocTest<MessageListBloc, MessageListState>(
      'calls markAsRead on ChannelRepository',
      build: buildBloc,
      seed: () =>
          MessageListLoaded(messages: [msg], hasOlder: false),
      setUp: () {
        when(mockChannelRepo.markAsRead(any, any))
            .thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(MessageListMarkAsReadRequested(
        channelId: 'ch-1',
        lastMessageId: 'msg-1',
      )),
      verify: (_) {
        verify(mockChannelRepo.markAsRead('ch-1', 'msg-1')).called(1);
      },
      expect: () => [],
    );
  });

  group('MessageListReadReceiptReceived', () {
    final sentMsg = makeMessage('msg-1');

    blocTest<MessageListBloc, MessageListState>(
      'marks sent messages as read',
      build: buildBloc,
      seed: () => MessageListLoaded(messages: [sentMsg], hasOlder: false),
      act: (bloc) => bloc.add(MessageListReadReceiptReceived(
        channelId: 'ch-1',
        userId: 'user-2',
      )),
      expect: () => [
        predicate<MessageListState>(
          (s) =>
              s is MessageListLoaded &&
              s.messages.first.status == MessageStatus.read,
          'message marked read',
        ),
      ],
    );

    blocTest<MessageListBloc, MessageListState>(
      'does not affect sending/failed messages',
      build: buildBloc,
      seed: () => MessageListLoaded(
        messages: [
          sentMsg.copyWith(status: MessageStatus.sending),
          sentMsg.copyWith(id: 'msg-2', status: MessageStatus.failed),
        ],
        hasOlder: false,
      ),
      act: (bloc) => bloc.add(MessageListReadReceiptReceived(
        channelId: 'ch-1',
        userId: 'user-2',
      )),
      expect: () => [
        predicate<MessageListState>(
          (s) =>
              s is MessageListLoaded &&
              s.messages[0].status == MessageStatus.sending &&
              s.messages[1].status == MessageStatus.failed,
          'sending/failed unchanged',
        ),
      ],
    );
  });
}
