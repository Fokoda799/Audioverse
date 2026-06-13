import 'package:dio/dio.dart';
import 'package:Audioverse/core/network/token_storage.dart';
import 'package:Audioverse/core/utils/app_logger.dart';

// ─────────────────────────────────────────────────────────────
// AuthInterceptor
//
// This is the most important piece of the whole auth system.
// It runs automatically on every single request and response.
//
// It does two jobs:
//
//  JOB 1 — onRequest:
//    Before any request leaves the app, attach the Bearer token
//    to the Authorization header automatically. You never have
//    to remember to add it manually in your repository methods.
//
//  JOB 2 — onError:
//    When a 401 (Unauthorized) comes back, it means the access
//    token expired. Instead of crashing or showing a login screen,
//    we silently:
//      1. Call POST /auth/refresh to get a new access token
//      2. Save the new token
//      3. Retry the original request with the new token
//    The UI never sees any of this happen.
//
// IMPORTANT — The _isRefreshing flag:
//    Imagine 3 API calls fire at the same time and all get 401.
//    Without this flag, you'd trigger 3 simultaneous refresh calls,
//    which would cause chaos. The flag ensures only ONE refresh
//    happens, and the other calls just wait for it to finish.
// ─────────────────────────────────────────────────────────────

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  // Prevents multiple simultaneous refresh attempts
  bool _isRefreshing = false;

  AuthInterceptor({required Dio dio, required TokenStorage tokenStorage})
      : _dio = dio,
        _tokenStorage = tokenStorage;

  // ── JOB 1: Attach token to every outgoing request ─────────
  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    final token = await _tokenStorage.getAccessToken();

    if (token != null) {
      // Attach the Bearer token — server uses this to know who you are
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Pass the request along — without this it would never be sent
    handler.next(options);
  }

  // ── JOB 2: Catch 401 and silently refresh the token ───────
  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    final is401 = err.response?.statusCode == 401;
    AppLogger.d('Error code is: ${err.response?.statusCode}');
    final isRefreshEndpoint = err.requestOptions.path.contains('/auth/refresh');

    // If it's not a 401, or if the refresh endpoint itself returned 401
    // (meaning the refresh token is also expired → force logout),
    // just pass the error through normally.
    if (!is401 || isRefreshEndpoint) {
      return handler.next(err);
    }

    // Prevent multiple simultaneous refresh calls
    if (_isRefreshing) {
      return handler.next(err);
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();

      if (refreshToken == null) {
        // No refresh token stored — user must log in again
        return handler.next(err);
      }

      // ── Attempt to get a new access token ─────────────────
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        // Skip the interceptor for this call to avoid infinite loops
        options: Options(extra: {'skipInterceptor': true}),
      );

      final newAccessToken  = response.data['access-token']  as String;
      final newRefreshToken = response.data['refresh-token'] as String;

      // Save the new tokens to secure storage
      await _tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      // ── Retry the original failed request ─────────────────
      // Re-create the request options with the new token attached
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      final retryResponse = await _dio.fetch(retryOptions);
      return handler.resolve(retryResponse); // return success to the caller

    } catch (_) {
      // Refresh failed entirely — clear tokens and let the error bubble up
      // Your app should listen for this and redirect to the login screen
      await _tokenStorage.clearTokens();
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}
