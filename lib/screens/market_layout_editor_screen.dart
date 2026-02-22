import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';

const int _maxInputChars = 100;

class MarketLayoutEditorScreen extends StatefulWidget {
  const MarketLayoutEditorScreen({
    super.key,
    this.layout,
    List<String>? categories,
  }) : categories = categories ?? const [];

  final MarketLayout? layout;
  final List<String> categories;

  @override
  State<MarketLayoutEditorScreen> createState() => _MarketLayoutEditorScreenState();
}

class _MarketLayoutEditorScreenState extends State<MarketLayoutEditorScreen> {
  late final TextEditingController _nameController;
  late List<String> _allCategories;
  late List<String> _orderedCategories;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.layout?.name ?? '');
    _allCategories = [...widget.categories];
    _orderedCategories = [...(widget.layout?.categoryOrder ?? const <String>[])];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.layout != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editMarketLayout : l10n.addMarketLayout),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_maxInputChars),
              ],
              decoration: InputDecoration(labelText: l10n.marketLayoutName),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.categoriesInOrder,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _orderedCategories.isEmpty
                  ? Center(child: Text(l10n.noCategoriesInLayout))
                  : ReorderableListView.builder(
                      itemCount: _orderedCategories.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }

                          final item = _orderedCategories.removeAt(oldIndex);
                          _orderedCategories.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final category = _orderedCategories[index];

                        return Card(
                          key: ValueKey(category),
                          child: ListTile(
                            title: Text(l10n.categoryLabel(category)),
                            leading: ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_indicator),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _orderedCategories.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _addCategory,
              icon: const Icon(Icons.add),
              label: Text(l10n.addCategoryToLayout),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _save,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
              ),
              icon: const Icon(Icons.save),
              label: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCategory() async {
    final l10n = AppLocalizations.of(context);
    final available = _allCategories
        .where((category) =>
            !_orderedCategories.any((selected) => selected.toLowerCase() == category.toLowerCase()))
        .toList()
      ..sort((a, b) => l10n.categoryLabel(a).toLowerCase().compareTo(
            l10n.categoryLabel(b).toLowerCase(),
          ));

    final selection = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: Text(l10n.addNewCategory),
                  onTap: () => Navigator.pop(sheetContext, '__add_new__'),
                ),
                if (available.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.createCategoryFirst),
                  ),
                if (available.isNotEmpty)
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: available.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final category = available[index];
                        return ListTile(
                          title: Text(l10n.categoryLabel(category)),
                          onTap: () => Navigator.pop(sheetContext, category),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selection == null) {
      return;
    }

    if (selection == '__add_new__') {
      final created = await _promptAndCreateCategory();
      if (!mounted || created == null) {
        return;
      }

      setState(() {
        if (!_allCategories.any((existing) => existing.toLowerCase() == created.toLowerCase())) {
          _allCategories.add(created);
        }
        if (!_orderedCategories.any((existing) => existing.toLowerCase() == created.toLowerCase())) {
          _orderedCategories.add(created);
        }
      });
      return;
    }

    setState(() {
      if (!_orderedCategories.any((existing) => existing.toLowerCase() == selection.toLowerCase())) {
        _orderedCategories.add(selection);
      }
    });
  }

  Future<String?> _promptAndCreateCategory() async {
    final l10n = AppLocalizations.of(context);
    var draftName = '';

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.addNewCategory),
          content: TextField(
            inputFormatters: [
              LengthLimitingTextInputFormatter(_maxInputChars),
            ],
            decoration: InputDecoration(labelText: l10n.newCategoryName),
            autofocus: true,
            onChanged: (value) {
              draftName = value;
            },
            onSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isNotEmpty) {
                Navigator.pop(dialogContext, trimmed);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final value = draftName.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(dialogContext, value);
                }
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );

    if (name == null || name.trim().isEmpty) {
      return null;
    }

    return name.trim();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.nameCannotBeEmpty)),
      );
      return;
    }

    final result = MarketLayout(
      id: widget.layout?.id ?? createId(),
      name: name,
      categoryOrder: _orderedCategories,
    );

    Navigator.pop(context, result);
  }
}
