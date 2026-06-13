import 'package:Audioverse/features/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:Audioverse/core/router/app_router.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/core/network/network.dart';
import 'package:Audioverse/features/auth/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final tokenStorage = TokenStorage();
  final dioClient    = DioClient(tokenStorage: tokenStorage);

  final authRepo    = AuthRepositoryImpl(
    dio:          dioClient.dio,
    tokenStorage: tokenStorage,
  );
  final profileRepo = ProfileRepositoryImpl(dio: dioClient.dio);

  final authProvider    = AuthProvider(repository: authRepo);
  final profileProvider = ProfileProvider(repository: profileRepo);

  // Restore session before the app renders anything
  // await authProvider.restoreSession();

  runApp(AudioVerseApp(
    authProvider:    authProvider,
    profileProvider: profileProvider,
  ));
}

class AudioVerseApp extends StatefulWidget {
  final AuthProvider    authProvider;
  final ProfileProvider profileProvider;

  const AudioVerseApp({
    super.key,
    required this.authProvider,
    required this.profileProvider,
  });

  @override
  State<AudioVerseApp> createState() => _AudioVerseAppState();
}

class _AudioVerseAppState extends State<AudioVerseApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(authProvider: widget.authProvider);
    // ProfileProvider doesn't need to go into the router —
    // the router only needs authProvider for redirect logic
  }

  @override
  Widget build(BuildContext context) {
    // MultiProvider puts BOTH providers into the widget tree
    // so any screen below can access either one
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider.value(value: widget.profileProvider),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: _appRouter.router,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
      ),
    );
  }
}