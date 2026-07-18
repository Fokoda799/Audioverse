import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/core/widgets/app_button.dart';
import 'package:Audioverse/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

class AppDialog extends StatefulWidget {
  final String title;
  final String message;

  final String confirmText;
  final String cancelText;

  /// Shows a text input if true.
  final bool showInput;

  /// Makes the input a password field.
  final bool obscureText;

  final String? hintText;
  final String? label;

  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;

  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'OK',
    this.cancelText = 'Cancel',
    this.showInput = false,
    this.obscureText = false,
    this.hintText,
    this.label,
    this.controller,
    this.validator,
  });

  @override
  State<AppDialog> createState() => _AppDialogState();
}

class _AppDialogState extends State<AppDialog> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController? _internalController;

  TextEditingController get _controller =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.showInput && widget.controller == null) {
      _internalController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (widget.showInput) {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      Navigator.of(context).pop(_controller.text.trim());
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text(
        widget.title,
        style: AppTextStyles.titleLarge(AppColors.textPrimaryDark),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.message,
              style: AppTextStyles.bodyMedium(AppColors.textSecondaryDark),
            ),

            if (widget.showInput) ...[
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                controller: _controller,
                hintText: widget.hintText,
                validator: widget.validator,
                isPassword: widget.obscureText,
                keyboardType: widget.obscureText
                    ? TextInputType.visiblePassword
                    : TextInputType.text,
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: widget.cancelText,
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: widget.confirmText,
                onPressed: _onConfirm,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
