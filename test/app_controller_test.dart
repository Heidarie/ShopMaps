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
