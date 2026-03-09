import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tuna_chat_flutter/tuna_chat_flutter.dart';

// TunaChat SDK — Host App Simulation Example
//
// This example simulates how a real host app integrates the TunaChat SDK:
//   1. Host app authenticates the user with its own backend.
//   2. Host backend issues a JWT signed with the TunaChat api_secret.
//   3. Host app calls TunaChatSDK.instance.connectUser(userId, token).
//   4. TunaChat SDK validates the JWT and opens a WebSocket connection.
//
// ─────────────────────────────────────────────────────────────────────────────
// CONFIGURATION — update these values before running:
// ─────────────────────────────────────────────────────────────────────────────
// API key from your TunaChat app (created via POST /apps):
const _kApiKey = 'tuna_key_your_api_key_here';
//
// REST base URL for the TunaChat backend:
//   Android emulator → 'http://10.0.2.2:8080/api/v1'   ← default below
//   iOS simulator    → 'http://127.0.0.1:8080/api/v1'
//   macOS / Linux    → 'http://localhost:8080/api/v1'
//   Physical device  → 'http://<your-lan-ip>:8080/api/v1'
const _kBaseUrl = 'http://10.0.2.2:8080/api/v1';
const _kWsUrl = 'ws://10.0.2.2:8080/api/v1/ws';
// ─────────────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TunaChatSDK.init(
    config: const TunaChatConfig(
      apiKey: _kApiKey,
      baseUrl: _kBaseUrl,
      wsUrl: _kWsUrl,
      // In a real app, implement tokenProvider to fetch a fresh JWT from
      // your backend whenever the current one expires:
      //
      // tokenProvider: () async {
      //   final userId = myAuthService.currentUserId;
      //   return await myBackend.fetchChatToken(userId);
      // },
    ),
  );

  runApp(const _HostAppSimulation());
}

class _HostAppSimulation extends StatelessWidget {
  const _HostAppSimulation();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ConnectionBloc>(create: (_) => ConnectionBloc()),
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

/// Root widget: shows [_DemoLoginPage] until connected, then [_ChatShell].
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionBloc, ConnectionState>(
      builder: (context, state) {
        if (state is ConnectionConnected) {
          return BlocProvider<ChannelListBloc>(
            create: (_) => ChannelListBloc(),
            child: _ChatShell(user: state.user),
          );
        }
        return const _DemoLoginPage();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Demo Login Page
//
// Simulates the host app's own login screen. In a real integration this page
// would call your own backend, authenticate the user, and receive a JWT signed
// with your TunaChat api_secret.
// ─────────────────────────────────────────────────────────────────────────────
class _DemoLoginPage extends StatefulWidget {
  const _DemoLoginPage();

  @override
  State<_DemoLoginPage> createState() => _DemoLoginPageState();
}

class _DemoLoginPageState extends State<_DemoLoginPage> {
  final _userIdCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Demo preset users for easy testing.
  static const _presets = [
    _Preset(label: 'Alice', userId: 'alice', hint: 'Use user ID: alice'),
    _Preset(label: 'Bob', userId: 'bob', hint: 'Use user ID: bob'),
    _Preset(label: 'Custom', userId: '', hint: 'Enter custom credentials'),
  ];

  void _applyPreset(_Preset preset) {
    setState(() {
      _userIdCtrl.text = preset.userId;
      _tokenCtrl.text = '';
    });
  }

  void _onSignIn() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ConnectionBloc>().add(
      ConnectUserRequested(
        userId: _userIdCtrl.text.trim(),
        token: _tokenCtrl.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: BlocListener<ConnectionBloc, ConnectionState>(
        listener: (context, state) {
          if (state is ConnectionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: BlocBuilder<ConnectionBloc, ConnectionState>(
                    builder: (context, state) {
                      final isLoading = state is ConnectionConnecting;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          Icon(
                            Icons.chat_bubble_rounded,
                            size: 56,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'TunaChat SDK Demo',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Host App Simulation',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 32),

                          // Info card explaining the flow
                          Card(
                            color: colorScheme.surfaceContainerHighest,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'How it works',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(color: colorScheme.primary),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '1. Your backend authenticates the user\n'
                                    '2. Your backend signs a JWT with your api_secret\n'
                                    '3. Pass the userId + JWT to connectUser()',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Quick preset selector
                          Text(
                            'Quick presets',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _presets.map((p) {
                              return ActionChip(
                                label: Text(p.label),
                                onPressed: isLoading
                                    ? null
                                    : () => _applyPreset(p),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 20),

                          // User ID field
                          TextFormField(
                            controller: _userIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'User ID',
                              hintText: 'e.g. alice',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            enabled: !isLoading,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // JWT token field
                          TextFormField(
                            controller: _tokenCtrl,
                            decoration: const InputDecoration(
                              labelText: 'JWT Token',
                              hintText: 'HMAC-SHA256 signed by your backend',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.key_outlined),
                              helperText:
                                  'Generate via: POST /server/users + sign JWT with api_secret',
                              helperMaxLines: 2,
                            ),
                            maxLines: 3,
                            enabled: !isLoading,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),

                          const SizedBox(height: 24),

                          FilledButton.icon(
                            onPressed: isLoading ? null : _onSignIn,
                            icon: isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: Text(
                              isLoading
                                  ? 'Connecting…'
                                  : 'Sign in with TunaChat',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Preset {
  const _Preset({
    required this.label,
    required this.userId,
    required this.hint,
  });
  final String label;
  final String userId;
  final String hint;
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat Shell — shown after successful connection
//
// Wraps ChannelListPage with a bottom navigation area showing the connected
// user and a disconnect option (simulating the host app's logout flow).
// ─────────────────────────────────────────────────────────────────────────────
class _ChatShell extends StatelessWidget {
  const _ChatShell({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    // ChannelListPage is the main SDK UI entry point. It provides:
    //   • Scrollable channel list with pull-to-refresh and infinite scroll
    //   • FAB to create new channels (group / direct / public)
    //   • Tap to open MessageListPage which has:
    //       - Real-time messaging via WebSocket
    //       - Emoji reactions (long-press to pick)
    //       - Thread replies
    //       - File attachments (images + files)
    //       - Message search (magnifier icon in AppBar)
    //       - Typing indicator and read receipts
    return ChannelListPage(currentUserId: user.id);
  }
}
