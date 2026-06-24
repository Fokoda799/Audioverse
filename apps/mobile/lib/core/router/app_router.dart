import 'package:Audioverse/features/content/content.dart';
import 'package:Audioverse/features/content/providers/content_detail_provider.dart';
import 'package:Audioverse/features/content/screens/content_search_screen.dart';
import 'package:Audioverse/features/content/screens/player_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:Audioverse/features/player/screen_with_miniplayer.dart';

import 'package:Audioverse/features/auth/auth_provider.dart';
import 'package:Audioverse/features/auth/screens/login_screen.dart';
import 'package:Audioverse/features/auth/screens/register_screen.dart';
import 'package:Audioverse/features/auth/screens/password_screen.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/profile/profile.dart';
import 'package:Audioverse/features/shell/main_scaffold.dart';
import 'package:Audioverse/features/home/home_screen.dart';
import 'package:Audioverse/features/content/screens/content_detail_screen.dart';
import 'package:provider/provider.dart';

// ── Route name constants ───────────────────────────────────────
// Always use these instead of raw strings like '/login'.
// If you rename a route, you change it in one place only.
class AppRoutes {
  static const login          = '/login';
  static const register       = '/register';
  static const forgotPassword = '/forgot-password';
  static const home           = '/home';
  static const search         = '/search';
  static const library        = '/library';
  static const profile        = '/profile';
}

// ─────────────────────────────────────────────────────────────
// AppRouter
//
// Receives AuthProvider so the redirect logic can check
// isLoggedIn without needing a BuildContext.
//
// HOW REDIRECT WORKS:
//   Every time AuthProvider calls notifyListeners(), the router
//   re-evaluates the redirect function. If the user just logged
//   in, isLoggedIn becomes true and the router automatically
//   sends them to /home — no manual navigation needed in screens.
//
// STRUCTURE:
//   Auth routes (login/register/forgot-password) stay as plain
//   top-level GoRoutes, exactly as before — they have no bottom
//   nav and shouldn't be wrapped in the shell.
//
//   The 4 bottom-nav tabs (home/search/library/profile) are now
//   ONE StatefulShellRoute, nested inside the SAME routes list.
//   The redirect function doesn't care about this nesting — it
//   matches on state.matchedLocation, which works identically
//   whether a route is top-level or nested inside a shell branch.
// ─────────────────────────────────────────────────────────────

class AppRouter {
  final AuthProvider _authProvider;

  AppRouter({required AuthProvider authProvider})
      : _authProvider = authProvider;

  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,

    // refreshListenable tells go_router to re-run redirect
    // every time AuthProvider calls notifyListeners()
    refreshListenable: _authProvider,

    redirect: (context, state) {
      final isLoggedIn     = _authProvider.isLoggedIn;
      final isOnAuthScreen = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ].contains(state.matchedLocation);

      AppLogger.d("Is logged in : $isLoggedIn");

      // Not logged in and trying to access a protected screen → login
      if (!isLoggedIn && !isOnAuthScreen) return AppRoutes.login;

      // Already logged in and on an auth screen → home
      // (prevents going back to login after successful auth)
      if (isLoggedIn && isOnAuthScreen) return AppRoutes.home;

      // No redirect needed
      return null;
    },

    routes: [
      // ── Auth routes ──────────────────────────────────────
      // Unchanged — these stay outside the shell since they have
      // no bottom nav bar.
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: LoginScreen(
            onForgotPassword: () => context.go(AppRoutes.forgotPassword),
            onCreateAccount:  () => context.go(AppRoutes.register),
          ),
        ),
      ),

      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: RegisterScreen(
            onLogin: () => context.go(AppRoutes.login),
          ),
        ),
      ),

      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: ForgotPasswordScreen(
            onBackToLogin: () => context.go(AppRoutes.login),
          ),
        ),
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/content/:id',
        pageBuilder: (context, state) {
          final contentId = state.pathParameters['id']!;

          return _fadePage(
              state: state,
              child: ChangeNotifierProvider(
                create: (context) => ContentDetailProvider(
                    repository: context.read<ContentRepository>(),
                    contentId: contentId
                )..load(),
                child: ScreenWithMiniplayer(
                    child: ContentDetailScreen(contentId: contentId)
                ),
              )
          );
        }
      ),

      GoRoute(
        path: '/player',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            fullscreenDialog: true,
            child: const FullPlayerScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0); // 👈 from bottom
              const end = Offset.zero;

              const curve = Curves.easeOutCubic; // smooth deceleration

              final tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );

              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
              );

              return SlideTransition(
                position: tween.animate(curvedAnimation),
                child: child,
              );
            },
          );
        },
      ),

      // ── Protected routes — bottom nav shell ──────────────
      // Everything that should show the bottom nav bar lives inside
      // this single StatefulShellRoute. The redirect logic above
      // still applies to every path in here — e.g. hitting /profile
      // while logged out still bounces to /login first.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Home
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (context, state) => _fadePage(
                  state: state,
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),

          // Tab 1: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                // TODO: replace with your real SearchScreen
                pageBuilder: (context, state) => _fadePage(
                  state: state,
                  child: const SearchScreen(),
                ),
              ),
            ],
          ),

          // Tab 2: Library
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.library,
                // TODO: replace with your real LibraryScreen
                pageBuilder: (context, state) => _fadePage(
                  state: state,
                  child: const Placeholder(),
                ),
              ),
            ],
          ),

          // Tab 3: Profile
          // Your original /profile GoRoute is now this branch's root —
          // ProfileScreen now appears INSIDE the bottom nav shell rather
          // than as a screen pushed on top of a placeholder Home AppBar
          // button. The IconButton that used to do context.push('/profile')
          // in your old placeholder Home is no longer needed; tapping the
          // Profile tab in the bottom nav replaces that entirely.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                pageBuilder: (context, state) => _fadePage(
                  state: state,
                  child: const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  // Smooth fade transition instead of the default slide — feels more
  // natural for auth flows and is kept consistent for the shell routes too.
  CustomTransitionPage _fadePage({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}
