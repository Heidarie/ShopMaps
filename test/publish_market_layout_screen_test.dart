import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopmaps/cloud/cloud_controller.dart';
import 'package:shopmaps/cloud/cloud_models.dart';
import 'package:shopmaps/app_controller.dart';
import 'package:shopmaps/local_store.dart';
import 'package:shopmaps/l10n/app_localizations.dart';
import 'package:shopmaps/models.dart';
import 'package:shopmaps/screens/publish_market_layout_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NearbyStoresCloudController extends CloudController {
  _NearbyStoresCloudController() : super(null);

  String? publishedStoreName;
  GeoapifyAddressSuggestion? publishedAddress;
  String? publishedStoreLocationId;
  List<String>? publishedOnlineCategoryOrder;
  PublishMarketLayoutResult publishResult = PublishMarketLayoutResult.published;

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
          providerPlaceId: 'store-id',
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

  @override
  Future<PublishMarketLayoutResult> publishMarketLayout({
    required MarketLayout layout,
    required NearbyStoreSuggestion store,
    required List<String> onlineCategoryOrder,
  }) async {
    publishedStoreName = store.name;
    publishedAddress = store.address;
    publishedStoreLocationId = store.storeLocationId;
    publishedOnlineCategoryOrder = onlineCategoryOrder;
    return publishResult;
  }
}

class _NotifyingNearbyStoresCloudController
    extends _NearbyStoresCloudController {
  int nearbySearchCount = 0;

  @override
  Future<List<NearbyStoreSuggestion>> searchNearbyStores({
    required GeoapifyAddressSuggestion address,
    required String languageCode,
  }) {
    nearbySearchCount++;
    notifyListeners();
    return super.searchNearbyStores(
      address: address,
      languageCode: languageCode,
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('loads nearby stores for an existing map after the first frame', (
    tester,
  ) async {
    final appController = AppController(LocalStore());
    await appController.load(localeLanguageCode: 'pl');
    addTearDown(appController.dispose);
    final cloudController = _NotifyingNearbyStoresCloudController();
    final existingMap = SharedMarketLayout(
      id: 'shared-map',
      createdBy: 'current-user',
      creatorHandle: 'Current#0001',
      sourceLocalId: 'local-map',
      categoryOrder: const [],
      location: const CloudStoreLocation(
        id: 'catalog-store-id',
        providerPlaceId: 'store-id',
        storeName: 'Lidl',
        formattedAddress: 'Pułaskiego 12, Warszawa',
        street: 'Pułaskiego',
        houseNumber: '12',
        postcode: '00-001',
        city: 'Warszawa',
        countryCode: 'pl',
        latitude: 52.2001,
        longitude: 21.0001,
      ),
      downloadCount: 0,
      updatedAt: DateTime.utc(2026, 6, 15),
    );

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
        home: ListenableBuilder(
          listenable: cloudController,
          builder: (context, _) => PublishMarketLayoutScreen(
            controller: appController,
            cloudController: cloudController,
            layout: const MarketLayout(
              id: 'local-map',
              name: 'Moja mapa',
              categoryOrder: [],
            ),
            existingMap: existingMap,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(cloudController.nearbySearchCount, 1);
    expect(find.text('Lidl'), findsWidgets);

    cloudController.dispose();
  });

  testWidgets(
    'selecting an address shows nearby stores and uses selected store',
    (tester) async {
      final appController = AppController(LocalStore());
      await appController.load(localeLanguageCode: 'pl');
      addTearDown(appController.dispose);
      final cloudController = _NearbyStoresCloudController();

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
          home: PublishMarketLayoutScreen(
            controller: appController,
            cloudController: cloudController,
            layout: const MarketLayout(
              id: 'local-map',
              name: 'Moja mapa',
              categoryOrder: [],
            ),
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Adres sklepu'),
        'Pulaskiego 10',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pułaskiego 10, Warszawa'));
      await tester.pumpAndSettle();

      expect(find.text('Sklepy najbliżej tego adresu'), findsOneWidget);
      expect(find.text('Lidl'), findsOneWidget);
      expect(find.textContaining('87 m'), findsOneWidget);

      await tester.tap(find.text('Lidl'));
      await tester.pumpAndSettle();
      expect(find.text('Lidl'), findsWidgets);

      await tester.tap(find.text('Opublikuj mapę'));
      await tester.pumpAndSettle();

      expect(cloudController.publishedStoreName, 'Lidl');
      expect(cloudController.publishedAddress?.providerPlaceId, 'store-id');
      expect(cloudController.publishedStoreLocationId, 'catalog-store-id');
      expect(cloudController.publishedOnlineCategoryOrder, isEmpty);

      cloudController.dispose();
    },
  );

  testWidgets('shows a message when the same store layout already exists', (
    tester,
  ) async {
    final appController = AppController(LocalStore());
    await appController.load(localeLanguageCode: 'pl');
    addTearDown(appController.dispose);
    final cloudController = _NearbyStoresCloudController()
      ..publishResult = PublishMarketLayoutResult.duplicate;

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
        home: PublishMarketLayoutScreen(
          controller: appController,
          cloudController: cloudController,
          layout: const MarketLayout(
            id: 'duplicate-local-map',
            name: 'Moja mapa',
            categoryOrder: ['Pieczywo', 'Nabiał'],
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Adres sklepu'),
      'Pulaskiego 10',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pułaskiego 10, Warszawa'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lidl'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Lidl'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Opublikuj mapę'));
    await tester.pumpAndSettle();

    expect(
      find.text('Taki układ tego sklepu jest już udostępniony.'),
      findsOneWidget,
    );
    expect(find.byType(PublishMarketLayoutScreen), findsOneWidget);

    cloudController.dispose();
  });

  testWidgets('requires mapping for an unknown local category before publish', (
    tester,
  ) async {
    final storedData = jsonEncode({
      'categories': ['Moja alejka'],
      'marketLayouts': [],
      'groceryLists': [],
      'depositVouchers': [],
      'itemCategoryMemory': [],
      'frequentItemStats': [],
      'removeCheckedShoppingItems': true,
      'predefinedItemsSeedVersion': 0,
      'onlineCategoryMappings': {'moja alejka': 'drinks'},
    });
    SharedPreferences.setMockInitialValues({'shopmaps_data_v1': storedData});
    final appController = AppController(LocalStore());
    await appController.load(localeLanguageCode: 'pl');
    addTearDown(appController.dispose);
    final cloudController = _NearbyStoresCloudController();

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
        home: PublishMarketLayoutScreen(
          controller: appController,
          cloudController: cloudController,
          layout: const MarketLayout(
            id: 'custom-local-map',
            name: 'Moja mapa',
            categoryOrder: ['Moja alejka'],
          ),
        ),
      ),
    );

    expect(find.text('Dopasuj kategorie'), findsOneWidget);
    expect(find.text('Moja alejka'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Napoje').last);
    await tester.pumpAndSettle();

    expect(find.text('Dopasuj kategorie'), findsOneWidget);
    expect(find.text('Moja alejka -> Napoje'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Adres sklepu'),
      'Pulaskiego 10',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pułaskiego 10, Warszawa'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lidl'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Lidl'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Opublikuj mapę'));
    await tester.pumpAndSettle();

    expect(cloudController.publishedOnlineCategoryOrder, ['drinks']);

    cloudController.dispose();
  });
}
