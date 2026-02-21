import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';

class GoShoppingScreen extends StatefulWidget {
  const GoShoppingScreen({
    super.key,
    required this.controller,
    required this.groceryListId,
    required this.marketLayoutId,
  });

  final AppController controller;
  final String groceryListId;
  final String marketLayoutId;

  @override
  State<GoShoppingScreen> createState() => _GoShoppingScreenState();
}

class _GoShoppingScreenState extends State<GoShoppingScreen> {
  final List<CompletedShoppingItemRemoval> _undoStack = [];
  final Set<String> _checkedItemIds = {};
  final Set<String> _processingItemIds = {};

  Future<void> _completeItem(String itemId) async {
    if (_processingItemIds.contains(itemId)) {
      return;
    }

    setState(() {
      _checkedItemIds.add(itemId);
      _processingItemIds.add(itemId);
    });

    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) {
      return;
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
      if (removal != null) {
        _undoStack.add(removal);
      }
    });
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
                Text(l10n.nothingToShow)
              else
                ...sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
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
                                      ?.copyWith(color: Theme.of(context).colorScheme.error),
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
}
