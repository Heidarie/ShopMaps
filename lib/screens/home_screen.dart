import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import 'categories_configuration_screen.dart';
import 'frequent_items_configuration_screen.dart';
import 'go_shopping_screen.dart';
import 'grocery_list_editor_screen.dart';
import 'market_layout_editor_screen.dart';

const int _maxInputChars = 100;

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onToggleThemeMode,
  });

  final AppController controller;
  final VoidCallback onToggleThemeMode;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedTab);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _startGoShoppingFlow() async {
    final l10n = AppLocalizations.of(context);
    final groceryLists = widget.controller.groceryLists;
    final marketLayouts = widget.controller.marketLayouts;

    if (groceryLists.isEmpty || marketLayouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectListAndMarket)),
      );
      return;
    }

    final selection = await showModalBottomSheet<_ShoppingSetupSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        String? selectedListId;
        String? selectedMarketLayoutId;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.goShoppingFlow,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.step1,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedListId,
                      items: groceryLists
                          .map(
                            (list) => DropdownMenuItem<String>(
                              value: list.id,
                              child: Text(list.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedListId = value;
                        });
                      },
                      decoration: InputDecoration(labelText: l10n.groceryList),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.step2,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMarketLayoutId,
                      items: marketLayouts
                          .map(
                            (layout) => DropdownMenuItem<String>(
                              value: layout.id,
                              child: Text(layout.name),
                            ),
                          )
                          .toList(),
                      onChanged: selectedListId == null
                          ? null
                          : (value) {
                              setModalState(() {
                                selectedMarketLayoutId = value;
                              });
                            },
                      decoration: InputDecoration(labelText: l10n.market),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: selectedListId != null && selectedMarketLayoutId != null
                          ? () {
                              Navigator.pop(
                                sheetContext,
                                _ShoppingSetupSelection(
                                  groceryListId: selectedListId!,
                                  marketLayoutId: selectedMarketLayoutId!,
                                  startedAt: DateTime.now(),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: Text(l10n.goShopping),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || selection == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GoShoppingScreen(
          controller: widget.controller,
          groceryListId: selection.groceryListId,
          marketLayoutId: selection.marketLayoutId,
          shoppingStartedAt: selection.startedAt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final homePages = [
          _MarketLayoutsTab(controller: widget.controller),
          _GroceryListsTab(controller: widget.controller),
          _ConfigurationTab(controller: widget.controller),
        ];
        final homeTabs = [
          _HomeTabItem(
            label: l10n.market,
            selectedIcon: Icons.store_mall_directory,
            unselectedIcon: Icons.store_mall_directory_outlined,
          ),
          _HomeTabItem(
            label: l10n.groceryList,
            selectedIcon: Icons.playlist_add_check,
            unselectedIcon: Icons.playlist_add_check_outlined,
          ),
          _HomeTabItem(
            label: l10n.configurationTab,
            selectedIcon: Icons.settings,
            unselectedIcon: Icons.settings_outlined,
          ),
        ];

        if (widget.controller.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF318887),
            body: Center(
              child: SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          extendBody: true,
          appBar: AppBar(
            title: Text(
              l10n.appTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                onPressed: widget.onToggleThemeMode,
                icon: Icon(
                  Theme.of(context).brightness == Brightness.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  if (_selectedTab == index) {
                    return;
                  }
                  setState(() {
                    _selectedTab = index;
                  });
                },
                children: homePages,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _startGoShoppingFlow,
                            icon: const Icon(Icons.shopping_cart_checkout),
                            label: Text(l10n.goShopping),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: _HomeTabSwitcher(
                          items: homeTabs,
                          selectedIndex: _selectedTab,
                          onChanged: (index) {
                            if (index == _selectedTab) {
                              return;
                            }
                            setState(() {
                              _selectedTab = index;
                            });
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShoppingSetupSelection {
  const _ShoppingSetupSelection({
    required this.groceryListId,
    required this.marketLayoutId,
    required this.startedAt,
  });

  final String groceryListId;
  final String marketLayoutId;
  final DateTime startedAt;
}

class _HomeTabItem {
  const _HomeTabItem({
    required this.label,
    required this.selectedIcon,
    required this.unselectedIcon,
  });

  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;
}

class _HomeTabSwitcher extends StatelessWidget {
  const _HomeTabSwitcher({
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<_HomeTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1D1F21).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: List.generate(items.length * 2 - 1, (index) {
            if (index.isOdd) {
              return const SizedBox(width: 3);
            }

            final itemIndex = index ~/ 2;
            final item = items[itemIndex];
            return Expanded(
              child: _HomeTabButton(
                label: item.label,
                selected: selectedIndex == itemIndex,
                selectedIcon: item.selectedIcon,
                unselectedIcon: item.unselectedIcon,
                onTap: () => onChanged(itemIndex),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _HomeTabButton extends StatelessWidget {
  const _HomeTabButton({
    required this.label,
    required this.selected,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = isDark ? Colors.white : theme.colorScheme.primary;
    final unselectedColor = theme.colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : theme.colorScheme.primary.withValues(alpha: 0.08))
                : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? selectedIcon : unselectedIcon,
                size: 20,
                color: selected ? selectedColor : unselectedColor,
              ),
              const SizedBox(height: 1),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                style: theme.textTheme.labelSmall!.copyWith(
                  color: selected ? selectedColor : unselectedColor,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketLayoutsTab extends StatelessWidget {
  const _MarketLayoutsTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final marketLayouts = List<MarketLayout>.of(controller.marketLayouts);
    final categories = List<String>.of(controller.categories);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.market,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push<MarketLayout>(
                    MaterialPageRoute(
                      builder: (_) => MarketLayoutEditorScreen(
                        controller: controller,
                        layout: null,
                        categories: categories,
                      ),
                    ),
                  );

                  if (result != null) {
                    await controller.upsertMarketLayout(result);
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: marketLayouts.isEmpty
                ? Center(child: Text(l10n.emptyMarketLayouts))
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 170),
                    itemCount: marketLayouts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final layout = marketLayouts[index];

                      return Card(
                        child: ListTile(
                          onTap: () async {
                            final result = await Navigator.of(context).push<MarketLayout>(
                              MaterialPageRoute(
                                builder: (_) => MarketLayoutEditorScreen(
                                  controller: controller,
                                  layout: layout,
                                  categories: categories,
                                ),
                              ),
                            );

                            if (result != null) {
                              await controller.upsertMarketLayout(result);
                            }
                          },
                          title: Text(layout.name),
                          subtitle: Text(
                            layout.categoryOrder
                                .map(l10n.categoryLabel)
                                .join('  →  '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final result = await Navigator.of(context).push<MarketLayout>(
                                  MaterialPageRoute(
                                    builder: (_) => MarketLayoutEditorScreen(
                                      controller: controller,
                                      layout: layout,
                                      categories: categories,
                                    ),
                                  ),
                                );

                                if (result != null) {
                                  await controller.upsertMarketLayout(result);
                                }
                                return;
                              }

                              final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(l10n.deleteLayout),
                                      content: Text(layout.name),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text(l10n.cancel),
                                        ),
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Theme.of(context).colorScheme.error,
                                          ),
                                          onPressed: () => Navigator.pop(context, true),
                                          icon: const Icon(Icons.delete_outline),
                                          label: Text(l10n.delete),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;

                              if (shouldDelete) {
                                await controller.deleteMarketLayout(layout.id);
                              }
                            },
                            itemBuilder: (menuContext) => [
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Text(l10n.edit),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Theme.of(menuContext).colorScheme.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.delete,
                                      style: TextStyle(
                                        color: Theme.of(menuContext).colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GroceryListsTab extends StatelessWidget {
  const _GroceryListsTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groceryLists = List<GroceryListModel>.of(controller.groceryLists);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.groceryList,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final name = await showNamePrompt(
                    context: context,
                    title: l10n.addGroceryList,
                    label: l10n.groceryListName,
                  );
                  if (name == null) {
                    return;
                  }

                  final listId = await controller.createGroceryList(name);
                  if (listId == null || !context.mounted) {
                    return;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GroceryListEditorScreen(
                        controller: controller,
                        listId: listId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: groceryLists.isEmpty
                ? Center(child: Text(l10n.emptyGroceryLists))
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 170),
                    itemCount: groceryLists.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final list = groceryLists[index];

                      return Card(
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => GroceryListEditorScreen(
                                  controller: controller,
                                  listId: list.id,
                                ),
                              ),
                            );
                          },
                          title: Text(list.name),
                          subtitle: Text(
                            list.items.isEmpty
                                ? l10n.emptyGroceryListItems
                                : l10n.itemsCount(list.items.length),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'rename') {
                                final name = await showNamePrompt(
                                  context: context,
                                  title: l10n.rename,
                                  label: l10n.groceryListName,
                                  initialValue: list.name,
                                );
                                if (name != null) {
                                  await controller.renameGroceryList(
                                    listId: list.id,
                                    newName: name,
                                  );
                                }
                                return;
                              }

                              final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(l10n.deleteList),
                                      content: Text(list.name),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text(l10n.cancel),
                                        ),
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Theme.of(context).colorScheme.error,
                                          ),
                                          onPressed: () => Navigator.pop(context, true),
                                          icon: const Icon(Icons.delete_outline),
                                          label: Text(l10n.delete),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;

                              if (shouldDelete) {
                                await controller.deleteGroceryList(list.id);
                              }
                            },
                            itemBuilder: (menuContext) => [
                              PopupMenuItem<String>(
                                value: 'rename',
                                child: Text(l10n.rename),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Theme.of(menuContext).colorScheme.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.delete,
                                      style: TextStyle(
                                        color: Theme.of(menuContext).colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConfigurationTab extends StatelessWidget {
  const _ConfigurationTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.configurationTab,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.category_outlined),
              title: Text(l10n.categoriesTab),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CategoriesConfigurationScreen(
                      controller: controller,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_fire_department_outlined),
              title: Text(l10n.topArticles),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FrequentItemsConfigurationScreen(
                      controller: controller,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> showNamePrompt({
  required BuildContext context,
  required String title,
  required String label,
  String initialValue = '',
}) async {
  var draftName = initialValue;
  final l10n = AppLocalizations.of(context);

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initialValue,
          inputFormatters: [
            LengthLimitingTextInputFormatter(_maxInputChars),
          ],
          decoration: InputDecoration(labelText: label),
          autofocus: true,
          onChanged: (value) {
            draftName = value;
          },
          onFieldSubmitted: (value) {
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
              if (value.isEmpty) {
                return;
              }
              Navigator.pop(dialogContext, value);
            },
            child: Text(l10n.save),
          ),
        ],
      );
    },
  );

  return result;
}
