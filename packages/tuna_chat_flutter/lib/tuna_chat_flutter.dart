/// tuna_chat_flutter — Flutter UI package for TunaChat SDK.
///
/// Provides BLoC state management, widgets, and pages built on top of tuna_chat.
library;

export 'package:tuna_chat/tuna_chat.dart';

// SDK initialization
export 'src/tuna_chat_sdk.dart';

// DI
export 'src/di/injection.dart';

// ── Presentation — Connection ─────────────────────────────────────────────
export 'src/presentation/connection/bloc/connection_bloc.dart';
export 'src/presentation/connection/pages/connect_page.dart';

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
