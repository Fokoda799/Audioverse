import 'package:flutter/material.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/features/content/models/content_models.dart';
import 'package:Audioverse/features/home/widgets/content_grid.dart'; // ContentCard
import 'package:Audioverse/features/home/widgets/shimmer_box.dart';

class AudiobookRow extends StatelessWidget {
  const AudiobookRow({
    super.key,
    required this.items,
    required this.isLoading,
  });

  final List<Content> items;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 240,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (_, __) => const ShimmerBox(
            width: 150,
            height: 240,
            borderRadius: AppRadius.lg,
          ),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 240,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final content = items[index];
          return SizedBox(
            width: 150,
            child: ContentCard(content: content),
          );
        },
      ),
    );
  }
}
