import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

// ─────────────────────────────────────────────────────────────
// AppLogger
//
// One shared logger for the entire app.
// Import this file wherever you need to log — never create
// a new Logger() instance in individual files.
//
// USAGE:
//   import 'package:Audioverse/core/utils/app_logger.dart';
//
//   AppLogger.i('User logged in');
//   AppLogger.e('Login failed', error: e, stackTrace: st);
// ─────────────────────────────────────────────────────────────

class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: false,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    output: _ConsoleOutput(),
    level: kDebugMode ? Level.trace : Level.warning,
  );

  // ── Public static methods ─────────────────────────────────
  // Static so you call AppLogger.d() not AppLogger().d()

  /// Ultra-verbose — every tiny step (use sparingly, remove before PR)
  static void t(String message) => _logger.t(message);

  /// What's happening — your main debugging tool during development
  static void d(String message) => _logger.d(message);

  /// Important milestones — user logged in, screen loaded, data fetched
  static void i(String message) => _logger.i(message);

  /// Something unexpected happened but the app can continue
  static void w(String message, {Object? error}) =>
      _logger.w(message, error: error);

  /// Something failed — always pass the error and stackTrace
  static void e(
      String message, {
        Object? error,
        StackTrace? stackTrace,
      }) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  /// App cannot continue — crash-level issue
  static void f(
      String message, {
        Object? error,
        StackTrace? stackTrace,
      }) =>
      _logger.f(message, error: error, stackTrace: stackTrace);
}

/// Custom output that uses debugPrint to ensure logs reach the IDE console
class _ConsoleOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      // debugPrint is usually enough, but print() is the most direct way
      // to bypass any IDE/Logger logic that might be hiding your logs.
      debugPrint(line);
      print(line);
    }
  }
}
