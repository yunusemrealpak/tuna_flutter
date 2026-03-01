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
