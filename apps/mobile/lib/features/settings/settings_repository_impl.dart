// import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:Audioverse/features/settings/settings_models.dart';
import 'package:Audioverse/features/settings/settings_repository.dart';

// Settings Repository Implementation
//
// Makes real HTTP calls using Dio.
// The Dio instance is injected â€” it already has the AuthInterceptor
// attached, so Bearer tokens are added automatically to every request.
//
// Every method follows the same pattern:
//   1. Call the API with Dio
//   2. Parse the JSON response with fromJson()
//   3. Return the clean model â€” or throw a readable exception

class SettingsRepositoryImpl implements SettingsRepository {
  final Dio _dio;

  SettingsRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<UserPreferences> updatePreferences(UserPreferences data) async {
    try {
      final response = await _dio.patch(
        '/settings/preferences',
        data: data.toJson(),
      );
      return UserPreferences.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<UserPreferences> getPreferences() async {
    try {
      final response = await _dio.get(
        '/settings/preferences',
      );
      return UserPreferences.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timed out. Check your internet.');
      case DioExceptionType.connectionError:
        return Exception('No internet connection.');
      case DioExceptionType.badResponse:
        final status  = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Something went wrong';
        return switch (status) {
          400 => Exception('Bad request: $message'),
          401 => Exception('Unauthorized.'),
          403 => Exception('Forbidden.'),
          404 => Exception('Not found.'),
          409 => Exception('Conflict: $message'),
          500 => Exception('Server error. Try again later.'),
          _   => Exception('Error $status: $message'),
        };
      default:
        return Exception('Unexpected error. Please try again.');
    }
  }
}
