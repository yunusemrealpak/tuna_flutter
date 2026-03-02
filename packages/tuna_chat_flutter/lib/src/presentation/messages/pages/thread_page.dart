import 'dart:async';

import 'package:tuna_chat/tuna_chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../di/injection.dart';
import '../bloc/message_list_bloc.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';

/// Displays thread replies for [parentMessage].
///
/// The parent message is pinned at the top. Replies are listed below. The
/// input field sends replies with [parentId] set to the parent message ID.
class ThreadPage extends StatefulWidget {
  const ThreadPage({
    super.key,
    required this.channelId,
    required this.parentMessage,
    this.currentUserId,
  });

  final String channelId;
  final Message parentMessage;
  final String? currentUserId;

  @override
  State<ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  final _scrollController = ScrollController();
  StreamSubscription<ChatEvent>? _wsSubscription;
  late final MessageListBloc _threadBloc;

  @override
  void initState() {
    super.initState();
    _threadBloc = MessageListBloc();
    _threadBloc.add(MessageListThreadLoadRequested(
      channelId: widget.channelId,
      parentId: widget.parentMessage.id,
    ));
    _subscribeToWsEvents();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _scrollController.dispose();
    _threadBloc.close();
    super.dispose();
  }

  void _subscribeToWsEvents() {
    _wsSubscription = sl<WsClient>().events.listen((event) {
      if (event.channelId != widget.channelId) return;

      switch (event.type) {
        case WsEventType.messageNew:
          try {
            final message = Message.fromJson(
              event.data['message'] as Map<String, dynamic>,
            );
            // Only accept replies to this thread.
            if (message.parentId == widget.parentMessage.id) {
              _threadBloc.add(MessageListMessageReceived(message));
              _scrollToBottom();
            }
          } catch (_) {}
        case WsEventType.messageDeleted:
          final messageId = event.data['id'] as String?;
          if (messageId != null) {
            _threadBloc.add(MessageListMessageDeleted(messageId));
          }
        case WsEventType.reactionNew:
          final messageId = event.data['message_id'] as String?;
          final userId = event.data['user_id'] as String?;
          final type = event.data['type'] as String?;
          if (messageId != null && userId != null && type != null) {
            _threadBloc.add(MessageListReactionAdded(
              messageId: messageId,
              userId: userId,
              type: type,
            ));
          }
        case WsEventType.reactionDeleted:
          final messageId = event.data['message_id'] as String?;
          final userId = event.data['user_id'] as String?;
          final type = event.data['type'] as String?;
          if (messageId != null && userId != null && type != null) {
            _threadBloc.add(MessageListReactionRemoved(
              messageId: messageId,
              userId: userId,
              type: type,
            ));
          }
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _threadBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thread'),
        ),
        body: Column(
          children: [
            // ── Pinned parent message ──────────────────────────────────────
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Original message',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ),
                    MessageBubble(
                      message: widget.parentMessage,
                      isMe: widget.currentUserId != null &&
                          widget.parentMessage.senderId ==
                              widget.currentUserId,
                      reactions: const [],
                      currentUserId: widget.currentUserId,
                    ),
                    const Divider(height: 1),
                  ],
                ),
              ),
            ),
            // ── Thread replies ──────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<MessageListBloc, MessageListState>(
                builder: (context, state) {
                  if (state is MessageListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is MessageListLoaded) {
                    if (state.messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'No replies yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final msgIndex = state.messages.length - 1 - index;
                        final message = state.messages[msgIndex];
                        final isMe = widget.currentUserId != null &&
                            message.senderId == widget.currentUserId;
                        final reactions =
                            state.reactions[message.id] ?? const [];

                        return MessageBubble(
                          key: ValueKey(message.id),
                          message: message,
                          isMe: isMe,
                          reactions: reactions,
                          currentUserId: widget.currentUserId,
                          onReactionAdd: (type) {
                            try {
                              sl<ReactionRepository>().addReaction(
                                widget.channelId,
                                message.id,
                                type: type,
                              );
                            } catch (_) {}
                          },
                          onReactionRemove: (type) {
                            try {
                              sl<ReactionRepository>().removeReaction(
                                widget.channelId,
                                message.id,
                                type,
                              );
                            } catch (_) {}
                          },
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
            // ── Reply input ────────────────────────────────────────────────
            BlocBuilder<MessageListBloc, MessageListState>(
              builder: (context, state) {
                final isSending = state is MessageListLoaded && state.isSending;
                return MessageInput(
                  channelId: widget.channelId,
                  isSending: isSending,
                  hintText: 'Reply in thread…',
                  onSend: (text) {
                    _threadBloc.add(MessageListSendRequested(
                      channelId: widget.channelId,
                      text: text,
                      parentId: widget.parentMessage.id,
                    ));
                    _scrollToBottom();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
