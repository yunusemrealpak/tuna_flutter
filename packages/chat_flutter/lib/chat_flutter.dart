/// chat_flutter — Flutter UI package for the Chat SDK.
///
/// Provides BLoC state management, widgets, and pages built on top of chat_core.
library;

export 'package:chat_core/chat_core.dart';

// SDK initialization
export 'src/chat_sdk.dart';

// DI
export 'src/di/injection.dart';

// Token storage
export 'src/data/datasources/local/secure_token_storage.dart';

// ── Presentation — Auth ──────────────────────────────────────────────────────
export 'src/presentation/auth/bloc/auth_bloc.dart';
export 'src/presentation/auth/widgets/auth_text_field.dart';
export 'src/presentation/auth/pages/login_page.dart';
export 'src/presentation/auth/pages/register_page.dart';

// ── Presentation — Channels ──────────────────────────────────────────────────
export 'src/presentation/channels/bloc/channel_list_bloc.dart';
export 'src/presentation/channels/bloc/create_channel_bloc.dart';
export 'src/presentation/channels/widgets/channel_list_tile.dart';
export 'src/presentation/channels/pages/channel_list_page.dart';
export 'src/presentation/channels/pages/create_channel_page.dart';
export 'src/presentation/channels/pages/channel_detail_page.dart';

// ── Presentation — Messages ──────────────────────────────────────────────────
export 'src/presentation/messages/bloc/message_list_bloc.dart';
export 'src/presentation/messages/bloc/typing_bloc.dart';
export 'src/presentation/messages/widgets/message_bubble.dart';
export 'src/presentation/messages/widgets/message_input.dart';
export 'src/presentation/messages/widgets/typing_indicator.dart';
export 'src/presentation/messages/pages/message_list_page.dart';

// ── Presentation — Shared ────────────────────────────────────────────────────
export 'src/presentation/shared/bloc/connectivity_cubit.dart';
export 'src/presentation/shared/widgets/presence_indicator.dart';
export 'src/presentation/shared/widgets/user_avatar.dart';
export 'src/presentation/shared/widgets/offline_banner.dart';
export 'src/presentation/shared/widgets/sync_indicator.dart';
