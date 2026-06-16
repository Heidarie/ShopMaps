import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopmaps/cloud/cloud_controller.dart';
import 'package:shopmaps/cloud/cloud_models.dart';
import 'package:shopmaps/l10n/app_localizations.dart';
import 'package:shopmaps/screens/canonical_store_picker_screen.dart';

class _CatalogCloudController extends CloudController {
  _CatalogCloudController() : super(null);

  @override
  Future<List<GeoapifyAddressSuggestion>> searchStoreAddresses({
    required String query,
    required String languageCode,
  }) async {
    return const [
      GeoapifyAddressSuggestion(
        providerPlaceId: 'address-id',
        formattedAddress: 'Pułaskiego 10, Warszawa',
        street: 'Pułaskiego',
        houseNumber: '10',
        postcode: '00-001',
        city: 'Warszawa',
        countryCode: 'pl',
        latitude: 52.2,
        longitude: 21.0,
      ),
    ];
  }

  @override
  Future<List<NearbyStoreSuggestion>> searchNearbyStores({
    required GeoapifyAddressSuggestion address,
    required String languageCode,
  }) async {
    return const [
      NearbyStoreSuggestion(
        storeLocationId: 'catalog-store-id',
        name: 'Lidl',
        distanceMeters: 87,
        categories: ['commercial.supermarket'],
        address: GeoapifyAddressSuggestion(
          providerPlaceId: 'store-place-id',
          formattedAddress: 'Pułaskiego 12, Warszawa',
          street: 'Pułaskiego',
          houseNumber: '12',
          postcode: '00-001',
          city: 'Warszawa',
          countryCode: 'pl',
          latitude: 52.2001,
          longitude: 21.0001,
        ),
      ),
    ];
  }
}

void main() {
  testWidgets('returns only a store selected from the canonical catalog', (
    tester,
  ) async {
    final cloudController = _CatalogCloudController();
    NearbyStoreSuggestion? selectedStore;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pl'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                selectedStore = await Navigator.of(context)
                    .push<NearbyStoreSuggestion>(
                      MaterialPageRoute<NearbyStoreSuggestion>(
                        builder: (_) => CanonicalStorePickerScreen(
                          cloudController: cloudController,
                        ),
                      ),
                    );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Adres sklepu'),
      'Pulaskiego 10',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pułaskiego 10, Warszawa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lidl'));
    await tester.pumpAndSettle();

    expect(selectedStore?.storeLocationId, 'catalog-store-id');
    expect(selectedStore?.name, 'Lidl');

    cloudController.dispose();
  });
}
