import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/core/widgets/widgets.dart';
import 'package:Audioverse/features/home/widgets/empty_state.dart';
import 'package:Audioverse/features/settings/models/download_model.dart';
import 'package:Audioverse/features/settings/providers/downloads_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadProvider>().downloads;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Downloads',
          style: AppTextStyles.titleLarge(AppColors.textPrimaryDark),
        ),
      ),
      body: downloads.isEmpty
          ? const Center(
        child: EmptyState(
          icon: Icons.download_outlined,
          title: 'No general yet',
          message: 'Download an audiobook to listen offline.',
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: downloads.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = downloads[index];
          return _DownloadTile(item: item);
        },
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  const _DownloadTile({required this.item});

  final DownloadItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/content/${item.contentId}'),
      child: AppCard(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: CachedNetworkImage(
                imageUrl: item.coverUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: AppColors.darkCard),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.darkCard,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.textSecondaryDark,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge(AppColors.textPrimaryDark)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  _buildStatusRow(),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            _buildTrailingAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    switch (item.status) {
      case DownloadStatus.downloading:
        final progress = item.progress.clamp(0.0, 1.0);
        return Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: AppColors.darkBorder,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${(progress * 100).round()}%',
              style: AppTextStyles.labelSmall(AppColors.textSecondaryDark),
            ),
          ],
        );
      case DownloadStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 14, color: AppColors.error),
            const SizedBox(width: 4),
            Text('Download failed', style: AppTextStyles.labelSmall(AppColors.error)),
          ],
        );
      case DownloadStatus.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_done_rounded,
                size: 14, color: AppColors.accent),
            const SizedBox(width: 4),
            Text('Downloaded',
                style: AppTextStyles.labelSmall(AppColors.textSecondaryDark)),
          ],
        );
      case DownloadStatus.queued:
      case DownloadStatus.paused:
        return Text(
          item.status == DownloadStatus.paused ? 'Paused' : 'Queued',
          style: AppTextStyles.labelSmall(AppColors.textSecondaryDark),
        );
    }
  }

  Widget _buildTrailingAction(BuildContext context) {
    final provider = context.read<DownloadProvider>();
    final isActive = item.status == DownloadStatus.downloading;

    return IconButton(
      icon: Icon(
        isActive ? Icons.close_rounded : Icons.delete_outline_rounded,
        color: AppColors.textSecondaryDark,
        size: 20,
      ),
      onPressed: () {
        isActive
            ? provider.cancelDownload(item.contentId)
            : provider.removeDownload(item.contentId);
      },
    );
  }
}