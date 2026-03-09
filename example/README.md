# TunaChat SDK — Example Host App

This example demonstrates how to integrate the TunaChat Flutter SDK into a real Flutter application. It simulates a typical "host app" that:

1. Authenticates its users with its own backend
2. Obtains a host-signed JWT for TunaChat
3. Passes the JWT to `TunaChatSDK.instance.connectUser()`
4. Shows the full TunaChat UI

---

## Features demonstrated

| Feature | Where to find |
|---|---|
| SDK initialization | `main()` → `TunaChatSDK.init()` |
| Host app auth simulation | `_DemoLoginPage` |
| Connect user | `ConnectionBloc` → `ConnectUserRequested` |
| Channel list with unread badges | `ChannelListPage` |
| Create channel (group/direct/public) | FAB on `ChannelListPage` |
| Real-time messaging | `MessageListPage` |
| Emoji reactions | Long-press any message |
| Thread replies | Tap reply count on any message |
| File attachments | Paperclip icon in message input |
| Message search | Magnifier icon in message list AppBar |
| Read receipts | Auto-triggered on channel open |
| Typing indicator | Start typing in any channel |
| Presence (online/offline) | Member avatars in channel detail |
| Channel member management | Tap the channel name in AppBar |
| Offline banner | Disconnect your network |

---

## Prerequisites

- Flutter ≥ 3.24.0
- A running TunaChat backend (see `backend/README.md`)
- A TunaChat app with an API key and API secret (create via `POST /apps`)

---

## Step 1 — Create a TunaChat app

```bash
curl -X POST http://localhost:8080/apps \
  -H "Content-Type: application/json" \
  -d '{"name": "My Demo App"}'
```

Response:
```json
{
  "data": {
    "id": "01JXXX...",
    "api_key": "tuna_key_xxxx",
    "api_secret": "tuna_secret_xxxx"
  }
}
```

**Save the `api_secret` — it is shown only once.**

---

## Step 2 — Create a test user

```bash
curl -X POST http://localhost:8080/server/users \
  -H "Authorization: Bearer tuna_secret_xxxx" \
  -H "Content-Type: application/json" \
  -d '{"external_id": "alice", "username": "alice", "display_name": "Alice"}'
```

---

## Step 3 — Generate a JWT for the user

Your backend (or the helper script below) signs a JWT with the `api_secret`:

```bash
# Using Node.js (requires jsonwebtoken: npm i -g jsonwebtoken)
node -e "
  const jwt = require('jsonwebtoken');
  const token = jwt.sign(
    { user_id: 'alice' },
    'tuna_secret_xxxx',
    { algorithm: 'HS256' }
  );
  console.log(token);
"
```

Or using Go:
```go
import "github.com/golang-jwt/jwt/v5"

claims := jwt.MapClaims{"user_id": "alice"}
token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
signed, _ := token.SignedString([]byte("tuna_secret_xxxx"))
fmt.Println(signed)
```

---

## Step 4 — Configure the example app

Open `lib/main.dart` and set the constants at the top:

```dart
const _kApiKey  = 'tuna_key_xxxx';   // from Step 1
const _kBaseUrl = 'http://10.0.2.2:8080/api/v1';  // Android emulator
const _kWsUrl   = 'ws://10.0.2.2:8080/api/v1/ws'; // Android emulator
```

URL values by platform:

| Platform | Base URL |
|---|---|
| Android emulator | `http://10.0.2.2:8080/api/v1` |
| iOS simulator | `http://127.0.0.1:8080/api/v1` |
| macOS / Linux desktop | `http://localhost:8080/api/v1` |
| Physical device | `http://<your-lan-ip>:8080/api/v1` |

---

## Step 5 — Run the app

```bash
cd example
flutter pub get
flutter run
```

On the login screen, enter:
- **User ID:** `alice` (the `external_id` you created in Step 2)
- **JWT Token:** the token you generated in Step 3

---

## Connecting a second user

Open the app on a second device or emulator with a different user (e.g. `bob`). Send messages between them to see real-time delivery, typing indicators, and read receipts.

---

## Production integration

In a real app, replace the manual token input with calls to your own backend:

```dart
// In your auth service:
final jwt = await myBackend.fetchChatToken(currentUserId);

// Then connect:
await TunaChatSDK.instance.connectUser(
  userId: currentUserId,
  token: jwt,
);
```

For token refresh (when JWT expires), provide a `tokenProvider`:

```dart
await TunaChatSDK.init(
  config: TunaChatConfig(
    apiKey: _kApiKey,
    baseUrl: _kBaseUrl,
    wsUrl: _kWsUrl,
    tokenProvider: () async => await myBackend.fetchChatToken(currentUserId),
  ),
);
```

---

## Push notifications

To enable push notifications in the example app:

1. Add a `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) to the platform folders.
2. Initialize `PushNotificationService` after connecting:

```dart
await PushNotificationService.initialize(
  deviceRepository: TunaChatSDK.instance.sl<DeviceRepository>(),
  onChannelTap: (channelId) {
    // Navigate to the channel when user taps the notification
  },
);
```

---

## Architecture overview

```
main.dart
├── TunaChatSDK.init()          ← SDK initialization
├── _HostAppSimulation          ← MaterialApp root
│   ├── ConnectionBloc          ← SDK connection lifecycle
│   └── ConnectivityCubit       ← Network reachability
├── _DemoLoginPage              ← Simulates host app's own auth screen
│   └── ConnectUserRequested    ← BLoC event → connectUser()
└── _ChatShell                  ← Shown after successful connection
    └── ChannelListPage         ← Full SDK UI starts here
        └── MessageListPage     ← Tapped from channel list
            └── ThreadPage      ← Tapped from reply count
```
