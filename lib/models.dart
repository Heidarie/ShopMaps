import 'dart:math';

const int maxCategoryCount = 1000;

const Map<String, String> _latinCharacterFoldMap = {
  'a': 'a',
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'ą': 'a',
  'æ': 'ae',
  'c': 'c',
  'ç': 'c',
  'ć': 'c',
  'č': 'c',
  'd': 'd',
  'ď': 'd',
  'e': 'e',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ę': 'e',
  'ě': 'e',
  'g': 'g',
  'ğ': 'g',
  'i': 'i',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ł': 'l',
  'ľ': 'l',
  'ĺ': 'l',
  'n': 'n',
  'ñ': 'n',
  'ń': 'n',
  'ň': 'n',
  'o': 'o',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ø': 'o',
  'œ': 'oe',
  'r': 'r',
  'ŕ': 'r',
  'ř': 'r',
  's': 's',
  'ś': 's',
  'š': 's',
  'ß': 'ss',
  't': 't',
  'ť': 't',
  'u': 'u',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ů': 'u',
  'y': 'y',
  'ý': 'y',
  'ÿ': 'y',
  'z': 'z',
  'ź': 'z',
  'ż': 'z',
  'ž': 'z',
};

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

const Map<String, List<String>> defaultCategoryAliases = {
  'Drinks': [
    'Drinks',
    'Napoje',
    'Getränke',
    'Dranken',
    'Bebidas',
    'Boissons',
    'Напої',
    'Bevande',
  ],
  'Sweets': [
    'Sweets',
    'Słodycze',
    'Süßigkeiten',
    'Snoep',
    'Dulces',
    'Confiseries',
    'Солодощі',
    'Dolci',
    'Doces',
  ],
  'Fruits': [
    'Fruits',
    'Owoce',
    'Obst',
    'Fruit',
    'Frutas',
    'Фрукти',
    'Frutta',
  ],
  'Vegetables': [
    'Vegetables',
    'Warzywa',
    'Gemüse',
    'Groenten',
    'Verduras',
    'Légumes',
    'Овочі',
    'Verdure',
    'Vegetais',
  ],
  'Alcohol': [
    'Alcohol',
    'Alkohol',
    'Alcohol',
    'Alcool',
    'Алкоголь',
    'Alcolici',
    'Álcool',
  ],
  'Dairy': [
    'Dairy',
    'Nabiał',
    'Nabial',
    'Molkereiprodukte',
    'Zuivel',
    'Lácteos',
    'Produits laitiers',
    'Молочні продукти',
    'Latticini',
    'Laticínios',
  ],
  'Bakery': [
    'Bakery',
    'Piekarnia',
    'Bäckerei',
    'Bakkerij',
    'Panadería',
    'Boulangerie',
    'Випічка',
    'Panetteria',
    'Padaria',
  ],
  'Meat': [
    'Meat',
    'Mięso',
    'Mieso',
    'Fleisch',
    'Vlees',
    'Carne',
    'Viande',
    'М\'ясо',
  ],
  'Frozen': [
    'Frozen',
    'Mrożonki',
    'Mrozonki',
    'Tiefkühlkost',
    'Diepvries',
    'Congelados',
    'Surgelés',
    'Заморожені продукти',
    'Surgelati',
  ],
  'Household': [
    'Household',
    'Chemia domowa',
    'Haushalt',
    'Huishouden',
    'Hogar',
    'Maison',
    'Побутова хімія',
    'Casa',
  ],
};

String normalizeLatinText(String value) {
  final buffer = StringBuffer();

  for (final rune in value.trim().toLowerCase().runes) {
    final character = String.fromCharCode(rune);
    buffer.write(_latinCharacterFoldMap[character] ?? character);
  }

  return buffer.toString();
}

bool sameNormalizedText(String left, String right) {
  return normalizeLatinText(left) == normalizeLatinText(right);
}

