import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_flutter/chat_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ChatSDK.initialize(
    const ChatConfig(
      apiBaseUrl: 'http://localhost:8080/api/v1',
      wsUrl: 'ws://localhost:8080/api/v1/ws',
    ),
  );

  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // AuthBloc and ConnectivityCubit are app-wide — provided above MaterialApp
        // so all routes (including named routes) inherit them.
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc()..add(AuthCheckStatusRequested()),
        ),
        BlocProvider<ConnectivityCubit>(
          create: (_) => ConnectivityCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'Chat SDK Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        // LoginPage is the entry point; it navigates to /channels on auth.
        home: const LoginPage(),
        routes: {
          '/channels': (context) => BlocProvider<ChannelListBloc>(
                create: (_) => ChannelListBloc(),
                child: const ChannelListPage(),
              ),
        },
      ),
    );
  }
}
