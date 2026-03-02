import 'package:chat_core/chat_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/create_channel_bloc.dart';
import '../../messages/pages/message_list_page.dart';

class CreateChannelPage extends StatefulWidget {
  const CreateChannelPage({super.key});

  @override
  State<CreateChannelPage> createState() => _CreateChannelPageState();
}

class _CreateChannelPageState extends State<CreateChannelPage> {
  late final CreateChannelBloc _bloc;
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  ChannelType _selectedType = ChannelType.group;

  @override
  void initState() {
    super.initState();
    _bloc = CreateChannelBloc();
  }

  @override
  void dispose() {
    _bloc.close();
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (_selectedType != ChannelType.direct && name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Channel name is required')),
      );
      return;
    }
    _bloc.add(CreateChannelSubmitted(
      type: _selectedType,
      name: name.isNotEmpty ? name : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<CreateChannelBloc, CreateChannelState>(
        listener: (context, state) {
          if (state.createdChannel != null) {
            final channel = state.createdChannel!;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MessageListPage(
                  channelId: channel.id,
                  channelName: channel.name,
                ),
              ),
            );
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('New Channel'),
              actions: [
                TextButton(
                  onPressed: state.isSubmitting ? null : _submit,
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Channel type selector
                const Text(
                  'Channel Type',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SegmentedButton<ChannelType>(
                  segments: const [
                    ButtonSegment(
                      value: ChannelType.direct,
                      label: Text('Direct'),
                      icon: Icon(Icons.person),
                    ),
                    ButtonSegment(
                      value: ChannelType.group,
                      label: Text('Group'),
                      icon: Icon(Icons.group),
                    ),
                    ButtonSegment(
                      value: ChannelType.public,
                      label: Text('Public'),
                      icon: Icon(Icons.public),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedType = selection.first);
                  },
                ),
                const SizedBox(height: 16),

                // Name field (not for direct)
                if (_selectedType != ChannelType.direct) ...[
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Channel Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // User search
                const Text(
                  'Add Members',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search users...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (query) {
                    _bloc.add(CreateChannelSearchUsers(query));
                  },
                ),
                const SizedBox(height: 8),

                // Selected members chips
                if (state.selectedMembers.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: state.selectedMembers.map((user) {
                      return Chip(
                        label: Text(user.displayName),
                        avatar: CircleAvatar(
                          child: Text(user.displayName[0].toUpperCase()),
                        ),
                        onDeleted: () {
                          _bloc.add(CreateChannelToggleMember(user));
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],

                // Search results
                if (state.isSearching)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state.searchResults.isNotEmpty)
                  ...state.searchResults.map((user) {
                    final isSelected =
                        state.selectedMembers.any((u) => u.id == user.id);
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.displayName[0].toUpperCase()),
                      ),
                      title: Text(user.displayName),
                      subtitle: Text('@${user.username}'),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.circle_outlined),
                      onTap: () {
                        _bloc.add(CreateChannelToggleMember(user));
                      },
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
