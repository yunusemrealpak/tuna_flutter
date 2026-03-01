/// chat_core — Platform-agnostic core library for the Chat SDK.
///
/// Exports domain entities, repository interfaces, and core types.
library;

// Core
export 'src/core/exceptions.dart';
export 'src/core/failures.dart';
export 'src/core/type_defs.dart';
export 'src/core/constants.dart';

// Domain — Entities
export 'src/domain/entities/user.dart';
export 'src/domain/entities/channel.dart';
export 'src/domain/entities/message.dart';
export 'src/domain/entities/membership.dart';

// Domain — Repository interfaces
export 'src/domain/repositories/auth_repository.dart';
export 'src/domain/repositories/channel_repository.dart';
export 'src/domain/repositories/message_repository.dart';
export 'src/domain/repositories/user_repository.dart';
export 'src/domain/repositories/presence_repository.dart';

// Data — Remote
export 'src/data/datasources/remote/token_storage.dart';
export 'src/data/datasources/remote/api_client.dart';
export 'src/data/datasources/remote/chat_event.dart';
export 'src/data/datasources/remote/ws_client.dart';

// Data — Local (Drift)
export 'src/data/datasources/local/app_database.dart';
export 'src/data/datasources/local/tables/users_table.dart';
export 'src/data/datasources/local/tables/channels_table.dart';
export 'src/data/datasources/local/tables/messages_table.dart';
export 'src/data/datasources/local/tables/memberships_table.dart';
export 'src/data/datasources/local/tables/pending_events_table.dart';
export 'src/data/datasources/local/daos/user_dao.dart';
export 'src/data/datasources/local/daos/channel_dao.dart';
export 'src/data/datasources/local/daos/message_dao.dart';
export 'src/data/datasources/local/daos/membership_dao.dart';
export 'src/data/datasources/local/daos/pending_event_dao.dart';
