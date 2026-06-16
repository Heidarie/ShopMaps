import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopmaps/app_controller.dart';
import 'package:shopmaps/cloud/cloud_controller.dart';
import 'package:shopmaps/cloud/cloud_models.dart';
import 'package:shopmaps/device_location_service.dart';
import 'package:shopmaps/l10n/app_localizations.dart';
import 'package:shopmaps/local_store.dart';
import 'package:shopmaps/models.dart';
import 'package:shopmaps/screens/home_screen.dart';

class _SharedDataCloudController extends CloudController {
  _SharedDataCloudController() : super(null);

  bool hiddenSharedVoucher = false;
  bool usedSharedVoucher = false;

  @override
  List<SharedGroceryList> get sharedLists => const [
    SharedGroceryList(
      id: 'shared-list',
      spaceId: 'group-id',
      groupName: 'Dom',
      name: 'Weekend',
      sourceLocalId: 'local-weekend',
      items: [
        GroceryItem(
          id: 'shared-item',
          name: 'Mleko',
          category: 'Nabiał',
          quantity: 1,
        ),
      ],
    ),
  ];

  @override
  List<SharedDepositVoucher> get sharedVouchers =>
      hiddenSharedVoucher || usedSharedVoucher
      ? const []
      : [
          SharedDepositVoucher(
            id: 'shared-voucher',
            spaceId: 'group-id',
            groupName: 'Dom',
            code: 'SHARED-CODE',
            format: 'qrCode',
            scannedAt: DateTime.utc(2026, 6, 11),
            amount: 10,
            storeName: 'Market',
            validUntil: DateTime.utc(2026, 7, 1),
            redeemedAt: null,
          ),
        ];

  @override
  Future<bool> hideSharedVoucher(String voucherId) async {
    hiddenSharedVoucher = true;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> useSharedVoucher(String voucherId) async {
    usedSharedVoucher = true;
    notifyListeners();
    return true;
  }
}

class _PublicMapsCloudController extends CloudController {
  _PublicMapsCloudController({
    this.includeLongMap = false,
    this.includeFarMap = false,
  }) : super(null);

  final bool includeLongMap;
  final bool includeFarMap;
  int recordedDownloads = 0;
  String? reportedMapId;
  String? reportReason;

  @override
  bool get isSignedIn => true;

  @override
  CloudProfile get profile => const CloudProfile(
    id: 'current-user',
    displayName: 'Current',
    discriminator: 1,
  );

  @override
  List<SharedMarketLayout> get publicMarketLayouts => [
    if (includeFarMap)
      SharedMarketLayout(
        id: 'far-map',
        createdBy: 'far-user',
        creatorHandle: 'Far#0044',
        sourceLocalId: 'far-source-map',
        categoryOrder: const ['Household'],
        downloadCount: 30,
        location: const CloudStoreLocation(
          id: 'far-location-id',
          providerPlaceId: 'far-place-id',
          storeName: 'Daleki Market',
          formattedAddress: 'Rynek 1, Kraków',
          street: 'Rynek',
          houseNumber: '1',
          postcode: '31-042',
          city: 'Kraków',
          countryCode: 'pl',
          latitude: 50.0614,
          longitude: 19.9366,
        ),
        updatedAt: DateTime.utc(2026, 6, 13),
      ),
    SharedMarketLayout(
      id: 'popular-map',
      createdBy: 'popular-user',
      creatorHandle: 'Popular#0021',
      sourceLocalId: 'popular-source-map',
      categoryOrder: const ['Drinks'],
      downloadCount: 25,
      location: const CloudStoreLocation(
        id: 'popular-location-id',
        providerPlaceId: 'popular-place-id',
        storeName: 'Popular Market',
        formattedAddress: 'ul. Popularna 1, Warszawa',
        street: 'Popularna',
        houseNumber: '1',
        postcode: '00-002',
        city: 'Warszawa',
        countryCode: 'pl',
        latitude: 52.21,
        longitude: 21.01,
      ),
      updatedAt: DateTime.utc(2026, 6, 10),
    ),
    SharedMarketLayout(
      id: 'public-map',
      createdBy: 'other-user',
      creatorHandle: 'Endriu#0042',
      sourceLocalId: 'source-map',
      categoryOrder: const ['Bakery', 'Dairy'],
      downloadCount: 7,
      location: const CloudStoreLocation(
        id: 'location-id',
        providerPlaceId: 'place-id',
        storeName: 'Market Pułaskiego',
        formattedAddress: 'ul. Pułaskiego 10, Warszawa',
        street: 'Pułaskiego',
        houseNumber: '10',
        postcode: '00-001',
        city: 'Warszawa',
        countryCode: 'pl',
        latitude: 52.2,
        longitude: 21.0,
      ),
      updatedAt: DateTime.utc(2026, 6, 11),
    ),
    if (includeLongMap)
      SharedMarketLayout(
        id: 'long-map',
        createdBy: 'long-map-user',
        creatorHandle: 'Long#0043',
        sourceLocalId: 'long-source-map',
        categoryOrder: const [
          'Bakery',
          'Dairy',
          'Drinks',
          'Frozen',
          'Fruits',
          'Vegetables',
        ],
        downloadCount: 1,
        location: const CloudStoreLocation(
          id: 'long-location-id',
          providerPlaceId: 'long-place-id',
          storeName: 'Long Market',
          formattedAddress: 'ul. Długa 1, Warszawa',
          street: 'Długa',
          houseNumber: '1',
          postcode: '00-003',
          city: 'Warszawa',
          countryCode: 'pl',
          latitude: 52.22,
          longitude: 21.02,
        ),
        updatedAt: DateTime.utc(2026, 6, 12),
      ),
  ];

