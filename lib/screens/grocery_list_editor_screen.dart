import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../cloud/cloud_controller.dart';
import '../cloud/cloud_localizations.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../widgets/category_name_prompt.dart';
import '../widgets/delete_category_prompt.dart';

const int _maxInputChars = 100;
const int _maxVisibleItemHints = 3;
const _itemEditorScrollKey = ValueKey('grocery-list-item-editor-scroll');

class GroceryListEditorScreen extends StatefulWidget {
  const GroceryListEditorScreen({
    super.key,
    required this.controller,
    required this.listId,
    this.cloudController,
    this.isShared = false,
  }) : assert(!isShared || cloudController != null);

  final AppController controller;
  final String listId;
  final CloudController? cloudController;
  final bool isShared;

  @override
  State<GroceryListEditorScreen> createState() =>
      _GroceryListEditorScreenState();
}

class _GroceryListEditorScreenState extends State<GroceryListEditorScreen> {
  late final TextEditingController _itemController;
  late final FocusNode _itemFocusNode;
  late final Listenable _listenable;
  List<ItemHint> _hints = const [];
  String? _selectedCategory;
  int _selectedQuantity = 1;
  bool _isAddingItem = false;
  bool _showAddedItemToast = false;
  bool _addedSharedItems = false;
  bool _sharedAdditionNotificationSent = false;
  Timer? _addedItemToastTimer;

  @override
  void initState() {
    super.initState();
    _itemController = TextEditingController();
    _itemFocusNode = FocusNode();
    _listenable = widget.isShared
        ? Listenable.merge([widget.controller, widget.cloudController!])
        : widget.controller;
  }

  @override
  void dispose() {
    _addedItemToastTimer?.cancel();
    _itemController.dispose();
    _itemFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope<void>(
      canPop: !_isAddingItem,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isAddingItem) {
          _showList();
          return;
        }
        if (didPop) {
          _notifySharedListAdditions();
        }
      },
      child: ListenableBuilder(
        listenable: _listenable,
        builder: (context, _) {
          final groceryList = _groceryList;

          if (groceryList == null) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(child: Text(l10n.nothingToShow)),
            );
          }

