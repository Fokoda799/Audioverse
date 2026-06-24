import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/features/content/models/models.dart';

// FeaturedCarousel
//
// A PageView of 3-5 featured content items with auto-scroll every 4s,
// pausing whenever the user manually interacts (drags), and resuming
// after they let go. Each slide is full-bleed cover art with a gradient
// overlay and title/author — the Larq Player "hero" treatment, rather
// than a generic card-in-a-carousel look.
//
// featured_carousel.dart

class FeaturedCarousel extends StatefulWidget {
  const FeaturedCarousel({super.key, required this.items});

  final List<Content> items;

  @override
  State<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<FeaturedCarousel> {
  late final PageController _controller;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  static const _autoScrollInterval = Duration(seconds: 4);
  static const _pageAnimationDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();

    // Don't bother auto-scrolling a single-item carousel — there's
    // nothing to advance to.
    if (widget.items.length <= 1) return;

    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (_) {
      final isLastPage = _currentPage == widget.items.length - 1;
      final nextPage = isLastPage ? 0 : _currentPage + 1;

      _controller.animateToPage(
        nextPage,
        duration: _pageAnimationDuration,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  // Called the moment the user touches the carousel — pauses auto-scroll
  // immediately so a manual drag never fights against a timer-driven page
  // change mid-gesture.
  void _onInteractionStart() {
    _autoScrollTimer?.cancel();
  }

  // Called when the user lifts their finger — resumes auto-scroll from
  // wherever they left it, restarting the 4s countdown fresh.
  void _onInteractionEnd() {
    _startAutoScroll();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Listener(
            onPointerDown: (_) => _onInteractionStart(),
            onPointerUp: (_) => _onInteractionEnd(),
            onPointerCancel: (_) => _onInteractionEnd(),
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.items.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                return _FeaturedSlide(content: widget.items[index]);
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _DotIndicator(
          count: widget.items.length,
          currentIndex: _currentPage,
        ),
      ],
    );
  }
}

class _FeaturedSlide extends StatelessWidget {
  const _FeaturedSlide({required this.content});

  final Content content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: GestureDetector(
        onTap: () => context.push('/content/${content.id}'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: content.coverUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: AppColors.darkCard),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.darkCard,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: AppColors.textSecondaryDark),
                ),
              ),
              // Gradient ensures title text stays legible regardless of
              // how bright/busy the cover art is underneath it.
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (content.category != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          content.category!.name,
                          style: AppTextStyles.labelSmall(Colors.white),
                        ),
                      ),
                    Text(
                      content.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleLarge(AppColors.textPrimaryDark),
                    ),
                    if (content.author != null)
                      Text(
                        content.author!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium(AppColors.textSecondaryDark),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.darkBorder,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        );
      }),
    );
  }
}
