import 'package:flutter/material.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/features/content/models/models.dart';

// CategoryChips
//
// Horizontally scrollable row of filter chips: "All" + one per Category.
// Tapping a chip calls onCategorySelected — the parent (HomeScreen) owns
// the actual filtering logic via ContentListProvider; this widget is
// purely presentational and reports taps upward.
//
// "All" is represented as `null` selectedCategoryId, matching
// ContentFilters where categoryId == null means "no filter."
//
// category_chips.dart

class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  final List<Category> categories;
  final String? selectedCategoryId; // null = "All" is selected
  final ValueChanged<String?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        // +1 for the leading "All" chip
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _Chip(
              label: 'All',
              isSelected: selectedCategoryId == null,
              // "All" has no brand color of its own — use primary so it
              // still reads as "active" when selected.
              activeColor: AppColors.primary,
              onTap: () => onCategorySelected(null),
            );
          }

          final category = categories[index - 1];
          return _Chip(
            label: category.name,
            isSelected: selectedCategoryId == category.id,
            // Each category gets its own accent color (colorHex from the
            // backend) when active — this is what makes the chip row feel
            // alive rather than a flat list of identical Material chips.
            activeColor: _parseColor(category.colorHex) ?? AppColors.primary,
            onTap: () => onCategorySelected(category.id),
          );
        },
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    final cleanHex = hex.replaceAll('#', '');
    final value = int.tryParse('FF$cleanHex', radix: 16);
    return value != null ? Color(value) : null;
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.16) : AppColors.darkCard,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.darkBorder,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.labelLarge(
            isSelected ? activeColor : AppColors.textSecondaryDark,
          ).copyWith(fontSize: 14),
        ),
      ),
    );
  }
}
