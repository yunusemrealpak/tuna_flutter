## 0.1.0

**Initial stable release — M5 feature complete.**

### Added

#### SDK entry point
- `TunaChatSDK.init(config)` — single initialization call at app startup
- `TunaChatSDK.instance.connectUser(userId, token)` — host-signed JWT connection
- `TunaChatSDK.instance.disconnectUser()` — clean disconnect and WS close
- `TunaChatConfig` — API key, base URL, WS URL, `tokenProvider` callback

#### State management (BLoC)
- `ConnectionBloc` — SDK lifecycle (connecting / connected / error / disconnected)
- `ChannelListBloc` — load, paginate, refresh channel list; WS channel updates
- `CreateChannelBloc` — user search, member selection, channel creation
- `MessageListBloc` — optimistic send, edit/delete, reactions, read receipts, thread load
- `TypingBloc` — `typing.start` / `typing.stop` WS events with 3 s debounce
- `ConnectivityCubit` — network reachability monitoring; triggers sync on reconnect

#### Pages
- `ConnectPage` — user ID + JWT token input form
- `ChannelListPage` — pull-to-refresh, infinite scroll, unread badges
- `CreateChannelPage` — type selector, user search, multi-member chip selector
- `ChannelDetailPage` — member list, add/remove members, delete channel
- `MessageListPage` — full message list, file upload, reaction picker, search icon
- `ThreadPage` — thread reply view with pinned parent message
- `MessageSearchPage` — 400 ms debounced search, result navigation

#### Widgets
- `MessageBubble` — chat bubble, own/other alignment, deleted state, reaction bar, reply count
- `AttachmentView` — inline image (CachedNetworkImage) or tappable file chip (url_launcher)
- `MessageInput` — text field, file picker, attachment chip with clear, send button
- `ReactionBar` — compact emoji counters with own-reaction highlight
- `ReactionPicker` — bottom-sheet emoji grid
- `TypingIndicator` — animated bouncing-dot indicator
- `PresenceIndicator` — 12×12 green/grey online dot
- `UserAvatar` — CircleAvatar with optional presence overlay
- `OfflineBanner` — animated red banner with auto-dismiss
- `SyncIndicator` — syncing progress indicator

#### Infrastructure
- `PushNotificationService` — FCM token registration, `onChannelTap` callback for notification navigation
- Private SDK-scoped `GetIt` instance (avoids conflicts with host app DI)

#### Tests
- 50 unit tests covering ConnectionBloc, ChannelListBloc, CreateChannelBloc, MessageListBloc, reaction BLoC, and ConnectivityCubit