          final grouped = _groupItems(groceryList.items, l10n);
          return Scaffold(
            appBar: AppBar(
              title: Text(_isAddingItem ? l10n.addItem : groceryList.name),
              actions: _isAddingItem
                  ? null
                  : [
                      IconButton(
                        tooltip: l10n.loadFrequentItems,
                        icon: const Icon(Icons.autorenew_rounded),
                        onPressed: () => _showLoadFrequentItemsDialog(
                          listId: groceryList.id,
                        ),
                      ),
                    ],
            ),
            body: _isAddingItem
                ? _buildAddItemScreen(
                    context: context,
                    listId: groceryList.id,
                    l10n: l10n,
                  )
                : _buildListScreen(
                    context: context,
                    grouped: grouped,
                    listId: groceryList.id,
                    l10n: l10n,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildListScreen({
    required BuildContext context,
    required List<MapEntry<String, List<GroceryItem>>> grouped,
    required String listId,
    required AppLocalizations l10n,
  }) {
    return Column(
      children: [
        Expanded(
          child: _buildGroupedItems(
            context: context,
            grouped: grouped,
            listId: listId,
            l10n: l10n,
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              onPressed: _showAddItem,
              icon: const Icon(Icons.add),
              label: Text(l10n.addItem),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddItemScreen({
    required BuildContext context,
    required String listId,
    required AppLocalizations l10n,
  }) {
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: _itemEditorScrollKey,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _itemController,
                            focusNode: _itemFocusNode,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(_maxInputChars),
                            ],
                            decoration: InputDecoration(
                              labelText: l10n.itemName,
                            ),
                            onChanged: _onItemChanged,
                          ),
                          const SizedBox(height: 8),
                          if (_hints.isNotEmpty) ...[
                            Text(
                              l10n.itemHint,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            _ItemHints(hints: _hints, onSelected: _selectHint),
                            const SizedBox(height: 8),
                          ] else if (_itemController.text
                              .trim()
                              .isNotEmpty) ...[
                            Text(
                              l10n.noHints,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                          ],
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
                        ],
                      ),
                    ),
                  ),
                  if (_showAddedItemToast)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _InlineToast(message: l10n.itemAdded),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showList,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n.back),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _addItem(listId),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addItem),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedItems({
    required BuildContext context,
    required List<MapEntry<String, List<GroceryItem>>> grouped,
    required String listId,
    required AppLocalizations l10n,
  }) {
    if (grouped.isEmpty) {
      return Center(child: Text(l10n.nothingToShow));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                  for (
                    var itemIndex = 0;
                    itemIndex < entry.value.length;
                    itemIndex++
                  ) ...[
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        _editItem(listId: listId, item: entry.value[itemIndex]);
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
                                listId: listId,
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
                              _removeItem(
                                listId: listId,
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
      ..sort(
        (a, b) => l10n
            .categoryLabel(a.key)
            .toLowerCase()
            .compareTo(l10n.categoryLabel(b.key).toLowerCase()),
      );

    for (final entry in entries) {
      entry.value.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }

    return entries;
  }

  void _onItemChanged(String value) {
    final hints = _visibleHintsFor(value);
    final exactCategory = widget.controller.findCategoryForExactItem(value);

    setState(() {
      _showAddedItemToast = false;
      _hints = hints;
      if (exactCategory != null) {
        _selectedCategory = exactCategory;
      }
    });
  }

  void _selectHint(ItemHint hint) {
    setState(() {
      _itemController.text = hint.itemName;
      _itemController.selection = TextSelection.collapsed(
        offset: _itemController.text.length,
      );
      _selectedCategory = hint.category;
      _hints = const [];
      _showAddedItemToast = false;
    });
    _requestItemInputFocus();
  }

  List<ItemHint> _visibleHintsFor(String value) {
    return widget.controller
        .findItemHints(value)
        .take(_maxVisibleItemHints)
        .toList(growable: false);
  }

  void _requestItemInputFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _itemFocusNode.requestFocus();
      }
    });
  }

  void _showAddItem() {
    setState(() {
      _isAddingItem = true;
    });
    _requestItemInputFocus();
  }

  void _showList() {
    setState(() {
      _isAddingItem = false;
      _showAddedItemToast = false;
    });
    _addedItemToastTimer?.cancel();
    _itemFocusNode.unfocus();
  }

  Future<void> _pickCategory() async {
    final l10n = AppLocalizations.of(context);

    final selection = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final canCreateNewCategory =
                widget.controller.categories.length < maxCategoryCount;
            final categories = [...widget.controller.categories]
              ..sort(
                (a, b) => l10n
                    .categoryLabel(a)
                    .toLowerCase()
                    .compareTo(l10n.categoryLabel(b).toLowerCase()),
              );

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
                            trailing: IconButton(
                              tooltip: l10n.deleteCategory,
                              icon: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () =>
                                  _deleteCategoryFromPicker(category),
                            ),
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
        _showAddedItemToast = false;
      });
      return;
    }

    setState(() {
      _selectedCategory = selection;
      _showAddedItemToast = false;
    });
  }

  Future<void> _deleteCategoryFromPicker(String category) async {
    final l10n = AppLocalizations.of(context);
    final usage = widget.controller.getCategoryUsage(category);
    if (usage == null) {
      return;
    }

    final shouldDelete = await showDeleteCategoryPrompt(
      context: context,
      categoryLabel: l10n.categoryLabel(category),
      usage: usage,
    );
    if (!mounted || !shouldDelete) {
      return;
    }

    await widget.controller.deleteCategoryAndUsages(category);
    if (!mounted) {
      return;
    }

    setState(() {
      if (_selectedCategory != null &&
          sameNormalizedText(_selectedCategory!, category)) {
        _selectedCategory = null;
      }
    });
  }

  Future<void> _showLoadFrequentItemsDialog({required String listId}) async {
    final l10n = AppLocalizations.of(context);
    final suggestions = widget.controller.getTopFrequentItems();

    final shouldLoad =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(l10n.frequentItemsDialogTitle),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.frequentItemsDialogExplanation),
                      const SizedBox(height: 16),
                      if (suggestions.isEmpty)
                        Text(
                          l10n.frequentItemsDialogEmpty,
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        for (
                          var index = 0;
                          index < suggestions.length;
                          index++
                        ) ...[
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 14,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(suggestions[index].itemName),
                            subtitle: Text(
                              l10n.categoryLabel(suggestions[index].category),
                            ),
                            trailing: suggestions[index].isFavorite
                                ? Icon(
                                    Icons.favorite_rounded,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 18,
                                  )
                                : null,
                          ),
                          if (index < suggestions.length - 1)
                            const Divider(height: 1),
                        ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: suggestions.isEmpty
                      ? null
                      : () => Navigator.pop(dialogContext, true),
                  child: Text(l10n.load),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldLoad || !mounted) {
      return;
    }

    if (widget.isShared) {
      final currentNames =
          _groceryList?.items
              .map((item) => normalizeLatinText(item.name))
              .toSet() ??
          <String>{};
      for (final suggestion in suggestions) {
        if (!currentNames.add(normalizeLatinText(suggestion.itemName))) {
          continue;
        }
        final added = await _addSharedItem(
          listId: listId,
          itemName: suggestion.itemName,
          category: suggestion.category,
          quantity: 1,
        );
        if (!added) {
          _showOperationFailure(l10n);
          break;
        }
      }
    } else {
      await widget.controller.loadTopFrequentItemsIntoList(
        listId,
        suggestions: suggestions,
      );
    }
  }

  Future<void> _editItem({
    required String listId,
    required GroceryItem item,
  }) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<_EditItemResult>(
      context: context,
      builder: (_) =>
          _EditItemDialog(item: item, categories: widget.controller.categories),
    );

    if (!mounted || result == null) {
      return;
    }

    final updated = widget.isShared
        ? await _updateSharedItem(
            listId: listId,
            itemId: item.id,
            itemName: result.name,
            category: result.category,
            quantity: result.quantity,
          )
        : await widget.controller.updateItemInList(
            listId: listId,
            itemId: item.id,
            itemName: result.name,
            category: result.category,
            quantity: result.quantity,
          );
    if (!mounted || updated) {
      return;
    }

    _showOperationFailure(l10n);
  }

  Future<String?> _promptAndCreateCategory() async {
    final l10n = AppLocalizations.of(context);
    if (widget.controller.categories.length >= maxCategoryCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.maxCategoriesReached(maxCategoryCount))),
      );
      return null;
    }
    final name = await showCategoryNamePrompt(
      context: context,
      title: l10n.addNewCategory,
      existingCategories: widget.controller.categories
          .map(l10n.categoryLabel)
          .toList(),
    );

    if (name == null || name.trim().isEmpty) {
      return null;
    }

    return name.trim();
  }

  Future<void> _addItem(String listId) async {
    final l10n = AppLocalizations.of(context);
    final itemName = _itemController.text.trim();

    _hideAddedItemToast();

    if (itemName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.nameCannotBeEmpty)));
      _requestItemInputFocus();
      return;
    }

    if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.selectCategoryFirst)));
      _requestItemInputFocus();
      return;
    }

    final added = widget.isShared
        ? await _addSharedItem(
            listId: listId,
            itemName: itemName,
            category: _selectedCategory!,
            quantity: _selectedQuantity,
          )
        : await widget.controller.addItemToList(
            listId: listId,
            itemName: itemName,
            category: _selectedCategory!,
            quantity: _selectedQuantity,
          );
    if (!added) {
      if (!mounted) {
        return;
      }
      _showOperationFailure(l10n);
      _requestItemInputFocus();
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
      _showAddedItemToast = true;
    });
    _startAddedItemToastTimer();
    _requestItemInputFocus();
  }

  void _hideAddedItemToast() {
    _addedItemToastTimer?.cancel();
    if (!_showAddedItemToast) {
      return;
    }
    setState(() {
      _showAddedItemToast = false;
    });
  }

  void _startAddedItemToastTimer() {
    _addedItemToastTimer?.cancel();
    _addedItemToastTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showAddedItemToast = false;
      });
    });
  }

  GroceryListModel? get _groceryList {
    if (widget.isShared) {
      return widget.cloudController
          ?.getSharedListById(widget.listId)
          ?.toGroceryListModel();
    }
    return widget.controller.getGroceryListById(widget.listId);
  }

  Future<void> _removeItem({
    required String listId,
    required String itemId,
  }) async {
    if (widget.isShared) {
      await widget.cloudController!.removeItemFromSharedList(
        listId: listId,
        itemId: itemId,
      );
      return;
    }
    await widget.controller.removeItemFromList(listId: listId, itemId: itemId);
  }

  Future<bool> _addSharedItem({
    required String listId,
    required String itemName,
    required String category,
    required int quantity,
  }) async {
    if (!await _ensureLocalCategory(category)) {
      return false;
    }
    final added = await widget.cloudController!.addItemToSharedList(
      listId: listId,
      itemName: itemName,
      category: category,
      quantity: quantity,
    );
    if (added) {
      _addedSharedItems = true;
    }
    return added;
  }

  Future<bool> _updateSharedItem({
    required String listId,
    required String itemId,
    required String itemName,
    required String category,
    required int quantity,
  }) async {
    if (!await _ensureLocalCategory(category)) {
      return false;
    }
    return widget.cloudController!.updateSharedItem(
      listId: listId,
      itemId: itemId,
      itemName: itemName,
      category: category,
      quantity: quantity,
    );
  }

  Future<bool> _ensureLocalCategory(String category) async {
    if (widget.controller.categories.any(
      (existing) => sameNormalizedText(existing, category),
    )) {
      return true;
    }
    return await widget.controller.addCategory(category) != null;
  }

  void _showOperationFailure(AppLocalizations l10n) {
    if (!mounted) {
      return;
    }
    final cloudController = widget.cloudController;
    final message = cloudController == null
        ? null
        : CloudLocalizations.of(context).errorMessage(cloudController);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? l10n.maxCategoriesReached(maxCategoryCount)),
      ),
    );
    cloudController?.clearError();
  }

  void _notifySharedListAdditions() {
    if (!widget.isShared ||
        !_addedSharedItems ||
        _sharedAdditionNotificationSent) {
      return;
    }
    _sharedAdditionNotificationSent = true;
    unawaited(
      widget.cloudController!.notifySharedListAdditionsCompleted(widget.listId),
    );
  }
}

class _ItemHints extends StatelessWidget {
  const _ItemHints({required this.hints, required this.onSelected});

  final List<ItemHint> hints;
  final ValueChanged<ItemHint> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final hint in hints)
          ActionChip(
            label: Text(l10n.hintLabel(hint.itemName, hint.category)),
            onPressed: () => onSelected(hint),
          ),
      ],
    );

    return chips;
  }
}

class _InlineToast extends StatelessWidget {
  const _InlineToast({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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
  const _EditItemDialog({required this.item, required this.categories});

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
    if (!categories.any((entry) => sameNormalizedText(entry, _draftCategory))) {
      categories.add(_draftCategory);
    }
    categories.sort(
      (a, b) => l10n
          .categoryLabel(a)
          .toLowerCase()
          .compareTo(l10n.categoryLabel(b).toLowerCase()),
    );

    String? selectedCategory;
    for (final category in categories) {
      if (sameNormalizedText(category, _draftCategory)) {
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
