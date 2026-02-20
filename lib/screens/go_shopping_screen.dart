import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../l10n/app_localizations.dart';

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

  Future<void> _completeItem(String itemId) async {
    final removal = await widget.controller.completeShoppingItem(
      listId: widget.groceryListId,
      itemId: itemId,
    );

    if (!mounted || removal == null) {
      return;
    }

    setState(() {
      _undoStack.add(removal);
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

    setState(() {});
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
                            ...section.items.map(
                              (item) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Checkbox(
                                  value: false,
                                  onChanged: (_) => _completeItem(item.id),
                                ),
                                title: Text(item.name),
                              ),
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
