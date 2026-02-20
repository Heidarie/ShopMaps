import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';

class GroceryListEditorScreen extends StatefulWidget {
  const GroceryListEditorScreen({
    super.key,
    required this.controller,
    required this.listId,
  });

  final AppController controller;
  final String listId;

  @override
  State<GroceryListEditorScreen> createState() => _GroceryListEditorScreenState();
}

class _GroceryListEditorScreenState extends State<GroceryListEditorScreen> {
  late final TextEditingController _itemController;
  List<ItemHint> _hints = const [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _itemController = TextEditingController();
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final groceryList = widget.controller.getGroceryListById(widget.listId);

        if (groceryList == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.nothingToShow)),
          );
        }

        final grouped = _groupItems(groceryList.items, l10n);

        return Scaffold(
          appBar: AppBar(title: Text(groceryList.name)),
          body: Column(
            children: [
              Expanded(
                child: grouped.isEmpty
                    ? Center(child: Text(l10n.nothingToShow))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: grouped.length,
                        itemBuilder: (context, index) {
                          final entry = grouped[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.categoryLabel(entry.key),
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    ...entry.value.map(
                                      (item) => ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(item.name),
                                        trailing: IconButton(
                                          tooltip: l10n.deleteItem,
                                          icon: const Icon(Icons.delete_outline),
                                          onPressed: () {
                                            widget.controller.removeItemFromList(
                                              listId: groceryList.id,
                                              itemId: item.id,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _itemController,
                            decoration: InputDecoration(
                              labelText: l10n.itemName,
                            ),
                            onChanged: _onItemChanged,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.selectedCategory,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ActionChip(
                              onPressed: _pickCategory,
                              avatar: Icon(
                                _selectedCategory == null
                                    ? Icons.add_circle_outline
                                    : Icons.category_outlined,
                                size: 18,
                              ),
                              label: Text(
                                _selectedCategory == null
                                    ? l10n.addCategory
                                    : l10n.categoryLabel(_selectedCategory!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_hints.isNotEmpty) ...[
                            Text(
                              l10n.itemHint,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _hints
                                  .map(
                                    (hint) => ActionChip(
                                      label: Text(l10n.hintLabel(hint.itemName, hint.category)),
                                      onPressed: () {
                                        setState(() {
                                          _itemController.text = hint.itemName;
                                          _itemController.selection = TextSelection.collapsed(
                                            offset: _itemController.text.length,
                                          );
                                          _selectedCategory = hint.category;
                                          _hints = widget.controller.findItemHints(hint.itemName);
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          ] else
                            Text(
                              l10n.noHints,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => _addItem(groceryList.id),
                            icon: const Icon(Icons.add),
                            label: Text(l10n.addItem),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<MapEntry<String, List<GroceryItem>>> _groupItems(
    List<GroceryItem> items,
    AppLocalizations l10n,
  ) {
    final grouped = <String, List<GroceryItem>>{};

    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => l10n.categoryLabel(a.key).toLowerCase().compareTo(
            l10n.categoryLabel(b.key).toLowerCase(),
          ));

    for (final entry in entries) {
      entry.value.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return entries;
  }

  void _onItemChanged(String value) {
    final hints = widget.controller.findItemHints(value);
    final exactCategory = widget.controller.findCategoryForExactItem(value);

    setState(() {
      _hints = hints;
      if (exactCategory != null) {
        _selectedCategory = exactCategory;
      }
    });
  }

  Future<void> _pickCategory() async {
    final l10n = AppLocalizations.of(context);

    final selection = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        final categories = [...widget.controller.categories]
          ..sort((a, b) => l10n.categoryLabel(a).toLowerCase().compareTo(
                l10n.categoryLabel(b).toLowerCase(),
              ));

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: Text(l10n.addNewCategory),
                onTap: () => Navigator.pop(sheetContext, '__add_new__'),
              ),
              if (categories.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.createCategoryFirst),
                ),
              if (categories.isNotEmpty)
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return ListTile(
                        title: Text(l10n.categoryLabel(category)),
                        onTap: () => Navigator.pop(sheetContext, category),
                      );
                    },
                  ),
                ),
            ],
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
        _selectedCategory = created;
      });
      return;
    }

    setState(() {
      _selectedCategory = selection;
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

  Future<void> _addItem(String listId) async {
    final l10n = AppLocalizations.of(context);
    final itemName = _itemController.text.trim();

    if (itemName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.nameCannotBeEmpty)),
      );
      return;
    }

    if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectCategoryFirst)),
      );
      return;
    }

    await widget.controller.addItemToList(
      listId: listId,
      itemName: itemName,
      category: _selectedCategory!,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _itemController.clear();
      _hints = const [];
      _selectedCategory = null;
    });
  }
}
