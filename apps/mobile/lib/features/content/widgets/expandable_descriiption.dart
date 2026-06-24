// ── Expandable description ───────────────────────────────────────────────
//
// Truncates to 3 lines with a "Read more" toggle. Uses a LayoutBuilder +
// TextPainter to detect whether the text actually overflows 3 lines at
// the available width — if it doesn't, no "Read more" is shown at all,
// since a toggle that doesn't reveal anything new is just noise.
//
// Animates height via AnimatedSize so the expand/collapse doesn't pop.

import 'package:Audioverse/core/theme/theme.dart';
import 'package:flutter/cupertino.dart';

class ExpandableDescription extends StatefulWidget {
  const ExpandableDescription({super.key, required this.text});

  final String text;

  @override
  State<ExpandableDescription> createState() => ExpandableDescriptionState();
}

class ExpandableDescriptionState extends State<ExpandableDescription> {
  static const int _collapsedMaxLines = 3;

  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.text.trim().isEmpty) return const SizedBox.shrink();

    final style = AppTextStyles.bodyMedium(AppColors.textSecondaryDark);

    return LayoutBuilder(
      builder: (context, constraints) {
        final doesOverflow = _doesTextOverflow(
          text: widget.text,
          style: style,
          maxWidth: constraints.maxWidth,
          maxLines: _collapsedMaxLines,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Text(
                widget.text,
                style: style,
                maxLines: _isExpanded ? null : _collapsedMaxLines,
                overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),
            if (doesOverflow) ...[
              const SizedBox(height: AppSpacing.xs),
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Text(
                  _isExpanded ? 'Show less' : 'Read more',
                  style: AppTextStyles.labelSmall(AppColors.primary),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // Measures whether `text` would exceed `maxLines` at `maxWidth` using the
  // given style. Pure layout math — no widget tree involved — so this is
  // cheap to call inside build() via LayoutBuilder.
  bool _doesTextOverflow({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required int maxLines,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    return painter.didExceedMaxLines;
  }
}
