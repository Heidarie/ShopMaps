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

  final List<CompletedShoppingItemRemoval> _undoStack = [];
  final Set<String> _checkedItemIds = {};
  final Set<String> _processingItemIds = {};
  final Set<String> _collapsingSectionCategories = {};
  bool _completionRewardShown = false;
  Duration? _pendingRewardElapsed;

  Future<void> _completeItem(String itemId) async {
    if (_processingItemIds.contains(itemId)) {
      return;
    }
    final isFinalCheck = _isFinalPendingCheck(itemId);
    if (isFinalCheck && !_completionRewardShown) {
      _pendingRewardElapsed = DateTime.now().difference(widget.shoppingStartedAt);
    }

    HapticFeedback.lightImpact();

    setState(() {
      _checkedItemIds.add(itemId);
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

    final removal = await widget.controller.completeShoppingItem(
      listId: widget.groceryListId,
      itemId: itemId,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _checkedItemIds.remove(itemId);
      _processingItemIds.remove(itemId);
      if (collapsingCategory != null) {
        _collapsingSectionCategories.remove(collapsingCategory);
      }
      if (removal != null) {
        _undoStack.add(removal);
      }
    });

    if (removal == null || _completionRewardShown || _pendingRewardElapsed == null) {
      return;
    }

    final updatedList = widget.controller.getGroceryListById(widget.groceryListId);
    if (updatedList == null || updatedList.items.isNotEmpty) {
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

  Future<void> _undoLastRemoval() async {
    if (_undoStack.isEmpty) {
      return;
    }

    final removal = _undoStack.removeLast();
    final restored = await widget.controller.undoCompletedShoppingItem(removal);

    if (!mounted) {
      return;
    }

    if (!restored) {
      return;
    }

    setState(() {
      _checkedItemIds.remove(removal.item.id);
      _processingItemIds.remove(removal.item.id);
    });
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

        final sections = widget.controller.buildShoppingSections(
          listId: widget.groceryListId,
          marketLayoutId: widget.marketLayoutId,
        );
        final visibleItemIds = <String>{
          for (final section in sections) ...[
            for (final item in section.items) item.id,
          ],
        };
        _checkedItemIds.removeWhere((id) => !visibleItemIds.contains(id));
        _processingItemIds.removeWhere((id) => !visibleItemIds.contains(id));

        return Scaffold(
          appBar: AppBar(title: Text(l10n.goShoppingFlow)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              Text('${l10n.groceryList}: ${groceryList.name}'),
              Text('${l10n.market}: ${marketLayout.name}'),
              const SizedBox(height: 12),
              if (sections.isEmpty)
                Text(l10n.emptyShoppingList)
              else
                ...sections.map(
                  (section) {
                    final isCollapsing =
                        _collapsingSectionCategories.contains(section.category);
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
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.error,
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
                  },
                ),
            ],
          ),
          bottomNavigationBar: _bottomActions(l10n),
        );
      },
    );
  }

  Widget _buildShoppingItem({
    required GroceryItem item,
    required bool isLast,
  }) {
    final isChecked = _checkedItemIds.contains(item.id);

    return KeyedSubtree(
      key: ValueKey(item.id),
      child: Column(
      children: [
        ListTile(
          key: ValueKey('tile_${item.id}'),
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Checkbox(
            key: ValueKey('checkbox_${item.id}'),
            value: isChecked,
            onChanged: (value) {
              if (value == true && !isChecked) {
                _completeItem(item.id);
              }
            },
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
                onPressed: _undoStack.isEmpty ? null : _undoLastRemoval,
                icon: const Icon(Icons.undo),
                label: Text(l10n.undo),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: Text(l10n.finishShopping),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isFinalPendingCheck(String itemId) {
    final sections = widget.controller.buildShoppingSections(
      listId: widget.groceryListId,
      marketLayoutId: widget.marketLayoutId,
    );
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
    final sections = widget.controller.buildShoppingSections(
      listId: widget.groceryListId,
      marketLayoutId: widget.marketLayoutId,
    );

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
}
