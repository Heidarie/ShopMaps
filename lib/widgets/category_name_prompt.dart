import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';

const int _maxCategoryNameChars = 100;

Future<String?> showCategoryNamePrompt({
  required BuildContext context,
  required String title,
  required Iterable<String> existingCategories,
  String initialValue = '',
  String? excludedCategory,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CategoryNamePromptDialog(
      title: title,
      existingCategories: existingCategories.toList(),
      initialValue: initialValue,
      excludedCategory: excludedCategory,
    ),
  );
}

class _CategoryNamePromptDialog extends StatefulWidget {
  const _CategoryNamePromptDialog({
    required this.title,
    required this.existingCategories,
    required this.initialValue,
    required this.excludedCategory,
  });

  final String title;
  final List<String> existingCategories;
  final String initialValue;
  final String? excludedCategory;

  @override
  State<_CategoryNamePromptDialog> createState() => _CategoryNamePromptDialogState();
}

class _CategoryNamePromptDialogState extends State<_CategoryNamePromptDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_handleChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  String get _trimmedValue => _controller.text.trim();

  bool get _hasDuplicate {
    final normalizedCandidate = normalizeLatinText(_trimmedValue);
    if (normalizedCandidate.isEmpty) {
      return false;
    }

    final excludedNormalized = widget.excludedCategory == null
        ? null
        : normalizeLatinText(widget.excludedCategory!);

    for (final existing in widget.existingCategories) {
      final normalizedExisting = normalizeLatinText(existing);
      if (excludedNormalized != null && normalizedExisting == excludedNormalized) {
        continue;
      }
      if (normalizedExisting == normalizedCandidate) {
        return true;
      }
    }

    return false;
  }

  bool get _canSave => _trimmedValue.isNotEmpty && !_hasDuplicate;

  void _handleChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _submit() {
    if (!_canSave) {
      return;
    }
    Navigator.of(context).pop(_trimmedValue);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        inputFormatters: [
          LengthLimitingTextInputFormatter(_maxCategoryNameChars),
        ],
        decoration: InputDecoration(
          labelText: l10n.newCategoryName,
          errorText: _hasDuplicate ? l10n.categoryAlreadyExists : null,
        ),
        autofocus: true,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _canSave ? _submit : null,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
