import 'package:flutter/cupertino.dart';


class AnimatedSection extends StatelessWidget {
  const AnimatedSection({
    super.key,
    required this.slide,
    required this.fade,
    required this.child,
  });

  final Animation<Offset> slide;
  final Animation<double> fade;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}