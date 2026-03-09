# tuna_chat

Pure Dart core library for the TunaChat SDK. Provides domain entities, repository interfaces, an HTTP client, a WebSocket client, and offline-first local storage.

> **Most Flutter apps should use [`tuna_chat_flutter`](../tuna_chat_flutter/README.md)** instead, which adds BLoC state management and pre-built UI widgets on top of this package.

---

## Features

- **Domain entities** — `User`, `Channel`, `Message`, `Membership`, `Reaction`, `Attachment`
- **Repository interfaces** — type-safe abstractions for connection, channels, messages, presence, reactions, and device tokens
- **HTTP client** — `ApiClient` with `X-API-Key` + Bearer JWT auth, automatic 401 token refresh via `tokenProvider`, and JSON envelope parsing
- **WebSocket client** — `WsClient` with exponential-backoff reconnection, 30 s heartbeat, and `tokenProvider` support for seamless token rotation
- **Offline-first storage** — Drift/SQLite local database with DAOs for channels, messages, memberships, and pending events
- **Sync engine** — Retries failed outbox events on reconnection

---

## Getting Started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  tuna_chat: ^0.1.0
```

---

## Usage

### 1. Create an API client

```dart
import 'package:tuna_chat/tuna_chat.dart';

final apiClient = ApiClient(
  baseUrl: 'https://chat.example.com/api/v1',
  apiKey: 'tuna_key_your_key_here',
  // Optional: called on 401 to get a fresh JWT from your backend
  tokenProvider: () async => await myBackend.fetchChatToken(userId),
);
```

### 2. Connect via WebSocket

```dart
final wsClient = WsClient(
  wsUrl: 'wss://chat.example.com/api/v1/ws',
  tokenProvider: () async => await myBackend.fetchChatToken(userId),
);

await wsClient.connect(token: hostSignedJwt);

// Listen for real-time events
wsClient.events.listen((event) {
  switch (event.type) {
    case WsEventType.messageNew:
      handleNewMessage(event.data);
    case WsEventType.reactionNew:
      handleNewReaction(event.data);
    default:
      break;
  }
});
```

### 3. Use repositories

All repository methods return `FutureEither<T>` (`Future<Either<Failure, T>>`):

```dart
final channelRepo = ChannelRepositoryImpl(
  remoteDataSource: ChannelRemoteDataSourceImpl(apiClient),
  database: appDatabase,
);

final result = await channelRepo.listChannels();
result.fold(
  (failure) => print('Error: ${failure.message}'),
  (page)    => page.channels.forEach(print),
);
```

---

## Error handling

```dart
final result = await messageRepo.sendMessage(channelId, text: 'Hello');
result.fold(
  (failure) {
    if (failure is NetworkFailure) showOfflineBanner();
    if (failure is AuthFailure)   refreshTokenAndRetry();
    if (failure is ServerFailure) showErrorToast(failure.message);
  },
  (message) => updateUI(message),
);
```

---

## Authentication model

TunaChat uses the **host-signed JWT** pattern:

1. Your backend signs a JWT with your `api_secret` (HMAC-SHA256).
2. Your mobile app obtains this JWT from your backend after the user logs in.
3. The JWT is passed to `TunaChatSDK.instance.connectUser(userId, token)`.
4. TunaChat validates the JWT using the `api_secret` stored server-side.

```
Host App → [POST /auth/chat-token] → Your Backend
Your Backend → [JWT signed with api_secret] → Host App
Host App → [connectUser(userId, jwt)] → TunaChat SDK
TunaChat SDK → [validates JWT, opens WS] → TunaChat Backend
```

---

## Architecture

```
tuna_chat/
├── core/          # Exceptions, Failures, FutureEither<T>, constants
├── domain/
│   ├── entities/  # User, Channel, Message, Membership, Reaction, Attachment
│   └── repositories/  # Abstract interfaces (no external deps)
└── data/
    ├── datasources/
    │   ├── remote/ # ApiClient, WsClient, *RemoteDataSource implementations
    │   └── local/  # AppDatabase (Drift), DAOs, table definitions
    ├── repositories/ # Concrete repository implementations
    └── sync/      # EventHandler (WS → DB), SyncEngine (outbox retry)
```

**Dependency rule:** `data → domain`. Domain has no external package dependencies.

---

## Additional information

- Issues and feature requests: open an issue in the project repository.
- Contributions welcome — please read the contribution guide first.
