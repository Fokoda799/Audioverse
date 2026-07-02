import 'dart:io';
import 'package:dio/dio.dart';
import 'package:Audioverse/core/utils/app_logger.dart';
import 'package:Audioverse/core/network/file_upload/storage_repository.dart';

// StorageRepositoryImpl
//
// multipart/form-data upload to POST /storage/upload/cover — matches
// the field name 'file' and admin-only auth your NestJS
// StorageController.uploadCover already expects (the Authorization
// header is added automatically by AuthInterceptor on the shared Dio
// instance, same as every other repository in this app).
//
// ⚠️ Your existing /storage/upload/cover endpoint is gated with
// @Roles(UserRole.ADMIN) (see the StorageController built earlier in
// this conversation). A regular user uploading their OWN avatar will
// get a 403 against that route as it currently stands. This repository
// calls the endpoint as specified — the backend route itself needs a
// decision: either open /storage/upload/cover to any authenticated
// user (not just admins), or add a separate non-admin avatar upload
// route. Flagging this clearly rather than silently assuming it works.

class StorageRepositoryImpl implements StorageRepository {
  final Dio _dio;

  StorageRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<String> uploadCoverImage(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _dio.post('/storage/upload/cover', data: formData);

      final publicId = response.data['public-id'] as String?;

      if (publicId == null) {
        throw Exception('Upload succeeded but no publicId was returned');
      }

      return publicId;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return Exception('No internet connection. Please try again.');
    }

    final statusCode = e.response?.statusCode;
    final serverMessage = e.response?.data is Map
        ? (e.response?.data as Map)['message']
        : null;

    switch (statusCode) {
      case 400:
        return Exception(serverMessage ?? 'Invalid image file');
      case 401:
        return Exception('Session expired. Please log in again.');
      case 403:
      // See the class-level warning above — this is the most likely
      // error a non-admin user hits against the current backend route.
        return Exception('You don\'t have permission to upload this');
      default:
        AppLogger.e('Unhandled DioException in StorageRepository: $e');
        return Exception('Upload failed. Please try again.');
    }
  }
}
