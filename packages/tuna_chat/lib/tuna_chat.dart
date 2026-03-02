/// tuna_chat — Pure Dart core library for TunaChat SDK.
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
export 'src/domain/entities/reaction.dart';

// Domain — Repository interfaces
export 'src/domain/repositories/connection_repository.dart';
export 'src/domain/repositories/channel_repository.dart';
export 'src/domain/repositories/message_repository.dart';
export 'src/domain/repositories/user_repository.dart';
export 'src/domain/repositories/presence_repository.dart';
export 'src/domain/repositories/reaction_repository.dart';

// Data — Remote
export 'src/data/datasources/remote/api_client.dart';
export 'src/data/datasources/remote/chat_event.dart';
export 'src/data/datasources/remote/ws_client.dart';
export 'src/data/datasources/remote/channel_remote_data_source.dart';
export 'src/data/datasources/remote/message_remote_data_source.dart';
export 'src/data/datasources/remote/user_remote_data_source.dart';
export 'src/data/datasources/remote/presence_remote_data_source.dart';
export 'src/data/datasources/remote/reaction_remote_data_source.dart';

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

// Data — Repositories
export 'src/data/repositories/connection_repository_impl.dart';
export 'src/data/repositories/channel_repository_impl.dart';
export 'src/data/repositories/message_repository_impl.dart';
export 'src/data/repositories/user_repository_impl.dart';
export 'src/data/repositories/presence_repository_impl.dart';
export 'src/data/repositories/reaction_repository_impl.dart';

// Data — Sync
export 'src/data/sync/event_handler.dart';
export 'src/data/sync/sync_engine.dart';
