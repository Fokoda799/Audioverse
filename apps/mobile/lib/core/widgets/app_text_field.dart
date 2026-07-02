import 'package:flutter/material.dart';
import 'package:Audioverse/core/theme/theme.dart';

/// ─────────────────────────────────────────────
/// AppTextField
///
/// Customizable text field with:
///   • prefix icon
///   • optional trailing action (password toggle, clear)
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
                color: AppColors.primary.withOpacity(0.15 * _focusAnim.value),
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
          suffixIcon: widget.isPassword
              ? GestureDetector(
            onTap: () => setState(() => _obscureText = !_obscureText),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md),
              child: Icon(
                _obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: iconColor,
                size: 20,
              ),
            ),
          )
              : null,
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
