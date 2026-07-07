import 'dart:async';
import 'dart:ui';

import 'package:Audioverse/core/auth/google.dart';
import 'package:Audioverse/core/network/cach_manager.dart';
import 'package:Audioverse/core/network/file_upload/storage_repository_impl.dart';
import 'package:Audioverse/core/error/app_crash_reporter.dart';
import 'package:Audioverse/features/content/content.dart';
import 'package:Audioverse/features/content/providers/categories_provider.dart';
import 'package:Audioverse/features/content/providers/search_provider.dart';
import 'package:Audioverse/features/home/home_provider.dart';
import 'package:Audioverse/features/personalization/providers/favorites_provider.dart';
import 'package:Audioverse/features/personalization/providers/history_provider.dart';
import 'package:Audioverse/features/personalization/repositories/favorites_repository_impl.dart';
import 'package:Audioverse/features/personalization/repositories/history_repository_impl.dart';
import 'package:Audioverse/features/profile/profile.dart';
import 'package:Audioverse/features/settings/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:Audioverse/core/router/app_router.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/core/network/network.dart';
import 'package:Audioverse/features/auth/auth.dart';
import 'package:Audioverse/core/audio/audio_player_service.dart';
import 'package:Audioverse/core/widgets/app_error_screen.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final sentryDsn = (dotenv.env['SENTRY_DSN'] ?? '').trim();
  final crashReporter = AppCrashReporter(useSentry: sentryDsn.isNotEmpty);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    crashReporter.reportFlutterError(details);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    crashReporter.reportError(error, stackTrace, source: 'PlatformDispatcher');
    return true;
  };

  ErrorWidget.builder = (details) {
    crashReporter.reportFlutterError(details);
    return AppErrorScreen(
      title: 'Something went wrong',
      message:
          'The app hit an unexpected error. Please restart it and try again.',
      details: details.exceptionAsString(),
    );
  };

  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.sendDefaultPii = true;
        options.debug = kDebugMode;
        options.tracesSampleRate = 0.0;
      },
      appRunner: () async {
        await runZonedGuarded(
          () async {
            await _bootstrapApp(crashReporter);
          },
          (error, stackTrace) {
            crashReporter.reportError(
              error,
              stackTrace,
              source: 'runZonedGuarded',
            );
          },
        );
      },
    );
    return;
  }

  await runZonedGuarded(
    () async {
      await _bootstrapApp(crashReporter);
    },
    (error, stackTrace) {
      crashReporter.reportError(error, stackTrace, source: 'runZonedGuarded');
    },
  );
}

Future<void> _bootstrapApp(AppCrashReporter crashReporter) async {
  // Optimize image loading: memory cache to 100 images
  PaintingBinding.instance.imageCache.maximumSize = 100;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          Brightness.light, // since your app is dark-themed
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  await Hive.initFlutter();
  await Hive.openBox('categories_cache');
  await Hive.openBox('content_cache');
  await Hive.openBox('recent_searches');

  await AudioPlayerService.instance.init();

  final tokenStorage = TokenStorage();
  final dioClient = DioClient(tokenStorage: tokenStorage);
  final cache = CacheManager();
  final googleAuth = GoogleAuthService();

  final authRepo = AuthRepositoryImpl(
    dio: dioClient.dio,
    tokenStorage: tokenStorage,
  );
  final profileRepo = ProfileRepositoryImpl(dio: dioClient.dio, tokenStorage: tokenStorage);
  final favoriteRepo = FavoritesRepositoryImpl(dio: dioClient.dio, tokenStorage: tokenStorage);
  final historyRepo = HistoryRepositoryImpl(dio: dioClient.dio, tokenStorage: tokenStorage);
  final storageRepo = StorageRepositoryImpl(dio: dioClient.dio);
  final settingsRepo = SettingsRepositoryImpl(dio: dioClient.dio);

  AudioPlayerService.instance.attachHistoryRepository(historyRepo);

  // ✅ Keep a reference to contentRepo so we can ALSO put it directly
  // into the widget tree below — not just hand it to other providers.
  final ContentRepository contentRepo = ContentRepositoryImpl(
    dio: dioClient.dio,
    cache: cache,
  );

  final authProvider = AuthProvider(repository: authRepo, googleAuth: googleAuth);
  crashReporter.attachAuthProvider(authProvider);
  final profileProvider = ProfileProvider(
    repository: profileRepo,
    storageRepository: storageRepo,
  );
  final homeProvider = HomeProvider(repository: contentRepo);
  final contentListProvider = ContentListProvider(repository: contentRepo);
  final categoryProvider = CategoriesProvider(repository: contentRepo);
  final searchProvider = SearchProvider(repository: contentRepo, cache: cache);
  final favoriteProvider = FavoritesProvider(repository: favoriteRepo);
  final historyProvider = HistoryProvider(repository: historyRepo);
  final settingsProvider = SettingsProvider(repository: settingsRepo);

  runApp(
    AudioVerseApp(
      contentRepo: contentRepo,
      authProvider: authProvider,
      profileProvider: profileProvider,
      homeProvider: homeProvider,
      contentListProvider: contentListProvider,
      categoryProvider: categoryProvider,
      searchProvider: searchProvider,
      favoriteProvider: favoriteProvider,
      historyProvider: historyProvider,
      settingsProvider: settingsProvider,
    ),
  );
}

class AudioVerseApp extends StatefulWidget {
  final ContentRepository contentRepo; // ← new field
  final AuthProvider authProvider;
  final ProfileProvider profileProvider;
  final HomeProvider homeProvider;
  final ContentListProvider contentListProvider;
  final CategoriesProvider categoryProvider;
  final SearchProvider searchProvider;
  final FavoritesProvider favoriteProvider;
  final HistoryProvider historyProvider;
  final SettingsProvider settingsProvider;

  const AudioVerseApp({
    super.key,
    required this.contentRepo,
    required this.authProvider,
    required this.profileProvider,
    required this.homeProvider,
    required this.contentListProvider,
    required this.categoryProvider,
    required this.searchProvider,
    required this.favoriteProvider,
    required this.historyProvider,
    required this.settingsProvider,
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
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ Register ContentRepository itself — this is what was missing.
        // Provider.value (not ChangeNotifierProvider) because ContentRepository
        // is a plain repository, not a ChangeNotifier.
        Provider<ContentRepository>.value(value: widget.contentRepo),

        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider.value(value: widget.profileProvider),
        ChangeNotifierProvider.value(value: widget.homeProvider),
        ChangeNotifierProvider.value(value: widget.contentListProvider),
        ChangeNotifierProvider.value(value: widget.categoryProvider),
        ChangeNotifierProvider.value(value: widget.searchProvider),
        ChangeNotifierProvider.value(value: widget.favoriteProvider),
        ChangeNotifierProvider.value(value: widget.historyProvider),
        ChangeNotifierProvider.value(value: widget.settingsProvider),
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
