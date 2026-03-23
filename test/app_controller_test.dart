import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shopmaps/app_controller.dart';
import 'package:shopmaps/local_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('top frequent items require at least 3 additions and are sorted by count', () async {
    final controller = AppController(LocalStore());
    await controller.load();

    final listId = await controller.createGroceryList('Weekly list');
    expect(listId, isNotNull);
    final createdListId = listId!;

    for (var index = 0; index < 4; index++) {
      await controller.addItemToList(
        listId: createdListId,
        itemName: 'Banana',
        category: 'Fruits',
        quantity: 1,
      );
    }

    for (var index = 0; index < 3; index++) {
      await controller.addItemToList(
        listId: createdListId,
        itemName: 'Milk',
        category: 'Dairy',
        quantity: 1,
      );
    }

    for (var index = 0; index < 2; index++) {
      await controller.addItemToList(
        listId: createdListId,
        itemName: 'Water',
        category: 'Drinks',
        quantity: 1,
      );
    }

    final suggestions = controller.getTopFrequentItems();

    expect(
      suggestions.map((entry) => entry.itemName).toList(),
      ['Banana', 'Milk'],
    );
    expect(
      suggestions.map((entry) => entry.occurrenceCount).toList(),
      [4, 3],
    );
  });

  test('frequent items older than 2 weeks are ignored after loading', () async {
    final now = DateTime.now().toUtc();
    final storedData = jsonEncode({
      'categories': ['Dairy'],
      'marketLayouts': [],
      'groceryLists': [],
      'itemCategoryMemory': [],
      'frequentItemStats': [
        {
          'itemName': 'Old milk',
          'category': 'Dairy',
          'occurrenceCount': 5,
          'lastAddedAt': now.subtract(const Duration(days: 15)).toIso8601String(),
        },
        {
          'itemName': 'Fresh milk',
          'category': 'Dairy',
          'occurrenceCount': 3,
          'lastAddedAt': now.subtract(const Duration(days: 2)).toIso8601String(),
        },
      ],
    });

    SharedPreferences.setMockInitialValues({
      'shopmaps_data_v1': storedData,
    });

    final controller = AppController(LocalStore());
    await controller.load();

    final suggestions = controller.getTopFrequentItems();

    expect(suggestions, hasLength(1));
    expect(suggestions.single.itemName, 'Fresh milk');
    expect(suggestions.single.occurrenceCount, 3);
  });

  test('first load seeds default categories in the requested locale', () async {
    final controller = AppController(LocalStore());
    await controller.load(localeLanguageCode: 'pl');

    expect(
      controller.categories,
      [
        'Napoje',
        'Słodycze',
        'Owoce',
        'Warzywa',
        'Alkohol',
        'Nabiał',
        'Piekarnia',
        'Mięso',
        'Mrożonki',
        'Chemia domowa',
      ],
    );
  });

  test('first load seeds predefined items in the requested locale', () async {
    final controller = AppController(LocalStore());
    await controller.load(localeLanguageCode: 'pl');

    expect(controller.findCategoryForExactItem('Woda niegazowana'), 'Napoje');
    expect(controller.findCategoryForExactItem('Czekolada mleczna'), 'Słodycze');
    expect(controller.findCategoryForExactItem('Papryczka chili'), 'Warzywa');
    expect(controller.findCategoryForExactItem('Still water'), isNull);
  });

  test('first load seeds english predefined items for english locale', () async {
    final controller = AppController(LocalStore());
    await controller.load(localeLanguageCode: 'en');

    expect(controller.findCategoryForExactItem('Still water'), 'Drinks');
    expect(controller.findCategoryForExactItem('Milk chocolate'), 'Sweets');
    expect(controller.findCategoryForExactItem('Chili pepper'), 'Vegetables');
    expect(controller.findCategoryForExactItem('Woda niegazowana'), isNull);
    expect(controller.findCategoryForExactItem('Papryczka chili'), isNull);
  });

  test('first load seeds translated extra predefined items for german locale', () async {
    final controller = AppController(LocalStore());
    await controller.load(localeLanguageCode: 'de');

    expect(controller.findCategoryForExactItem('Aromatisiertes Wasser'), 'Getränke');
    expect(controller.findCategoryForExactItem('Chilischote'), 'Gemüse');
    expect(controller.findCategoryForExactItem('Woda smakowa'), isNull);
  });

  test('unsupported locale falls back to english predefined items', () async {
    final controller = AppController(LocalStore());
    await controller.load(localeLanguageCode: 'ru');

    expect(controller.categories.first, 'Drinks');
    expect(controller.findCategoryForExactItem('Still water'), 'Drinks');
    expect(controller.findCategoryForExactItem('Chili pepper'), 'Vegetables');
    expect(controller.findCategoryForExactItem('Woda niegazowana'), isNull);
    expect(controller.findCategoryForExactItem('Papryczka chili'), isNull);
  });

  test('remove checked shopping items setting defaults to true and persists', () async {
    final controller = AppController(LocalStore());
    await controller.load(localeLanguageCode: 'pl');

    expect(controller.removeCheckedShoppingItems, isTrue);

    await controller.setRemoveCheckedShoppingItems(false);

    final reloadedController = AppController(LocalStore());
    await reloadedController.load(localeLanguageCode: 'pl');

    expect(reloadedController.removeCheckedShoppingItems, isFalse);
  });

  test('removeItemsFromList removes selected items and keeps the grocery list', () async {
    final controller = AppController(LocalStore());
    await controller.load(localeLanguageCode: 'pl');

    final listId = await controller.createGroceryList('Weekend');
    expect(listId, isNotNull);

    await controller.addItemToList(
      listId: listId!,
      itemName: 'Jabłko',
      category: 'Owoce',
      quantity: 1,
    );
    await controller.addItemToList(
      listId: listId,
      itemName: 'Pomidor',
      category: 'Warzywa',
      quantity: 2,
    );

    final initialList = controller.getGroceryListById(listId)!;
    final removedCount = await controller.removeItemsFromList(
      listId: listId,
      itemIds: [initialList.items.first.id],
    );

    expect(removedCount, 1);
    expect(controller.getGroceryListById(listId), isNotNull);
    expect(
      controller.getGroceryListById(listId)!.items.map((item) => item.name).toList(),
      ['Pomidor'],
    );

    final removedAll = await controller.removeItemsFromList(
      listId: listId,
      itemIds: controller.getGroceryListById(listId)!.items.map((item) => item.id),
    );

    expect(removedAll, 1);
    expect(controller.getGroceryListById(listId), isNotNull);
    expect(controller.getGroceryListById(listId)!.items, isEmpty);
  });

  test('predefined item migration keeps existing remembered category overrides', () async {
    final storedData = jsonEncode({
      'categories': [
        'Napoje',
        'Słodycze',
        'Owoce',
        'Warzywa',
        'Alkohol',
        'Nabiał',
        'Piekarnia',
        'Mięso',
        'Mrożonki',
        'Chemia domowa',
        'Specjalna kategoria',
      ],
      'marketLayouts': [],
      'groceryLists': [],
      'itemCategoryMemory': [
        {
          'itemName': 'Woda niegazowana',
          'category': 'Specjalna kategoria',
        },
      ],
      'frequentItemStats': [],
      'removeCheckedShoppingItems': true,
    });

    SharedPreferences.setMockInitialValues({
      'shopmaps_data_v1': storedData,
    });

    final controller = AppController(LocalStore());
    await controller.load(localeLanguageCode: 'pl');

    expect(
      controller.findCategoryForExactItem('Woda niegazowana'),
      'Specjalna kategoria',
    );
    expect(controller.findCategoryForExactItem('Papryczka chili'), 'Warzywa');
  });

  test('predefined items are repaired for existing installs even at the same seed version', () async {
    final storedData = jsonEncode({
      'categories': [
        'Napoje',
        'Słodycze',
        'Owoce',
        'Warzywa',
        'Alkohol',
        'Nabiał',
        'Piekarnia',
        'Mięso',
        'Mrożonki',
        'Chemia domowa',
      ],
      'marketLayouts': [],
      'groceryLists': [],
      'itemCategoryMemory': [],
      'frequentItemStats': [],
      'predefinedItemsSeedVersion': 2,
    });

    SharedPreferences.setMockInitialValues({
      'shopmaps_data_v1': storedData,
    });

    final controller = AppController(LocalStore());
    await controller.load(localeLanguageCode: 'en');

    expect(controller.findCategoryForExactItem('Still water'), 'Napoje');
    expect(controller.findCategoryForExactItem('Chili pepper'), 'Warzywa');
    expect(controller.findCategoryForExactItem('Papryczka chili'), isNull);
  });

  test('first seeded categories stay fixed after later loads with a different locale', () async {
    final firstController = AppController(LocalStore());
    await firstController.load(localeLanguageCode: 'pl');

    final secondController = AppController(LocalStore());
    await secondController.load(localeLanguageCode: 'en');

    expect(
      secondController.categories,
      [
        'Napoje',
        'Słodycze',
        'Owoce',
        'Warzywa',
        'Alkohol',
        'Nabiał',
        'Piekarnia',
        'Mięso',
        'Mrożonki',
        'Chemia domowa',
      ],
    );
  });

  test('invalid stored json is backed up before resetting to localized defaults', () async {
    SharedPreferences.setMockInitialValues({
      'shopmaps_data_v1': '{broken json',
    });

    final controller = AppController(LocalStore());
    await controller.load(localeLanguageCode: 'pl');

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('shopmaps_data_backup_v1'),
      '{broken json',
    );
    expect(controller.categories.first, 'Napoje');
  });

  test('non-map stored json is backed up before resetting to localized defaults', () async {
    SharedPreferences.setMockInitialValues({
      'shopmaps_data_v1': jsonEncode(['unexpected', 'payload']),
    });

    final controller = AppController(LocalStore());
    await controller.load(localeLanguageCode: 'pl');

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('shopmaps_data_backup_v1'),
      jsonEncode(['unexpected', 'payload']),
    );
    expect(controller.categories.first, 'Napoje');
  });

  test('legacy english default categories migrate to localized defaults with references', () async {
    final now = DateTime.now().toUtc();
    final storedData = jsonEncode({
      'categories': [
        'Drinks',
        'Sweets',
        'Fruits',
        'Vegetables',
        'Alcohol',
        'Dairy',
        'Bakery',
        'Meat',
        'Frozen',
        'Household',
      ],
      'marketLayouts': [
        {
          'id': 'layout-1',
          'name': 'Test market',
          'categoryOrder': ['Drinks', 'Fruits', 'Vegetables'],
        },
      ],
      'groceryLists': [
        {
          'id': 'list-1',
          'name': 'Test list',
          'items': [
            {
              'id': 'item-1',
              'name': 'Water',
              'category': 'Drinks',
              'quantity': 1,
            },
          ],
        },
      ],
      'itemCategoryMemory': [
        {
          'itemName': 'Water',
          'category': 'Drinks',
        },
      ],
      'frequentItemStats': [
        {
          'itemName': 'Water',
          'category': 'Drinks',
          'occurrenceCount': 4,
          'lastAddedAt': now.toIso8601String(),
          'isFavorite': false,
        },
      ],
    });

    SharedPreferences.setMockInitialValues({
      'shopmaps_data_v1': storedData,
    });

    final controller = AppController(LocalStore());
    await controller.load(localeLanguageCode: 'pl');

    expect(controller.categories.first, 'Napoje');
    expect(controller.marketLayouts.single.categoryOrder.first, 'Napoje');
    expect(controller.groceryLists.single.items.single.category, 'Napoje');
    expect(controller.findCategoryForExactItem('Water'), 'Napoje');
    expect(controller.getTopFrequentItems().single.category, 'Napoje');
  });

  test('legacy default categories migrate even when stored values differ in case', () async {
    final now = DateTime.now().toUtc();
    final storedData = jsonEncode({
      'categories': [
        'drinks',
        'sweets',
        'fruits',
        'vegetables',
        'alcohol',
        'dairy',
        'bakery',
        'meat',
        'frozen',
        'household',
      ],
      'marketLayouts': [
        {
          'id': 'layout-1',
          'name': 'Test market',
          'categoryOrder': ['drinks', 'fruits'],
        },
      ],
      'groceryLists': [
        {
          'id': 'list-1',
          'name': 'Test list',
          'items': [
            {
              'id': 'item-1',
              'name': 'Water',
              'category': 'drinks',
              'quantity': 1,
            },
          ],
        },
      ],
      'itemCategoryMemory': [
        {
          'itemName': 'Water',
          'category': 'drinks',
        },
      ],
      'frequentItemStats': [
        {
          'itemName': 'Water',
          'category': 'drinks',
          'occurrenceCount': 4,
          'lastAddedAt': now.toIso8601String(),
          'isFavorite': false,
        },
      ],
    });

    SharedPreferences.setMockInitialValues({
      'shopmaps_data_v1': storedData,
    });

    final controller = AppController(LocalStore());
    await controller.load(localeLanguageCode: 'pl');

    expect(controller.categories.first, 'Napoje');
    expect(controller.marketLayouts.single.categoryOrder.first, 'Napoje');
    expect(controller.groceryLists.single.items.single.category, 'Napoje');
    expect(controller.findCategoryForExactItem('Water'), 'Napoje');
    expect(controller.getTopFrequentItems().single.category, 'Napoje');
  });

  test('legacy categories are not migrated after user changes the default set', () async {
    final storedData = jsonEncode({
      'categories': [
        'My Drinks',
        'Sweets',
        'Fruits',
        'Vegetables',
        'Alcohol',
        'Dairy',
        'Bakery',
        'Meat',
        'Frozen',
        'Household',
      ],
      'marketLayouts': [],
      'groceryLists': [],
      'itemCategoryMemory': [],
      'frequentItemStats': [],
    });

    SharedPreferences.setMockInitialValues({
      'shopmaps_data_v1': storedData,
    });

    final controller = AppController(LocalStore());
    await controller.load(localeLanguageCode: 'pl');

    expect(controller.categories.first, 'My Drinks');
    expect(controller.categories[1], 'Sweets');
  });

  test('favorite frequent items are kept and shown before regular suggestions', () async {
    final now = DateTime.now().toUtc();
    final storedData = jsonEncode({
      'categories': ['Fruits', 'Dairy'],
      'marketLayouts': [],
      'groceryLists': [],
      'itemCategoryMemory': [],
      'frequentItemStats': [
        {
          'itemName': 'Pinned apple',
          'category': 'Fruits',
          'occurrenceCount': 1,
          'lastAddedAt': now.subtract(const Duration(days: 20)).toIso8601String(),
          'isFavorite': true,
        },
        {
          'itemName': 'Milk',
          'category': 'Dairy',
          'occurrenceCount': 5,
          'lastAddedAt': now.subtract(const Duration(days: 2)).toIso8601String(),
          'isFavorite': false,
        },
      ],
    });

    SharedPreferences.setMockInitialValues({
      'shopmaps_data_v1': storedData,
    });

    final controller = AppController(LocalStore());
    await controller.load();

    final suggestions = controller.getTopFrequentItems();

    expect(suggestions, hasLength(2));
    expect(suggestions.first.itemName, 'Pinned apple');
    expect(suggestions.first.isFavorite, isTrue);
    expect(suggestions[1].itemName, 'Milk');
  });

  test('favorite frequent items are limited to 10', () async {
    final now = DateTime.now().toUtc();
    final frequentItemStats = List.generate(
      11,
      (index) => {
        'itemName': 'Item $index',
        'category': 'Fruits',
        'occurrenceCount': 1,
        'lastAddedAt': now.subtract(Duration(days: index)).toIso8601String(),
        'isFavorite': false,
      },
    );
    final storedData = jsonEncode({
      'categories': ['Fruits'],
      'marketLayouts': [],
      'groceryLists': [],
      'itemCategoryMemory': [],
      'frequentItemStats': frequentItemStats,
    });

    SharedPreferences.setMockInitialValues({
      'shopmaps_data_v1': storedData,
    });

    final controller = AppController(LocalStore());
    await controller.load();

    for (var index = 0; index < 10; index++) {
      final updated = await controller.setFrequentItemFavorite(
        itemName: 'Item $index',
        isFavorite: true,
      );
      expect(updated, isTrue);
    }

    final blockedUpdate = await controller.setFrequentItemFavorite(
      itemName: 'Item 10',
      isFavorite: true,
    );

    expect(blockedUpdate, isFalse);
    expect(controller.favoriteFrequentItemCount, 10);
  });

  test('deleteFrequentItem removes the entry and updates favorites state', () async {
    final now = DateTime.now().toUtc();
    final storedData = jsonEncode({
      'categories': ['Fruits', 'Dairy'],
      'marketLayouts': [],
      'groceryLists': [],
      'itemCategoryMemory': [],
      'frequentItemStats': [
        {
          'itemName': 'Pinned apple',
          'category': 'Fruits',
          'occurrenceCount': 4,
          'lastAddedAt': now.subtract(const Duration(days: 1)).toIso8601String(),
          'isFavorite': true,
        },
        {
          'itemName': 'Milk',
          'category': 'Dairy',
          'occurrenceCount': 5,
          'lastAddedAt': now.subtract(const Duration(days: 2)).toIso8601String(),
          'isFavorite': false,
        },
      ],
    });

    SharedPreferences.setMockInitialValues({
      'shopmaps_data_v1': storedData,
    });

    final controller = AppController(LocalStore());
    await controller.load();

    expect(controller.favoriteFrequentItemCount, 1);

    final deleted = await controller.deleteFrequentItem('Pinned apple');

    expect(deleted, isTrue);
    expect(controller.favoriteFrequentItemCount, 0);
    expect(
      controller.getFrequentItemsForConfiguration().map((entry) => entry.itemName).toList(),
      ['Milk'],
    );
    expect(controller.getFrequentItemsForConfiguration().single.isFavorite, isFalse);
    expect(controller.getTopFrequentItems().single.itemName, 'Milk');
    expect(controller.getTopFrequentItems().single.occurrenceCount, 5);
  });

  test('loading frequent items skips articles already on the list', () async {
    final controller = AppController(LocalStore());
    await controller.load();

    final sourceListId = await controller.createGroceryList('Source list');
    expect(sourceListId, isNotNull);
    final sourceId = sourceListId!;

    for (var index = 0; index < 4; index++) {
      await controller.addItemToList(
        listId: sourceId,
        itemName: 'Banana',
        category: 'Fruits',
        quantity: 1,
      );
    }

    for (var index = 0; index < 3; index++) {
      await controller.addItemToList(
        listId: sourceId,
        itemName: 'Milk',
        category: 'Dairy',
        quantity: 1,
      );
    }

    final targetListId = await controller.createGroceryList('Target list');
    expect(targetListId, isNotNull);
    final targetId = targetListId!;

    await controller.addItemToList(
      listId: targetId,
      itemName: 'Banana',
      category: 'Fruits',
      quantity: 1,
    );

    final addedCount = await controller.loadTopFrequentItemsIntoList(targetId);
    final targetList = controller.getGroceryListById(targetId);

    expect(addedCount, 1);
    expect(targetList, isNotNull);
    expect(
      targetList!.items.map((item) => item.name).toList(),
      ['Banana', 'Milk'],
    );
  });
}
