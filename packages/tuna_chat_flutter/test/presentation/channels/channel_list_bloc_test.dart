import 'package:bloc_test/bloc_test.dart';
import 'package:tuna_chat/tuna_chat.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:tuna_chat_flutter/src/presentation/channels/bloc/channel_list_bloc.dart';

import 'channel_list_bloc_test.mocks.dart';

@GenerateMocks([ChannelRepository])
void main() {
  late MockChannelRepository mockChannelRepo;
  late GetIt sl;

  final tNow = DateTime(2024, 6, 1);

  Channel makeChannel(String id) => Channel(
        id: id,
        type: ChannelType.group,
        name: 'Channel $id',
        createdBy: 'user-1',
        memberCount: 2,
        createdAt: tNow,
        updatedAt: tNow,
      );

  setUp(() {
    sl = GetIt.asNewInstance();
    mockChannelRepo = MockChannelRepository();
    sl.registerSingleton<ChannelRepository>(mockChannelRepo);
  });

  tearDown(() async {
    await sl.reset();
  });

  ChannelListBloc buildBloc() => ChannelListBloc.withServiceLocator(sl);

  group('ChannelListLoadRequested', () {
    final tChannels = [makeChannel('ch-1'), makeChannel('ch-2')];

    blocTest<ChannelListBloc, ChannelListState>(
      'emits [Loading, Loaded] with channels on success',
      build: buildBloc,
      setUp: () {
        when(mockChannelRepo.listChannels(
          cursor: anyNamed('cursor'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => Right((
              channels: tChannels,
              nextCursor: null,
            )));
      },
      act: (bloc) => bloc.add(ChannelListLoadRequested()),
      expect: () => [
        isA<ChannelListLoading>(),
        predicate<ChannelListState>(
          (s) =>
              s is ChannelListLoaded &&
              s.channels.length == 2 &&
              !s.hasMore,
          'Loaded with 2 channels, no more',
        ),
      ],
    );

    blocTest<ChannelListBloc, ChannelListState>(
      'emits [Loading, Error] on failure',
      build: buildBloc,
      setUp: () {
        when(mockChannelRepo.listChannels(
          cursor: anyNamed('cursor'),
          limit: anyNamed('limit'),
        )).thenAnswer(
          (_) async => const Left(NetworkFailure(message: 'Network error')),
        );
      },
      act: (bloc) => bloc.add(ChannelListLoadRequested()),
      expect: () => [
        isA<ChannelListLoading>(),
        isA<ChannelListError>(),
      ],
    );

    blocTest<ChannelListBloc, ChannelListState>(
      'emits [Loading, Loaded] with hasMore=true when nextCursor present',
      build: buildBloc,
      setUp: () {
        when(mockChannelRepo.listChannels(
          cursor: anyNamed('cursor'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => Right((
              channels: tChannels,
              nextCursor: 'cursor-abc',
            )));
      },
      act: (bloc) => bloc.add(ChannelListLoadRequested()),
      expect: () => [
        isA<ChannelListLoading>(),
        predicate<ChannelListState>(
          (s) => s is ChannelListLoaded && s.hasMore && s.nextCursor == 'cursor-abc',
          'Loaded with hasMore=true',
        ),
      ],
    );
  });

  group('ChannelListRefreshRequested', () {
    blocTest<ChannelListBloc, ChannelListState>(
      'reloads channels from first page',
      build: buildBloc,
      setUp: () {
        when(mockChannelRepo.listChannels(
          cursor: anyNamed('cursor'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => Right((
              channels: [makeChannel('ch-fresh')],
              nextCursor: null,
            )));
      },
      act: (bloc) => bloc.add(ChannelListRefreshRequested()),
      expect: () => [
        predicate<ChannelListState>(
          (s) => s is ChannelListLoaded && s.channels.length == 1,
          'Loaded with 1 refreshed channel',
        ),
      ],
    );
  });

  group('ChannelListLoadMoreRequested', () {
    final firstPage = [makeChannel('ch-1'), makeChannel('ch-2')];
    final secondPage = [makeChannel('ch-3')];

    blocTest<ChannelListBloc, ChannelListState>(
      'appends channels on load more',
      build: buildBloc,
      seed: () => ChannelListLoaded(
        channels: firstPage,
        hasMore: true,
        nextCursor: 'cursor-next',
      ),
      setUp: () {
        when(mockChannelRepo.listChannels(
          cursor: anyNamed('cursor'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => Right((
              channels: secondPage,
              nextCursor: null,
            )));
      },
      act: (bloc) => bloc.add(ChannelListLoadMoreRequested()),
      expect: () => [
        predicate<ChannelListState>(
          (s) => s is ChannelListLoaded && s.channels.length == 3 && !s.hasMore,
          'Loaded with 3 channels total, no more',
        ),
      ],
    );

    blocTest<ChannelListBloc, ChannelListState>(
      'does nothing when hasMore is false',
      build: buildBloc,
      seed: () => ChannelListLoaded(
        channels: firstPage,
        hasMore: false,
      ),
      act: (bloc) => bloc.add(ChannelListLoadMoreRequested()),
      expect: () => [],
    );
  });

  group('ChannelListChannelUpdated', () {
    final ch1 = makeChannel('ch-1');
    final ch2 = makeChannel('ch-2');
    final updatedCh1 = ch1.copyWith(name: 'Updated Channel 1');

    blocTest<ChannelListBloc, ChannelListState>(
      'updates channel in list by id',
      build: buildBloc,
      seed: () => ChannelListLoaded(
        channels: [ch1, ch2],
        hasMore: false,
      ),
      act: (bloc) => bloc.add(ChannelListChannelUpdated(updatedCh1)),
      expect: () => [
        predicate<ChannelListState>(
          (s) =>
              s is ChannelListLoaded &&
              s.channels[0].name == 'Updated Channel 1' &&
              s.channels[1].id == 'ch-2',
          'Channel 1 updated, channel 2 unchanged',
        ),
      ],
    );

    blocTest<ChannelListBloc, ChannelListState>(
      'does nothing when not in Loaded state',
      build: buildBloc,
      act: (bloc) => bloc.add(ChannelListChannelUpdated(ch1)),
      expect: () => [],
    );
  });
}
