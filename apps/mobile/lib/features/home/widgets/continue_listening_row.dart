import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/features/content/models/models.dart';
import 'package:Audioverse/features/home/widgets/shimmer_box.dart';

// ContinueListeningItem
//
// Pairs a Content with its progress percentage (0.0–1.0) for this user.
// This is NOT part of the Content model itself — progress is per-user,
// per-content data that lives on ListeningHistory on the backend, so it's
// modeled here as its own small composite rather than polluting Content
// with a field that's meaningless outside this specific screen.
//
// continue_listening_row.dart

class ContinueListeningItem {
  const ContinueListeningItem({
    required this.content,
    required this.progress, // 0.0 to 1.0
  });

  final Content content;
  final double progress;

  factory ContinueListeningItem.fromJson(
      Map<String, dynamic> json,
      Content content,
      ) {
    // Matches ListeningHistory.progressPercent from the backend, which is
    // stored as 0–100 (Decimal) — convert to the 0.0–1.0 scale this UI uses.
    final progressPercent = (json['progressPercent'] as num).toDouble();
    return ContinueListeningItem(
      content: content,
      progress: (progressPercent / 100).clamp(0.0, 1.0),
    );
  }
}

// ── ContinueListeningRow ────────────────────────────────────────────────
//
// Only renders anything if there's history to show — per the brief,
// this section should be invisible entirely (not an empty state) when
// the user has no in-progress items, since "continue listening" doesn't
// make sense as a concept to show empty on a fresh account.
class ContinueListeningRow extends StatelessWidget {
  const ContinueListeningRow({
    super.key,
    required this.items,
    required this.isLoading,
  });

  final List<ContinueListeningItem> items;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (_, __) => const ContinueListeningCardSkeleton(),
        ),
      );
    }

    // Invisible when empty — no header, no placeholder. HomeScreen should
    // conditionally skip rendering this section's title too when items
    // is empty (see HomeScreen for that check).
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) => _ContinueListeningCard(item: items[index]),
      ),
    );
  }
}

class _ContinueListeningCard extends StatelessWidget {
  const _ContinueListeningCard({required this.item});

  final ContinueListeningItem item;

  @override
  Widget build(BuildContext context) {
    final content = item.content;

    return GestureDetector(
      onTap: () => context.push('/home/content/${content.id}'),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: CachedNetworkImage(
                    imageUrl: content.coverUrl,
                    height: 90,
                    width: 160,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 90,
                      width: 160,
                      color: AppColors.darkCard,
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 90,
                      width: 160,
                      color: AppColors.darkCard,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: AppColors.textSecondaryDark),
                    ),
                  ),
                ),
                // Centered play affordance — signals "resume" rather than
                // "start fresh," distinguishing this card visually from a
                // plain ContentGrid card even before reading the progress bar.
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              content.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium(AppColors.textPrimaryDark)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            // Progress bar — uses accent green rather than primary blue so
            // it reads distinctly as "progress" against the blue-heavy UI
            // elsewhere (chips, buttons), borrowing AppColors.accent for
            // exactly that semantic purpose.
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: item.progress,
                minHeight: 4,
                backgroundColor: AppColors.darkBorder,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
