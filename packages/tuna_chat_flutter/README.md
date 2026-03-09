# tuna_chat_flutter

Flutter SDK for TunaChat — real-time chat as a service. Drop pre-built pages and widgets into your Flutter app in minutes. Powered by BLoC, Drift, and WebSockets.

---

## Features

- **One-line SDK initialization** — `TunaChatSDK.init(config)` + `connectUser(userId, token)`
- **Full chat UI** out of the box — channel list, message list, thread view, search
- **Real-time** — WebSocket with automatic reconnection and exponential backoff
- **Reactions** — emoji reactions with long-press picker and live updates
- **Threads** — reply-in-thread with pinned parent and reply count
- **File attachments** — image preview and file download via `file_picker`
- **Typing indicators** — animated bouncing-dot indicator with 3 s auto-stop
- **Presence** — online/offline dot overlay on user avatars
- **Push notifications** — FCM token registration + navigation-on-tap via `firebase_messaging`
- **Message search** — 400 ms debounced search powered by Meilisearch
- **Read receipts** — auto mark-as-read on channel open, unread badge on channel list
- **Offline-first** — Drift/SQLite cache, sync engine retries on reconnection
- **Connectivity banner** — animated offline banner with auto-dismiss on reconnect

---

## Getting Started

### 1. Add the dependency

```yaml
dependencies:
  tuna_chat_flutter:
    git:
      url: https://github.com/your-org/tuna_flutter.git
      path: frontend/packages/tuna_chat_flutter
```

### 2. Initialize the SDK at app startup

```dart
import 'package:tuna_chat_flutter/tuna_chat_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TunaChatSDK.init(
    config: TunaChatConfig(
      apiKey: 'tuna_key_your_api_key',
      baseUrl: 'https://chat.example.com/api/v1',
      wsUrl: 'wss://chat.example.com/api/v1/ws',
      // Called automatically on 401 — fetch a fresh JWT from your backend
      tokenProvider: () async => await myBackend.fetchChatToken(currentUserId),
    ),
  );

  runApp(const MyApp());
}
```

### 3. Connect the user

After your own auth flow completes and you have obtained a host-signed JWT:

```dart
final user = await TunaChatSDK.instance.connectUser(
  userId: 'host-user-123',   // your system's user ID
  token: hostSignedJwt,       // HMAC-SHA256 JWT from your backend
);
```

### 4. Show the channel list

```dart
BlocProvider<ChannelListBloc>(
  create: (_) => ChannelListBloc(),
  child: ChannelListPage(currentUserId: user.id),
)
```

---

## Authentication model

TunaChat uses the **host-signed JWT** pattern — your backend remains the source of truth for user identity:

```
1. User logs into YOUR app  →  your backend authenticates them
2. Your backend signs a JWT with your TunaChat api_secret (HMAC-SHA256)
3. Your mobile app receives that JWT and calls:
       TunaChatSDK.instance.connectUser(userId: id, token: jwt)
4. TunaChat validates the JWT against your api_secret and opens the WS connection
```

Your `api_secret` never leaves your backend.

---

## Usage examples

### Disconnect on logout

```dart
await TunaChatSDK.instance.disconnectUser();
```

### Open a specific channel

```dart
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => BlocProvider(
    create: (_) => MessageListBloc(),
    child: MessageListPage(
      channelId: channel.id,
      channelName: channel.name,
      currentUserId: currentUser.id,
    ),
  ),
));
```

### Register FCM push token

```dart
await PushNotificationService.initialize(
  deviceRepository: TunaChatSDK.instance.sl<DeviceRepository>(),
  onChannelTap: (channelId) => navigateToChannel(channelId),
);
```

### Show presence indicator

```dart
UserAvatar(
  user: member.user,
  isOnline: true,
  radius: 20,
)
```

### Show offline banner

Add `OfflineBanner` at the top of any Scaffold body:

```dart
Column(
  children: [
    BlocProvider(
      create: (_) => ConnectivityCubit(),
      child: const OfflineBanner(),
    ),
    Expanded(child: ChannelListPage(currentUserId: userId)),
  ],
)
```

---

## BLoC reference

| BLoC / Cubit | Purpose |
|---|---|
| `ConnectionBloc` | SDK connect/disconnect lifecycle |
| `ChannelListBloc` | Load, paginate, and refresh channel list |
| `CreateChannelBloc` | User search and channel creation |
| `MessageListBloc` | Messages, optimistic send, reactions, read receipts |
| `TypingBloc` | typing.start / typing.stop WS events |
| `ConnectivityCubit` | Network reachability + sync trigger |

---

## Widgets reference

| Widget | Purpose |
|---|---|
| `ConnectPage` | userId + token input form |
| `ChannelListPage` | Scrollable channel list with pull-to-refresh |
| `MessageListPage` | Full message list with input, reactions, threads |
| `ThreadPage` | Thread reply view with pinned parent |
| `MessageSearchPage` | Debounced full-text search |
| `ChannelDetailPage` | Member management (add/remove, roles) |
| `MessageBubble` | Chat bubble with attachments and reaction bar |
| `TypingIndicator` | Animated bouncing dots |
| `PresenceIndicator` | Online/offline dot |
| `UserAvatar` | Avatar with presence overlay |
| `OfflineBanner` | Animated connectivity banner |

---

## Requirements

- Flutter ≥ 3.24.0
- Dart ≥ 3.10.1
- A running TunaChat backend (see backend README)
- Firebase project for push notifications (optional)

---

## Additional information

- Core library (pure Dart): [`tuna_chat`](../tuna_chat/README.md)
- Backend setup: see `backend/README.md` in the project root
- Issues and feature requests: open an issue in the project repository
