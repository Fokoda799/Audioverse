import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:Audioverse/core/theme/theme.dart';

// ShimmerBox
//
// A single shimmering rectangle — the base building block for every
// loading skeleton in the app (content cards, carousel slides, chips).
// Composing skeletons from this one primitive keeps every loading state
// visually consistent instead of each widget inventing its own shimmer.

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      // Slightly lighter than darkCard so the shimmer is visible against
      // the dark background, but still feels native to the dark theme
      // rather than looking like a generic gray placeholder.
      baseColor: AppColors.darkCard,
      highlightColor: AppColors.darkBorder.withValues(alpha: 0.5),
      period: const Duration(milliseconds: 1400),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.md),
        ),
      ),
    );
  }
}

// ── Pre-composed skeleton for a single ContentCard ────────────────────────
// Mirrors ContentCard's exact layout (cover + title line + author line)
// so the loading state doesn't visually "jump" once real content arrives.
class ContentCardSkeleton extends StatelessWidget {
  const ContentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ShimmerBox(borderRadius: AppRadius.lg),
        ),
        SizedBox(height: AppSpacing.sm),
        ShimmerBox(height: 14, width: double.infinity),
        SizedBox(height: 6),
        ShimmerBox(height: 12, width: 90),
      ],
    );
  }
}

// ── Pre-composed skeleton for the Featured Carousel ────────────────────────
class FeaturedCarouselSkeleton extends StatelessWidget {
  const FeaturedCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ShimmerBox(height: 200, borderRadius: AppRadius.xl),
    );
  }
}

// ── Pre-composed skeleton for a ContinueListening card ─────────────────────
class ContinueListeningCardSkeleton extends StatelessWidget {
  const ContinueListeningCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(height: 90, width: 160, borderRadius: AppRadius.md),
          SizedBox(height: AppSpacing.sm),
          ShimmerBox(height: 12, width: 120),
        ],
      ),
    );
  }
}
