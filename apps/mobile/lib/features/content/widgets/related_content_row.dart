// ── Related content rows ─────────────────────────────────────────────────
//
// Two horizontal-scroll rows, each independently driven by
// RelatedContentProvider's two lists. A row renders nothing at all
// (not even its title) when there's nothing to show — no empty-state
// illustration here, since this is a secondary section beneath the
// description, not a primary screen state.
//
// Usage inside ContentDetailScreen's build (after the description):
//
//   Consumer<RelatedContentProvider>(
//     builder: (context, related, _) => Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         RelatedContentRow(
//           title: 'More from this author',
//           items: related.byAuthor,
//           isLoading: related.isLoadingAuthor,
//           hasError: related.authorError != null,
//         ),
//         const SizedBox(height: AppSpacing.lg),
//         RelatedContentRow(
//           title: 'More in this category',
//           items: related.byCategory,
//           isLoading: related.isLoadingCategory,
//           hasError: related.categoryError != null,
//         ),
//       ],
//     ),
//   ),

import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/features/content/models/content_models.dart';
import 'package:Audioverse/features/home/widgets/shimmer_box.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RelatedContentRow extends StatelessWidget {
  const RelatedContentRow({
    super.key,
    required this.title,
    required this.items,
    required this.isLoading,
    required this.hasError,
  });

  final String title;
  final List<Content> items;
  final bool isLoading;
  final bool hasError;

  static const double _cardWidth = 132;
  static const double _cardHeight = 200;

  @override
  Widget build(BuildContext context) {
    // Nothing to show and nothing loading/failed — collapse entirely.
    if (!isLoading && !hasError && items.isEmpty) {
      return const SizedBox.shrink();
    }
    // A failed fetch with no cached items — quietly say nothing rather
    // than surface a second error UI on top of the detail screen's own.
    if (hasError && items.isEmpty && !isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleLarge(AppColors.textPrimaryDark),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: _cardHeight,
          child: isLoading
              ? const _RelatedRowSkeleton(cardWidth: _cardWidth, cardHeight: _cardHeight)
              : ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) => _RelatedContentCard(
              content: items[index],
              width: _cardWidth,
            ),
          ),
        ),
      ],
    );
  }
}

class _RelatedContentCard extends StatelessWidget {
  const _RelatedContentCard({required this.content, required this.width});

  final Content content;
  final double width;

  void _onTap(BuildContext context) {
    // Mirrors the existing /home/content/:id route used to reach this
    // very screen — pushing here stacks a new detail screen on top.
    context.push('/content/${content.id}');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: content.coverUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: AppColors.darkCard),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.darkCard,
                    child: const Icon(Icons.image_not_supported_outlined,
                        color: AppColors.textSecondaryDark, size: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              content.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium(AppColors.textPrimaryDark)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            if (content.author != null)
              Text(
                content.author!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall(AppColors.textSecondaryDark),
              ),
          ],
        ),
      ),
    );
  }
}

class _RelatedRowSkeleton extends StatelessWidget {
  const _RelatedRowSkeleton({required this.cardWidth, required this.cardHeight});

  final double cardWidth;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
      itemBuilder: (_, __) => SizedBox(
        width: cardWidth,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ShimmerBox(borderRadius: AppRadius.md),
            ),
            SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 14,
              child: ShimmerBox(borderRadius: AppRadius.sm),
            ),
          ],
        ),
      ),
    );
  }
}
