import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../cloud/cloud_controller.dart';
import '../cloud/cloud_localizations.dart';
import '../cloud/cloud_models.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import '../online_categories.dart';

class PublishMarketLayoutScreen extends StatefulWidget {
  const PublishMarketLayoutScreen({
    super.key,
    required this.controller,
    required this.cloudController,
    required this.layout,
    this.existingMap,
  });

  final AppController controller;
  final CloudController cloudController;
  final MarketLayout layout;
  final SharedMarketLayout? existingMap;

  @override
  State<PublishMarketLayoutScreen> createState() =>
      _PublishMarketLayoutScreenState();
}

class _PublishMarketLayoutScreenState extends State<PublishMarketLayoutScreen> {
  late final TextEditingController _addressController;
  Timer? _searchTimer;
  List<GeoapifyAddressSuggestion> _suggestions = const [];
  List<NearbyStoreSuggestion> _nearbyStores = const [];
  GeoapifyAddressSuggestion? _selectedAddress;
  NearbyStoreSuggestion? _selectedNearbyStore;
  bool _isSearching = false;
  bool _isSearchingNearbyStores = false;
  bool _isPublishing = false;
  String _lastRequestedQuery = '';
  String? _lastNearbyAddressId;
  bool _didLoadExistingNearbyStores = false;
  bool _didInitializeCategoryMappings = false;
  Map<String, String?> _categoryMappings = const {};

  @override
  void initState() {
    super.initState();
    final existingLocation = widget.existingMap?.location;
    _addressController = TextEditingController(
      text: existingLocation?.formattedAddress ?? '',
    );
    _selectedAddress = existingLocation?.toAddressSuggestion();
    _selectedNearbyStore = existingLocation == null
        ? null
        : NearbyStoreSuggestion.fromLocation(existingLocation);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitializeCategoryMappings) {
      _didInitializeCategoryMappings = true;
      _categoryMappings = widget.controller.resolveOnlineCategoryMappings(
        widget.layout.categoryOrder,
        languageCode: Localizations.localeOf(context).languageCode,
      );
    }

