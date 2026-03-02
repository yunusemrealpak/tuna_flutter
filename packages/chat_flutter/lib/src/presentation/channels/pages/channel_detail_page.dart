import 'package:chat_core/chat_core.dart';
import 'package:flutter/material.dart';

import '../../../di/injection.dart';
import '../../shared/widgets/user_avatar.dart';

class ChannelDetailPage extends StatefulWidget {
  const ChannelDetailPage({
    super.key,
    required this.channel,
    this.currentUserId,
  });

  final Channel channel;
  final String? currentUserId;

  @override
  State<ChannelDetailPage> createState() => _ChannelDetailPageState();
}

class _ChannelDetailPageState extends State<ChannelDetailPage> {
  List<Membership> _members = [];
  Map<String, User> _userMap = {};
  bool _isLoading = true;
  String? _error;
  MemberRole? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result =
        await sl<ChannelRepository>().getMembers(widget.channel.id);
    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _error = failure.message;
            _isLoading = false;
          });
        }
      },
      (members) async {
        // Determine current user's role
        MemberRole? role;
        if (widget.currentUserId != null) {
          final membership = members.where(
            (m) => m.userId == widget.currentUserId,
          );
          if (membership.isNotEmpty) {
            role = membership.first.role;
          }
        }

        // Load user details for each member
        final userMap = <String, User>{};
        for (final member in members) {
          final userResult =
              await sl<UserRepository>().getUser(member.userId);
          userResult.fold(
            (_) {},
            (user) => userMap[user.id] = user,
          );
        }

        if (mounted) {
          setState(() {
            _members = members;
            _userMap = userMap;
            _currentUserRole = role;
            _isLoading = false;
          });
        }
      },
    );
  }

  bool get _isOwner => _currentUserRole == MemberRole.owner;
  bool get _isAdmin =>
      _currentUserRole == MemberRole.admin ||
      _currentUserRole == MemberRole.owner;

  Future<void> _removeMember(String userId) async {
    final result = await sl<ChannelRepository>().removeMember(
      widget.channel.id,
      userId,
    );
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) => _loadMembers(),
    );
  }

  Future<void> _deleteChannel() async {
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

    if (confirm != true) return;

    final result =
        await sl<ChannelRepository>().deleteChannel(widget.channel.id);
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        // Pop back to channel list
        Navigator.of(context)
          ..pop() // pop detail
          ..pop(); // pop message list
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channel.name),
        actions: [
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Channel',
              onPressed: _deleteChannel,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMembers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    // Channel info section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.channel.description != null) ...[
                            Text(
                              widget.channel.description!,
                              style:
                                  Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            '${widget.channel.memberCount} members',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Divider(),

                    // Members header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
                          if (_isAdmin)
                            TextButton.icon(
                              icon: const Icon(Icons.person_add),
                              label: const Text('Add'),
                              onPressed: () {
                                // Add member flow could be implemented here
                              },
                            ),
                        ],
                      ),
                    ),

                    // Members list
                    ..._members.map((membership) {
                      final user = _userMap[membership.userId];
                      final isCurrentUser =
                          membership.userId == widget.currentUserId;
                      return ListTile(
                        leading: user != null
                            ? UserAvatar(
                                user: user,
                                size: 40,
                                showPresence: false,
                              )
                            : const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                        title: Text(
                          user?.displayName ?? membership.userId,
                        ),
                        subtitle: Text(_roleLabel(membership.role)),
                        trailing: _isAdmin &&
                                !isCurrentUser &&
                                membership.role != MemberRole.owner
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.red,
                                tooltip: 'Remove member',
                                onPressed: () =>
                                    _removeMember(membership.userId),
                              )
                            : null,
                      );
                    }),
                  ],
                ),
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
