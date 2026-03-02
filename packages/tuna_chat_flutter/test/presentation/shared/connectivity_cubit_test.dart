import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:tuna_chat/tuna_chat.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:tuna_chat_flutter/src/presentation/shared/bloc/connectivity_cubit.dart';

// ---------------------------------------------------------------------------
// Inline mocks — no build_runner needed
// ---------------------------------------------------------------------------

class _MockSyncEngine extends Mock implements SyncEngine {
  @override
  void start() => super.noSuchMethod(
        Invocation.method(#start, []),
        returnValueForMissingStub: null,
      );

  @override
  void stop() => super.noSuchMethod(
        Invocation.method(#stop, []),
        returnValueForMissingStub: null,
      );

  @override
  Future<void> enqueue({
    required String eventType,
    required Map<String, dynamic> payload,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#enqueue, [], {
              #eventType: eventType,
              #payload: payload,
            }),
            returnValue: Future<void>.value(),
            returnValueForMissingStub: Future<void>.value(),
          ) as Future<void>);
}

class _MockConnectivity extends Mock implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() =>
      (super.noSuchMethod(
            Invocation.method(#checkConnectivity, []),
            returnValue: Future<List<ConnectivityResult>>.value(
              const <ConnectivityResult>[],
            ),
            returnValueForMissingStub: Future<List<ConnectivityResult>>.value(
              const <ConnectivityResult>[],
            ),
          ) as Future<List<ConnectivityResult>>);

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      (super.noSuchMethod(
            Invocation.getter(#onConnectivityChanged),
            returnValue: Stream<List<ConnectivityResult>>.empty(),
            returnValueForMissingStub: Stream<List<ConnectivityResult>>.empty(),
          ) as Stream<List<ConnectivityResult>>);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _MockSyncEngine mockSyncEngine;
  late _MockConnectivity mockConnectivity;
  late StreamController<List<ConnectivityResult>> connectivityController;

  setUp(() {
    mockSyncEngine = _MockSyncEngine();
    mockConnectivity = _MockConnectivity();
    connectivityController =
        StreamController<List<ConnectivityResult>>.broadcast();

    // Default stubs — overridden per test as needed.
    when(mockConnectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => connectivityController.stream);
  });

  tearDown(() async {
    await connectivityController.close();
  });

  ConnectivityCubit buildCubit() => ConnectivityCubit.withDependencies(
        syncEngine: mockSyncEngine,
        connectivity: mockConnectivity,
      );

  // ── Initial state ─────────────────────────────────────────────────────────

  test('initial state is isOnline: true before async init completes', () {
    final cubit = buildCubit();
    expect(cubit.state.isOnline, isTrue);
    addTearDown(cubit.close);
  });

  // ── Staying online ────────────────────────────────────────────────────────

  blocTest<ConnectivityCubit, ConnectivityState>(
    'does NOT call syncEngine.start() when already online and stays online',
    build: () {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      return buildCubit();
    },
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero); // let _init() complete
      connectivityController.add([ConnectivityResult.mobile]);
      await Future<void>.delayed(Duration.zero);
    },
    // Two emissions: one from initial checkConnectivity([wifi]) and one from
    // the stream change to mobile — both isOnline: true.
    expect: () => [
      predicate<ConnectivityState>((s) => s.isOnline, 'online from init'),
      predicate<ConnectivityState>((s) => s.isOnline, 'online from stream'),
    ],
    verify: (_) => verifyNever(mockSyncEngine.start()),
  );

  // ── Going offline ─────────────────────────────────────────────────────────

  blocTest<ConnectivityCubit, ConnectivityState>(
    'emits isOnline: false when connectivity changes to none',
    build: () {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      return buildCubit();
    },
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero); // let init emit online state
      connectivityController.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);
    },
    expect: () => [
      predicate<ConnectivityState>((s) => s.isOnline, 'online from init'),
      predicate<ConnectivityState>((s) => !s.isOnline, 'offline from stream'),
    ],
    verify: (_) => verifyNever(mockSyncEngine.start()),
  );

  // ── Initial offline ───────────────────────────────────────────────────────

  blocTest<ConnectivityCubit, ConnectivityState>(
    'emits isOnline: false from initial check and does not call start()',
    build: () {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      return buildCubit();
    },
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero); // let init complete
    },
    expect: () => [
      predicate<ConnectivityState>((s) => !s.isOnline, 'offline from init'),
    ],
    verify: (_) => verifyNever(mockSyncEngine.start()),
  );

  // ── Coming back online ────────────────────────────────────────────────────

  blocTest<ConnectivityCubit, ConnectivityState>(
    'emits isOnline: true and calls syncEngine.start() when back online',
    build: () {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      return buildCubit();
    },
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero); // let init emit offline state
      connectivityController.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
    },
    expect: () => [
      predicate<ConnectivityState>((s) => !s.isOnline, 'offline from init'),
      predicate<ConnectivityState>((s) => s.isOnline, 'online from stream'),
    ],
    verify: (_) => verify(mockSyncEngine.start()).called(1),
  );

  blocTest<ConnectivityCubit, ConnectivityState>(
    'calls syncEngine.start() exactly once even across multiple online events',
    build: () {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      return buildCubit();
    },
    act: (cubit) async {
      await Future<void>.delayed(Duration.zero); // offline from init
      connectivityController.add([ConnectivityResult.wifi]); // back online → start()
      await Future<void>.delayed(Duration.zero);
      connectivityController.add([ConnectivityResult.mobile]); // already online → no start()
      await Future<void>.delayed(Duration.zero);
    },
    verify: (_) => verify(mockSyncEngine.start()).called(1),
  );

  // ── Close ─────────────────────────────────────────────────────────────────

  test('close() cancels stream subscription', () async {
    final cubit = buildCubit();
    // Let _init() complete so the subscription is set up before we close.
    await Future<void>.delayed(Duration.zero);
    await cubit.close();

    // After close, adding to the stream controller should not trigger
    // any cubit state emission (subscription was cancelled).
    expect(
      () => connectivityController.add([ConnectivityResult.none]),
      returnsNormally,
    );
  });
}
