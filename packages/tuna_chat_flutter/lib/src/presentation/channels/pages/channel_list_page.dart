import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/channel_list_bloc.dart';
import '../widgets/channel_list_tile.dart';
import 'create_channel_page.dart';
import '../../messages/pages/message_list_page.dart';

class ChannelListPage extends StatefulWidget {
  const ChannelListPage({super.key, this.currentUserId});

  /// The currently connected user's ID. Used to render own messages on the right.
  final String? currentUserId;

  @override
  State<ChannelListPage> createState() => _ChannelListPageState();
}

class _ChannelListPageState extends State<ChannelListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ChannelListBloc>().add(ChannelListLoadRequested());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ChannelListBloc>().add(ChannelListLoadMoreRequested());
    }
  }

  Future<void> _onRefresh() async {
    final completer = Completer<void>();
    final subscription = context.read<ChannelListBloc>().stream.listen((state) {
      if (state is ChannelListLoaded || state is ChannelListError) {
        if (!completer.isCompleted) completer.complete();
      }
    });
    context.read<ChannelListBloc>().add(ChannelListRefreshRequested());
    await completer.future;
    await subscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Channels'),
      ),
      body: BlocBuilder<ChannelListBloc, ChannelListState>(
        builder: (context, state) {
          if (state is ChannelListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChannelListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<ChannelListBloc>()
                          .add(ChannelListLoadRequested());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ChannelListLoaded) {
            if (state.channels.isEmpty) {
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView(
                  children: const [
                    SizedBox(height: 200),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No channels yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Create a channel to get started',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                controller: _scrollController,
                itemCount:
                    state.channels.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.channels.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final channel = state.channels[index];
                  return ChannelListTile(
                    channel: channel,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MessageListPage(
                            channelId: channel.id,
                            channelName: channel.name,
                            currentUserId: widget.currentUserId,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateChannelPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
