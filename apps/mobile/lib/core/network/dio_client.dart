import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:Audioverse/core/network/network.dart';
import 'package:Audioverse/core/utils/app_logger.dart';

// ─────────────────────────────────────────────────────────────
// DioClient
//
// A single, configured Dio instance shared across the whole app.
// Think of this as the "factory" that creates the delivery truck
// with all the right settings already applied.
// ─────────────────────────────────────────────────────────────

class DioClient {
  late final Dio dio;

  DioClient({required TokenStorage tokenStorage}) {
    dio = Dio(
      BaseOptions(
        // Read base URL from .env — never hardcoded
        baseUrl: dotenv.env['BASE_URL'] ?? '',

        // How long to wait for the server to CONNECT before giving up
        connectTimeout: Duration(
          milliseconds: int.parse(dotenv.env['CONNECT_TIMEOUT_MS'] ?? '10000'),
        ),

        // How long to wait for the server to send a RESPONSE before giving up
        receiveTimeout: Duration(
          milliseconds: int.parse(dotenv.env['RECEIVE_TIMEOUT_MS'] ?? '15000'),
        ),

        // Tell the server we're always sending and expecting JSON
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Attach our interceptor — this runs on EVERY request and response.
    dio.interceptors.add(AuthInterceptor(dio: dio, tokenStorage: tokenStorage));

    // Custom network logger that uses our AppLogger
    if (kDebugMode) {
      dio.interceptors.add(_AppDioLogger());
    }
  }
}


class _AppDioLogger extends Interceptor {
  final _requestTimes = <int, DateTime>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _requestTimes[options.hashCode] = DateTime.now();

    // Strip Authorization header — never log bearer tokens
    final safeHeaders = Map<String, dynamic>.from(options.headers)
      ..remove('Authorization');

    AppLogger.d(
      '→ ${options.method} ${options.path}\n'
          '   Headers: $safeHeaders\n'
          '   Body: ${options.data}',
    );

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final duration = _duration(response.requestOptions);
    AppLogger.i(
      '← ${response.statusCode} ${response.requestOptions.path} '
          '(${duration}ms)\n'
          '   Body: ${response.data}',
    );
    _requestTimes.remove(response.requestOptions.hashCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final duration = _duration(err.requestOptions);
    AppLogger.e(
      '✗ ${err.response?.statusCode ?? 'NO_RESPONSE'} '
          '${err.requestOptions.path} (${duration}ms)\n'
          '   Error: ${err.message}\n'
          '   Response: ${err.response?.data}',
      error: err,
      stackTrace: err.stackTrace,
    );
    _requestTimes.remove(err.requestOptions.hashCode);
    handler.next(err);
  }

  int _duration(RequestOptions options) {
    final start = _requestTimes[options.hashCode];
    if (start == null) return 0;
    return DateTime.now().difference(start).inMilliseconds;
  }
}
