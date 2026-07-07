import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:Audioverse/features/auth/auth.dart';
import 'package:Audioverse/core/network/token_storage.dart';

// ─────────────────────────────────────────────────────────────
// AuthRepositoryImpl
//
// The concrete implementation of AuthRepository using Dio.
//
// This class is the bridge between:
//   - Your domain layer (pure Dart, knows nothing about HTTP)
//   - The real world (JWT tokens, JSON, HTTP status codes)
//
// Every method follows the same 3-step pattern:
//   1. Call the API with Dio
//   2. Parse the JSON response into a Model
//   3. Convert the Model into a clean domain Entity and return it
//
// Errors are caught here and re-thrown as readable messages
// so the UI and provider layer always get clean exceptions.
// ─────────────────────────────────────────────────────────────

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  AuthRepositoryImpl({required Dio dio, required TokenStorage tokenStorage})
    : _dio = dio,
      _tokenStorage = tokenStorage;

  // ── POST /auth/register ────────────────────────────────────
  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      final token = AuthToken.fromJson(response.data);
      final user = User.fromJson(response.data['user']);

      await Future.wait([
        _tokenStorage.saveTokens(
          accessToken: token.accessToken,
          refreshToken: token.refreshToken,
        ),
        _tokenStorage.saveUser(user),
      ]);

      return user;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── POST /auth/login ───────────────────────────────────────
  @override
  Future<User> login({required String email, required String password}) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final token = AuthToken.fromJson(response.data);
      final user = User.fromJson(response.data['user']);

      await Future.wait([
        _tokenStorage.saveTokens(
          accessToken: token.accessToken,
          refreshToken: token.refreshToken,
        ),
        _tokenStorage.saveUser(user),
      ]);

      return user;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<User> googleSignIn({
    required String tokenId,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/google',
        data: {'token_id': tokenId},
      );

      final token = AuthToken.fromJson(response.data);
      final user = User.fromJson(response.data['user']);

      await Future.wait([
        _tokenStorage.saveTokens(
          accessToken: token.accessToken,
          refreshToken: token.refreshToken,
        ),
        _tokenStorage.saveUser(user),
      ]);

      return user;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── POST /auth/logout ──────────────────────────────────────
  @override
  Future<void> logout() async {
    try {
      // Tell the server to invalidate this token
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      // Even if the server call fails (e.g. no internet),
      // we still want to clear local tokens — always log out locally
      throw _handleError(e);
    } finally {
      // This runs whether the server call succeeded or failed.
      // The user is always logged out on their device.
      await _tokenStorage.clearTokens();
    }
  }

  // ── POST /auth/refresh ─────────────────────────────────────
  // NOTE: In most cases you don't call this directly — the
  // AuthInterceptor calls it automatically when a 401 is detected.
  // But having it here lets you trigger a manual refresh if needed.
  @override
  Future<AuthToken> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final token = AuthToken.fromJson(response.data);

      await _tokenStorage.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );

      return token;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── GET /auth/me ───────────────────────────────────────────
  // The Authorization header is added automatically by AuthInterceptor.
  // You don't need to pass the token here at all.
  @override
  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');

      AppLogger.d('Raw login response: ${response.data}');

      final user = await User.fromJson(response.data);

      await _tokenStorage.saveUser(user);

      return user;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<bool> deleteAccount(String password) async {
    var shouldClearLocalStorage = false;

    try {
      final response = await _dio.post(
        '/auth/delete',
        data: {'password': password},
      );

      if (response.statusCode == 201) {
        shouldClearLocalStorage = true;
        return true;
      }

      return false;
    } on DioException catch (e) {
      throw _handleError(e);
    } finally {
      if (shouldClearLocalStorage) {
        await _tokenStorage.clearTokens();
      }
    }
  }

  // ── Error handler ──────────────────────────────────────────
  // Converts raw Dio errors into human-readable exceptions.
  // One central place means you only update error handling here,
  // not in every single method above.
  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timed out. Check your internet.');

      case DioExceptionType.connectionError:
        return Exception('No internet connection.');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Something went wrong';

        return switch (statusCode) {
          400 => Exception('Invalid request: $message'),
          401 => Exception('Incorrect email or password.'),
          403 => Exception('You do not have permission to do this.'),
          404 => Exception('Resource not found.'),
          409 => Exception('An account with this email already exists.'),
          422 => Exception('Validation error: $message'),
          500 => Exception('Server error. Please try again later.'),
          _ => Exception('Error $statusCode: $message'),
        };

      default:
        return Exception('Unexpected error. Please try again.');
    }
  }
}
