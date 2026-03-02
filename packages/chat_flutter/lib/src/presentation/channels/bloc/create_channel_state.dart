part of 'create_channel_bloc.dart';

class CreateChannelState {
  final List<User> searchResults;
  final List<User> selectedMembers;
  final bool isSearching;
  final bool isSubmitting;
  final Channel? createdChannel;
  final String? error;

  const CreateChannelState({
    this.searchResults = const [],
    this.selectedMembers = const [],
    this.isSearching = false,
    this.isSubmitting = false,
    this.createdChannel,
    this.error,
  });

  CreateChannelState copyWith({
    List<User>? searchResults,
    List<User>? selectedMembers,
    bool? isSearching,
    bool? isSubmitting,
    Channel? createdChannel,
    String? error,
    bool clearCreatedChannel = false,
    bool clearError = false,
  }) {
    return CreateChannelState(
      searchResults: searchResults ?? this.searchResults,
      selectedMembers: selectedMembers ?? this.selectedMembers,
      isSearching: isSearching ?? this.isSearching,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      createdChannel: clearCreatedChannel ? null : (createdChannel ?? this.createdChannel),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
