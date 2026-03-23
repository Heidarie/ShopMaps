import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';

class GoShoppingScreen extends StatefulWidget {
  const GoShoppingScreen({
    super.key,
    required this.controller,
    required this.groceryListId,
    required this.marketLayoutId,
    required this.shoppingStartedAt,
  });

  final AppController controller;
  final String groceryListId;
  final String marketLayoutId;
  final DateTime shoppingStartedAt;

  @override
  State<GoShoppingScreen> createState() => _GoShoppingScreenState();
}

class _GoShoppingScreenState extends State<GoShoppingScreen> {
  static const Duration _itemCheckedVisibleDuration = Duration(seconds: 1);
  static const Duration _sectionCollapseDuration = Duration(milliseconds: 260);

  final List<String> _undoStack = [];
  final List<String> _checkedItemOrder = [];
  final Set<String> _checkedItemIds = {};
  final Set<String> _processingItemIds = {};
  final Set<String> _collapsingSectionCategories = {};
  bool _completionRewardShown = false;
  Duration? _pendingRewardElapsed;
  bool _isFinishing = false;

  Future<void> _completeItem(String itemId) async {
    if (_processingItemIds.contains(itemId) || _checkedItemIds.contains(itemId)) {
      return;
    }

    final isFinalCheck = _isFinalPendingCheck(itemId);
    if (isFinalCheck && !_completionRewardShown) {
      _pendingRewardElapsed = DateTime.now().difference(widget.shoppingStartedAt);
    }

    HapticFeedback.lightImpact();

    setState(() {
      _checkedItemIds.add(itemId);
      _checkedItemOrder.remove(itemId);
      _checkedItemOrder.add(itemId);
      _processingItemIds.add(itemId);
    });

    await Future<void>.delayed(_itemCheckedVisibleDuration);
    if (!mounted) {
      return;
    }

    final collapsingCategory = _findSingleVisibleItemSectionCategory(itemId);
    if (collapsingCategory != null) {
      setState(() {
        _collapsingSectionCategories.add(collapsingCategory);
      });

      await Future<void>.delayed(_sectionCollapseDuration);
      if (!mounted) {
        return;
      }
    }

    setState(() {
      _processingItemIds.remove(itemId);
      if (collapsingCategory != null) {
        _collapsingSectionCategories.remove(collapsingCategory);
      }
      _undoStack.add(itemId);
    });

    _showCompletionRewardIfNeeded();
  }

  Future<void> _undoLastItem() async {
    if (_undoStack.isEmpty || _isFinishing) {
      return;
    }

    final itemId = _undoStack.removeLast();
    _restoreCheckedItem(itemId);
  }

  void _restoreCheckedItem(String itemId) {
    setState(() {
      _checkedItemIds.remove(itemId);
      _processingItemIds.remove(itemId);
      _checkedItemOrder.remove(itemId);
      _removeItemFromUndoStack(itemId);
    });
  }

  void _removeItemFromUndoStack(String itemId) {
    for (var index = _undoStack.length - 1; index >= 0; index--) {
      if (_undoStack[index] == itemId) {
        _undoStack.removeAt(index);
        break;
      }
    }
  }

  Future<void> _finishShopping() async {
    if (_isFinishing) {
      return;
    }

    setState(() {
      _isFinishing = true;
    });

    await _commitCheckedItems();
    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<bool> _handleBackNavigation() async {
    if (_isFinishing) {
      return false;
    }

    setState(() {
      _isFinishing = true;
    });

    await _commitCheckedItems();
    return true;
  }

  Future<void> _commitCheckedItems() async {
    if (_checkedItemIds.isEmpty) {
      return;
    }

    await widget.controller.removeItemsFromList(
      listId: widget.groceryListId,
      itemIds: _checkedItemIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final groceryList = widget.controller.getGroceryListById(widget.groceryListId);
        final marketLayout = widget.controller.getMarketLayoutById(widget.marketLayoutId);

        if (groceryList == null || marketLayout == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.goShoppingFlow)),
            body: Center(child: Text(l10n.nothingToShow)),
            bottomNavigationBar: _bottomActions(l10n),
          );
        }

        final currentItemIds = groceryList.items.map((item) => item.id).toSet();
        _pruneSessionState(currentItemIds);

        final activeSections = _activeSections();
        final cartItems = _cartItems(groceryList);

        return PopScope<void>(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) {
              return;
            }

