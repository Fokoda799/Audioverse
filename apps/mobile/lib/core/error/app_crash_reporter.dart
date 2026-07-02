import 'dart:async';

import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/features/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AppCrashReporter {
  AppCrashReporter({required bool useSentry}) : _useSentry = useSentry;

  final bool _useSentry;
  AuthProvider? _authProvider;

  void attachAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  void reportFlutterError(FlutterErrorDetails details) {
    reportError(
      details.exception,
      details.stack ?? StackTrace.current,
      source: 'FlutterError',
      context: details.exceptionAsString(),
    );
  }

  void reportError(
    Object error,
    StackTrace stackTrace, {
    String source = 'Unhandled',
    String? context,
  }) {
    AppLogger.f(
      _message(source: source, context: context),
      error: error,
      stackTrace: stackTrace,
    );

    if (_useSentry) {
      unawaited(
        _captureToSentry(
          error,
          stackTrace,
          source: source,
          context: context,
        ),
      );
    }
  }

  String _message({required String source, String? context}) {
    final user = _authProvider?.currentUser;
    final userContext = user == null
        ? 'anonymous'
        : 'id=${user.id}, email=${user.email}, name=${user.name}';

    final contextSuffix = context == null ? '' : '\nContext: $context';

    return '$source crash\nUser: $userContext$contextSuffix';
  }

  Future<void> _captureToSentry(
    Object error,
    StackTrace stackTrace, {
    required String source,
    String? context,
  }) async {
    final user = _authProvider?.currentUser;

    await Sentry.configureScope((scope) {
      scope.setTag('source', source);

      if (context != null) {
        scope.setExtra('context', context);
      }

      if (user == null) {
        scope.setUser(null);
        return;
      }

      scope.setUser(
        SentryUser(
          id: user.id,
          email: user.email,
          username: user.name,
        ),
      );
    });

    await Sentry.captureException(error, stackTrace: stackTrace);
  }
}
