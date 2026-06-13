import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:Audioverse/features/auth/auth_provider.dart';
import 'package:Audioverse/features/auth/screens/login_screen.dart';
import 'package:Audioverse/features/auth/screens/register_screen.dart';
import 'package:Audioverse/features/auth/screens/password_screen.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/profile/profile.dart';

// ── Route name constants ───────────────────────────────────────
// Always use these instead of raw strings like '/login'.
// If you rename a route, you change it in one place only.
class AppRoutes {
  static const login          = '/login';
  static const register       = '/register';
  static const forgotPassword = '/forgot-password';
  static const home           = '/home';
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
// ─────────────────────────────────────────────────────────────

class AppRouter {
  final AuthProvider _authProvider;

  AppRouter({required AuthProvider authProvider})
      : _authProvider = authProvider;

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,

    // refreshListenable tells go_router to re-run redirect
    // every time AuthProvider calls notifyListeners()
    refreshListenable: _authProvider,

    redirect: (context, state) {
      final isLoggedIn      = _authProvider.isLoggedIn;
      final isOnAuthScreen  = [
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
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: LoginScreen(
            // Navigation callbacks — routing is the router's job,
            // not the screen's and not the provider's
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

      // ── Protected routes ─────────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => _fadePage(
          state: state,
          // Replace with your real HomeScreen
          child: const _PlaceholderHomeScreen(),
        ),
      ),

      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) => _fadePage(
          state: state,
          // Replace with your real HomeScreen
          child: const ProfileScreen(),
        ),
      ),
    ],
  );

  // Smooth fade transition between auth screens instead of
  // the default slide — feels more natural for auth flows
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

// Temporary home screen placeholder — replace with your real one
class _PlaceholderHomeScreen extends StatelessWidget {
  const _PlaceholderHomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: const Center(child: Text('You are logged in!')),
    );
  }
}
