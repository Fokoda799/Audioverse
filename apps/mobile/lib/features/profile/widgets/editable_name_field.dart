import 'package:flutter/material.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/core/widgets/widgets.dart';

// EditableNameField
//
// Tap-to-edit text field used for BOTH the display name and the bio on
// ProfileScreen's hero header — hence the centered/isSecondary/maxLines
// params, even though the class name still says "Name" (kept for now
// rather than renaming to something generic like EditableTextField,
// since renaming would touch every call site for a cosmetic reason —
// worth doing in a later pass if more fields adopt this widget).
//
// View state sits directly on the gradient hero with NO background of
// its own — tapping the text itself enters edit mode (not a separate
// pencil icon button), which is what makes this feel like "this text
// IS editable" rather than "there's a button near this text." A subtle
// pencil glyph still appears, but inline next to the text, not as a
// large standalone tap target competing for space in a centered layout.
//
// editable_name_field.dart

class EditableNameField extends StatefulWidget {
  const EditableNameField({
    super.key,
    required this.name,
    required this.onSave,
    this.emptyPlaceholder = 'Add a name',
    this.maxLines = 1,
    this.centered = false,
    this.isSecondary = false,
  });

  final String name;
  final Future<void> Function(String newValue) onSave;
  final String emptyPlaceholder;
  final int maxLines;
  // Centers text + edit controls — used on ProfileScreen's hero where
  // everything is vertically stacked and centered under the avatar.
  final bool centered;
  // Secondary = smaller, dimmer text (for bio, under the bold name).
  final bool isSecondary;

  @override
  State<EditableNameField> createState() => _EditableNameFieldState();
}

class _EditableNameFieldState extends State<EditableNameField> {
  late TextEditingController _controller;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.name);
  }

  @override
  void didUpdateWidget(EditableNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.name != widget.name) {
      _controller.text = widget.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _error = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _controller.text = widget.name;
      _isEditing = false;
      _error = null;
    });
  }

  Future<void> _confirmEditing() async {
    final newValue = _controller.text.trim();

    if (newValue == widget.name) {
      setState(() => _isEditing = false);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await widget.onSave(newValue);
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  TextStyle get _textStyle => widget.isSecondary
      ? AppTextStyles.bodyMedium(AppColors.textSecondaryDark)
      : AppTextStyles.titleLarge(AppColors.textPrimaryDark)
      .copyWith(fontWeight: FontWeight.w700);

  @override
  Widget build(BuildContext context) {
    if (!_isEditing) {
      final hasValue = widget.name.isNotEmpty;

      // Tapping the text/placeholder itself starts editing — no separate
      // icon button taking up its own row-width budget in a centered layout.
      return GestureDetector(
        onTap: _startEditing,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment:
          widget.centered ? MainAxisAlignment.center : MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                hasValue ? widget.name : widget.emptyPlaceholder,
                textAlign: widget.centered ? TextAlign.center : TextAlign.start,
                maxLines: widget.maxLines,
                overflow: TextOverflow.ellipsis,
                style: hasValue
                    ? _textStyle
                    : _textStyle.copyWith(color: AppColors.textSecondaryDark, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.edit_outlined,
              size: widget.isSecondary ? 13 : 15,
              color: AppColors.textSecondaryDark.withValues(alpha: 0.7),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
      widget.centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _controller,
                hintText: widget.emptyPlaceholder,
                enabled: !_isSaving,
                textInputAction:
                widget.maxLines > 1 ? TextInputAction.newline : TextInputAction.done,
                onFieldSubmitted: widget.maxLines > 1 ? null : (_) => _confirmEditing(),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: AppLoader(size: 20, strokeWidth: 2),
              )
            else ...[
              IconButton(
                onPressed: _confirmEditing,
                icon: const Icon(Icons.check_rounded, color: AppColors.success),
              ),
              IconButton(
                onPressed: _cancelEditing,
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryDark),
              ),
            ],
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(_error!, style: AppTextStyles.labelSmall(AppColors.error)),
          ),
      ],
    );
  }
}
