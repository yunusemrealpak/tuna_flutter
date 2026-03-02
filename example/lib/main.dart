import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tuna_chat_flutter/tuna_chat_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize TunaChat SDK with your app's API key.
  // Replace these values with real credentials from your TunaChat dashboard.
  await TunaChatSDK.init(
    config: const TunaChatConfig(
      apiKey: 'tuna_key_your_api_key_here',
      baseUrl: 'http://10.0.2.2:8080/api/v1',
      wsUrl: 'ws://10.0.2.2:8080/api/v1/ws',
    ),
  );

  runApp(const TunaChatExampleApp());
}

class TunaChatExampleApp extends StatelessWidget {
  const TunaChatExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // ConnectionBloc: manages TunaChat user lifecycle.
        BlocProvider<ConnectionBloc>(create: (_) => ConnectionBloc()),
        // ConnectivityCubit: monitors network state.
        BlocProvider<ConnectivityCubit>(create: (_) => ConnectivityCubit()),
      ],
      child: MaterialApp(
        title: 'TunaChat SDK Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const _AppRoot(),
      ),
    );
  }
}

/// Root widget that switches between ConnectPage and ChannelListPage
/// based on connection state.
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectionBloc, ConnectionState>(
      listener: (context, state) {
        // Wire EventHandler after successful connection.
        // TunaChatSDK.instance handles this automatically when connectUser is called.
      },
      child: BlocBuilder<ConnectionBloc, ConnectionState>(
        builder: (context, state) {
          if (state is ConnectionConnected) {
            return BlocProvider<ChannelListBloc>(
              create: (_) => ChannelListBloc(),
              child: ChannelListPage(currentUserId: state.user.id),
            );
          }

          // Show ConnectPage when not yet connected.
          return const ConnectPage();
        },
      ),
    );
  }
}
