import 'dart:io';

// StorageRepository
//
// Thin wrapper around your existing /storage/upload/cover endpoint
// (and /storage/upload/audio, not used here but included for parity —
// see implementation note below). Avatar upload reuses the COVER
// endpoint specifically — avatars and content covers are both small
// images stored the same way on the backend, so there's no reason to
// add a separate /storage/upload/avatar route just for this.

abstract class StorageRepository {
  /// Uploads an image file and returns the Cloudinary publicId —
  /// matches what /storage/upload/cover returns. The caller (here,
  /// ProfileProvider) is responsible for persisting that publicId
  /// wherever it belongs (UserProfile.avatarUrl).
  Future<String> uploadCoverImage(File file);
}
