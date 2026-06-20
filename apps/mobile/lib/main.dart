import 'package:Audioverse/core/network/cach_manager.dart';
import 'package:Audioverse/features/content/content.dart';
import 'package:Audioverse/features/content/providers/categories_provider.dart';
import 'package:Audioverse/features/content/providers/search_provider.dart';
import 'package:Audioverse/features/home/home_provider.dart';
import 'package:Audioverse/features/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:Audioverse/core/router/app_router.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/core/network/network.dart';
import 'package:Audioverse/features/auth/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();
  await Hive.openBox('categories_cache');
  await Hive.openBox('content_cache');
  await Hive.openBox('recent_searches');

  final tokenStorage = TokenStorage();
  final dioClient    = DioClient(tokenStorage: tokenStorage);
  final cache         = CacheManager();

  final authRepo    = AuthRepositoryImpl(dio: dioClient.dio, tokenStorage: tokenStorage);
  final profileRepo = ProfileRepositoryImpl(dio: dioClient.dio);

  // ✅ Keep a reference to contentRepo so we can ALSO put it directly
  // into the widget tree below — not just hand it to other providers.
  final ContentRepository contentRepo = ContentRepositoryImpl(dio: dioClient.dio, cache: cache);

  final authProvider        = AuthProvider(repository: authRepo);
  final profileProvider     = ProfileProvider(repository: profileRepo);
  final homeProvider        = HomeProvider(repository: contentRepo);
  final contentListProvider = ContentListProvider(repository: contentRepo);
  final categoryProvider    = CategoriesProvider(repository: contentRepo);
  final searchProvider      = SearchProvider(repository: contentRepo, cache: cache);

  runApp(AudioVerseApp(
    contentRepo:          contentRepo, // ← pass it down too
    authProvider:         authProvider,
    profileProvider:      profileProvider,
    homeProvider:         homeProvider,
    contentListProvider:  contentListProvider,
    categoryProvider:     categoryProvider,
    searchProvider:       searchProvider,
  ));
}

class AudioVerseApp extends StatefulWidget {
  final ContentRepository contentRepo; // ← new field
  final AuthProvider    authProvider;
  final ProfileProvider profileProvider;
  final HomeProvider homeProvider;
  final ContentListProvider contentListProvider;
  final CategoriesProvider categoryProvider;
  final SearchProvider searchProvider;

  const AudioVerseApp({
    super.key,
    required this.contentRepo,
    required this.authProvider,
    required this.profileProvider,
    required this.homeProvider,
    required this.contentListProvider,
    required this.categoryProvider,
    required this.searchProvider,
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
