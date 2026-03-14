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
