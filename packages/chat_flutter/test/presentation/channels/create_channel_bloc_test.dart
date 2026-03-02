import 'package:bloc_test/bloc_test.dart';
import 'package:chat_core/chat_core.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:chat_flutter/src/presentation/channels/bloc/create_channel_bloc.dart';

import 'create_channel_bloc_test.mocks.dart';

@GenerateMocks([UserRepository, ChannelRepository])
void main() {
  late MockUserRepository mockUserRepo;
  late MockChannelRepository mockChannelRepo;
  late GetIt sl;

  final tNow = DateTime(2024, 6, 1);

  User makeUser(String id, {String? username}) => User(
        id: id,
        username: username ?? 'user_$id',
        displayName: 'User $id',
        createdAt: tNow,
      );

  Channel makeChannel(String id) => Channel(
        id: id,
        type: ChannelType.group,
        name: 'Channel $id',
        createdBy: 'user-1',
        memberCount: 1,
        createdAt: tNow,
        updatedAt: tNow,
      );

  setUp(() {
    sl = GetIt.asNewInstance();
    mockUserRepo = MockUserRepository();
    mockChannelRepo = MockChannelRepository();
    sl.registerSingleton<UserRepository>(mockUserRepo);
    sl.registerSingleton<ChannelRepository>(mockChannelRepo);
  });

  tearDown(() async {
    await sl.reset();
  });

  CreateChannelBloc buildBloc() => CreateChannelBloc.withServiceLocator(sl);

  // ---------------------------------------------------------------------------
  // CreateChannelSearchUsers
  // ---------------------------------------------------------------------------
  group('CreateChannelSearchUsers', () {
    final tUsers = [makeUser('u1'), makeUser('u2')];

    blocTest<CreateChannelBloc, CreateChannelState>(
      'emits searchResults on success',
      build: buildBloc,
      setUp: () {
        when(mockUserRepo.searchUsers(any))
            .thenAnswer((_) async => Right(tUsers));
      },
      act: (bloc) => bloc.add(CreateChannelSearchUsers('alice')),
      expect: () => [
        predicate<CreateChannelState>(
          (s) => s.isSearching && s.searchResults.isEmpty,
          'isSearching=true',
        ),
        predicate<CreateChannelState>(
          (s) => !s.isSearching && s.searchResults.length == 2,
          'Results with 2 users',
        ),
      ],
    );

    blocTest<CreateChannelBloc, CreateChannelState>(
      'emits error on failure',
      build: buildBloc,
      setUp: () {
        when(mockUserRepo.searchUsers(any)).thenAnswer(
          (_) async => const Left(NetworkFailure(message: 'No internet')),
        );
      },
      act: (bloc) => bloc.add(CreateChannelSearchUsers('bob')),
      expect: () => [
        predicate<CreateChannelState>((s) => s.isSearching, 'isSearching=true'),
        predicate<CreateChannelState>(
          (s) => !s.isSearching && s.error == 'No internet',
          'error set',
        ),
      ],
    );

    blocTest<CreateChannelBloc, CreateChannelState>(
      'emits empty results for blank query without calling repository',
      build: buildBloc,
      act: (bloc) => bloc.add(CreateChannelSearchUsers('  ')),
      expect: () => [
        predicate<CreateChannelState>(
          (s) => s.searchResults.isEmpty && s.error == null,
          'empty results, no error',
        ),
      ],
      verify: (_) => verifyNever(mockUserRepo.searchUsers(any)),
    );
  });

  // ---------------------------------------------------------------------------
  // CreateChannelToggleMember
  // ---------------------------------------------------------------------------
  group('CreateChannelToggleMember', () {
    final user1 = makeUser('u1');
    final user2 = makeUser('u2');

    blocTest<CreateChannelBloc, CreateChannelState>(
      'adds user to selectedMembers',
      build: buildBloc,
      act: (bloc) => bloc.add(CreateChannelToggleMember(user1)),
      expect: () => [
        predicate<CreateChannelState>(
          (s) => s.selectedMembers.length == 1 && s.selectedMembers.first == user1,
          'user1 selected',
        ),
      ],
    );

    blocTest<CreateChannelBloc, CreateChannelState>(
      'removes already-selected user',
      build: buildBloc,
      seed: () => CreateChannelState(selectedMembers: [user1, user2]),
      act: (bloc) => bloc.add(CreateChannelToggleMember(user1)),
      expect: () => [
        predicate<CreateChannelState>(
          (s) =>
              s.selectedMembers.length == 1 &&
              s.selectedMembers.first.id == 'u2',
          'only user2 remains',
        ),
      ],
    );

    blocTest<CreateChannelBloc, CreateChannelState>(
      'toggle same user twice returns to empty list',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(CreateChannelToggleMember(user1))
        ..add(CreateChannelToggleMember(user1)),
      expect: () => [
        predicate<CreateChannelState>(
          (s) => s.selectedMembers.length == 1,
          'user1 added',
        ),
        predicate<CreateChannelState>(
          (s) => s.selectedMembers.isEmpty,
          'user1 removed',
        ),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // CreateChannelSubmitted
  // ---------------------------------------------------------------------------
  group('CreateChannelSubmitted', () {
    final tChannel = makeChannel('ch-new');
    final selectedUser = makeUser('u1');

    blocTest<CreateChannelBloc, CreateChannelState>(
      'emits createdChannel on success',
      build: buildBloc,
      seed: () => CreateChannelState(selectedMembers: [selectedUser]),
      setUp: () {
        when(mockChannelRepo.createChannel(
          type: anyNamed('type'),
          name: anyNamed('name'),
          description: anyNamed('description'),
          memberIds: anyNamed('memberIds'),
        )).thenAnswer((_) async => Right(tChannel));
      },
      act: (bloc) => bloc.add(
        CreateChannelSubmitted(type: ChannelType.group, name: 'Dev Chat'),
      ),
      expect: () => [
        predicate<CreateChannelState>((s) => s.isSubmitting, 'isSubmitting'),
        predicate<CreateChannelState>(
          (s) => !s.isSubmitting && s.createdChannel?.id == 'ch-new',
          'channel created',
        ),
      ],
      verify: (_) {
        verify(mockChannelRepo.createChannel(
          type: ChannelType.group,
          name: 'Dev Chat',
          description: null,
          memberIds: ['u1'],
        )).called(1);
      },
    );

    blocTest<CreateChannelBloc, CreateChannelState>(
      'emits error on failure',
      build: buildBloc,
      setUp: () {
        when(mockChannelRepo.createChannel(
          type: anyNamed('type'),
          name: anyNamed('name'),
          description: anyNamed('description'),
          memberIds: anyNamed('memberIds'),
        )).thenAnswer(
          (_) async =>
              const Left(ServerFailure(message: 'Server error', errorCode: 'ERR')),
        );
      },
      act: (bloc) => bloc.add(
        CreateChannelSubmitted(type: ChannelType.group, name: 'Bad Channel'),
      ),
      expect: () => [
        predicate<CreateChannelState>((s) => s.isSubmitting, 'isSubmitting'),
        predicate<CreateChannelState>(
          (s) => !s.isSubmitting && s.error == 'Server error',
          'error set',
        ),
      ],
    );

    blocTest<CreateChannelBloc, CreateChannelState>(
      'passes correct memberIds from selectedMembers',
      build: buildBloc,
      seed: () => CreateChannelState(
        selectedMembers: [makeUser('u1'), makeUser('u2'), makeUser('u3')],
      ),
      setUp: () {
        when(mockChannelRepo.createChannel(
          type: anyNamed('type'),
          name: anyNamed('name'),
          description: anyNamed('description'),
          memberIds: anyNamed('memberIds'),
        )).thenAnswer((_) async => Right(tChannel));
      },
      act: (bloc) => bloc.add(
        CreateChannelSubmitted(type: ChannelType.public, name: 'Big Group'),
      ),
      verify: (_) {
        // captured order: [type, name, description, memberIds]
        final captured = verify(mockChannelRepo.createChannel(
          type: captureAnyNamed('type'),
          name: captureAnyNamed('name'),
          description: captureAnyNamed('description'),
          memberIds: captureAnyNamed('memberIds'),
        )).captured;
        expect(captured[3] as List, containsAll(['u1', 'u2', 'u3']));
      },
    );
  });
}
