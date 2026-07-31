import 'package:flutter/material.dart';
import 'package:Audioverse/core/theme/theme.dart';


class AnimatedHeroGraphic extends StatefulWidget {
  const AnimatedHeroGraphic({super.key, this.size = 120});

  final double size;

  @override
  State<AnimatedHeroGraphic> createState() => _AnimatedHeroGraphicState();
}

class _AnimatedHeroGraphicState extends State<AnimatedHeroGraphic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Outer ring: breathes out slightly further/slower.
  late final Animation<double> _outerScale;
  late final Animation<double> _outerOpacity;

  // Middle ring: breathes with a slight phase offset for a
  // layered, organic feel rather than everything moving in sync.
  late final Animation<double> _middleScale;
  late final Animation<double> _middleOpacity;

  // Center badge: very subtle pulse, like a heartbeat.
  late final Animation<double> _coreScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _outerScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _outerOpacity = Tween<double>(begin: 0.08, end: 0.14).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _middleScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 1.0, curve: Curves.easeInOut),
      ),
    );
    _middleOpacity = Tween<double>(begin: 0.10, end: 0.16).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 1.0, curve: Curves.easeInOut),
      ),
    );

    _coreScale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: _outerScale.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(
                      alpha: _outerOpacity.value,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: _middleScale.value,
                child: Container(
                  width: widget.size / 1.427,
                  height: widget.size / 1.427,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(
                      alpha: _middleOpacity.value,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: _coreScale.value,
                child: Container(
                  width: widget.size / 2.14,
                  height: widget.size / 2.14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    boxShadow: AppShadows.buttonPrimary,
                  ),
                  child: Icon(
                    Icons.headphones_rounded,
                    color: Colors.white,
                    size: widget.size / 4.61,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
