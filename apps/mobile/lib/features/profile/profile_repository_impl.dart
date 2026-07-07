import 'package:Audioverse/core/network/network.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:Audioverse/features/profile/profile_models.dart';
import 'package:Audioverse/features/profile/profile_repository.dart';

// Profile Repository Implementation
//
// Makes real HTTP calls using Dio.
// The Dio instance is injected â€” it already has the AuthInterceptor
// attached, so Bearer tokens are added automatically to every request.
//
// Every method follows the same pattern:
//   1. Call the API with Dio
//   2. Parse the JSON response with fromJson()
//   3. Return the clean model â€” or throw a readable exception

class ProfileRepositoryImpl implements ProfileRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  ProfileRepositoryImpl({required Dio dio, required TokenStorage tokenStorage})
      : _dio = dio,
        _tokenStorage = tokenStorage;

  @override
  Future<Profile?> getProfile() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) return null;
      final response = await _dio.get('/profile/me');
      return Profile.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Profile> update(UpdateProfileRequest data) async {
    try {
      final response = await _dio.patch('/profile',
        data: data,
      );
      return Profile.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Converts raw Dio errors into readable exceptions.
  // Add this to every repository impl same pattern as auth.
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
