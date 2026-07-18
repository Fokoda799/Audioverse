import 'package:flutter/material.dart';
import 'package:Audioverse/core/theme/theme.dart';

// SearchBar
//
// The fixed top bar: search icon + TextField + conditional clear button.
// Extracted as-is from SearchScreen — purely presentational, owns no
// state of its own. The parent screen owns the TextEditingController
// and FocusNode so it can autofocus/clear from outside this widget.
//
// search_bar.dart

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.surfaceColor,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Color surfaceColor;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  const SizedBox(width: AppSpacing.md),
                  Icon(Icons.search_rounded, size: 20, color: textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      textInputAction: TextInputAction.search,
                      keyboardType: TextInputType.text,
                      style: AppTextStyles.bodyLarge(textPrimary),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: 'Search audiobooks, podcasts…',
                        hintStyle: AppTextStyles.bodyLarge(textSecondary),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (_, value, __) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 18, color: textSecondary),
                        onPressed: onClear,
                        tooltip: 'Clear',
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        constraints: const BoxConstraints(),
                      );
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
