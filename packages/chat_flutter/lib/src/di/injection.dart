import 'package:get_it/get_it.dart';

import '../chat_sdk.dart';

final GetIt sl = GetIt.instance;

/// Registers all dependencies in the correct order:
/// Core → DataSources → Repositories → UseCases → BLoCs
Future<void> registerDependencies(ChatConfig config) async {
  // TODO(T111): implement full DI registration
}

Future<void> tearDownDependencies() async {
  await sl.reset();
}
