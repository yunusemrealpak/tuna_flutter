import 'package:chat_core/chat_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../di/injection.dart';
import '../bloc/channel_detail_cubit.dart';

class ChannelDetailPage extends StatelessWidget {
  const ChannelDetailPage({
    super.key,
    required this.channel,
    this.currentUserId,
  });

  final Channel channel;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChannelDetailCubit()
        ..load(channel.id, currentUserId: currentUserId),
      child: _ChannelDetailView(channel: channel),
    );
  }
}

class _ChannelDetailView extends StatelessWidget {
  const _ChannelDetailView({required this.channel});

  final Channel channel;

  Future<void> _showAddMemberDialog(
    BuildContext context,
    ChannelDetailCubit cubit,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AddMemberDialog(
        onAdd: (user) => cubit.addMember(channel.id, userId: user.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChannelDetailCubit, ChannelDetailState>(
      listener: (context, state) {
        if (state is ChannelDetailDeleted) {
          // Pop detail + message list pages.
          Navigator.of(context)
            ..pop()
            ..pop();
        } else if (state is ChannelDetailError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
          // Reload to recover from transient errors.
          context.read<ChannelDetailCubit>().load(
                channel.id,
                currentUserId: (context.read<ChannelDetailCubit>().state
                        is ChannelDetailLoaded)
                    ? (context.read<ChannelDetailCubit>().state
                            as ChannelDetailLoaded)
                        .currentUserId
                    : null,
              );
        }
      },
      builder: (context, state) {
        final cubit = context.read<ChannelDetailCubit>();

        return Scaffold(
          appBar: AppBar(
            title: Text(channel.name),
            actions: [
              if (state is ChannelDetailLoaded && state.isOwner)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete Channel',
                  onPressed: () => _confirmDelete(context, cubit),
                ),
            ],
          ),
          body: switch (state) {
            ChannelDetailLoading() =>
              const Center(child: CircularProgressIndicator()),
            ChannelDetailError() => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => cubit.load(channel.id),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ChannelDetailLoaded() => _MemberList(
                channel: channel,
                state: state,
                cubit: cubit,
                onAddMember: () =>
                    _showAddMemberDialog(context, cubit),
              ),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ChannelDetailCubit cubit,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Channel'),
        content: const Text(
          'Are you sure you want to delete this channel? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      cubit.deleteChannel(channel.id);
    }
  }
}

class _MemberList extends StatelessWidget {
  const _MemberList({
    required this.channel,
    required this.state,
    required this.cubit,
    required this.onAddMember,
  });

  final Channel channel;
  final ChannelDetailLoaded state;
  final ChannelDetailCubit cubit;
  final VoidCallback onAddMember;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Channel info section
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (channel.description != null) ...[
                Text(
                  channel.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
              ],
              Text(
                '${channel.memberCount} members',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Divider(),

        // Members header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Members',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (state.isAdmin)
                TextButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add'),
                  onPressed: onAddMember,
                ),
            ],
          ),
        ),

        // Members list — uses fields returned by /channels/:id/members (R-M4-004).
        ...state.members.map((membership) {
          final isCurrentUser = membership.userId == state.currentUserId;
          final displayLabel =
              membership.displayName ?? membership.username ?? membership.userId;
          return ListTile(
            leading: _MemberAvatar(membership: membership),
            title: Text(displayLabel),
            subtitle: Text(_roleLabel(membership.role)),
            trailing: state.isAdmin &&
                    !isCurrentUser &&
                    membership.role != MemberRole.owner
                ? IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red,
                    tooltip: 'Remove member',
                    onPressed: () =>
                        cubit.removeMember(channel.id, membership.userId),
                  )
                : null,
          );
        }),
      ],
    );
  }

  String _roleLabel(MemberRole role) {
    switch (role) {
      case MemberRole.owner:
        return 'Owner';
      case MemberRole.admin:
        return 'Admin';
      case MemberRole.member:
        return 'Member';
    }
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context) {
    final initial = (membership.displayName ?? membership.username ?? '?')
        .substring(0, 1)
        .toUpperCase();
    if (membership.avatarUrl != null) {
      return CircleAvatar(
        backgroundImage: NetworkImage(membership.avatarUrl!),
        onBackgroundImageError: (e, stackTrace) {},
      );
    }
    return CircleAvatar(child: Text(initial));
  }
}

/// A dialog that searches for users and lets the caller add one to a channel.
class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog({required this.onAdd});

  final Future<void> Function(User user) onAdd;

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _controller = TextEditingController();
  List<User> _results = [];
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _error = null;
    });
    final result = await sl<UserRepository>().searchUsers(query.trim());
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _isSearching = false;
        _error = failure.message;
      }),
      (users) => setState(() {
        _isSearching = false;
        _results = users;
      }),
    );
  }

  Future<void> _select(User user) async {
    await widget.onAdd(user);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Member'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Search users',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 8),
            if (_isSearching)
              const CircularProgressIndicator()
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else if (_results.isEmpty && _controller.text.length >= 2)
              const Text('No users found')
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final user = _results[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          user.displayName.substring(0, 1).toUpperCase(),
                        ),
                      ),
                      title: Text(user.displayName),
                      subtitle: Text('@${user.username}'),
                      onTap: () => _select(user),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
