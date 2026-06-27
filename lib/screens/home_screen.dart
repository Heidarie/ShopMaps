import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../cloud/cloud_controller.dart';
import '../cloud/cloud_localizations.dart';
import '../cloud/cloud_models.dart';
import '../device_location_service.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../online_categories.dart';
import 'account_groups_screen.dart';
import 'categories_configuration_screen.dart';
import 'deposit_vouchers_screen.dart';
import 'frequent_items_configuration_screen.dart';
import 'go_shopping_screen.dart';
import 'grocery_list_editor_screen.dart';
import 'market_layout_editor_screen.dart';
import 'publish_market_layout_screen.dart';
import 'settings_screen.dart';

const int _maxInputChars = 100;
const int _publicMapPreviewItemLimit = 4;
const double _nearbyPublicStoresRadiusMeters = 4000;

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.cloudController,
    required this.onToggleThemeMode,
    this.locationService = const GeolocatorDeviceLocationService(),
  });

  final AppController controller;
  final CloudController cloudController;
  final VoidCallback onToggleThemeMode;
  final DeviceLocationService locationService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedTab = 0;
  late final PageController _pageController;
  late final Listenable _homeListenable;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _selectedTab);
    _homeListenable = Listenable.merge([
      widget.controller,
      widget.cloudController,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(widget.cloudController.refresh());
        }
      });
    }
  }

  Future<void> _startGoShoppingFlow() async {
    final l10n = AppLocalizations.of(context);
    final sharedSourceLocalIds = widget.cloudController.sharedSourceLocalIds;
    final groceryLists = [
      ...widget.controller.groceryLists
          .where((list) => !sharedSourceLocalIds.contains(list.id))
          .map(
            (list) => _ShoppingListOption(
              id: list.id,
              name: list.name,
              isShared: false,
            ),
          ),
      ...widget.cloudController.sharedLists.map(
        (list) => _ShoppingListOption(
          id: list.id,
          name: '${list.name} · ${list.groupName}',
          isShared: true,
        ),
      ),
    ];
    final marketLayouts = widget.controller.marketLayouts;

    if (groceryLists.isEmpty || marketLayouts.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.selectListAndMarket)));
      return;
    }

    final selection = await showModalBottomSheet<_ShoppingSetupSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        _ShoppingListOption? selectedList;
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
                    DropdownButtonFormField<_ShoppingListOption>(
                      initialValue: selectedList,
                      items: groceryLists
                          .map(
                            (list) => DropdownMenuItem<_ShoppingListOption>(
                              value: list,
                              child: Text(list.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedList = value;
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
                      onChanged: selectedList == null
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
                      onPressed:
                          selectedList != null && selectedMarketLayoutId != null
                          ? () {
                              Navigator.pop(
                                sheetContext,
                                _ShoppingSetupSelection(
                                  groceryListId: selectedList!.id,
                                  isShared: selectedList!.isShared,
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
          cloudController: widget.cloudController,
          isShared: selection.isShared,
        ),
      ),
    );
  }

  void _openAccountGroups() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccountGroupsScreen(
          cloudController: widget.cloudController,
          appController: widget.controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _homeListenable,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final cloudL10n = CloudLocalizations.of(context);
        final homePages = [
          _MarketLayoutsTab(
            controller: widget.controller,
            cloudController: widget.cloudController,
            locationService: widget.locationService,
          ),
          _GroceryListsTab(
            controller: widget.controller,
            cloudController: widget.cloudController,
          ),
          DepositVouchersTab(
            controller: widget.controller,
            cloudController: widget.cloudController,
          ),
          _ConfigurationTab(
            controller: widget.controller,
            cloudController: widget.cloudController,
          ),
        ];
        final homeTabs = [
          _HomeTabItem(
            label: l10n.market,
            selectedIcon: Icons.store_mall_directory,
            unselectedIcon: Icons.store_mall_directory_outlined,
          ),
          _HomeTabItem(
            label: l10n.groceryListsTab,
            selectedIcon: Icons.playlist_add_check,
            unselectedIcon: Icons.playlist_add_check_outlined,
          ),
          _HomeTabItem(
            label: l10n.depositTab,
            selectedIcon: Icons.qr_code_2_rounded,
            unselectedIcon: Icons.qr_code_2_outlined,
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
              ListenableBuilder(
                listenable: widget.cloudController,
                builder: (context, _) => IconButton(
                  onPressed: _openAccountGroups,
                  tooltip: cloudL10n.text('account'),
                  icon: Icon(
                    widget.cloudController.isSignedIn
                        ? Icons.account_circle
                        : Icons.account_circle_outlined,
                  ),
                ),
              ),
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
    required this.isShared,
    required this.marketLayoutId,
    required this.startedAt,
  });

  final String groceryListId;
  final bool isShared;
  final String marketLayoutId;
  final DateTime startedAt;
}

class _ShoppingListOption {
  const _ShoppingListOption({
    required this.id,
    required this.name,
    required this.isShared,
  });

  final String id;
  final String name;
  final bool isShared;
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

class _MarketLayoutsTab extends StatefulWidget {
  const _MarketLayoutsTab({
    required this.controller,
    required this.cloudController,
    required this.locationService,
  });

  final AppController controller;
  final CloudController cloudController;
  final DeviceLocationService locationService;

  @override
  State<_MarketLayoutsTab> createState() => _MarketLayoutsTabState();
}

class _MarketLayoutsTabState extends State<_MarketLayoutsTab> {
  bool _showPublicMaps = false;
  String _publicSearch = '';
  DeviceLocation? _currentLocation;
  bool _isFindingLocation = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cloudL10n = CloudLocalizations.of(context);

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
              if (!_showPublicMaps)
                FilledButton.icon(
                  onPressed: _addLayout,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.add),
                ),
              if (_showPublicMaps &&
                  widget.cloudController.isSignedIn &&
                  widget.cloudController.profile?.hasStoreCountry == true)
                FilledButton.icon(
                  onPressed: _showShareLocalMapPicker,
                  icon: const Icon(Icons.ios_share_outlined),
                  label: Text(cloudL10n.text('share')),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment<bool>(
                value: false,
                icon: const Icon(Icons.storefront_outlined),
                label: Text(cloudL10n.text('myStoreMaps')),
              ),
              ButtonSegment<bool>(
                value: true,
                icon: const Icon(Icons.public),
                label: Text(cloudL10n.text('publicStoreMaps')),
              ),
            ],
            selected: {_showPublicMaps},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              setState(() {
                _showPublicMaps = selection.first;
              });
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _showPublicMaps
                ? _buildPublicMaps(l10n, cloudL10n)
                : _buildLocalMaps(l10n, cloudL10n),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalMaps(AppLocalizations l10n, CloudLocalizations cloudL10n) {
    final marketLayouts = List<MarketLayout>.of(
      widget.controller.marketLayouts,
    );
    if (marketLayouts.isEmpty) {
      return Center(child: Text(l10n.emptyMarketLayouts));
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 170),
      itemCount: marketLayouts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final layout = marketLayouts[index];
        final publicMap = widget.cloudController.publicMapForLocalId(layout.id);
        final hasMoreItems =
            layout.categoryOrder.length > _publicMapPreviewItemLimit;
        final previewItems = layout.categoryOrder
            .take(_publicMapPreviewItemLimit)
            .map(l10n.categoryLabel);
        return Card(
          child: ListTile(
            key: ValueKey('local-map-${layout.id}'),
            leading: publicMap == null ? null : const Icon(Icons.public),
            onTap: hasMoreItems
                ? () => _showLocalMapDetails(layout)
                : () => _editLayout(layout),
            title: Text(layout.name),
            subtitle: Text(
              [
                if (publicMap != null) publicMap.location.formattedAddress,
                [...previewItems, if (hasMoreItems) '...'].join('  →  '),
              ].where((value) => value.isNotEmpty).join('\n'),
              maxLines: publicMap == null ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) =>
                  _handleLocalMapAction(value, layout, publicMap),
              itemBuilder: (menuContext) => [
                PopupMenuItem<String>(value: 'edit', child: Text(l10n.edit)),
                if (widget.cloudController.isSignedIn &&
                    widget.cloudController.profile?.hasStoreCountry == true)
                  PopupMenuItem<String>(
                    value: 'publish',
                    child: Text(
                      cloudL10n.text(
                        publicMap == null
                            ? 'shareStoreMap'
                            : 'updateSharedStoreMap',
                      ),
                    ),
                  ),
                if (publicMap != null)
                  PopupMenuItem<String>(
                    value: 'unpublish',
                    child: Text(cloudL10n.text('unshareStoreMap')),
                  ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text(
                    l10n.delete,
                    style: TextStyle(
                      color: Theme.of(menuContext).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPublicMaps(AppLocalizations l10n, CloudLocalizations cloudL10n) {
    if (!widget.cloudController.isSignedIn) {
      return Center(child: Text(cloudL10n.text('signInToBrowseStoreMaps')));
    }
    if (widget.cloudController.isProfileLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.cloudController.profile?.hasStoreCountry != true) {
      return Center(
        child: Text(cloudL10n.text('completeProfileToBrowseStoreMaps')),
      );
    }

    final normalizedSearch = normalizeLatinText(_publicSearch);
    final maps = widget.cloudController.publicMarketLayouts.where((map) {
      if (normalizedSearch.isEmpty) {
        return true;
      }
      return normalizeLatinText(
        '${map.location.storeName} ${map.location.formattedAddress}',
      ).contains(normalizedSearch);
    }).toList();
    final groupedStores = _groupPublicMaps(
      maps,
      currentLocation: _currentLocation,
    );
    final stores = _currentLocation == null
        ? groupedStores
        : groupedStores
              .where(
                (store) =>
                    store.distanceMeters != null &&
                    store.distanceMeters! <= _nearbyPublicStoresRadiusMeters,
              )
              .toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isFindingLocation
                    ? null
                    : () => _findNearMe(cloudL10n),
                icon: _isFindingLocation
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: Text(cloudL10n.text('findNearMe')),
              ),
            ),
            if (_currentLocation != null) ...[
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: () {
                  setState(() {
                    _currentLocation = null;
                  });
                },
                tooltip: cloudL10n.text('clearLocation'),
                icon: const Icon(Icons.location_off_outlined),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
            hintText: cloudL10n.text('searchSharedStores'),
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _publicSearch = value;
            });
          },
        ),
        const SizedBox(height: 10),
        Expanded(
          child: stores.isEmpty
              ? Center(child: Text(cloudL10n.text('emptyPublicStoreMaps')))
              : RefreshIndicator(
                  onRefresh: widget.cloudController.refreshSharedData,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 170),
                    itemCount: stores.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      return Card(
                        child: ExpansionTile(
                          leading: const Icon(Icons.storefront_outlined),
                          title: Text(store.location.storeName),
                          subtitle: Text(
                            [
                              store.location.formattedAddress,
                              if (store.distanceMeters != null)
                                _formatDistance(store.distanceMeters!),
                              '${cloudL10n.text('mapsCountLabel')}: ${store.maps.length}',
                            ].where((value) => value.isNotEmpty).join('\n'),
                          ),
                          children: store.maps.map((map) {
                            final isInMyStores = _isPublicMapInMyStores(map);
                            final hasMoreItems =
                                map.categoryOrder.length >
                                _publicMapPreviewItemLimit;
                            final previewItems = map.categoryOrder
                                .take(_publicMapPreviewItemLimit)
                                .map(_publicCategoryLabel);
                            return ListTile(
                              key: ValueKey('public-map-${map.id}'),
                              onTap: hasMoreItems
                                  ? () => _showPublicMapDetails(map)
                                  : null,
                              leading: CircleAvatar(
                                child: Text(map.creatorInitial),
                              ),
                              title: Text(
                                [
                                  ...previewItems,
                                  if (hasMoreItems) '...',
                                ].join('  →  '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${cloudL10n.text('downloadsCountLabel')}: '
                                '${map.downloadCount}',
                              ),
                              trailing:
                                  isInMyStores &&
                                      !widget.cloudController.isOwnPublicMap(
                                        map,
                                      )
                                  ? Tooltip(
                                      message: cloudL10n.text(
                                        'storeMapAlreadyAdded',
                                      ),
                                      child: const Icon(
                                        Icons.check_circle_outline,
                                      ),
                                    )
                                  : PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'copy') {
                                          await _copyPublicMap(map);
                                        } else if (value == 'unpublish') {
                                          await _unpublishMap(map);
                                        } else if (value == 'report') {
                                          await _reportMap(map);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        if (!isInMyStores)
                                          PopupMenuItem<String>(
                                            value: 'copy',
                                            child: Text(
                                              cloudL10n.text('copyStoreMap'),
                                            ),
                                          ),
                                        if (widget.cloudController
                                            .isOwnPublicMap(map))
                                          PopupMenuItem<String>(
                                            value: 'unpublish',
                                            child: Text(
                                              cloudL10n.text('unshareStoreMap'),
                                            ),
                                          ),
                                        if (!widget.cloudController
                                            .isOwnPublicMap(map))
                                          PopupMenuItem<String>(
                                            value: 'report',
                                            child: Text(
                                              cloudL10n.text('reportStoreMap'),
                                            ),
                                          ),
                                      ],
                                    ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _showLocalMapDetails(MarketLayout layout) async {
    final l10n = AppLocalizations.of(context);
    final cloudL10n = CloudLocalizations.of(context);
    final shouldEdit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final maxListHeight = MediaQuery.sizeOf(sheetContext).height * 0.5;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  layout.name,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxListHeight),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: layout.categoryOrder.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) => ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(
                        l10n.categoryLabel(layout.categoryOrder[index]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: Text(l10n.edit),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: Text(cloudL10n.text('back')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldEdit == true && mounted) {
      await _editLayout(layout);
    }
  }

  Future<void> _showPublicMapDetails(SharedMarketLayout map) async {
    final l10n = AppLocalizations.of(context);
    final cloudL10n = CloudLocalizations.of(context);
    final isInMyStores = _isPublicMapInMyStores(map);
    final shouldAdd = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final maxListHeight = MediaQuery.sizeOf(sheetContext).height * 0.5;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  map.location.storeName,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxListHeight),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: map.categoryOrder.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) => ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(
                        _publicCategoryLabel(map.categoryOrder[index]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: isInMyStores
                            ? null
                            : () => Navigator.pop(sheetContext, true),
                        child: Text(l10n.add),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: Text(cloudL10n.text('back')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldAdd == true && mounted) {
      await _copyPublicMap(map);
    }
  }

  Future<void> _addLayout() async {
    final result = await Navigator.of(context).push<MarketLayout>(
      MaterialPageRoute(
        builder: (_) => MarketLayoutEditorScreen(
          controller: widget.controller,
          layout: null,
          categories: List<String>.of(widget.controller.categories),
        ),
      ),
    );
    if (result != null) {
      await widget.controller.upsertMarketLayout(result);
    }
  }

  Future<void> _showShareLocalMapPicker() async {
    final l10n = AppLocalizations.of(context);
    final cloudL10n = CloudLocalizations.of(context);
    final marketLayouts = List<MarketLayout>.of(
      widget.controller.marketLayouts,
    );
    final selectedLayout = await showModalBottomSheet<MarketLayout>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final maxListHeight = MediaQuery.sizeOf(sheetContext).height * 0.55;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  cloudL10n.text('selectStoreMapToShare'),
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (marketLayouts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.emptyMarketLayouts,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxListHeight),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: marketLayouts.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final layout = marketLayouts[index];
                        final publicMap = widget.cloudController
                            .publicMapForLocalId(layout.id);
                        final hasMoreItems =
                            layout.categoryOrder.length >
                            _publicMapPreviewItemLimit;
                        final previewItems = layout.categoryOrder
                            .take(_publicMapPreviewItemLimit)
                            .map(l10n.categoryLabel);

                        return ListTile(
                          leading: publicMap == null
                              ? const Icon(Icons.storefront_outlined)
                              : const Icon(Icons.public),
                          title: Text(layout.name),
                          subtitle: Text(
                            [
                              if (publicMap != null)
                                publicMap.location.formattedAddress,
                              [
                                ...previewItems,
                                if (hasMoreItems) '...',
                              ].join('  →  '),
                            ].where((value) => value.isNotEmpty).join('\n'),
                            maxLines: publicMap == null ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.pop(sheetContext, layout),
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

    if (selectedLayout == null || !mounted) {
      return;
    }
    await _shareLocalMap(
      selectedLayout,
      widget.cloudController.publicMapForLocalId(selectedLayout.id),
    );
  }

  Future<void> _findNearMe(CloudLocalizations l10n) async {
    setState(() {
      _isFindingLocation = true;
    });
    try {
      final location = await widget.locationService.getCurrentLocation();
      if (!mounted) {
        return;
      }
      setState(() {
        _currentLocation = location;
      });
    } on DeviceLocationException catch (error) {
      if (mounted) {
        _showLocationError(error.failure, l10n);
      }
    } catch (_) {
      if (mounted) {
        _showLocationError(DeviceLocationFailure.unavailable, l10n);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFindingLocation = false;
        });
      }
    }
  }

  void _showLocationError(
    DeviceLocationFailure failure,
    CloudLocalizations l10n,
  ) {
    final messageKey = switch (failure) {
      DeviceLocationFailure.servicesDisabled => 'locationServicesDisabled',
      DeviceLocationFailure.permissionDenied => 'locationPermissionDenied',
      DeviceLocationFailure.permissionDeniedForever =>
        'locationPermissionDeniedForever',
      DeviceLocationFailure.unavailable => 'locationUnavailable',
    };
    final canOpenSettings =
        failure == DeviceLocationFailure.servicesDisabled ||
        failure == DeviceLocationFailure.permissionDeniedForever;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.text(messageKey)),
        action: canOpenSettings
            ? SnackBarAction(
                label: l10n.text('openSettings'),
                onPressed: () {
                  if (failure == DeviceLocationFailure.servicesDisabled) {
                    unawaited(widget.locationService.openLocationSettings());
                  } else {
                    unawaited(widget.locationService.openAppSettings());
                  }
                },
              )
            : null,
      ),
    );
  }

  String _formatDistance(double distanceMeters) {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  Future<void> _editLayout(MarketLayout layout) async {
    final result = await Navigator.of(context).push<MarketLayout>(
      MaterialPageRoute(
        builder: (_) => MarketLayoutEditorScreen(
          controller: widget.controller,
          layout: layout,
          categories: List<String>.of(widget.controller.categories),
        ),
      ),
    );
    if (result != null) {
      await widget.controller.upsertMarketLayout(result);
    }
  }

  Future<void> _handleLocalMapAction(
    String value,
    MarketLayout layout,
    SharedMarketLayout? publicMap,
  ) async {
    if (value == 'edit') {
      await _editLayout(layout);
      return;
    }
    if (value == 'publish') {
      await _shareLocalMap(layout, publicMap);
      return;
    }
    if (value == 'unpublish' && publicMap != null) {
      await _unpublishMap(publicMap);
      return;
    }
    if (value == 'delete') {
      await _deleteLayout(layout);
    }
  }

  Future<void> _shareLocalMap(
    MarketLayout layout,
    SharedMarketLayout? publicMap,
  ) async {
    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PublishMarketLayoutScreen(
          controller: widget.controller,
          cloudController: widget.cloudController,
          layout: layout,
          existingMap: publicMap,
        ),
      ),
    );
    if (published == true && mounted) {
      final cloudL10n = CloudLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(cloudL10n.text('storeMapPublished'))),
      );
    }
  }

  Future<void> _copyPublicMap(SharedMarketLayout map) async {
    if (_isPublicMapInMyStores(map)) {
      return;
    }
    final localCategoryOrder = await widget.controller
        .ensureLocalCategoriesForOnlineOrder(
          map.categoryOrder,
          languageCode: Localizations.localeOf(context).languageCode,
        );
    if (localCategoryOrder == null) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.maxCategoriesReached(maxCategoryCount))),
      );
      return;
    }
    await widget.controller.upsertMarketLayout(
      map.toLocalMarketLayout(localCategoryOrder: localCategoryOrder),
    );
    await widget.cloudController.recordMarketLayoutDownload(map.id);
    if (!mounted) {
      return;
    }
    final cloudL10n = CloudLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(cloudL10n.text('storeMapCopied'))));
  }

  bool _isPublicMapInMyStores(SharedMarketLayout map) {
    return widget.controller.marketLayouts.any(
      (layout) =>
          layout.sourceSharedMarketLayoutId == map.id ||
          (widget.cloudController.isOwnPublicMap(map) &&
              layout.id == map.sourceLocalId),
    );
  }

  String _publicCategoryLabel(String categoryId) {
    return OnlineCategories.label(
      categoryId,
      Localizations.localeOf(context).languageCode,
    );
  }

  Future<void> _unpublishMap(SharedMarketLayout map) async {
    final removed = await widget.cloudController.unpublishMarketLayout(map.id);
    if (!mounted || !removed) {
      return;
    }
    final cloudL10n = CloudLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(cloudL10n.text('storeMapUnpublished'))),
    );
  }

  Future<void> _reportMap(SharedMarketLayout map) async {
    final l10n = CloudLocalizations.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.text('reportStoreMap')),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'incorrect'),
            child: Text(l10n.text('reportReasonIncorrect')),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'inappropriate'),
            child: Text(l10n.text('reportReasonInappropriate')),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'other'),
            child: Text(l10n.text('reportReasonOther')),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) {
      return;
    }

    final reported = await widget.cloudController.reportMarketLayout(
      publicMapId: map.id,
      reason: reason,
    );
    if (!mounted) {
      return;
    }
    if (reported) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.text('reportSubmitted'))));
      return;
    }
    final message = CloudLocalizations.of(
      context,
    ).errorMessage(widget.cloudController);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      widget.cloudController.clearError();
    }
  }

  Future<void> _deleteLayout(MarketLayout layout) async {
    final l10n = AppLocalizations.of(context);
    final shouldDelete =
        await showDialog<bool>(
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
      await widget.controller.deleteMarketLayout(layout.id);
    }
  }

  List<_PublicStoreEntry> _groupPublicMaps(
    List<SharedMarketLayout> maps, {
    DeviceLocation? currentLocation,
  }) {
    final grouped = <String, List<SharedMarketLayout>>{};
    for (final map in maps) {
      grouped.putIfAbsent(map.location.id, () => []).add(map);
    }
    final stores = grouped.values.map((storeMaps) {
      storeMaps.sort((a, b) {
        final downloads = b.downloadCount.compareTo(a.downloadCount);
        return downloads != 0 ? downloads : b.updatedAt.compareTo(a.updatedAt);
      });
      final location = storeMaps.first.location;
      return _PublicStoreEntry(
        storeMaps,
        distanceMeters: currentLocation?.distanceTo(
          latitude: location.latitude,
          longitude: location.longitude,
        ),
      );
    }).toList();
    stores.sort((a, b) {
      if (a.distanceMeters != null && b.distanceMeters != null) {
        final distance = a.distanceMeters!.compareTo(b.distanceMeters!);
        if (distance != 0) {
          return distance;
        }
      }
      final downloads = b.mostDownloadedCount.compareTo(a.mostDownloadedCount);
      return downloads != 0
          ? downloads
          : b.maps.first.updatedAt.compareTo(a.maps.first.updatedAt);
    });
    return stores;
  }
}

