import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopmaps/app_controller.dart';
import 'package:shopmaps/cloud/cloud_controller.dart';
import 'package:shopmaps/cloud/cloud_models.dart';
import 'package:shopmaps/l10n/app_localizations.dart';
import 'package:shopmaps/local_store.dart';
import 'package:shopmaps/models.dart';
import 'package:shopmaps/screens/go_shopping_screen.dart';
import 'package:shopmaps/screens/grocery_list_editor_screen.dart';

class _MutableSharedCloudController extends CloudController {
  _MutableSharedCloudController(this.list) : super(null);

  SharedGroceryList list;
  final List<String> removedItemIds = [];
  final List<String> addedItemNames = [];
  final List<String> notifiedListIds = [];

  @override
  List<SharedGroceryList> get sharedLists => [list];

  @override
  SharedGroceryList? getSharedListById(String id) =>
      id == list.id ? list : null;

  @override
  Future<bool> addItemToSharedList({
    required String listId,
    required String itemName,
    required String category,
    required int quantity,
  }) async {
    addedItemNames.add(itemName);
    list = SharedGroceryList(
      id: list.id,
      spaceId: list.spaceId,
      groupName: list.groupName,
      name: list.name,
      sourceLocalId: list.sourceLocalId,
      items: [
        ...list.items,
        GroceryItem(
          id: 'added-${addedItemNames.length}',
          name: itemName,
          category: category,
          quantity: quantity,
        ),
      ],
    );
    notifyListeners();
    return true;
  }

  @override
  Future<bool> removeItemFromSharedList({
    required String listId,
    required String itemId,
  }) {
    return removeItemsFromSharedList(listId: listId, itemIds: [itemId]);
  }

  @override
  Future<bool> removeItemsFromSharedList({
    required String listId,
    required Iterable<String> itemIds,
  }) async {
    final ids = itemIds.toSet();
    removedItemIds.addAll(ids);
    list = SharedGroceryList(
      id: list.id,
      spaceId: list.spaceId,
      groupName: list.groupName,
      name: list.name,
      sourceLocalId: list.sourceLocalId,
      items: list.items.where((item) => !ids.contains(item.id)).toList(),
    );
    notifyListeners();
    return true;
  }

  @override
  Future<bool> notifySharedListAdditionsCompleted(String listId) async {
    notifiedListIds.add(listId);
    return true;
  }
}

class _RejectingSharedCloudController extends _MutableSharedCloudController {
  _RejectingSharedCloudController(super.list);

  bool _hasError = false;

  @override
  CloudErrorKind? get errorKind =>
      _hasError ? CloudErrorKind.contentRejected : null;

  @override
  String? get errorMessage => _hasError ? 'CONTENT_NOT_ALLOWED' : null;

  @override
  Future<bool> addItemToSharedList({
    required String listId,
    required String itemName,
    required String category,
    required int quantity,
  }) async {
    _hasError = true;
    notifyListeners();
    return false;
  }

