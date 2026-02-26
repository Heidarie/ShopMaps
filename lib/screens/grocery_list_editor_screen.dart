import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';

const int _maxInputChars = 100;

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
  int _selectedQuantity = 1;

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
                                    for (var itemIndex = 0;
                                        itemIndex < entry.value.length;
                                        itemIndex++) ...[
                                      ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        onTap: () {
                                          _editItem(
                                            listId: groceryList.id,
                                            item: entry.value[itemIndex],
                                          );
                                        },
                                        title: Text(
                                          '${entry.value[itemIndex].name} x ${entry.value[itemIndex].quantity}',
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: l10n.edit,
                                              icon: const Icon(Icons.edit_outlined),
                                              onPressed: () {
                                                _editItem(
                                                  listId: groceryList.id,
                                                  item: entry.value[itemIndex],
                                                );
                                              },
                                            ),
                                            IconButton(
                                              tooltip: l10n.deleteItem,
                                              icon: Icon(
                                                Icons.delete_outline,
                                                color: Theme.of(context).colorScheme.error,
                                              ),
                                              onPressed: () {
                                                widget.controller.removeItemFromList(
                                                  listId: groceryList.id,
                                                  itemId: entry.value[itemIndex].id,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (itemIndex < entry.value.length - 1)
                                        const Divider(height: 1),
                                    ],
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
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(_maxInputChars),
                            ],
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
                          Row(
                            children: [
                              Text(
                                l10n.quantity,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: _selectedQuantity > 1
                                    ? () {
                                        setState(() {
                                          _selectedQuantity -= 1;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(
                                '$_selectedQuantity',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedQuantity += 1;
                                  });
                                },
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
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
    final canCreateNewCategory = widget.controller.categories.length < maxCategoryCount;

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
                subtitle: canCreateNewCategory
                    ? null
                    : Text(l10n.maxCategoriesReached(maxCategoryCount)),
                enabled: canCreateNewCategory,
                onTap: canCreateNewCategory
                    ? () => Navigator.pop(sheetContext, '__add_new__')
                    : null,
              ),
              if (categories.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.createCategoryFirst),
                ),
              if (categories.isNotEmpty)
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
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

  Future<void> _editItem({
    required String listId,
    required GroceryItem item,
  }) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<_EditItemResult>(
      context: context,
      builder: (_) => _EditItemDialog(
        item: item,
        categories: widget.controller.categories,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final updated = await widget.controller.updateItemInList(
      listId: listId,
      itemId: item.id,
      itemName: result.name,
      category: result.category,
      quantity: result.quantity,
    );
    if (!mounted || updated) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.maxCategoriesReached(maxCategoryCount))),
    );
  }

  Future<String?> _promptAndCreateCategory() async {
    final l10n = AppLocalizations.of(context);
    if (widget.controller.categories.length >= maxCategoryCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.maxCategoriesReached(maxCategoryCount))),
      );
      return null;
    }
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

    final added = await widget.controller.addItemToList(
      listId: listId,
      itemName: itemName,
      category: _selectedCategory!,
      quantity: _selectedQuantity,
    );
    if (!added) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.maxCategoriesReached(maxCategoryCount))),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _itemController.clear();
      _hints = const [];
      _selectedCategory = null;
      _selectedQuantity = 1;
    });
  }
}

class _EditItemResult {
  const _EditItemResult({
    required this.name,
    required this.category,
    required this.quantity,
  });

  final String name;
  final String category;
  final int quantity;
}

class _EditItemDialog extends StatefulWidget {
  const _EditItemDialog({
    required this.item,
    required this.categories,
  });

  final GroceryItem item;
  final List<String> categories;

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  late final TextEditingController _nameController;
  late int _draftQuantity;
  late String _draftCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _draftQuantity = widget.item.quantity;
    _draftCategory = widget.item.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = [...widget.categories];
    if (!categories.any((entry) => entry.toLowerCase() == _draftCategory.toLowerCase())) {
      categories.add(_draftCategory);
    }
    categories.sort((a, b) => l10n.categoryLabel(a).toLowerCase().compareTo(
          l10n.categoryLabel(b).toLowerCase(),
        ));

    String? selectedCategory;
    for (final category in categories) {
      if (category.toLowerCase() == _draftCategory.toLowerCase()) {
        selectedCategory = category;
        break;
      }
    }

    return AlertDialog(
      title: Text(l10n.editItem),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_maxInputChars),
              ],
              decoration: InputDecoration(labelText: l10n.itemName),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              items: categories
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(l10n.categoryLabel(category)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _draftCategory = value;
                });
              },
              decoration: InputDecoration(labelText: l10n.category),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  l10n.quantity,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: _draftQuantity > 1
                      ? () {
                          setState(() {
                            _draftQuantity -= 1;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_draftQuantity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _draftQuantity += 1;
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final cleanedName = _nameController.text.trim();
            if (cleanedName.isEmpty || _draftCategory.trim().isEmpty) {
              return;
            }
            Navigator.pop(
              context,
              _EditItemResult(
                name: cleanedName,
                category: _draftCategory,
                quantity: _draftQuantity,
              ),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
