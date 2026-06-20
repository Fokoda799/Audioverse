import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/features/content/models/models.dart';

// ContentResultTile
//
// A single search result row: thumbnail, title, author, type badge.
// Extracted as-is from SearchScreen's _ContentResultTile/_PlaceholderThumb/
// _TypeBadge — unchanged in behavior, just relocated to its own file
// since ResultsList is the only thing that uses it.
//
// content_result_tile.dart

class ContentResultTile extends StatelessWidget {
  const ContentResultTile({
    super.key,
    required this.content,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.surfaceColor,
  });

  final Content content;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color surfaceColor;

  /// Maps content.contentType to a representative icon for the placeholder
  /// thumbnail (shown when the cover image fails to load).
  IconData _typeIcon() {
    final t = content.contentType.toLowerCase();
    if (t.contains('podcast')) return Icons.mic_rounded;
    if (t.contains('novel') || t.contains('book')) {
      return Icons.menu_book_rounded;
    }
    if (t.contains('education')) {
      return Icons.school_rounded;
    }
    return Icons.headphones_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return InkWell(
      onTap: () => context.push('/home/content/${content.id}'),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image.network(
                content.coverUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _PlaceholderThumb(icon: _typeIcon()),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge(textPrimary)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (content.author != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      content.author!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium(textSecondary),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  _TypeBadge(label: content.contentType),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right_rounded, size: 20, color: textSecondary),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderThumb extends StatelessWidget {
  const _PlaceholderThumb({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: AppColors.primary, size: 24),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label, style: AppTextStyles.labelSmall(AppColors.primary)),
    );
  }
}
