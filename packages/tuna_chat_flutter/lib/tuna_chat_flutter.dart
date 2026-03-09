/// tuna_chat_flutter — Flutter SDK for TunaChat real-time chat as a service.
///
/// Drop pre-built pages and widgets into your Flutter app in minutes.
/// Powered by BLoC, Drift, and WebSockets.
///
/// ## Quick start
///
/// ```dart
/// import 'package:tuna_chat_flutter/tuna_chat_flutter.dart';
///
/// // 1. Initialize once at app startup:
/// await TunaChatSDK.init(
///   config: TunaChatConfig(
///     apiKey: 'tuna_key_your_key',
///     baseUrl: 'https://chat.example.com/api/v1',
///     wsUrl: 'wss://chat.example.com/api/v1/ws',
///   ),
/// );
///
/// // 2. Connect after your own auth completes:
/// final user = await TunaChatSDK.instance.connectUser(
///   userId: 'host-user-123',
///   token: hostSignedJwt,
/// );
///
/// // 3. Show the channel list:
/// BlocProvider<ChannelListBloc>(
///   create: (_) => ChannelListBloc(),
///   child: ChannelListPage(currentUserId: user.id),
/// )
/// ```
library;

export 'package:tuna_chat/tuna_chat.dart';

// SDK initialization
export 'src/tuna_chat_sdk.dart';

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
