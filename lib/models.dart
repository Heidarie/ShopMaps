import 'dart:math';

const List<String> defaultCategories = [
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
];

String createId() {
  final randomPart = Random().nextInt(1 << 32).toRadixString(16);
  return '${DateTime.now().microsecondsSinceEpoch}_$randomPart';
}

class AppData {
  AppData({
    required this.categories,
    required this.marketLayouts,
    required this.groceryLists,
    required this.itemCategoryMemory,
  });

  factory AppData.empty() {
    return AppData(
      categories: [...defaultCategories],
      marketLayouts: const [],
      groceryLists: const [],
      itemCategoryMemory: const [],
    );
  }

  factory AppData.fromJson(Map<String, dynamic> json) {
    final loadedCategories = _uniqueCaseInsensitive(_toStringList(json['categories']));
    final marketLayouts = _toDynamicList(json['marketLayouts'])
        .map(MarketLayout.fromJson)
        .toList();
    final groceryLists = _toDynamicList(json['groceryLists'])
        .map(GroceryListModel.fromJson)
        .toList();
    final memoryFromStorage = _toDynamicList(json['itemCategoryMemory'])
        .map(RememberedItemCategory.fromJson)
        .toList();
    final memoryFromLists = _rememberedItemsFromLists(groceryLists);
    final mergedMemory = _mergeRememberedItems(
      baseline: memoryFromLists,
      overrides: memoryFromStorage,
    );

    return AppData(
      categories: loadedCategories.isEmpty
          ? [...defaultCategories]
          : loadedCategories,
      marketLayouts: marketLayouts,
      groceryLists: groceryLists,
      itemCategoryMemory: mergedMemory,
    );
  }

  final List<String> categories;
  final List<MarketLayout> marketLayouts;
  final List<GroceryListModel> groceryLists;
  final List<RememberedItemCategory> itemCategoryMemory;

  AppData copyWith({
    List<String>? categories,
    List<MarketLayout>? marketLayouts,
    List<GroceryListModel>? groceryLists,
    List<RememberedItemCategory>? itemCategoryMemory,
  }) {
    return AppData(
      categories: categories ?? this.categories,
      marketLayouts: marketLayouts ?? this.marketLayouts,
      groceryLists: groceryLists ?? this.groceryLists,
      itemCategoryMemory: itemCategoryMemory ?? this.itemCategoryMemory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories,
      'marketLayouts': marketLayouts.map((layout) => layout.toJson()).toList(),
      'groceryLists': groceryLists.map((list) => list.toJson()).toList(),
      'itemCategoryMemory':
          itemCategoryMemory.map((entry) => entry.toJson()).toList(),
    };
  }
}

class MarketLayout {
  const MarketLayout({
    required this.id,
    required this.name,
    required this.categoryOrder,
  });

  factory MarketLayout.fromJson(Map<String, dynamic> json) {
    return MarketLayout(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      categoryOrder: _toStringList(json['categoryOrder']),
    );
  }

  final String id;
  final String name;
  final List<String> categoryOrder;

  MarketLayout copyWith({
    String? id,
    String? name,
    List<String>? categoryOrder,
  }) {
    return MarketLayout(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryOrder: categoryOrder ?? this.categoryOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'categoryOrder': categoryOrder};
  }
}

class GroceryListModel {
  const GroceryListModel({
    required this.id,
    required this.name,
    required this.items,
  });

  factory GroceryListModel.fromJson(Map<String, dynamic> json) {
    return GroceryListModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      items: _toDynamicList(json['items']).map(GroceryItem.fromJson).toList(),
    );
  }

  final String id;
  final String name;
  final List<GroceryItem> items;

  GroceryListModel copyWith({
    String? id,
    String? name,
    List<GroceryItem>? items,
  }) {
    return GroceryListModel(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'items': items.map((item) => item.toJson()).toList()};
  }
}

class GroceryItem {
  const GroceryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      quantity: _toPositiveInt(json['quantity']),
    );
  }

  final String id;
  final String name;
  final String category;
  final int quantity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
    };
  }
}

class RememberedItemCategory {
  const RememberedItemCategory({
    required this.itemName,
    required this.category,
  });

  factory RememberedItemCategory.fromJson(Map<String, dynamic> json) {
    return RememberedItemCategory(
      itemName: (json['itemName'] ?? '').toString().trim(),
      category: (json['category'] ?? '').toString().trim(),
    );
  }

  final String itemName;
  final String category;

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'category': category,
    };
  }
}

class ItemHint {
  const ItemHint({required this.itemName, required this.category});

  final String itemName;
  final String category;
}

class ShoppingSection {
  const ShoppingSection({
    required this.category,
    required this.items,
    required this.inLayoutOrder,
  });

  final String category;
  final List<GroceryItem> items;
  final bool inLayoutOrder;
}

List<String> _toStringList(dynamic source) {
  if (source is! List) {
    return const [];
  }

  return source
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

List<Map<String, dynamic>> _toDynamicList(dynamic source) {
  if (source is! List) {
    return const [];
  }

  return source
      .whereType<Map>()
      .map((map) => Map<String, dynamic>.from(map))
      .toList();
}

int _toPositiveInt(dynamic source, {int fallback = 1}) {
  final parsed = switch (source) {
    int value => value,
    String value => int.tryParse(value) ?? fallback,
    _ => fallback,
  };

  return parsed < 1 ? fallback : parsed;
}

List<String> _uniqueCaseInsensitive(List<String> source) {
  final seen = <String>{};
  final result = <String>[];

  for (final item in source) {
    final key = item.toLowerCase();
    if (seen.add(key)) {
      result.add(item);
    }
  }

  return result;
}

List<RememberedItemCategory> _rememberedItemsFromLists(
  List<GroceryListModel> lists,
) {
  final byItem = <String, RememberedItemCategory>{};

  for (final list in lists) {
    for (final item in list.items) {
      final name = item.name.trim();
      final category = item.category.trim();
      if (name.isEmpty || category.isEmpty) {
        continue;
      }
      byItem[name.toLowerCase()] =
          RememberedItemCategory(itemName: name, category: category);
    }
  }

  return byItem.values.toList();
}

List<RememberedItemCategory> _mergeRememberedItems({
  required List<RememberedItemCategory> baseline,
  required List<RememberedItemCategory> overrides,
}) {
  final byItem = <String, RememberedItemCategory>{};

  for (final entry in baseline) {
    final key = entry.itemName.trim().toLowerCase();
    if (key.isEmpty || entry.category.trim().isEmpty) {
      continue;
    }
    byItem[key] = entry;
  }

  for (final entry in overrides) {
    final key = entry.itemName.trim().toLowerCase();
    if (key.isEmpty || entry.category.trim().isEmpty) {
      continue;
    }
    byItem[key] = entry;
  }

  return byItem.values.toList();
}
