import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuna_chat/tuna_chat.dart';
import 'package:tuna_chat_flutter/src/presentation/channels/widgets/channel_list_tile.dart';

// Helper to build a Channel for testing.
Channel makeChannel({
  String id = 'ch-1',
  String name = 'General',
  int unreadCount = 0,
  LastMessage? lastMessage,
}) =>
    Channel(
      id: id,
      type: ChannelType.group,
      name: name,
      createdBy: 'user-1',
      memberCount: 3,
      unreadCount: unreadCount,
      lastMessage: lastMessage,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

LastMessage makeLastMessage({String text = 'Hello!'}) => LastMessage(
      id: 'msg-1',
      text: text,
      senderId: 'user-2',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

Widget buildTile(Channel channel, {VoidCallback? onTap}) {
  return MaterialApp(
    home: Scaffold(
      body: ChannelListTile(
        channel: channel,
        onTap: onTap ?? () {},
      ),
    ),
  );
}

void main() {
  group('ChannelListTile', () {
    testWidgets('renders channel name', (tester) async {
      await tester.pumpWidget(buildTile(makeChannel(name: 'Marketing')));
      expect(find.text('Marketing'), findsOneWidget);
    });

    testWidgets('shows "No messages yet" when no last message', (tester) async {
      await tester.pumpWidget(buildTile(makeChannel(lastMessage: null)));
      expect(find.text('No messages yet'), findsOneWidget);
    });

    testWidgets('shows last message text when present', (tester) async {
      final channel = makeChannel(
        lastMessage: makeLastMessage(text: 'See you tomorrow'),
      );
      await tester.pumpWidget(buildTile(channel));
      expect(find.text('See you tomorrow'), findsOneWidget);
    });

    testWidgets('shows avatar initials from channel name', (tester) async {
      await tester.pumpWidget(buildTile(makeChannel(name: 'Engineering')));
      expect(find.text('E'), findsOneWidget);
    });

    testWidgets('shows unread badge when unreadCount > 0', (tester) async {
      final channel = makeChannel(unreadCount: 5);
      await tester.pumpWidget(buildTile(channel));
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows 99+ when unreadCount > 99', (tester) async {
      final channel = makeChannel(unreadCount: 150);
      await tester.pumpWidget(buildTile(channel));
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('does not show badge when unreadCount is 0', (tester) async {
      final channel = makeChannel(unreadCount: 0);
      await tester.pumpWidget(buildTile(channel));
      expect(find.text('0'), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildTile(
        makeChannel(),
        onTap: () => tapped = true,
      ));
      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });

    testWidgets('shows fallback "?" initial for empty channel name', (tester) async {
      await tester.pumpWidget(buildTile(makeChannel(name: '')));
      expect(find.text('?'), findsOneWidget);
    });
  });
}
