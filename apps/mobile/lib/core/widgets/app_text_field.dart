import 'package:flutter/material.dart';
import 'package:Audioverse/core/theme/theme.dart';

/// ─────────────────────────────────────────────
/// AppTextField
///
/// Customizable text field with:
///   • prefix icon
///   • optional trailing action (password toggle, clear, or custom button)
///   • inline error display
///   • animated focus ring
///   • password obscure toggle built-in
/// ─────────────────────────────────────────────
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.enabled = true,
    this.actionIcon,
    this.onActionPressed,
    this.isLoading = false,
  });

  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final bool enabled;

  /// Icon shown inside a trailing button, on the right side of the field.
  /// Ignored if [isPassword] is true (password toggle takes priority).
  final IconData? actionIcon;

  /// Callback fired when the trailing action button is tapped.
  /// If null, the button will not be shown even if [actionIcon] is set.
  final VoidCallback? onActionPressed;

  /// When true, shows a spinner in place of the action button/password
  /// toggle-less suffix slot, regardless of whether [actionIcon] is set.
  final bool isLoading;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField>
    with SingleTickerProviderStateMixin {
  late bool _obscureText;
  late FocusNode _focusNode;
  bool _isFocused = false;

  late AnimationController _focusAnimController;
  late Animation<double> _focusAnim;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    _focusAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _focusAnim = CurvedAnimation(
      parent: _focusAnimController,
      curve: Curves.easeOut,
    );
  }

  void _onFocusChange() {
    if (!mounted) return;

    setState(() => _isFocused = _focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      _focusAnimController.forward();
    } else {
      _focusAnimController.reverse();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    _focusAnimController.dispose();
    super.dispose();
  }

  Widget? _buildSuffixIcon(Color iconColor) {
    // Password toggle takes priority over everything else.
    if (widget.isPassword) {
      return GestureDetector(
        onTap: () => setState(() => _obscureText = !_obscureText),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Icon(
            _obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: iconColor,
            size: 20,
          ),
        ),
      );
    }

    // Loading spinner takes priority over the action button, and shows
    // regardless of whether actionIcon/onActionPressed are set — so you
    // can flip a field into a loading state without also needing an icon.
    if (widget.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (widget.actionIcon != null && widget.onActionPressed != null) {
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            onPressed: widget.onActionPressed,
            icon: Icon(
              widget.actionIcon,
              color: iconColor,
              size: 20,
            ),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
          ),
        ),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final iconColor = _isFocused
        ? AppColors.primary
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return AnimatedBuilder(
      animation: _focusAnim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: _isFocused
                ? [
              BoxShadow(
                color: AppColors.primary.withValues(alpha:  0.15 * _focusAnim.value),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ]
                : [],
          ),
          child: child,
        );
      },
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: _obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onFieldSubmitted,
        validator: widget.validator,
        style: AppTextStyles.bodyLarge(
          isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
        cursorColor: AppColors.primary,
        cursorWidth: 1.5,
        decoration: InputDecoration(
          hintText: widget.hintText,
          labelText: widget.labelText,
          hintStyle: AppTextStyles.bodyLarge(hintColor),
          labelStyle: AppTextStyles.bodyMedium(hintColor),
          floatingLabelStyle: AppTextStyles.labelSmall(AppColors.primary),
          prefixIcon: widget.prefixIcon != null
              ? AnimatedTheme(
            data: Theme.of(context),
            child: IconTheme(
              data: IconThemeData(color: iconColor, size: 20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md),
                child: widget.prefixIcon,
              ),
            ),
          )
              : null,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 52,
            minHeight: 48,
          ),
          suffixIcon: _buildSuffixIcon(iconColor),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 52,
            minHeight: 48,
          ),
          errorStyle: AppTextStyles.labelSmall(AppColors.error).copyWith(
            height: 1.4,
          ),
          errorMaxLines: 2,
        ),
      ),
    );
  }
}