String? canonicalDefaultCategory(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  for (final entry in defaultCategoryAliases.entries) {
    for (final alias in entry.value) {
      if (sameNormalizedText(trimmed, alias)) {
        return entry.key;
      }
    }
  }

  return null;
}

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
    required this.frequentItemStats,
  });

  factory AppData.empty() {
    return AppData(
      categories: [...defaultCategories],
      marketLayouts: const [],
      groceryLists: const [],
      itemCategoryMemory: const [],
      frequentItemStats: const [],
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
    final frequentItemStats = _toDynamicList(json['frequentItemStats'])
        .map(FrequentItemStat.fromJson)
        .where((entry) => entry.itemName.isNotEmpty && entry.category.isNotEmpty)
        .toList();

    return AppData(
      categories: loadedCategories.isEmpty
          ? [...defaultCategories]
          : loadedCategories,
      marketLayouts: marketLayouts,
      groceryLists: groceryLists,
      itemCategoryMemory: mergedMemory,
      frequentItemStats: _mergeFrequentItemStats(frequentItemStats),
    );
  }

  final List<String> categories;
  final List<MarketLayout> marketLayouts;
  final List<GroceryListModel> groceryLists;
  final List<RememberedItemCategory> itemCategoryMemory;
  final List<FrequentItemStat> frequentItemStats;

  AppData copyWith({
    List<String>? categories,
    List<MarketLayout>? marketLayouts,
    List<GroceryListModel>? groceryLists,
    List<RememberedItemCategory>? itemCategoryMemory,
    List<FrequentItemStat>? frequentItemStats,
  }) {
    return AppData(
      categories: categories ?? this.categories,
      marketLayouts: marketLayouts ?? this.marketLayouts,
      groceryLists: groceryLists ?? this.groceryLists,
      itemCategoryMemory: itemCategoryMemory ?? this.itemCategoryMemory,
      frequentItemStats: frequentItemStats ?? this.frequentItemStats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories,
      'marketLayouts': marketLayouts.map((layout) => layout.toJson()).toList(),
      'groceryLists': groceryLists.map((list) => list.toJson()).toList(),
      'itemCategoryMemory':
          itemCategoryMemory.map((entry) => entry.toJson()).toList(),
      'frequentItemStats':
          frequentItemStats.map((entry) => entry.toJson()).toList(),
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

class FrequentItemStat {
  const FrequentItemStat({
    required this.itemName,
    required this.category,
    required this.occurrenceCount,
    required this.lastAddedAt,
    required this.isFavorite,
  });

  factory FrequentItemStat.fromJson(Map<String, dynamic> json) {
    return FrequentItemStat(
      itemName: (json['itemName'] ?? '').toString().trim(),
      category: (json['category'] ?? '').toString().trim(),
      occurrenceCount: _toPositiveInt(json['occurrenceCount']),
      lastAddedAt: _toDateTime(json['lastAddedAt']),
      isFavorite: json['isFavorite'] == true,
    );
  }

  final String itemName;
  final String category;
  final int occurrenceCount;
  final DateTime lastAddedAt;
  final bool isFavorite;

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'category': category,
      'occurrenceCount': occurrenceCount,
      'lastAddedAt': lastAddedAt.toUtc().toIso8601String(),
      'isFavorite': isFavorite,
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

DateTime _toDateTime(dynamic source) {
  if (source is String) {
    final parsed = DateTime.tryParse(source);
    if (parsed != null) {
      return parsed;
    }
  }

  return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

List<String> _uniqueCaseInsensitive(List<String> source) {
  final seen = <String>{};
  final result = <String>[];

  for (final item in source) {
    final key = normalizeLatinText(item);
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

List<FrequentItemStat> _mergeFrequentItemStats(List<FrequentItemStat> source) {
  final byItem = <String, FrequentItemStat>{};

  for (final entry in source) {
    final key = normalizeLatinText(entry.itemName);
    if (key.isEmpty) {
      continue;
    }

    final existing = byItem[key];
    if (existing == null) {
      byItem[key] = entry;
      continue;
    }

    final existingIsNewer = !entry.lastAddedAt.isAfter(existing.lastAddedAt);
    byItem[key] = FrequentItemStat(
      itemName: existingIsNewer ? existing.itemName : entry.itemName,
      category: existingIsNewer ? existing.category : entry.category,
      occurrenceCount: existing.occurrenceCount + entry.occurrenceCount,
      lastAddedAt: existingIsNewer ? existing.lastAddedAt : entry.lastAddedAt,
      isFavorite: existing.isFavorite || entry.isFavorite,
    );
  }

  return byItem.values.toList();
}
