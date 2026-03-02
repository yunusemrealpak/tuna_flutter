import 'package:bloc/bloc.dart';
import 'package:tuna_chat/tuna_chat.dart';

import '../../../di/injection.dart';

part 'create_channel_event.dart';
part 'create_channel_state.dart';

class CreateChannelBloc extends Bloc<CreateChannelEvent, CreateChannelState> {
  /// Creates a [CreateChannelBloc] using the global service locator.
  CreateChannelBloc() : this.withServiceLocator(sl);

  /// Creates a [CreateChannelBloc] with a custom [GetIt] instance.
  /// Useful for testing.
  CreateChannelBloc.withServiceLocator(GetIt serviceLocator)
      : _sl = serviceLocator,
        super(const CreateChannelState()) {
    on<CreateChannelSearchUsers>(_onSearchUsers);
    on<CreateChannelToggleMember>(_onToggleMember);
    on<CreateChannelSubmitted>(_onSubmit);
  }

  final GetIt _sl;

  Future<void> _onSearchUsers(
    CreateChannelSearchUsers event,
    Emitter<CreateChannelState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(state.copyWith(searchResults: [], clearError: true));
      return;
    }

    emit(state.copyWith(isSearching: true, clearError: true));
    final result =
        await _sl<UserRepository>().searchUsers(event.query.trim());
    result.fold(
      (failure) => emit(state.copyWith(
        isSearching: false,
        error: failure.message,
      )),
      (users) => emit(state.copyWith(
        isSearching: false,
        searchResults: users,
      )),
    );
  }

  Future<void> _onToggleMember(
    CreateChannelToggleMember event,
    Emitter<CreateChannelState> emit,
  ) async {
    final selected = List<User>.from(state.selectedMembers);
    final exists = selected.any((u) => u.id == event.user.id);
    if (exists) {
      selected.removeWhere((u) => u.id == event.user.id);
    } else {
      selected.add(event.user);
    }
    emit(state.copyWith(selectedMembers: selected));
  }

  Future<void> _onSubmit(
    CreateChannelSubmitted event,
    Emitter<CreateChannelState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    final memberIds = state.selectedMembers.map((u) => u.id).toList();

    final result = await _sl<ChannelRepository>().createChannel(
      type: event.type,
      name: event.name,
      description: event.description,
      memberIds: memberIds,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isSubmitting: false,
        error: failure.message,
      )),
      (channel) => emit(state.copyWith(
        isSubmitting: false,
        createdChannel: channel,
      )),
    );
  }
}
