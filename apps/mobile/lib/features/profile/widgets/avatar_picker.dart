import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:Audioverse/core/theme/theme.dart';

// AvatarPicker
//
// Full real flow: pick (camera/gallery) → crop to a circle → hand the
// cropped file back via onImageSelected. Upload itself happens in the
// CALLER (ProfileScreen → ProfileProvider.updateAvatar), not in this
// widget — AvatarPicker's job ends at "here is a cropped image file,"
// matching the separation already used for onImageSelected elsewhere.
//
// avatar_picker.dart

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.currentAvatarUrl,
    required this.localPreviewFile,
    required this.onImageSelected,
    this.isUploading = false,
    this.size = 96,
  });

  final String? currentAvatarUrl;
  // Set immediately after cropping, before upload completes — lets the
  // UI show the new image right away rather than waiting on the
  // network round-trip.
  final File? localPreviewFile;
  final ValueChanged<File> onImageSelected;
  final bool isUploading;
  final double size;

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();

    // showModalBottomSheet for camera-vs-gallery choice — standard pattern,
    // avoids assuming the user always wants gallery.
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.textPrimaryDark),
              title: Text('Take a photo', style: AppTextStyles.bodyLarge(AppColors.textPrimaryDark)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.textPrimaryDark),
              title: Text('Choose from gallery', style: AppTextStyles.bodyLarge(AppColors.textPrimaryDark)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (source == null) return; // user dismissed the sheet

    final picked = await picker.pickImage(
      source: source,
      // No imageQuality/maxWidth constraint here anymore — image_cropper
      // below handles final compression via compressQuality, and
      // constraining BEFORE crop can clip the crop tool's usable
      // resolution unnecessarily. Let the cropper be the one place
      // that decides final output size/quality.
    );

    if (picked == null) return; // user cancelled the native picker
    if (!context.mounted) return;

    // ── Crop step ────────────────────────────────────────────────────────
    //
    // CropStyle.circle matches how the avatar is actually displayed
    // (ClipOval below) — the crop tool's preview should match the final
    // rendered shape, not crop to a square the UI then circle-clips
    // anyway, which would let users frame content that gets invisibly
    // cut off at the corners.
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop photo',
          toolbarColor: AppColors.darkSurface,
          toolbarWidgetColor: Colors.white,
          backgroundColor: AppColors.darkBackground,
          cropStyle: CropStyle.circle,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Crop photo',
          cropStyle: CropStyle.circle,
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (cropped == null) return; // user cancelled the crop screen

    onImageSelected(File(cropped.path));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : () => _pickImage(context),
      child: Stack(
        children: [
          ClipOval(
            child: SizedBox(
              width: size,
              height: size,
              child: _buildImage(),
            ),
          ),
          if (isUploading)
            Positioned.fill(
              child: ClipOval(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Camera badge — affordance signaling "tappable", since a
          // plain circular avatar alone doesn't read as interactive.
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkBackground, width: 2.5),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    // Local preview takes priority — this is the "optimistic" picked
    // image, shown immediately even though no upload has actually
    // happened (see file header note on the upload stub).
    if (localPreviewFile != null) {
      return Image.file(localPreviewFile!, fit: BoxFit.cover);
    }

    if (currentAvatarUrl != null) {
      if (kIsWeb) {
        return Image.network(
          currentAvatarUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
        );
      }
      return CachedNetworkImage(
        imageUrl: currentAvatarUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: AppColors.darkCard),
        errorWidget: (context, url, error) => _buildPlaceholderIcon(),
      );
    }

    return _buildPlaceholderIcon();
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: AppColors.darkCard,
      child: const Icon(Icons.person_rounded, color: AppColors.textSecondaryDark, size: 40),
    );
  }
}
