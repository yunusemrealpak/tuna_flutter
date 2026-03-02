import 'dart:io';

import 'package:tuna_chat/tuna_chat.dart';
import 'package:drift/native.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../tuna_chat_sdk.dart';

// Re-export for convenience in tests.
export 'package:get_it/get_it.dart' show GetIt;

final GetIt sl = GetIt.instance;

/// Registers all dependencies in the correct order:
/// Core → DataSources → Repositories → Sync
Future<void> registerDependencies(TunaChatConfig config) async {
  // ── 1. Local database ────────────────────────────────────────────────────
  final appDir = await getApplicationDocumentsDirectory();
  final dbFile = File(p.join(appDir.path, 'tuna_chat.db'));
  sl.registerSingleton<AppDatabase>(AppDatabase(NativeDatabase(dbFile)));

  // ── 2. API client ────────────────────────────────────────────────────────
  sl.registerSingleton<ApiClient>(
    ApiClient(
      baseUrl: config.resolvedBaseUrl,
      apiKey: config.apiKey,
    ),
  );

  // ── 3. WebSocket client ──────────────────────────────────────────────────
  sl.registerSingleton<WsClient>(
    WsClient(wsUrl: config.resolvedWsUrl),
  );

  // ── 4. Remote data sources ───────────────────────────────────────────────
  sl.registerSingleton<ChannelRemoteDataSource>(
    ChannelRemoteDataSourceImpl(sl<ApiClient>()),
  );
  sl.registerSingleton<MessageRemoteDataSource>(
    MessageRemoteDataSourceImpl(sl<ApiClient>()),
  );
  sl.registerSingleton<UserRemoteDataSource>(
    UserRemoteDataSourceImpl(sl<ApiClient>()),
  );
  sl.registerSingleton<PresenceRemoteDataSource>(
    PresenceRemoteDataSourceImpl(sl<ApiClient>()),
  );

  // ── 5. Repositories ──────────────────────────────────────────────────────
  sl.registerSingleton<ConnectionRepository>(
    ConnectionRepositoryImpl(
      apiClient: sl<ApiClient>(),
      wsClient: sl<WsClient>(),
      userRemoteDataSource: sl<UserRemoteDataSource>(),
    ),
  );
  sl.registerSingleton<ChannelRepository>(
    ChannelRepositoryImpl(
      remoteDataSource: sl<ChannelRemoteDataSource>(),
      database: sl<AppDatabase>(),
    ),
  );
  sl.registerSingleton<MessageRepository>(
    MessageRepositoryImpl(
      remoteDataSource: sl<MessageRemoteDataSource>(),
      database: sl<AppDatabase>(),
    ),
  );
  sl.registerSingleton<UserRepository>(
    UserRepositoryImpl(remoteDataSource: sl<UserRemoteDataSource>()),
  );
  sl.registerSingleton<PresenceRepository>(
    PresenceRepositoryImpl(
      remoteDataSource: sl<PresenceRemoteDataSource>(),
      wsClient: sl<WsClient>(),
    ),
  );

  // ── 6. Sync infrastructure ───────────────────────────────────────────────
  sl.registerSingleton<EventHandler>(EventHandler(sl<AppDatabase>()));

  sl.registerSingleton<SyncEngine>(
    SyncEngine(
      database: sl<AppDatabase>(),
      apiClient: sl<ApiClient>(),
    ),
  );

  sl<SyncEngine>().start();
}

Future<void> tearDownDependencies() async {
  sl<SyncEngine>().stop();
  await sl<AppDatabase>().close();
  await sl<WsClient>().dispose();
  sl<ApiClient>().dispose();
  await sl.reset();
}
