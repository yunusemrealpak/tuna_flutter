import 'package:chat_core/chat_core.dart';
import 'package:test/test.dart';

void main() {
  group('ChatEvent', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'type': 'message.new',
          'data': {'id': 'msg1', 'text': 'hello'},
          'channel_id': 'ch1',
          'timestamp': '2026-03-01T10:00:00.000Z',
        };

        final event = ChatEvent.fromJson(json);

        expect(event.type, 'message.new');
        expect(event.data, {'id': 'msg1', 'text': 'hello'});
        expect(event.channelId, 'ch1');
        expect(event.timestamp, DateTime.utc(2026, 3, 1, 10, 0, 0));
      });

      test('channel_id is nullable', () {
        final json = {
          'type': 'connection.ack',
          'data': {'user_id': 'u1', 'missed_events_count': 0},
          'timestamp': '2026-03-01T10:00:00.000Z',
        };

        final event = ChatEvent.fromJson(json);
        expect(event.channelId, isNull);
      });

      test('missing timestamp defaults to non-null DateTime', () {
        final json = {
          'type': 'ping',
          'data': <String, dynamic>{},
        };

        final event = ChatEvent.fromJson(json);
        expect(event.timestamp, isA<DateTime>());
      });

      test('missing data defaults to empty map', () {
        final json = {
          'type': 'user.typing_start',
          'timestamp': '2026-03-01T10:00:00.000Z',
        };

        final event = ChatEvent.fromJson(json);
        expect(event.data, isEmpty);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final event = ChatEvent(
          type: 'typing.start',
          data: {'channel_id': 'ch1'},
          channelId: 'ch1',
          timestamp: DateTime.utc(2026, 3, 1, 10, 0, 0),
        );

        final json = event.toJson();

        expect(json['type'], 'typing.start');
        expect(json['data'], {'channel_id': 'ch1'});
        expect(json['channel_id'], 'ch1');
        expect(json['timestamp'], '2026-03-01T10:00:00.000Z');
      });

      test('omits channel_id when null', () {
        final event = ChatEvent(
          type: 'connection.ack',
          data: <String, dynamic>{},
          timestamp: DateTime.utc(2026, 3, 1),
        );

        final json = event.toJson();
        expect(json.containsKey('channel_id'), isFalse);
      });

      test('round-trip fromJson → toJson is lossless', () {
        final original = {
          'type': 'message.new',
          'data': {'id': 'msg1'},
          'channel_id': 'ch1',
          'timestamp': '2026-03-01T10:00:00.000Z',
        };

        final json = ChatEvent.fromJson(original).toJson();
        expect(json['type'], original['type']);
        expect(json['channel_id'], original['channel_id']);
        expect(json['timestamp'], original['timestamp']);
      });
    });

    group('WsEventType constants', () {
      test('server→client constants are defined', () {
        expect(WsEventType.connectionAck, 'connection.ack');
        expect(WsEventType.messageNew, 'message.new');
        expect(WsEventType.messageUpdated, 'message.updated');
        expect(WsEventType.messageDeleted, 'message.deleted');
        expect(WsEventType.channelUpdated, 'channel.updated');
        expect(WsEventType.channelMemberAdded, 'channel.member_added');
        expect(WsEventType.channelMemberRemoved, 'channel.member_removed');
        expect(WsEventType.userPresenceChanged, 'user.presence_changed');
        expect(WsEventType.userTypingStart, 'user.typing_start');
        expect(WsEventType.userTypingStop, 'user.typing_stop');
      });

      test('client→server constants are defined', () {
        expect(WsEventType.typingStart, 'typing.start');
        expect(WsEventType.typingStop, 'typing.stop');
        expect(WsEventType.presenceUpdate, 'presence.update');
        expect(WsEventType.connectionResume, 'connection.resume');
      });
    });
  });
}