            final navigator = Navigator.of(context);
            final shouldPop = await _handleBackNavigation();
            if (shouldPop && navigator.mounted) {
              navigator.pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(title: Text(l10n.goShoppingFlow)),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 8),
                Text('${l10n.groceryList}: ${groceryList.name}'),
                Text('${l10n.market}: ${marketLayout.name}'),
                const SizedBox(height: 12),
                if (activeSections.isEmpty && cartItems.isEmpty)
                  Text(l10n.emptyShoppingList)
                else ...[
                  ...activeSections.map((section) => _buildSection(context, l10n, section)),
                  if (cartItems.isNotEmpty) _buildCartSection(context, l10n, cartItems),
                ],
              ],
            ),
            bottomNavigationBar: _bottomActions(l10n),
          ),
        );
      },
    );
  }

  void _pruneSessionState(Set<String> currentItemIds) {
    _checkedItemIds.removeWhere((id) => !currentItemIds.contains(id));
    _processingItemIds.removeWhere((id) => !currentItemIds.contains(id));
    _checkedItemOrder.removeWhere((id) => !currentItemIds.contains(id));
    _undoStack.removeWhere((id) => !currentItemIds.contains(id));
  }

  Widget _buildSection(
    BuildContext context,
    AppLocalizations l10n,
    ShoppingSection section,
  ) {
    final isCollapsing = _collapsingSectionCategories.contains(section.category);

    return Padding(
      key: ValueKey('section_wrap_${section.category}'),
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedOpacity(
        duration: _sectionCollapseDuration,
        curve: Curves.easeInOutCubic,
        opacity: isCollapsing ? 0 : 1,
        child: ClipRect(
          child: AnimatedSize(
            duration: _sectionCollapseDuration,
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: isCollapsing
                ? const SizedBox.shrink()
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.categoryLabel(section.category),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (!section.inLayoutOrder)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                l10n.missingInLayout,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          for (var itemIndex = 0;
                              itemIndex < section.items.length;
                              itemIndex++)
                            _buildShoppingItem(
                              item: section.items[itemIndex],
                              isLast: itemIndex == section.items.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartSection(
    BuildContext context,
    AppLocalizations l10n,
    List<GroceryItem> cartItems,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.cartSection,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (var itemIndex = 0; itemIndex < cartItems.length; itemIndex++)
                _buildShoppingItem(
                  item: cartItems[itemIndex],
                  isLast: itemIndex == cartItems.length - 1,
                  allowRestoring: true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShoppingItem({
    required GroceryItem item,
    required bool isLast,
    bool allowRestoring = false,
  }) {
    final isChecked = _checkedItemIds.contains(item.id);
    final canToggle = !_isFinishing && !(_processingItemIds.contains(item.id));
    final canRestore = allowRestoring && isChecked && canToggle;
    final canCheck = !isChecked && canToggle;

    return KeyedSubtree(
      key: ValueKey(item.id),
      child: Column(
        children: [
          ListTile(
            key: ValueKey('tile_${item.id}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: IgnorePointer(
              ignoring: !(canCheck || canRestore),
              child: Checkbox(
                key: ValueKey('checkbox_${item.id}'),
                value: isChecked,
                onChanged: (_) {
                  if (canRestore) {
                    _restoreCheckedItem(item.id);
                  } else if (canCheck) {
                    _completeItem(item.id);
                  }
                },
              ),
            ),
            title: Text(
              '${item.name} x ${item.quantity}',
              style: isChecked
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
          ),
          if (!isLast) const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _bottomActions(AppLocalizations l10n) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _undoStack.isEmpty || _isFinishing ? null : _undoLastItem,
                icon: const Icon(Icons.undo),
                label: Text(l10n.undo),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _isFinishing ? null : _finishShopping,
                child: Text(l10n.finishShopping),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isFinalPendingCheck(String itemId) {
    final sections = _activeSections();
    final pendingItemIds = <String>[];

    for (final section in sections) {
      for (final item in section.items) {
        if (!_processingItemIds.contains(item.id)) {
          pendingItemIds.add(item.id);
        }
      }
    }

    return pendingItemIds.length == 1 && pendingItemIds.first == itemId;
  }

  String? _findSingleVisibleItemSectionCategory(String itemId) {
    final sections = _activeSections();

    for (final section in sections) {
      if (section.items.length != 1) {
        continue;
      }
      if (section.items.first.id == itemId) {
        return section.category;
      }
    }

    return null;
  }

  List<ShoppingSection> _activeSections() {
    final sections = widget.controller.buildShoppingSections(
      listId: widget.groceryListId,
      marketLayoutId: widget.marketLayoutId,
    );

    return sections
        .map((section) {
          final visibleItems = section.items
              .where(
                (item) => !_checkedItemIds.contains(item.id) || _processingItemIds.contains(item.id),
              )
              .toList();
          if (visibleItems.isEmpty) {
            return null;
          }

          return ShoppingSection(
            category: section.category,
            items: visibleItems,
            inLayoutOrder: section.inLayoutOrder,
          );
        })
        .whereType<ShoppingSection>()
        .toList();
  }

  List<GroceryItem> _cartItems(GroceryListModel groceryList) {
    if (widget.controller.removeCheckedShoppingItems) {
      return const [];
    }

    final checkedItemsById = <String, GroceryItem>{
      for (final item in groceryList.items)
        if (_checkedItemIds.contains(item.id) && !_processingItemIds.contains(item.id))
          item.id: item,
    };

    final cartItems = <GroceryItem>[];
    for (final itemId in _checkedItemOrder) {
      final item = checkedItemsById.remove(itemId);
      if (item != null) {
        cartItems.add(item);
      }
    }

    cartItems.addAll(checkedItemsById.values);
    return cartItems;
  }

  void _showCompletionRewardIfNeeded() {
    if (_completionRewardShown || _pendingRewardElapsed == null || _activeSections().isNotEmpty) {
      return;
    }

    _completionRewardShown = true;
    final l10n = AppLocalizations.of(context);
    final elapsed = _pendingRewardElapsed!.isNegative ? Duration.zero : _pendingRewardElapsed!;
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    _pendingRewardElapsed = null;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.shoppingDoneMessage(minutes, seconds)),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
