import 'package:bloc_test/bloc_test.dart';
import 'package:tuna_chat/tuna_chat.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:tuna_chat_flutter/src/presentation/connection/bloc/connection_bloc.dart';

import 'connection_bloc_test.mocks.dart';

@GenerateMocks([ConnectionRepository])
void main() {
  late MockConnectionRepository mockConnectionRepo;
  late GetIt sl;

  final tNow = DateTime(2024, 6, 1);
  final tUser = User(
    id: '01HZZZZ',
    username: 'alice',
    displayName: 'Alice',
    createdAt: tNow,
  );

  setUp(() {
    sl = GetIt.asNewInstance();
    mockConnectionRepo = MockConnectionRepository();
    sl.registerSingleton<ConnectionRepository>(mockConnectionRepo);
  });

  tearDown(() async {
    await sl.reset();
  });

  ConnectionBloc buildBloc() => ConnectionBloc.withServiceLocator(sl);

  group('ConnectUserRequested', () {
    blocTest<ConnectionBloc, ConnectionState>(
      'emits [Connecting, Connected] on success',
      build: buildBloc,
      setUp: () {
        when(mockConnectionRepo.connectUser(
          userId: anyNamed('userId'),
          token: anyNamed('token'),
        )).thenAnswer((_) async => Right(tUser));
      },
      act: (bloc) => bloc.add(
        ConnectUserRequested(userId: 'alice', token: 'jwt-token'),
      ),
      expect: () => [
        isA<ConnectionConnecting>(),
        predicate<ConnectionState>(
          (s) => s is ConnectionConnected && s.user.id == '01HZZZZ',
          'Connected with correct user',
        ),
      ],
    );

    blocTest<ConnectionBloc, ConnectionState>(
      'emits [Connecting, Error] on failure',
      build: buildBloc,
      setUp: () {
        when(mockConnectionRepo.connectUser(
          userId: anyNamed('userId'),
          token: anyNamed('token'),
        )).thenAnswer(
          (_) async =>
              const Left(NetworkFailure(message: 'Connection failed')),
        );
      },
      act: (bloc) => bloc.add(
        ConnectUserRequested(userId: 'alice', token: 'bad-token'),
      ),
      expect: () => [
        isA<ConnectionConnecting>(),
        predicate<ConnectionState>(
          (s) => s is ConnectionError && s.message == 'Connection failed',
          'Error with correct message',
        ),
      ],
    );

    blocTest<ConnectionBloc, ConnectionState>(
      'passes userId and token to repository',
      build: buildBloc,
      setUp: () {
        when(mockConnectionRepo.connectUser(
          userId: anyNamed('userId'),
          token: anyNamed('token'),
        )).thenAnswer((_) async => Right(tUser));
      },
      act: (bloc) => bloc.add(
        ConnectUserRequested(userId: 'bob', token: 'bob-jwt'),
      ),
      verify: (_) {
        verify(mockConnectionRepo.connectUser(
          userId: 'bob',
          token: 'bob-jwt',
        )).called(1);
      },
    );
  });

  group('DisconnectUserRequested', () {
    blocTest<ConnectionBloc, ConnectionState>(
      'emits [Disconnected] after disconnect',
      build: buildBloc,
      seed: () => ConnectionConnected(tUser),
      setUp: () {
        when(mockConnectionRepo.disconnectUser())
            .thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(DisconnectUserRequested()),
      expect: () => [isA<ConnectionDisconnected>()],
    );

    blocTest<ConnectionBloc, ConnectionState>(
      'calls repository disconnectUser exactly once',
      build: buildBloc,
      seed: () => ConnectionConnected(tUser),
      setUp: () {
        when(mockConnectionRepo.disconnectUser())
            .thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(DisconnectUserRequested()),
      verify: (_) {
        verify(mockConnectionRepo.disconnectUser()).called(1);
      },
    );
  });

  group('Initial state', () {
    test('is ConnectionInitial', () {
      final bloc = buildBloc();
      expect(bloc.state, isA<ConnectionInitial>());
      bloc.close();
    });
  });
}
