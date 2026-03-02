import 'dart:async';

import 'package:chat_core/chat_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../di/injection.dart';
import '../bloc/message_list_bloc.dart';
import '../bloc/typing_bloc.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/typing_indicator.dart';

class MessageListPage extends StatefulWidget {
  const MessageListPage({
    super.key,
    required this.channelId,
    required this.channelName,
    this.currentUserId,
  });

  final String channelId;
  final String channelName;
  final String? currentUserId;

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  final _scrollController = ScrollController();
  StreamSubscription<ChatEvent>? _wsSubscription;
  late final MessageListBloc _messageBloc;
  late final TypingBloc _typingBloc;

  @override
  void initState() {
    super.initState();
    _messageBloc = MessageListBloc();
    _typingBloc = TypingBloc(channelId: widget.channelId);
    _messageBloc.add(MessageListLoadRequested(widget.channelId));
    _scrollController.addListener(_onScroll);
    _subscribeToWsEvents();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _scrollController.dispose();
    _messageBloc.close();
    _typingBloc.close();
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
            _messageBloc.add(MessageListMessageReceived(message));
            _scrollToBottomIfNear();
          } catch (_) {}
        case WsEventType.messageUpdated:
          try {
            final message = Message.fromJson(
              event.data['message'] as Map<String, dynamic>,
            );
            _messageBloc.add(MessageListMessageUpdated(message));
          } catch (_) {}
        case WsEventType.messageDeleted:
          // R-M4-001: backend emits {id, channel_id} — not message_id.
          final messageId = event.data['id'] as String?;
          if (messageId != null) {
            _messageBloc.add(MessageListMessageDeleted(messageId));
          }
        case WsEventType.userTypingStart:
          final userId = event.data['user_id'] as String?;
          final username = event.data['username'] as String?;
          if (userId != null && username != null) {
            _typingBloc.add(TypingUsersUpdated(
              channelId: widget.channelId,
              userId: userId,
              username: username,
              isTyping: true,
            ));
          }
        case WsEventType.userTypingStop:
          // R-M4-002: typing_stop payload is {channel_id, user_id} — no username.
          final userId = event.data['user_id'] as String?;
          if (userId != null) {
            _typingBloc.add(TypingUsersUpdated(
              channelId: widget.channelId,
              userId: userId,
              isTyping: false,
            ));
          }
      }
    });
  }

  void _onScroll() {
    // Load older messages when user scrolls to top of reversed list
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _messageBloc.add(MessageListLoadOlderRequested());
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    return _scrollController.position.pixels < 200;
  }

  void _scrollToBottomIfNear() {
    if (_isNearBottom()) {
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
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _messageBloc),
        BlocProvider.value(value: _typingBloc),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.channelName),
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocConsumer<MessageListBloc, MessageListState>(
                listener: (context, state) {
                  // Scroll to bottom on initial load
                  if (state is MessageListLoaded &&
                      state.messages.isNotEmpty) {
                    _scrollToBottom();
                  }
                },
                builder: (context, state) {
                  if (state is MessageListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is MessageListError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(state.message, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _messageBloc.add(
                              MessageListLoadRequested(widget.channelId),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is MessageListLoaded) {
                    if (state.messages.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            Text(
                              'Be the first to say something!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: state.messages.length +
                          (state.hasOlder ? 1 : 0),
                      itemBuilder: (context, index) {
                        // The loading indicator at the top (end in reversed list)
                        if (index == state.messages.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        // Reversed order: newest messages at index 0
                        final messageIndex =
                            state.messages.length - 1 - index;
                        final message = state.messages[messageIndex];
                        final isMe = widget.currentUserId != null &&
                            message.senderId == widget.currentUserId;

                        return MessageBubble(
                          key: ValueKey(message.id),
                          message: message,
                          isMe: isMe,
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
            BlocBuilder<TypingBloc, TypingState>(
              builder: (context, typingState) {
                return TypingIndicator(
                  typingUsernames: typingState.typingUsernames,
                );
              },
            ),
            BlocBuilder<MessageListBloc, MessageListState>(
              builder: (context, state) {
                final isSending =
                    state is MessageListLoaded && state.isSending;
                return MessageInput(
                  channelId: widget.channelId,
                  isSending: isSending,
                  onSend: (text) {
                    _messageBloc.add(MessageListSendRequested(
                      channelId: widget.channelId,
                      text: text,
                    ));
                    _scrollToBottom();
                  },
                  onTypingChanged: (isTyping) {
                    if (isTyping) {
                      _typingBloc.add(TypingStarted(widget.channelId));
                    } else {
                      _typingBloc.add(TypingStopped(widget.channelId));
                    }
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
