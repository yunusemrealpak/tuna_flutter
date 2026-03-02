import 'package:bloc/bloc.dart';
import 'package:chat_core/chat_core.dart';

import '../../../di/injection.dart';

part 'channel_detail_state.dart';

class ChannelDetailCubit extends Cubit<ChannelDetailState> {
  /// Creates a [ChannelDetailCubit] using the global service locator.
  ChannelDetailCubit() : this.withServiceLocator(sl);

  /// Creates a [ChannelDetailCubit] with a custom [GetIt] instance.
  /// Useful for testing.
  ChannelDetailCubit.withServiceLocator(GetIt serviceLocator)
      : _sl = serviceLocator,
        super(ChannelDetailInitial());

  final GetIt _sl;

  Future<void> load(String channelId, {String? currentUserId}) async {
    emit(ChannelDetailLoading());
    final result = await _sl<ChannelRepository>().getMembers(channelId);
    result.fold(
      (failure) => emit(ChannelDetailError(failure.message)),
      (members) {
        MemberRole? role;
        if (currentUserId != null) {
          final match = members.where((m) => m.userId == currentUserId);
          if (match.isNotEmpty) role = match.first.role;
        }
        emit(ChannelDetailLoaded(
          members: members,
          currentUserRole: role,
          currentUserId: currentUserId,
        ));
      },
    );
  }

  Future<void> removeMember(String channelId, String userId) async {
    if (state is! ChannelDetailLoaded) return;
    final loaded = state as ChannelDetailLoaded;
    final result =
        await _sl<ChannelRepository>().removeMember(channelId, userId);
    result.fold(
      (failure) => emit(ChannelDetailError(failure.message)),
      (_) => emit(
        ChannelDetailLoaded(
          members: loaded.members.where((m) => m.userId != userId).toList(),
          currentUserRole: loaded.currentUserRole,
          currentUserId: loaded.currentUserId,
        ),
      ),
    );
  }

  Future<void> addMember(
    String channelId, {
    required String userId,
    MemberRole role = MemberRole.member,
  }) async {
    if (state is! ChannelDetailLoaded) return;
    final loaded = state as ChannelDetailLoaded;
    final result = await _sl<ChannelRepository>().addMember(
      channelId,
      userId: userId,
      role: role,
    );
    result.fold(
      (failure) => emit(ChannelDetailError(failure.message)),
      (_) => load(channelId, currentUserId: loaded.currentUserId),
    );
  }

  Future<void> deleteChannel(String channelId) async {
    final result = await _sl<ChannelRepository>().deleteChannel(channelId);
    result.fold(
      (failure) => emit(ChannelDetailError(failure.message)),
      (_) => emit(ChannelDetailDeleted()),
    );
  }
}
