import 'package:go_router/go_router.dart';
import 'package:Audioverse/features/auth/screens/login_screen.dart';
import 'package:Audioverse/features/auth/screens/register_screen.dart';
import 'package:Audioverse/features/auth/screens/password_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(
        onForgotPassword: () => context.push('/forgot-password'),
        onCreateAccount: () => context.push('/register'),
      ),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterScreen(
        onLogin: () => context.go('/login'),
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => ForgotPasswordScreen(
        onBackToLogin: () => context.go('/login'),
      ),
    ),
  ],
);