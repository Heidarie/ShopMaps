import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopmaps/cloud/cloud_controller.dart';
import 'package:shopmaps/cloud/cloud_models.dart';
import 'package:shopmaps/l10n/app_localizations.dart';
import 'package:shopmaps/models.dart';
import 'package:shopmaps/screens/publish_market_layout_screen.dart';

class _NearbyStoresCloudController extends CloudController {
  _NearbyStoresCloudController() : super(null);

  String? publishedStoreName;
  GeoapifyAddressSuggestion? publishedAddress;
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
    required String storeName,
    required GeoapifyAddressSuggestion address,
  }) async {
    publishedStoreName = storeName;
    publishedAddress = address;
    return publishResult;
  }
}

void main() {
  testWidgets(
    'selecting an address shows nearby stores and uses selected store',
    (tester) async {
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
      expect(find.widgetWithText(TextField, 'Lidl'), findsOneWidget);

      await tester.tap(find.text('Opublikuj mapę'));
      await tester.pumpAndSettle();

      expect(cloudController.publishedStoreName, 'Lidl');
      expect(cloudController.publishedAddress?.providerPlaceId, 'store-id');

      cloudController.dispose();
    },
  );

  testWidgets('shows a message when the same store layout already exists', (
    tester,
  ) async {
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
}