  @override
  void clearError() {
    _hasError = false;
    notifyListeners();
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shared list editor sends item deletion to cloud controller', (
    tester,
  ) async {
    final appController = AppController(LocalStore());
    final cloudController = _MutableSharedCloudController(_sharedList());
    await appController.load(localeLanguageCode: 'pl');

    await tester.pumpWidget(
      _testApp(
        GroceryListEditorScreen(
          controller: appController,
          cloudController: cloudController,
          listId: cloudController.list.id,
          isShared: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(cloudController.removedItemIds, ['shared-item']);
    expect(cloudController.notifiedListIds, isEmpty);
    expect(appController.groceryLists, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('list editor opens full-screen item composer and limits hints', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 700);
    addTearDown(tester.view.resetPhysicalSize);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    addTearDown(tester.view.resetViewInsets);

    final appController = AppController(LocalStore());
    await appController.load(localeLanguageCode: 'pl');
    final sourceListId = await appController.createGroceryList('Źródło');
    final targetListId = await appController.createGroceryList('Cel');

    for (var index = 0; index < 10; index++) {
      await appController.addItemToList(
        listId: sourceListId!,
        itemName: 'Mleko wariant $index',
        category: 'Nabiał',
        quantity: 1,
      );
    }
    expect(
      appController.findItemHints('Mleko wariant'),
      hasLength(greaterThan(3)),
    );

    await tester.pumpWidget(
      _testApp(
        GroceryListEditorScreen(
          controller: appController,
          listId: targetListId!,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Dodaj produkt'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, 'Wróć'), findsOneWidget);
    await tester.showKeyboard(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Mleko wariant');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Mleko wariant',
    );
    expect(
      find.byKey(const ValueKey('grocery-list-item-editor-scroll')),
      findsOneWidget,
    );
    final chipLabels = tester
        .widgetList<ActionChip>(find.byType(ActionChip, skipOffstage: false))
        .map((chip) => (chip.label as Text).data)
        .toList();
    expect(chipLabels, containsAll(['Mleko wariant 0 -> Nabiał']));
    expect(
      chipLabels.where((label) => label?.contains('Mleko wariant') ?? false),
      hasLength(3),
    );

    await tester.tap(find.text('Mleko wariant 0 -> Nabiał'));
    await tester.pumpAndSettle();

    expect(tester.testTextInput.isVisible, isTrue);
    expect(
      find.widgetWithText(FilledButton, 'Dodaj produkt').hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Dodaj produkt'));
    await tester.pump();

    expect(find.text('Dodano'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Wróć'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Mleko wariant 0 x 1'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    appController.dispose();
  });

  testWidgets(
    'shared list editor sends one notification only after leaving with additions',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      final appController = AppController(LocalStore());
      final cloudController = _MutableSharedCloudController(_sharedList());
      await appController.load(localeLanguageCode: 'pl');

      await tester.pumpWidget(
        _testApp(
          Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GroceryListEditorScreen(
                        controller: appController,
                        cloudController: cloudController,
                        listId: cloudController.list.id,
                        isShared: true,
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
      await tester.tap(find.widgetWithText(FilledButton, 'Dodaj produkt'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Chleb');
      await tester.tap(find.text('Dodaj kategorię'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Nabiał'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Dodaj produkt'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Dodaj produkt'));
      await tester.pumpAndSettle();

      expect(cloudController.addedItemNames, ['Chleb']);
      expect(cloudController.notifiedListIds, isEmpty);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(cloudController.notifiedListIds, ['shared-list']);

      await tester.pumpWidget(const SizedBox.shrink());
      cloudController.dispose();
      appController.dispose();
    },
  );

  testWidgets(
    'rejected shared item keeps input and does not send a notification',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      final appController = AppController(LocalStore());
      final cloudController = _RejectingSharedCloudController(_sharedList());
      await appController.load(localeLanguageCode: 'pl');

      await tester.pumpWidget(
        _testApp(
          GroceryListEditorScreen(
            controller: appController,
            cloudController: cloudController,
            listId: cloudController.list.id,
            isShared: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Dodaj produkt'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Odrzucony produkt');
      await tester.tap(find.text('Dodaj kategorię'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Nabiał'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Dodaj produkt'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Dodaj produkt'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Treść zawiera niedozwolone lub obraźliwe słowa. '
          'Zmień ją i spróbuj ponownie.',
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'Odrzucony produkt',
      );
      expect(cloudController.addedItemNames, isEmpty);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(cloudController.notifiedListIds, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      cloudController.dispose();
      appController.dispose();
    },
  );

  testWidgets('leaving after deletions only does not send a notification', (
    tester,
  ) async {
    final appController = AppController(LocalStore());
    final cloudController = _MutableSharedCloudController(_sharedList());
    await appController.load(localeLanguageCode: 'pl');

    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GroceryListEditorScreen(
                      controller: appController,
                      cloudController: cloudController,
                      listId: cloudController.list.id,
                      isShared: true,
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
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(cloudController.removedItemIds, ['shared-item']);
    expect(cloudController.notifiedListIds, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('leaving shared shopping flow deletes purchased cloud items', (
    tester,
  ) async {
    final appController = AppController(LocalStore());
    final cloudController = _MutableSharedCloudController(_sharedList());
    await appController.load(localeLanguageCode: 'pl');
    await appController.upsertMarketLayout(
      const MarketLayout(
        id: 'market',
        name: 'Market',
        categoryOrder: ['Nabiał'],
      ),
    );

    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GoShoppingScreen(
                      controller: appController,
                      cloudController: cloudController,
                      groceryListId: cloudController.list.id,
                      marketLayoutId: 'market',
                      shoppingStartedAt: DateTime.now(),
                      isShared: true,
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
    await tester.tap(find.byType(Checkbox));
    await tester.pump(const Duration(seconds: 2));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(cloudController.removedItemIds, ['shared-item']);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });
}

Widget _testApp(Widget home) {
  return MaterialApp(
    locale: const Locale('pl'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}

SharedGroceryList _sharedList() {
  return const SharedGroceryList(
    id: 'shared-list',
    spaceId: 'group-id',
    groupName: 'Dom',
    name: 'Weekend',
    items: [
      GroceryItem(
        id: 'shared-item',
        name: 'Mleko',
        category: 'Nabiał',
        quantity: 1,
      ),
    ],
  );
}
