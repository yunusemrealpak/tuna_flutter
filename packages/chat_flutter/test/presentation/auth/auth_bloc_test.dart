import 'package:bloc_test/bloc_test.dart';
import 'package:chat_core/chat_core.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:chat_flutter/src/presentation/auth/bloc/auth_bloc.dart';

import 'auth_bloc_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockAuthRepo;
  late GetIt sl;

  final tUser = User(
    id: 'user-1',
    username: 'testuser',
    displayName: 'Test User',
    createdAt: DateTime(2024, 1, 1),
  );

  const tAccessToken = 'access-token';
  const tRefreshToken = 'refresh-token';

  setUp(() {
    sl = GetIt.asNewInstance();
    mockAuthRepo = MockAuthRepository();
    sl.registerSingleton<AuthRepository>(mockAuthRepo);
  });

  tearDown(() async {
    await sl.reset();
  });

  // Helper to create a bloc that uses our test GetIt instance.
  AuthBloc buildBloc() => AuthBloc.withServiceLocator(sl);

  group('AuthCheckStatusRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when user is logged in',
      build: buildBloc,
      setUp: () {
        when(mockAuthRepo.getCurrentUser())
            .thenAnswer((_) async => Right(tUser));
      },
      act: (bloc) => bloc.add(AuthCheckStatusRequested()),
      expect: () => [isA<AuthLoading>(), isA<Authenticated>()],
      verify: (_) {
        verify(mockAuthRepo.getCurrentUser()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when no user found',
      build: buildBloc,
      setUp: () {
        when(mockAuthRepo.getCurrentUser())
            .thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(AuthCheckStatusRequested()),
      expect: () => [isA<AuthLoading>(), isA<Unauthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] on failure',
      build: buildBloc,
      setUp: () {
        when(mockAuthRepo.getCurrentUser()).thenAnswer(
          (_) async => const Left(CacheFailure(message: 'No cached user')),
        );
      },
      act: (bloc) => bloc.add(AuthCheckStatusRequested()),
      expect: () => [isA<AuthLoading>(), isA<Unauthenticated>()],
    );
  });

  group('AuthLoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] on successful login',
      build: buildBloc,
      setUp: () {
        when(mockAuthRepo.login(email: anyNamed('email'), password: anyNamed('password')))
            .thenAnswer((_) async => Right((
                  user: tUser,
                  accessToken: tAccessToken,
                  refreshToken: tRefreshToken,
                )));
      },
      act: (bloc) => bloc.add(
        AuthLoginRequested(email: 'test@example.com', password: 'password123'),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<Authenticated>(),
      ],
      verify: (bloc) {
        verify(mockAuthRepo.login(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on login failure',
      build: buildBloc,
      setUp: () {
        when(mockAuthRepo.login(email: anyNamed('email'), password: anyNamed('password')))
            .thenAnswer((_) async => const Left(
                  AuthFailure(message: 'Invalid credentials', errorCode: '401'),
                ));
      },
      act: (bloc) => bloc.add(
        AuthLoginRequested(email: 'bad@example.com', password: 'wrongpass'),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );
  });

  group('AuthRegisterRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] on successful registration',
      build: buildBloc,
      setUp: () {
        when(mockAuthRepo.register(
          username: anyNamed('username'),
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
        )).thenAnswer((_) async => Right((
              user: tUser,
              accessToken: tAccessToken,
              refreshToken: tRefreshToken,
            )));
      },
      act: (bloc) => bloc.add(
        AuthRegisterRequested(
          username: 'testuser',
          email: 'test@example.com',
          password: 'password123',
        ),
      ),
      expect: () => [isA<AuthLoading>(), isA<Authenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on registration failure',
      build: buildBloc,
      setUp: () {
        when(mockAuthRepo.register(
          username: anyNamed('username'),
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
        )).thenAnswer((_) async => const Left(
              ServerFailure(message: 'Email already taken', errorCode: '409'),
            ));
      },
      act: (bloc) => bloc.add(
        AuthRegisterRequested(
          username: 'testuser',
          email: 'taken@example.com',
          password: 'password123',
        ),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthError>()],
    );
  });

  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] on logout',
      build: buildBloc,
      setUp: () {
        when(mockAuthRepo.logout())
            .thenAnswer((_) async => const Right(null));
      },
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      expect: () => [isA<AuthLoading>(), isA<Unauthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] even on logout error',
      build: buildBloc,
      setUp: () {
        when(mockAuthRepo.logout()).thenAnswer(
          (_) async => const Left(NetworkFailure(message: 'Offline')),
        );
      },
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      expect: () => [isA<AuthLoading>(), isA<Unauthenticated>()],
    );
  });

  group('Authenticated state', () {
    blocTest<AuthBloc, AuthState>(
      'Authenticated state holds the correct user',
      build: buildBloc,
      setUp: () {
        when(mockAuthRepo.getCurrentUser())
            .thenAnswer((_) async => Right(tUser));
      },
      act: (bloc) => bloc.add(AuthCheckStatusRequested()),
      expect: () => [
        isA<AuthLoading>(),
        predicate<AuthState>(
          (s) => s is Authenticated && s.user == tUser,
          'Authenticated with tUser',
        ),
      ],
    );
  });
}
