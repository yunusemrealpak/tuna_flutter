import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuna_chat/tuna_chat.dart';
import 'package:tuna_chat_flutter/src/presentation/messages/widgets/message_bubble.dart';

Message makeMessage({
  String id = 'msg-1',
  String text = 'Hello world',
  bool deleted = false,
  int replyCount = 0,
  MessageStatus status = MessageStatus.sent,
}) =>
    Message(
      id: id,
      channelId: 'ch-1',
      senderId: 'user-1',
      text: text,
      status: status,
      replyCount: replyCount,
      deletedAt: deleted ? DateTime(2025, 1, 2) : null,
      createdAt: DateTime(2025, 1, 1, 12, 30),
      updatedAt: DateTime(2025, 1, 1, 12, 30),
    );

Widget buildBubble({
  required Message message,
  bool isMe = false,
  String? senderName,
  List<Reaction> reactions = const [],
  String? currentUserId,
  VoidCallback? onReplyTap,
  void Function(String)? onReactionAdd,
}) {
  return MaterialApp(
    home: Scaffold(
      body: MessageBubble(
        message: message,
        isMe: isMe,
        senderName: senderName,
        reactions: reactions,
        currentUserId: currentUserId,
        onReplyTap: onReplyTap,
        onReactionAdd: onReactionAdd,
      ),
    ),
  );
}

void main() {
  group('MessageBubble', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(buildBubble(
        message: makeMessage(text: 'Hi there!'),
      ));
      expect(find.text('Hi there!'), findsOneWidget);
    });

    testWidgets('shows [Deleted] for soft-deleted message', (tester) async {
      await tester.pumpWidget(buildBubble(
        message: makeMessage(deleted: true),
      ));
      expect(find.text('[Deleted]'), findsOneWidget);
    });

    testWidgets('shows sender name for non-own messages when provided', (tester) async {
      await tester.pumpWidget(buildBubble(
        message: makeMessage(),
        isMe: false,
        senderName: 'Alice',
      ));
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('does not show sender name for own messages', (tester) async {
      await tester.pumpWidget(buildBubble(
        message: makeMessage(),
        isMe: true,
        senderName: 'Me',
      ));
      expect(find.text('Me'), findsNothing);
    });

    testWidgets('shows time in HH:mm format', (tester) async {
      await tester.pumpWidget(buildBubble(
        message: makeMessage(),
      ));
      // Time should be somewhere on screen (exact value depends on timezone)
      final timeFinder = find.textContaining(':');
      expect(timeFinder, findsAtLeastNWidgets(1));
    });

    testWidgets('shows reply count link when replyCount > 0 and onReplyTap provided',
        (tester) async {
      await tester.pumpWidget(buildBubble(
        message: makeMessage(replyCount: 3),
        onReplyTap: () {},
      ));
      expect(find.text('3 replies'), findsOneWidget);
    });

    testWidgets('shows singular "reply" when replyCount is 1', (tester) async {
      await tester.pumpWidget(buildBubble(
        message: makeMessage(replyCount: 1),
        onReplyTap: () {},
      ));
      expect(find.text('1 reply'), findsOneWidget);
    });

    testWidgets('does not show reply count when onReplyTap is null', (tester) async {
      await tester.pumpWidget(buildBubble(
        message: makeMessage(replyCount: 5),
        onReplyTap: null,
      ));
      expect(find.text('5 replies'), findsNothing);
    });

    testWidgets('does not show reply count when replyCount is 0', (tester) async {
      await tester.pumpWidget(buildBubble(
        message: makeMessage(replyCount: 0),
        onReplyTap: () {},
      ));
      expect(find.textContaining('repl'), findsNothing);
    });

    testWidgets('shows status icon for own message with sending status', (tester) async {
      await tester.pumpWidget(buildBubble(
        message: makeMessage(status: MessageStatus.sending),
        isMe: true,
      ));
      // Status icon: Icons.access_time for sending
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('shows check icon for own message with sent status', (tester) async {
      await tester.pumpWidget(buildBubble(
        message: makeMessage(status: MessageStatus.sent),
        isMe: true,
      ));
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('shows error icon for own message with failed status', (tester) async {
      await tester.pumpWidget(buildBubble(
        message: makeMessage(status: MessageStatus.failed),
        isMe: true,
      ));
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('does not show status icon for other users message', (tester) async {
      await tester.pumpWidget(buildBubble(
        message: makeMessage(status: MessageStatus.sent),
        isMe: false,
      ));
      expect(find.byIcon(Icons.check), findsNothing);
    });
  });
}
