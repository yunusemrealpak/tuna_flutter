import 'dart:io';

import 'package:chat_core/chat_core.dart';
import 'package:drift/native.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../chat_sdk.dart';
import '../data/datasources/local/secure_token_storage.dart';

final GetIt sl = GetIt.instance;

/// Registers all dependencies in the correct order:
/// Core → DataSources → Repositories → Sync
Future<void> registerDependencies(ChatConfig config) async {
  // ── 1. Local database ────────────────────────────────────────────────────
  final appDir = await getApplicationDocumentsDirectory();
  final dbFile = File(p.join(appDir.path, 'chat_sdk.db'));
  sl.registerSingleton<AppDatabase>(AppDatabase(NativeDatabase(dbFile)));

  // ── 2. Token storage ─────────────────────────────────────────────────────
  sl.registerSingleton<TokenStorage>(SecureTokenStorage());

  // ── 3. API client ────────────────────────────────────────────────────────
  sl.registerSingleton<ApiClient>(
    ApiClient(
      baseUrl: config.apiBaseUrl,
      tokenStorage: sl<TokenStorage>(),
    ),
  );

  // ── 4. WebSocket client ──────────────────────────────────────────────────
  sl.registerSingleton<WsClient>(
    WsClient(wsUrl: config.wsUrl),
  );

  // ── 5. Remote data sources ───────────────────────────────────────────────
  sl.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl(sl<ApiClient>()),
  );
  sl.registerSingleton<ChannelRemoteDataSource>(
    ChannelRemoteDataSourceImpl(sl<ApiClient>()),
  );
  sl.registerSingleton<MessageRemoteDataSource>(
    MessageRemoteDataSourceImpl(sl<ApiClient>()),
  );

  // ── 6. Local data sources ────────────────────────────────────────────────
  sl.registerSingleton<AuthLocalDataSource>(
    AuthLocalDataSourceImpl(sl<TokenStorage>()),
  );

  // ── 7. Repositories ──────────────────────────────────────────────────────
  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
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

  // ── 8. Sync infrastructure ───────────────────────────────────────────────
  sl.registerSingleton<EventHandler>(EventHandler(sl<AppDatabase>()));

  sl.registerSingleton<SyncEngine>(
    SyncEngine(
      database: sl<AppDatabase>(),
      apiClient: sl<ApiClient>(),
    ),
  );

  // Start the sync engine to process any pending events from a previous session.
  sl<SyncEngine>().start();
}

Future<void> tearDownDependencies() async {
  sl<SyncEngine>().stop();
  await sl<AppDatabase>().close();
  await sl<WsClient>().dispose();
  sl<ApiClient>().dispose();
  await sl.reset();
}