class _PublicStoreEntry {
  const _PublicStoreEntry(this.maps, {required this.distanceMeters});

  final List<SharedMarketLayout> maps;
  final double? distanceMeters;

  CloudStoreLocation get location => maps.first.location;
  int get mostDownloadedCount => maps.first.downloadCount;
}

class _GroceryListsTab extends StatelessWidget {
  const _GroceryListsTab({
    required this.controller,
    required this.cloudController,
  });

  final AppController controller;
  final CloudController cloudController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cloudL10n = CloudLocalizations.of(context);
    final sharedSourceLocalIds = cloudController.sharedSourceLocalIds;
    final groceryLists = [
      ...controller.groceryLists
          .where((list) => !sharedSourceLocalIds.contains(list.id))
          .map(_GroceryListEntry.local),
      ...cloudController.sharedLists.map(_GroceryListEntry.shared),
    ];

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
                      final entry = groceryLists[index];
                      final list = entry.list;

                      return Card(
                        child: ListTile(
                          leading: entry.isShared
                              ? const Icon(Icons.groups_2_outlined)
                              : null,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => GroceryListEditorScreen(
                                  controller: controller,
                                  listId: list.id,
                                  cloudController: cloudController,
                                  isShared: entry.isShared,
                                ),
                              ),
                            );
                          },
                          title: Text(list.name),
                          subtitle: Text(
                            [
                              if (entry.groupName != null) entry.groupName!,
                              list.items.isEmpty
                                  ? l10n.emptyGroceryListItems
                                  : l10n.itemsCount(list.items.length),
                            ].join(' · '),
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
                                  if (entry.isShared) {
                                    final renamed = await cloudController
                                        .renameSharedList(
                                          listId: list.id,
                                          newName: name,
                                        );
                                    if (!renamed && context.mounted) {
                                      final message = cloudL10n.errorMessage(
                                        cloudController,
                                      );
                                      if (message != null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(message)),
                                        );
                                      }
                                      cloudController.clearError();
                                    }
                                  } else {
                                    await controller.renameGroceryList(
                                      listId: list.id,
                                      newName: name,
                                    );
                                  }
                                }
                                return;
                              }

                              final shouldDelete =
                                  await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(l10n.deleteList),
                                      content: Text(list.name),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text(l10n.cancel),
                                        ),
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          label: Text(l10n.delete),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;

                              if (shouldDelete) {
                                if (entry.isShared) {
                                  final deleted = await cloudController
                                      .deleteSharedList(list.id);
                                  if (deleted && entry.sourceLocalId != null) {
                                    await controller.deleteGroceryList(
                                      entry.sourceLocalId!,
                                    );
                                  }
                                } else {
                                  await controller.deleteGroceryList(list.id);
                                }
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
                                      color: Theme.of(
                                        menuContext,
                                      ).colorScheme.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.delete,
                                      style: TextStyle(
                                        color: Theme.of(
                                          menuContext,
                                        ).colorScheme.error,
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

class _GroceryListEntry {
  const _GroceryListEntry._({
    required this.list,
    required this.isShared,
    required this.groupName,
    required this.sourceLocalId,
  });

  factory _GroceryListEntry.local(GroceryListModel list) {
    return _GroceryListEntry._(
      list: list,
      isShared: false,
      groupName: null,
      sourceLocalId: null,
    );
  }

  factory _GroceryListEntry.shared(SharedGroceryList list) {
    return _GroceryListEntry._(
      list: list.toGroceryListModel(),
      isShared: true,
      groupName: list.groupName,
      sourceLocalId: list.sourceLocalId,
    );
  }

  final GroceryListModel list;
  final bool isShared;
  final String? groupName;
  final String? sourceLocalId;
}

class _ConfigurationTab extends StatelessWidget {
  const _ConfigurationTab({
    required this.controller,
    required this.cloudController,
  });

  final AppController controller;
  final CloudController cloudController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cloudL10n = CloudLocalizations.of(context);

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
                    builder: (_) =>
                        CategoriesConfigurationScreen(controller: controller),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: cloudController,
            builder: (context, _) => Card(
              child: ListTile(
                leading: Badge.count(
                  key: const ValueKey('groups-invite-badge'),
                  count: cloudController.invites.length,
                  isLabelVisible: cloudController.invites.isNotEmpty,
                  child: Icon(
                    cloudController.isSignedIn
                        ? Icons.groups_2_outlined
                        : Icons.person_outline_rounded,
                  ),
                ),
                title: Text(cloudL10n.text('groups')),
                subtitle: Text(
                  cloudController.profile?.handle ??
                      cloudL10n.text('localMode'),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AccountGroupsScreen(
                        cloudController: cloudController,
                        appController: controller,
                      ),
                    ),
                  );
                },
              ),
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
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.tune_rounded),
              title: Text(l10n.settings),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SettingsScreen(controller: controller),
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
          inputFormatters: [LengthLimitingTextInputFormatter(_maxInputChars)],
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
