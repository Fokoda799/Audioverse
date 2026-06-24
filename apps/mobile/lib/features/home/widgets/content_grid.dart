import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/features/content/models/models.dart';
import 'package:Audioverse/features/home/widgets/shimmer_box.dart';
import 'package:Audioverse/features/home/widgets/empty_state.dart';

// ContentGrid
//
// 2-column grid of content cards. Tapping a card navigates to the
// detail screen. Handles its own loading (shimmer) and empty states
// internally so HomeScreen doesn't need separate branching logic for
// "grid is loading" vs "grid has no results."
//
// This widget is NOT scrollable on its own — it's meant to be placed
// inside a CustomScrollView as a SliverGrid (via toSliver()) so it
// participates in the same scroll physics as the rest of HomeScreen
// (carousel, chips, etc. all scroll together, not nested scrollables).
//
// content_grid.dart

class ContentGrid extends StatelessWidget {
  const ContentGrid({
    super.key,
    required this.items,
    required this.isLoading,
  });

  final List<Content> items;
  final bool isLoading;

  static const _crossAxisCount = 2;
  static const _spacing = AppSpacing.md;
  // Card aspect ratio: square cover + ~64px for title/author/badge text
  // beneath it. Tuned so two columns of cover art look balanced on a
  // typical phone width without the text area feeling cramped.
  static const _childAspectRatio = 0.68;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.md),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _crossAxisCount,
            mainAxisSpacing: _spacing,
            crossAxisSpacing: _spacing,
            childAspectRatio: _childAspectRatio,
          ),
          // 6 skeleton cards is enough to fill the visible viewport on
          // first load without over-rendering shimmer widgets.
          delegate: SliverChildBuilderDelegate(
                (context, index) => const ContentCardSkeleton(),
            childCount: 6,
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.library_music_outlined,
          title: 'Nothing here yet',
          message: 'Try a different category or check back soon.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.md),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _crossAxisCount,
          mainAxisSpacing: _spacing,
          crossAxisSpacing: _spacing,
          childAspectRatio: _childAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) => ContentCard(content: items[index]),
          childCount: items.length,
        ),
      ),
    );
  }
}

// ── ContentCard ─────────────────────────────────────────────────────────
// Exposed publicly (not private to this file) since ContinueListeningRow
// and search results reuse the same card shape elsewhere.
class ContentCard extends StatelessWidget {
  const ContentCard({super.key, required this.content});

  final Content content;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/content/${content.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: content.coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: AppColors.darkCard),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.darkCard,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ),
                  // Duration badge — bottom-right corner, over the cover art.
                  // Kept on the image itself (rather than in the text area
                  // below) so every card's text block stays the same height
                  // regardless of whether duration is shown.
                  Positioned(
                    right: AppSpacing.xs,
                    bottom: AppSpacing.xs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        content.formattedDuration,
                        style: AppTextStyles.labelSmall(Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge(AppColors.textPrimaryDark)
                .copyWith(fontWeight: FontWeight.w600, height: 1.2),
          ),
          if (content.author != null) ...[
            const SizedBox(height: 2),
            Text(
              content.author!.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium(AppColors.textSecondaryDark),
            ),
          ],
        ],
      ),
    );
  }
}
