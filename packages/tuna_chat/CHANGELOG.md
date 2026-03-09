## 0.1.0

**Initial stable release — M5 feature complete.**

### Added
- **Domain entities**: `User`, `Channel`, `Message`, `Membership`, `Reaction`, `Attachment`
  - All entities implement `Equatable`, `copyWith`, `fromJson`/`toJson`
  - Sentinel-based `copyWith` supports clearing nullable fields
- **Repository interfaces**: `ConnectionRepository`, `ChannelRepository`, `MessageRepository`,
  `UserRepository`, `PresenceRepository`, `ReactionRepository`, `DeviceRepository`
- **ApiClient**: HTTP client with `X-API-Key` + Bearer JWT auth, 401 → `tokenProvider` refresh,
  JSON `{"data": ..., "meta": ...}` envelope parsing, multipart upload support
- **WsClient**: WebSocket client with exponential-backoff reconnect, 30 s heartbeat,
  `tokenProvider` for token rotation, `connection.resume` on reconnect
- **ChatEvent** + `WsEventType` constants for all real-time events
- **AppDatabase** (Drift): SQLite schema with 5 tables (users, channels, messages, memberships, pending_events)
  and 5 DAOs with CRUD, watch streams, and offline sync status
- **Repository implementations**: offline-first `ChannelRepositoryImpl`, `MessageRepositoryImpl`;
  remote-only `ReactionRepositoryImpl`, `DeviceRepositoryImpl`
- **SyncEngine**: outbox retry with exponential backoff for pending events
- **EventHandler**: routes WS events to local DAO updates

### Architecture
- Strict Clean Architecture — `data → domain`, domain has zero external dependencies
- `FutureEither<T>` alias for `Future<Either<Failure, T>>` (dartz)
- Exception hierarchy: `ServerException`, `NetworkException`, `AuthException`, `CacheException`
- Failure hierarchy: `ServerFailure`, `NetworkFailure`, `AuthFailure`, `CacheFailure`