  @override
  Future<bool> recordMarketLayoutDownload(String publicMapId) async {
    recordedDownloads++;
    return true;
  }

  @override
  Future<bool> reportMarketLayout({
    required String publicMapId,
    required String reason,
  }) async {
    reportedMapId = publicMapId;
    reportReason = reason;
    return true;
  }
}

class _InvitedCloudController extends CloudController {
  _InvitedCloudController() : super(null);

  @override
  bool get isSignedIn => true;

  @override
  CloudProfile get profile => const CloudProfile(
    id: 'current-user',
    displayName: 'Tester',
    discriminator: 8533,
  );

  @override
  List<CloudGroupInvite> get invites => const [
    CloudGroupInvite(
      id: 'invite-id',
      spaceId: 'group-id',
      groupName: 'Dom',
      inviterHandle: 'Endriu#0042',
    ),
  ];
}

class _FixedLocationService implements DeviceLocationService {
  const _FixedLocationService(this.location);

  final DeviceLocation location;

  @override
  Future<DeviceLocation> getCurrentLocation() async => location;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shared lists and vouchers are visible in the main tabs', (
    tester,
  ) async {
    final appController = AppController(LocalStore());
    final cloudController = _SharedDataCloudController();
    await appController.load(localeLanguageCode: 'pl');
    await appController.upsertGroceryList(
      const GroceryListModel(id: 'local-weekend', name: 'Weekend', items: []),
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
        home: HomeScreen(
          controller: appController,
          cloudController: cloudController,
          onToggleThemeMode: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.playlist_add_check_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Weekend'), findsOneWidget);
    expect(find.textContaining('Dom'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.qr_code_2_outlined));
    await tester.pumpAndSettle();
    expect(find.text('SHARED-CODE'), findsOneWidget);
    expect(find.textContaining('Dom'), findsOneWidget);

    await tester.tap(find.text('SHARED-CODE'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Wykorzystany'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('deleting a shared voucher hides it only for the current user', (
    tester,
  ) async {
    final appController = AppController(LocalStore());
    final cloudController = _SharedDataCloudController();
    await appController.load(localeLanguageCode: 'pl');

    await tester.pumpWidget(
      _homeApp(appController: appController, cloudController: cloudController),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.qr_code_2_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usuń'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Usuń'));
    await tester.pumpAndSettle();

    expect(cloudController.hiddenSharedVoucher, isTrue);
    expect(cloudController.usedSharedVoucher, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('marking a shared voucher used removes it for everyone', (
    tester,
  ) async {
    final appController = AppController(LocalStore());
    final cloudController = _SharedDataCloudController();
    await appController.load(localeLanguageCode: 'pl');

    await tester.pumpWidget(
      _homeApp(appController: appController, cloudController: cloudController),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.qr_code_2_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wykorzystany'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Wykorzystany'));
    await tester.pumpAndSettle();

    expect(cloudController.usedSharedVoucher, isTrue);
    expect(cloudController.hiddenSharedVoucher, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('public store map can be copied to local maps', (tester) async {
    final appController = AppController(LocalStore());
    final cloudController = _PublicMapsCloudController();
    await appController.load(localeLanguageCode: 'pl');

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
        home: HomeScreen(
          controller: appController,
          cloudController: cloudController,
          onToggleThemeMode: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Szukaj'));
    await tester.pumpAndSettle();
    expect(find.text('Market Pułaskiego'), findsOneWidget);
    expect(find.textContaining('Pułaskiego 10'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Popular Market')).dy,
      lessThan(tester.getTopLeft(find.text('Market Pułaskiego')).dy),
    );

    await tester.tap(find.text('Market Pułaskiego'));
    await tester.pumpAndSettle();
    expect(find.text('E'), findsOneWidget);
    expect(find.text('Endriu#0042'), findsNothing);
    expect(find.text('Pobrania: 7'), findsOneWidget);
    await tester.ensureVisible(find.byType(PopupMenuButton<String>).first);
    await tester.drag(find.byType(ListView).last, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dodaj do moich sklepów'));
    await tester.pumpAndSettle();

    expect(cloudController.recordedDownloads, 1);
    expect(appController.marketLayouts.single.name, 'Market Pułaskiego');
    expect(appController.marketLayouts.single.categoryOrder, [
      'Bakery',
      'Dairy',
    ]);
    expect(
      appController.marketLayouts.single.sourceSharedMarketLayoutId,
      'public-map',
    );

    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.byTooltip('Już w moich sklepach'), findsOneWidget);
    expect(find.text('Dodaj do moich sklepów'), findsNothing);

    await appController.deleteMarketLayout(
      appController.marketLayouts.single.id,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(PopupMenuButton<String>).first);
    await tester.drag(find.byType(ListView).last, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    expect(find.text('Dodaj do moich sklepów'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('long public map preview opens full map modal', (tester) async {
    final appController = AppController(LocalStore());
    final cloudController = _PublicMapsCloudController(includeLongMap: true);
    await appController.load(localeLanguageCode: 'pl');

    await tester.pumpWidget(
      _homeApp(appController: appController, cloudController: cloudController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Szukaj'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Long Market'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -100));
    await tester.pumpAndSettle();

    expect(
      find.text('Bakery  →  Dairy  →  Drinks  →  Frozen  →  ...'),
      findsOneWidget,
    );
    expect(find.text('Fruits'), findsNothing);
    expect(find.text('Vegetables'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('public-map-long-map')));
    await tester.pumpAndSettle();

    expect(find.text('Fruits'), findsOneWidget);
    expect(find.text('Vegetables'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Dodaj'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Wróć'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Wróć'));
    await tester.pumpAndSettle();
    expect(appController.marketLayouts, isEmpty);

    await tester.tap(find.byKey(const ValueKey('public-map-long-map')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Dodaj'));
    await tester.pumpAndSettle();

    expect(cloudController.recordedDownloads, 1);
    expect(appController.marketLayouts.single.name, 'Long Market');
    expect(appController.marketLayouts.single.categoryOrder, [
      'Bakery',
      'Dairy',
      'Drinks',
      'Frozen',
      'Fruits',
      'Vegetables',
    ]);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('long local map preview opens full map modal', (tester) async {
    final appController = AppController(LocalStore());
    final cloudController = CloudController(null);
    await appController.load(localeLanguageCode: 'pl');
    await appController.upsertMarketLayout(
      const MarketLayout(
        id: 'long-local-map',
        name: 'Mój długi sklep',
        categoryOrder: [
          'Bakery',
          'Dairy',
          'Drinks',
          'Frozen',
          'Fruits',
          'Vegetables',
        ],
      ),
    );

    await tester.pumpWidget(
      _homeApp(appController: appController, cloudController: cloudController),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Bakery  →  Dairy  →  Drinks  →  Frozen  →  ...'),
      findsOneWidget,
    );
    expect(find.text('Fruits'), findsNothing);
    expect(find.text('Vegetables'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('local-map-long-local-map')));
    await tester.pumpAndSettle();

    expect(find.text('Fruits'), findsOneWidget);
    expect(find.text('Vegetables'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Edytuj'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Wróć'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Wróć'));
    await tester.pumpAndSettle();
    expect(find.text('Fruits'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('public store maps can be sorted by current location', (
    tester,
  ) async {
    final appController = AppController(LocalStore());
    final cloudController = _PublicMapsCloudController();
    await appController.load(localeLanguageCode: 'pl');

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
        home: HomeScreen(
          controller: appController,
          cloudController: cloudController,
          locationService: const _FixedLocationService(
            DeviceLocation(latitude: 52.2, longitude: 21.0),
          ),
          onToggleThemeMode: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Szukaj'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Popular Market')).dy,
      lessThan(tester.getTopLeft(find.text('Market Pułaskiego')).dy),
    );

    await tester.tap(find.text('Znajdź blisko mnie'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Market Pułaskiego')).dy,
      lessThan(tester.getTopLeft(find.text('Popular Market')).dy),
    );
    expect(find.textContaining('0 m'), findsOneWidget);
    expect(find.byTooltip('Wyczyść lokalizację'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('find near me shows stores within four kilometers', (
    tester,
  ) async {
    final appController = AppController(LocalStore());
    final cloudController = _PublicMapsCloudController(includeFarMap: true);
    await appController.load(localeLanguageCode: 'pl');

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
        home: HomeScreen(
          controller: appController,
          cloudController: cloudController,
          locationService: const _FixedLocationService(
            DeviceLocation(latitude: 52.2, longitude: 21.0),
          ),
          onToggleThemeMode: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Szukaj'));
    await tester.pumpAndSettle();
    expect(find.text('Daleki Market'), findsOneWidget);

    await tester.tap(find.text('Znajdź blisko mnie'));
    await tester.pumpAndSettle();

    expect(find.text('Daleki Market'), findsNothing);
    expect(find.text('Market Pułaskiego'), findsOneWidget);
    expect(find.text('Popular Market'), findsOneWidget);

    await tester.tap(find.byTooltip('Wyczyść lokalizację'));
    await tester.pumpAndSettle();
    expect(find.text('Daleki Market'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('a public store map can be reported', (tester) async {
    final appController = AppController(LocalStore());
    final cloudController = _PublicMapsCloudController();
    await appController.load(localeLanguageCode: 'pl');

    await tester.pumpWidget(
      _homeApp(appController: appController, cloudController: cloudController),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Szukaj'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Market Pułaskiego'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(PopupMenuButton<String>).first);
    await tester.drag(find.byType(ListView).last, const Offset(0, -150));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zgłoś mapę'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nieprawidłowe lub nieaktualne informacje'));
    await tester.pumpAndSettle();

    expect(cloudController.reportedMapId, 'public-map');
    expect(cloudController.reportReason, 'incorrect');
    expect(find.text('Mapa została zgłoszona.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('groups configuration tile shows pending invitation count', (
    tester,
  ) async {
    final appController = AppController(LocalStore());
    final cloudController = _InvitedCloudController();
    await appController.load(localeLanguageCode: 'pl');

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
        home: HomeScreen(
          controller: appController,
          cloudController: cloudController,
          onToggleThemeMode: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    final badge = find.byKey(const ValueKey('groups-invite-badge'));
    expect(badge, findsOneWidget);
    expect(
      find.descendant(of: badge, matching: find.text('1')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });
}

Widget _homeApp({
  required AppController appController,
  required CloudController cloudController,
}) {
  return MaterialApp(
    locale: const Locale('pl'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: HomeScreen(
      controller: appController,
      cloudController: cloudController,
      onToggleThemeMode: () {},
    ),
  );
}
