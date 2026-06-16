import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../cloud/cloud_controller.dart';
import '../cloud/cloud_localizations.dart';
import '../cloud/cloud_models.dart';

class CanonicalStorePickerScreen extends StatefulWidget {
  const CanonicalStorePickerScreen({super.key, required this.cloudController});

  final CloudController cloudController;

  @override
  State<CanonicalStorePickerScreen> createState() =>
      _CanonicalStorePickerScreenState();
}

class _CanonicalStorePickerScreenState
    extends State<CanonicalStorePickerScreen> {
  final _addressController = TextEditingController();
  Timer? _searchTimer;
  List<GeoapifyAddressSuggestion> _suggestions = const [];
  List<NearbyStoreSuggestion> _nearbyStores = const [];
  bool _isSearching = false;
  bool _isSearchingNearby = false;
  bool _didSearchNearby = false;
  String _lastRequestedQuery = '';
  String? _lastNearbyAddressId;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CloudLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('selectCanonicalStore'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.text('selectCanonicalStoreDescription')),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                autofocus: true,
                inputFormatters: [LengthLimitingTextInputFormatter(200)],
                decoration: InputDecoration(
                  labelText: l10n.text('storeAddress'),
                  helperText: l10n.text('addressHint'),
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
              const SizedBox(height: 12),
              Expanded(child: _buildResults(l10n)),
              Text(
                l10n.text('poweredByGeoapify'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(CloudLocalizations l10n) {
    if (_isSearchingNearby) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_nearbyStores.isNotEmpty) {
      return ListView.separated(
        itemCount: _nearbyStores.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              l10n.text('nearbyStores'),
              style: Theme.of(context).textTheme.titleMedium,
            );
          }
          final store = _nearbyStores[index - 1];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: Text(store.name),
              subtitle: Text(
                '${_formatDistance(store.distanceMeters)} · '
                '${store.address.formattedAddress}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, store),
            ),
          );
        },
      );
    }
    if (_didSearchNearby) {
      return Center(child: Text(l10n.text('nearbyStoresNoResults')));
    }

    final query = _addressController.text.trim();
    if (query.length < 3) {
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
            onTap: () => _searchNearbyStores(suggestion),
          ),
        );
      },
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
      _nearbyStores = const [];
      _isSearchingNearby = false;
      _didSearchNearby = false;
      _lastNearbyAddressId = null;
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
      _isSearching = false;
      _suggestions = const [];
      _isSearchingNearby = true;
      _didSearchNearby = false;
      _nearbyStores = const [];
      _addressController.text = address.formattedAddress;
    });
    final stores = await widget.cloudController.searchNearbyStores(
      address: address,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    if (!mounted || _lastNearbyAddressId != addressId) {
      return;
    }
    setState(() {
      _isSearchingNearby = false;
      _didSearchNearby = true;
      _nearbyStores = stores;
    });
  }
}