    final address = _selectedAddress;
    if (!_didLoadExistingNearbyStores && address != null) {
      _didLoadExistingNearbyStores = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            _selectedAddress?.providerPlaceId != address.providerPlaceId) {
          return;
        }
        unawaited(_searchNearbyStores(address));
      });
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cloudL10n = CloudLocalizations.of(context);
    final canPublish =
        !_isPublishing && _selectedNearbyStore != null && _allCategoriesMapped;

    return Scaffold(
      appBar: AppBar(title: Text(cloudL10n.text('shareStoreMap'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasUnmappedCategories) ...[
                _buildCategoryMappingSection(cloudL10n),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _addressController,
                inputFormatters: [LengthLimitingTextInputFormatter(200)],
                decoration: InputDecoration(
                  labelText: cloudL10n.text('storeAddress'),
                  helperText: cloudL10n.text('addressHint'),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.location_on_outlined),
                ),
                onChanged: _scheduleAddressSearch,
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildSearchResults(cloudL10n)),
              Text(
                cloudL10n.text('poweredByGeoapify'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: canPublish ? _publish : null,
                icon: _isPublishing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.public),
                label: Text(cloudL10n.text('publishStoreMap')),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _isPublishing ? null : () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(CloudLocalizations l10n) {
    if (_selectedAddress != null &&
        _addressController.text == _selectedAddress!.formattedAddress) {
      return ListView.separated(
        itemCount: 2 + _nearbyStores.length,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(
                  _selectedNearbyStore?.name ??
                      _selectedAddress!.formattedAddress,
                ),
                subtitle: _selectedNearbyStore == null
                    ? null
                    : Text(_selectedAddress!.formattedAddress),
              ),
            );
          }
          if (index == 1) {
            if (_isSearchingNearbyStores) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (_nearbyStores.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.text('nearbyStoresNoResults'),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(
                l10n.text('nearbyStores'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }

          final store = _nearbyStores[index - 2];
          final isSelected =
              _selectedNearbyStore?.address.providerPlaceId ==
              store.address.providerPlaceId;
          return Card(
            child: ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: Text(store.name),
              subtitle: Text(
                '${_formatDistance(store.distanceMeters)} · '
                '${store.address.formattedAddress}',
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle_outline)
                  : null,
              onTap: () {
                setState(() {
                  _selectedNearbyStore = store;
                  _selectedAddress = store.address;
                  _addressController.text = store.address.formattedAddress;
                });
              },
            ),
          );
        },
      );
    }

    if (_addressController.text.trim().length < 3) {
      return Center(child: Text(l10n.text('addressTooShort')));
    }

    if (!_isSearching && _suggestions.isEmpty) {
      return Center(child: Text(l10n.text('addressNoResults')));
    }

    return ListView.separated(
      itemCount: _suggestions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(suggestion.formattedAddress),
            onTap: () {
              setState(() {
                _selectedAddress = suggestion;
                _selectedNearbyStore = null;
                _addressController.text = suggestion.formattedAddress;
                _suggestions = const [];
                _nearbyStores = const [];
              });
              _searchNearbyStores(suggestion);
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryMappingSection(CloudLocalizations l10n) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final missingCategories = _categoryMappings.entries
        .where((entry) => entry.value == null)
        .map((entry) => entry.key)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.text('matchStoreMapCategories'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(l10n.text('matchStoreMapCategoriesDescription')),
            const SizedBox(height: 12),
            for (final localCategory in missingCategories) ...[
              DropdownButtonFormField<String>(
                initialValue: _categoryMappings[localCategory],
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: localCategory,
                  helperText: l10n.text('selectOnlineCategory'),
                ),
                items: OnlineCategories.all.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(
                      OnlineCategories.label(category.id, languageCode),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoryMappings = {
                      ..._categoryMappings,
                      localCategory: value,
                    };
                  });
                },
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDistance(int distanceMeters) {
    if (distanceMeters < 1000) {
      return '$distanceMeters m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  void _scheduleAddressSearch(String value) {
    _searchTimer?.cancel();
    final query = value.trim();
    setState(() {
      if (_selectedAddress?.formattedAddress != query) {
        _selectedAddress = null;
        _selectedNearbyStore = null;
        _nearbyStores = const [];
        _isSearchingNearbyStores = false;
        _lastNearbyAddressId = null;
      }
      if (query.length < 3) {
        _suggestions = const [];
        _isSearching = false;
      }
    });
    if (query.length < 3) {
      return;
    }

    _searchTimer = Timer(const Duration(milliseconds: 350), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    _lastRequestedQuery = query;
    setState(() {
      _isSearching = true;
    });
    final suggestions = await widget.cloudController.searchStoreAddresses(
      query: query,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    if (!mounted || query != _lastRequestedQuery) {
      return;
    }
    setState(() {
      _isSearching = false;
      _suggestions = suggestions;
    });
  }

  Future<void> _searchNearbyStores(GeoapifyAddressSuggestion address) async {
    final addressId = address.providerPlaceId;
    _lastNearbyAddressId = addressId;
    setState(() {
      _isSearchingNearbyStores = true;
      _nearbyStores = const [];
    });
    final stores = await widget.cloudController.searchNearbyStores(
      address: address,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    if (!mounted || _lastNearbyAddressId != addressId) {
      return;
    }
    setState(() {
      _isSearchingNearbyStores = false;
      _nearbyStores = stores;
    });
  }

  Future<void> _publish() async {
    final store = _selectedNearbyStore;
    if (store == null) {
      return;
    }
    final languageCode = Localizations.localeOf(context).languageCode;
    final selectedMappings = _selectedCategoryMappings();
    final onlineCategoryOrder = widget.controller.encodeOnlineCategoryOrder(
      widget.layout.categoryOrder,
      selectedMappings: selectedMappings,
      languageCode: languageCode,
    );
    if (onlineCategoryOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            CloudLocalizations.of(context).text('categoryMappingRequired'),
          ),
        ),
      );
      return;
    }
    setState(() {
      _isPublishing = true;
    });
    await widget.controller.rememberOnlineCategoryMappings(selectedMappings);
    final result = await widget.cloudController.publishMarketLayout(
      layout: widget.layout,
      store: store,
      onlineCategoryOrder: onlineCategoryOrder,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isPublishing = false;
    });
    if (result == PublishMarketLayoutResult.published) {
      Navigator.pop(context, true);
      return;
    }
    if (result == PublishMarketLayoutResult.duplicate) {
      final cloudL10n = CloudLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(cloudL10n.text('storeMapAlreadyExists'))),
      );
      return;
    }
    final message =
        CloudLocalizations.of(context).errorMessage(widget.cloudController) ??
        'Could not publish store map.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    widget.cloudController.clearError();
  }

  bool get _hasUnmappedCategories => _categoryMappings.values.any(
    (onlineCategoryId) => onlineCategoryId == null,
  );

  bool get _allCategoriesMapped => _categoryMappings.values.every(
    (onlineCategoryId) => onlineCategoryId != null,
  );

  Map<String, String> _selectedCategoryMappings() {
    return {
      for (final entry in _categoryMappings.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }
}
