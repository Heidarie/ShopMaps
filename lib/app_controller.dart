import 'package:flutter/foundation.dart';

import 'local_store.dart';
import 'models.dart';

class CompletedShoppingItemRemoval {
  const CompletedShoppingItemRemoval({
    required this.listId,
    required this.listName,
    required this.listIndex,
    required this.item,
    required this.itemIndex,
  });

  final String listId;
  final String listName;
  final int listIndex;
  final GroceryItem item;
  final int itemIndex;
}

class CategoryListUsage {
  const CategoryListUsage({
    required this.listId,
    required this.listName,
    required this.itemCount,
  });

  final String listId;
  final String listName;
  final int itemCount;
}

class CategoryLayoutUsage {
  const CategoryLayoutUsage({
    required this.layoutId,
    required this.layoutName,
  });

  final String layoutId;
  final String layoutName;
}

class CategoryUsageSummary {
  const CategoryUsageSummary({
    required this.category,
    required this.groceryLists,
    required this.marketLayouts,
  });

  final String category;
  final List<CategoryListUsage> groceryLists;
  final List<CategoryLayoutUsage> marketLayouts;

  bool get hasUsages => groceryLists.isNotEmpty || marketLayouts.isNotEmpty;
}

class AppController extends ChangeNotifier {
  AppController(this._store);

  static const Duration _frequentItemRetention = Duration(days: 14);
  static const int _maxFavoriteFrequentItems = 10;
  static const int _minimumFrequentItemOccurrences = 3;
  static const int _maxFrequentItemsToSuggest = 10;

  final LocalStore _store;

  AppData _data = AppData.empty();
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  List<String> get categories => _data.categories;
  List<MarketLayout> get marketLayouts => _data.marketLayouts;
  List<GroceryListModel> get groceryLists => _data.groceryLists;
  bool get hasReachedCategoryLimit => _data.categories.length >= maxCategoryCount;
  int get maxFavoriteFrequentItems => _maxFavoriteFrequentItems;
  int get favoriteFrequentItemCount => _pruneExpiredFrequentItemStats(
        _data.frequentItemStats,
      ).where((entry) => entry.isFavorite).length;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _data = await _store.load();
    final prunedFrequentItems = _pruneExpiredFrequentItemStats(
      _data.frequentItemStats,
    );
    if (prunedFrequentItems.length != _data.frequentItemStats.length) {
      _data = _data.copyWith(frequentItemStats: prunedFrequentItems);
      await _persist();
    }

    _isLoading = false;
    notifyListeners();
  }

  MarketLayout? getMarketLayoutById(String id) {
    for (final market in _data.marketLayouts) {
      if (market.id == id) {
        return market;
      }
    }
    return null;
  }

  GroceryListModel? getGroceryListById(String id) {
    for (final list in _data.groceryLists) {
      if (list.id == id) {
        return list;
      }
    }
    return null;
  }

  List<FrequentItemStat> getTopFrequentItems() {
    final favorites = <FrequentItemStat>[];
    final suggestions = <FrequentItemStat>[];

    for (final entry in _pruneExpiredFrequentItemStats(_data.frequentItemStats)) {
      final canonicalCategory = _resolveCategory(entry.category);
      if (canonicalCategory == null) {
        continue;
      }

      final normalizedEntry = FrequentItemStat(
        itemName: entry.itemName,
        category: canonicalCategory,
        occurrenceCount: entry.occurrenceCount,
        lastAddedAt: entry.lastAddedAt,
        isFavorite: entry.isFavorite,
      );

      if (entry.isFavorite) {
        favorites.add(normalizedEntry);
        continue;
      }

      if (entry.occurrenceCount >= _minimumFrequentItemOccurrences) {
        suggestions.add(normalizedEntry);
      }
    }

    void sortEntries(List<FrequentItemStat> entries) {
      entries.sort((left, right) {
        final countComparison = right.occurrenceCount.compareTo(left.occurrenceCount);
        if (countComparison != 0) {
          return countComparison;
        }

        final lastAddedComparison = right.lastAddedAt.compareTo(left.lastAddedAt);
        if (lastAddedComparison != 0) {
          return lastAddedComparison;
        }

        return normalizeLatinText(left.itemName).compareTo(
          normalizeLatinText(right.itemName),
        );
      });
    }

    sortEntries(favorites);
    sortEntries(suggestions);

    return [...favorites, ...suggestions].take(_maxFrequentItemsToSuggest).toList();
  }

  List<FrequentItemStat> getFrequentItemsForConfiguration() {
    final entries = _pruneExpiredFrequentItemStats(_data.frequentItemStats)
        .map((entry) {
          final canonicalCategory = _resolveCategory(entry.category) ?? entry.category;
          return FrequentItemStat(
            itemName: entry.itemName,
            category: canonicalCategory,
            occurrenceCount: entry.occurrenceCount,
            lastAddedAt: entry.lastAddedAt,
            isFavorite: entry.isFavorite,
          );
        })
        .toList();

    entries.sort((left, right) {
      final favoriteComparison = (right.isFavorite ? 1 : 0).compareTo(
        left.isFavorite ? 1 : 0,
      );
      if (favoriteComparison != 0) {
        return favoriteComparison;
      }

      final countComparison = right.occurrenceCount.compareTo(left.occurrenceCount);
      if (countComparison != 0) {
        return countComparison;
      }

      final lastAddedComparison = right.lastAddedAt.compareTo(left.lastAddedAt);
      if (lastAddedComparison != 0) {
        return lastAddedComparison;
      }

      return normalizeLatinText(left.itemName).compareTo(
        normalizeLatinText(right.itemName),
      );
    });

    return entries;
  }

  Future<int> loadTopFrequentItemsIntoList(
    String listId, {
    List<FrequentItemStat>? suggestions,
  }) async {
    final resolvedSuggestions = suggestions ?? getTopFrequentItems();
    if (resolvedSuggestions.isEmpty) {
      return 0;
    }

    final nextLists = [..._data.groceryLists];
    final listIndex = nextLists.indexWhere((list) => list.id == listId);
    if (listIndex == -1) {
      return 0;
    }

    final targetList = nextLists[listIndex];
    final timestamp = DateTime.now().toUtc();
    final updatedItems = [...targetList.items];
    final existingItemKeys = updatedItems
        .map((item) => normalizeLatinText(item.name))
        .where((key) => key.isNotEmpty)
        .toSet();
    var addedCount = 0;
    var updatedMemory = _data.itemCategoryMemory;
    var updatedFrequentItems = _pruneExpiredFrequentItemStats(
      _data.frequentItemStats,
      referenceTime: timestamp,
    );

    for (final suggestion in resolvedSuggestions) {
      final suggestionKey = normalizeLatinText(suggestion.itemName);
      if (suggestionKey.isEmpty || existingItemKeys.contains(suggestionKey)) {
        continue;
      }

      updatedItems.add(
        GroceryItem(
          id: createId(),
          name: suggestion.itemName,
          category: suggestion.category,
          quantity: 1,
        ),
      );
      addedCount += 1;
      existingItemKeys.add(suggestionKey);
      updatedMemory = _upsertItemCategoryMemory(
        source: updatedMemory,
        itemName: suggestion.itemName,
        category: suggestion.category,
      );
      updatedFrequentItems = _recordFrequentItemAddition(
        source: updatedFrequentItems,
        itemName: suggestion.itemName,
        category: suggestion.category,
        addedAt: timestamp,
      );
    }

    if (updatedItems.length == targetList.items.length) {
      return 0;
    }

    nextLists[listIndex] = targetList.copyWith(items: updatedItems);
    _data = _data.copyWith(
      groceryLists: nextLists,
      itemCategoryMemory: updatedMemory,
      frequentItemStats: updatedFrequentItems,
    );
    notifyListeners();
    await _persist();

    return addedCount;
  }

  String? findCategoryConflict(String candidate, {String? excludingCategory}) {
    return _findCategoryInList(
      _data.categories,
      candidate,
      excludingCategory: excludingCategory,
    );
  }

  Future<String?> addCategory(String rawName) async {
    final cleaned = rawName.trim();
    if (cleaned.isEmpty) {
      return null;
    }

    final existing = findCategoryConflict(cleaned);
    if (existing != null) {
      return null;
    }

    if (_data.categories.length >= maxCategoryCount) {
      return null;
    }

    final updated = [..._data.categories, cleaned];
    _data = _data.copyWith(categories: updated);
    notifyListeners();
    await _persist();

    return cleaned;
  }

  Future<bool> setFrequentItemFavorite({
    required String itemName,
    required bool isFavorite,
  }) async {
    final next = _pruneExpiredFrequentItemStats(_data.frequentItemStats);
    final index = next.indexWhere(
      (entry) => sameNormalizedText(entry.itemName, itemName),
    );
    if (index == -1) {
      return false;
    }

    if (isFavorite &&
        !next[index].isFavorite &&
        next.where((entry) => entry.isFavorite).length >= _maxFavoriteFrequentItems) {
      return false;
    }

    next[index] = FrequentItemStat(
      itemName: next[index].itemName,
      category: next[index].category,
      occurrenceCount: next[index].occurrenceCount,
      lastAddedAt: next[index].lastAddedAt,
      isFavorite: isFavorite,
    );

    _data = _data.copyWith(frequentItemStats: next);
    notifyListeners();
    await _persist();

    return true;
  }

  Future<bool> deleteFrequentItem(String itemName) async {
    final activeEntries = _pruneExpiredFrequentItemStats(_data.frequentItemStats);
    final hadMatch = activeEntries.any(
      (entry) => sameNormalizedText(entry.itemName, itemName),
    );
    if (!hadMatch) {
      return false;
    }

    final next = activeEntries
        .where((entry) => !sameNormalizedText(entry.itemName, itemName))
        .toList();
    _data = _data.copyWith(frequentItemStats: next);
    notifyListeners();
    await _persist();

    return true;
  }

  bool isCategoryUsed(String category) {
    return getCategoryUsage(category)?.hasUsages ?? false;
  }

  CategoryUsageSummary? getCategoryUsage(String category) {
    final canonicalCategory = _resolveCategory(category) ?? category.trim();
    if (canonicalCategory.isEmpty) {
      return null;
    }

    final groceryLists = <CategoryListUsage>[];
    for (final list in _data.groceryLists) {
      final itemCount = list.items.where(
        (item) => sameNormalizedText(item.category, canonicalCategory),
      ).length;
      if (itemCount > 0) {
        groceryLists.add(
          CategoryListUsage(
            listId: list.id,
            listName: list.name,
            itemCount: itemCount,
          ),
        );
      }
    }

    final marketLayouts = <CategoryLayoutUsage>[];
    for (final layout in _data.marketLayouts) {
      if (layout.categoryOrder.any(
        (entry) => sameNormalizedText(entry, canonicalCategory),
      )) {
        marketLayouts.add(
          CategoryLayoutUsage(
            layoutId: layout.id,
            layoutName: layout.name,
          ),
        );
      }
    }

    return CategoryUsageSummary(
      category: canonicalCategory,
      groceryLists: groceryLists,
      marketLayouts: marketLayouts,
    );
  }

  Future<String?> renameCategory({
    required String currentName,
    required String newName,
  }) async {
    final currentCanonical = _resolveCategory(currentName);
    final cleanedName = newName.trim();
    if (currentCanonical == null || cleanedName.isEmpty) {
      return null;
    }

    final existingConflict = findCategoryConflict(
      cleanedName,
      excludingCategory: currentCanonical,
    );
    if (existingConflict != null) {
      return null;
    }

    final targetCategory = cleanedName;
    final updatedCategories = <String>[];
    final seenCategoryKeys = <String>{};

    for (final category in _data.categories) {
      final nextCategory = sameNormalizedText(category, currentCanonical)
          ? targetCategory
          : category;
      final key = normalizeLatinText(nextCategory);
      if (key.isNotEmpty && seenCategoryKeys.add(key)) {
        updatedCategories.add(nextCategory);
      }
    }

    if (_findCategoryInList(updatedCategories, targetCategory) == null) {
      updatedCategories.add(targetCategory);
    }

    final updatedLayouts = _data.marketLayouts.map((layout) {
      final updatedOrder = _canonicalCategoryList(
        layout.categoryOrder
            .map(
              (category) => sameNormalizedText(category, currentCanonical)
                  ? targetCategory
                  : category,
            )
            .toList(),
      );
      return layout.copyWith(categoryOrder: updatedOrder);
    }).toList();

    final updatedLists = _data.groceryLists.map((list) {
      final updatedItems = list.items.map((item) {
        if (!sameNormalizedText(item.category, currentCanonical)) {
          return item;
        }
        return GroceryItem(
          id: item.id,
          name: item.name,
          category: targetCategory,
          quantity: item.quantity,
        );
      }).toList();
      return list.copyWith(items: updatedItems);
    }).toList();

    var updatedMemory = <RememberedItemCategory>[];
    for (final entry in _data.itemCategoryMemory) {
      updatedMemory = _upsertItemCategoryMemory(
        source: updatedMemory,
        itemName: entry.itemName,
        category: sameNormalizedText(entry.category, currentCanonical)
            ? targetCategory
            : entry.category,
      );
    }
    final updatedFrequentItems = _data.frequentItemStats.map((entry) {
      if (!sameNormalizedText(entry.category, currentCanonical)) {
        return entry;
      }

      return FrequentItemStat(
        itemName: entry.itemName,
        category: targetCategory,
        occurrenceCount: entry.occurrenceCount,
        lastAddedAt: entry.lastAddedAt,
        isFavorite: entry.isFavorite,
      );
    }).toList();

    _data = _data.copyWith(
      categories: updatedCategories,
      marketLayouts: updatedLayouts,
      groceryLists: updatedLists,
      itemCategoryMemory: updatedMemory,
      frequentItemStats: updatedFrequentItems,
    );
    notifyListeners();
    await _persist();

    return targetCategory;
  }

  Future<bool> deleteCategory(String category) async {
    final canonicalCategory = _resolveCategory(category);
    if (canonicalCategory == null || isCategoryUsed(canonicalCategory)) {
      return false;
    }

    final updatedCategories = _data.categories
        .where((entry) => !sameNormalizedText(entry, canonicalCategory))
        .toList();
    final updatedMemory = _data.itemCategoryMemory
        .where((entry) => !sameNormalizedText(entry.category, canonicalCategory))
        .toList();
    final updatedFrequentItems = _data.frequentItemStats
        .where((entry) => !sameNormalizedText(entry.category, canonicalCategory))
        .toList();

    _data = _data.copyWith(
      categories: updatedCategories,
      itemCategoryMemory: updatedMemory,
      frequentItemStats: updatedFrequentItems,
    );
    notifyListeners();
    await _persist();

    return true;
  }

  Future<bool> deleteCategoryAndUsages(String category) async {
    final usage = getCategoryUsage(category);
    if (usage == null) {
      return false;
    }

    final canonicalCategory = usage.category;
    final updatedCategories = _data.categories
        .where((entry) => !sameNormalizedText(entry, canonicalCategory))
        .toList();
    final updatedLayouts = _data.marketLayouts.map((layout) {
      final updatedOrder = layout.categoryOrder
          .where((entry) => !sameNormalizedText(entry, canonicalCategory))
          .toList();
      return layout.copyWith(categoryOrder: updatedOrder);
    }).toList();
    final updatedLists = _data.groceryLists.map((list) {
      final updatedItems = list.items
          .where((item) => !sameNormalizedText(item.category, canonicalCategory))
          .toList();
      return list.copyWith(items: updatedItems);
    }).toList();
    final updatedMemory = _data.itemCategoryMemory
        .where((entry) => !sameNormalizedText(entry.category, canonicalCategory))
        .toList();
    final updatedFrequentItems = _data.frequentItemStats
        .where((entry) => !sameNormalizedText(entry.category, canonicalCategory))
        .toList();

    _data = _data.copyWith(
      categories: updatedCategories,
      marketLayouts: updatedLayouts,
      groceryLists: updatedLists,
      itemCategoryMemory: updatedMemory,
      frequentItemStats: updatedFrequentItems,
    );
    notifyListeners();
    await _persist();

    return true;
  }

  Future<void> upsertMarketLayout(MarketLayout layout) async {
    final cleanedName = layout.name.trim();
    if (cleanedName.isEmpty) {
      return;
    }

    final canonicalOrder = _canonicalCategoryList(layout.categoryOrder);
    final normalized = layout.copyWith(
      id: layout.id.isEmpty ? createId() : layout.id,
      name: cleanedName,
      categoryOrder: canonicalOrder,
    );

    final next = [..._data.marketLayouts];
    final index = next.indexWhere((existing) => existing.id == normalized.id);
    if (index == -1) {
      next.add(normalized);
    } else {
      next[index] = normalized;
    }

    final mergedCategories = [..._data.categories];
    for (final category in canonicalOrder) {
      if (_findCategoryInList(mergedCategories, category) == null) {
        mergedCategories.add(category);
      }
    }

    _data = _data.copyWith(
      categories: mergedCategories,
      marketLayouts: next,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> deleteMarketLayout(String marketLayoutId) async {
    final next = _data.marketLayouts.where((layout) => layout.id != marketLayoutId).toList();
    _data = _data.copyWith(marketLayouts: next);
    notifyListeners();
    await _persist();
  }

  Future<String?> createGroceryList(String rawName) async {
    final cleaned = rawName.trim();
    if (cleaned.isEmpty) {
      return null;
    }

    final list = GroceryListModel(id: createId(), name: cleaned, items: const []);
    final next = [..._data.groceryLists, list];
    _data = _data.copyWith(groceryLists: next);
    notifyListeners();
    await _persist();

    return list.id;
  }

  Future<void> renameGroceryList({
    required String listId,
    required String newName,
  }) async {
    final cleaned = newName.trim();
    if (cleaned.isEmpty) {
      return;
    }

    final next = [..._data.groceryLists];
    final index = next.indexWhere((list) => list.id == listId);
    if (index == -1) {
      return;
    }

    next[index] = next[index].copyWith(name: cleaned);
    _data = _data.copyWith(groceryLists: next);
    notifyListeners();
    await _persist();
  }

  Future<void> deleteGroceryList(String listId) async {
    final next = _data.groceryLists.where((list) => list.id != listId).toList();
    _data = _data.copyWith(groceryLists: next);
    notifyListeners();
    await _persist();
  }

  Future<bool> addItemToList({
    required String listId,
    required String itemName,
    required String category,
    required int quantity,
  }) async {
    final cleanedName = itemName.trim();
    if (cleanedName.isEmpty) {
      return false;
    }

    final canonicalCategory = _resolveCategory(category) ?? category.trim();
    if (canonicalCategory.isEmpty) {
      return false;
    }
    final normalizedQuantity = quantity < 1 ? 1 : quantity;

    if (_resolveCategory(canonicalCategory) == null) {
      final addedCategory = await addCategory(canonicalCategory);
      if (addedCategory == null) {
        return false;
      }
    }

    final next = [..._data.groceryLists];
    final index = next.indexWhere((list) => list.id == listId);
    if (index == -1) {
      return false;
    }

    final list = next[index];
    final updatedItems = [
      ...list.items,
      GroceryItem(
        id: createId(),
        name: cleanedName,
        category: canonicalCategory,
        quantity: normalizedQuantity,
      ),
    ];
    final updatedMemory = _upsertItemCategoryMemory(
      source: _data.itemCategoryMemory,
      itemName: cleanedName,
      category: canonicalCategory,
    );
    final updatedFrequentItems = _recordFrequentItemAddition(
      source: _data.frequentItemStats,
      itemName: cleanedName,
      category: canonicalCategory,
    );

    next[index] = list.copyWith(items: updatedItems);
    _data = _data.copyWith(
      groceryLists: next,
      itemCategoryMemory: updatedMemory,
      frequentItemStats: updatedFrequentItems,
    );
    notifyListeners();
    await _persist();
    return true;
  }

  Future<bool> updateItemInList({
    required String listId,
    required String itemId,
    required String itemName,
    required String category,
    required int quantity,
  }) async {
    final cleanedName = itemName.trim();
    if (cleanedName.isEmpty) {
      return false;
    }

    final canonicalCategory = _resolveCategory(category) ?? category.trim();
    if (canonicalCategory.isEmpty) {
      return false;
    }
    final normalizedQuantity = quantity < 1 ? 1 : quantity;

    if (_resolveCategory(canonicalCategory) == null) {
      final addedCategory = await addCategory(canonicalCategory);
      if (addedCategory == null) {
        return false;
      }
    }

    final next = [..._data.groceryLists];
    final listIndex = next.indexWhere((list) => list.id == listId);
    if (listIndex == -1) {
      return false;
    }

    final list = next[listIndex];
    final itemIndex = list.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) {
      return false;
    }

    final updatedItems = [...list.items];
    updatedItems[itemIndex] = GroceryItem(
      id: list.items[itemIndex].id,
      name: cleanedName,
      category: canonicalCategory,
      quantity: normalizedQuantity,
    );
    final updatedMemory = _upsertItemCategoryMemory(
      source: _data.itemCategoryMemory,
      itemName: cleanedName,
      category: canonicalCategory,
    );

    next[listIndex] = list.copyWith(items: updatedItems);
    _data = _data.copyWith(
      groceryLists: next,
      itemCategoryMemory: updatedMemory,
    );
    notifyListeners();
    await _persist();
    return true;
  }

  Future<void> removeItemFromList({
    required String listId,
    required String itemId,
  }) async {
    final next = [..._data.groceryLists];
    final index = next.indexWhere((list) => list.id == listId);
    if (index == -1) {
      return;
    }

    final list = next[index];
    final updatedItems = list.items.where((item) => item.id != itemId).toList();
    next[index] = list.copyWith(items: updatedItems);

    _data = _data.copyWith(groceryLists: next);
    notifyListeners();
    await _persist();
  }

  Future<CompletedShoppingItemRemoval?> completeShoppingItem({
    required String listId,
    required String itemId,
  }) async {
    final next = [..._data.groceryLists];
    final listIndex = next.indexWhere((list) => list.id == listId);
    if (listIndex == -1) {
      return null;
    }

    final list = next[listIndex];
    final itemIndex = list.items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) {
      return null;
    }
    final removedItem = list.items[itemIndex];
    final updatedItems = [...list.items]..removeAt(itemIndex);

    // Keep the grocery list even when it becomes empty.
    next[listIndex] = list.copyWith(items: updatedItems);

    _data = _data.copyWith(groceryLists: next);
    notifyListeners();
    await _persist();

    return CompletedShoppingItemRemoval(
      listId: list.id,
      listName: list.name,
      listIndex: listIndex,
      item: removedItem,
      itemIndex: itemIndex,
    );
  }

  Future<bool> undoCompletedShoppingItem(CompletedShoppingItemRemoval removal) async {
    final nextLists = [..._data.groceryLists];
    final listIndex = nextLists.indexWhere((list) => list.id == removal.listId);

    if (listIndex == -1) {
      final restoredList = GroceryListModel(
        id: removal.listId,
        name: removal.listName,
        items: [removal.item],
      );
      final insertAt = removal.listIndex.clamp(0, nextLists.length).toInt();
      nextLists.insert(insertAt, restoredList);
    } else {
      final list = nextLists[listIndex];
      if (list.items.any((item) => item.id == removal.item.id)) {
        return false;
      }
      final restoredItems = [...list.items];
      final insertAt = removal.itemIndex.clamp(0, restoredItems.length).toInt();
      restoredItems.insert(insertAt, removal.item);
      nextLists[listIndex] = list.copyWith(items: restoredItems);
    }

    final nextCategories = [..._data.categories];
    if (_findCategoryInList(nextCategories, removal.item.category) == null) {
      nextCategories.add(removal.item.category);
    }
    final nextMemory = _upsertItemCategoryMemory(
      source: _data.itemCategoryMemory,
      itemName: removal.item.name,
      category: removal.item.category,
    );

    _data = _data.copyWith(
      categories: nextCategories,
      groceryLists: nextLists,
      itemCategoryMemory: nextMemory,
    );
    notifyListeners();
    await _persist();

    return true;
  }

  List<ItemHint> findItemHints(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final byName = <String, ItemHint>{};

    for (final remembered in _data.itemCategoryMemory) {
      final normalizedName = remembered.itemName.trim().toLowerCase();
      if (normalizedName.isEmpty) {
        continue;
      }
      if (normalizedName.startsWith(normalizedQuery)) {
        byName[normalizedName] = ItemHint(
          itemName: remembered.itemName,
          category: _resolveCategory(remembered.category) ?? remembered.category,
        );
      }
    }

    for (final list in _data.groceryLists) {
      for (final item in list.items) {
        final normalizedName = item.name.trim().toLowerCase();
        if (normalizedName.isEmpty) {
          continue;
        }
        if (normalizedName.startsWith(normalizedQuery) &&
            !byName.containsKey(normalizedName)) {
          byName[normalizedName] = ItemHint(
            itemName: item.name,
            category: _resolveCategory(item.category) ?? item.category,
          );
        }
      }
    }

    final hints = byName.values.toList();
    hints.sort((a, b) => a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()));

    return hints.take(5).toList();
  }

  String? findCategoryForExactItem(String itemName) {
    final normalized = itemName.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    for (final remembered in _data.itemCategoryMemory) {
      if (remembered.itemName.trim().toLowerCase() == normalized) {
        return _resolveCategory(remembered.category) ?? remembered.category;
      }
    }

    for (final list in _data.groceryLists) {
      for (final item in list.items.reversed) {
        if (item.name.trim().toLowerCase() == normalized) {
          return _resolveCategory(item.category) ?? item.category;
        }
      }
    }

    return null;
  }

  List<ShoppingSection> buildShoppingSections({
    required String listId,
    required String marketLayoutId,
  }) {
    final groceryList = getGroceryListById(listId);
    final marketLayout = getMarketLayoutById(marketLayoutId);

    if (groceryList == null || marketLayout == null) {
      return const [];
    }

    final grouped = <String, List<GroceryItem>>{};
    final categoryByKey = <String, String>{};

    for (final item in groceryList.items) {
      final category = _resolveCategory(item.category) ?? item.category;
      final key = normalizeLatinText(category);
      categoryByKey.putIfAbsent(key, () => category);
      grouped.putIfAbsent(key, () => []).add(item);
    }

    for (final items in grouped.values) {
      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    final result = <ShoppingSection>[];
    final used = <String>{};

    for (final category in _canonicalCategoryList(marketLayout.categoryOrder)) {
      final key = normalizeLatinText(category);
      final items = grouped[key];
      if (items == null || items.isEmpty) {
        continue;
      }

      result.add(ShoppingSection(
        category: categoryByKey[key] ?? category,
        items: items,
        inLayoutOrder: true,
      ));
      used.add(key);
    }

    final remaining = grouped.keys.where((key) => !used.contains(key)).toList()
      ..sort((a, b) => (categoryByKey[a] ?? a)
          .toLowerCase()
          .compareTo((categoryByKey[b] ?? b).toLowerCase()));

    for (final key in remaining) {
      final items = grouped[key] ?? const <GroceryItem>[];
      if (items.isEmpty) {
        continue;
      }

      result.add(ShoppingSection(
        category: categoryByKey[key] ?? key,
        items: items,
        inLayoutOrder: false,
      ));
    }

    return result;
  }

  List<String> _canonicalCategoryList(List<String> source) {
    final seen = <String>{};
    final result = <String>[];

    for (final raw in source) {
      final canonical = _resolveCategory(raw) ?? raw.trim();
      if (canonical.isEmpty) {
        continue;
      }

      final key = normalizeLatinText(canonical);
      if (seen.add(key)) {
        result.add(canonical);
      }
    }

    return result;
  }

  String? _resolveCategory(String candidate) {
    return _findCategoryInList(_data.categories, candidate);
  }

  List<RememberedItemCategory> _upsertItemCategoryMemory({
    required List<RememberedItemCategory> source,
    required String itemName,
    required String category,
  }) {
    final cleanedName = itemName.trim();
    final canonicalCategory = _resolveCategory(category) ?? category.trim();
    if (cleanedName.isEmpty || canonicalCategory.isEmpty) {
      return source;
    }

    final next = [...source];
    final index = next.indexWhere(
      (entry) => entry.itemName.trim().toLowerCase() == cleanedName.toLowerCase(),
    );
    final updatedEntry = RememberedItemCategory(
      itemName: cleanedName,
      category: canonicalCategory,
    );

    if (index == -1) {
      next.add(updatedEntry);
    } else {
      next[index] = updatedEntry;
    }

    return next;
  }

  List<FrequentItemStat> _recordFrequentItemAddition({
    required List<FrequentItemStat> source,
    required String itemName,
    required String category,
    DateTime? addedAt,
  }) {
    final cleanedName = itemName.trim();
    final canonicalCategory = _resolveCategory(category) ?? category.trim();
    final timestamp = (addedAt ?? DateTime.now()).toUtc();
    if (cleanedName.isEmpty || canonicalCategory.isEmpty) {
      return source;
    }

    final next = _pruneExpiredFrequentItemStats(
      source,
      referenceTime: timestamp,
    );
    final index = next.indexWhere(
      (entry) => sameNormalizedText(entry.itemName, cleanedName),
    );
    final currentCount = index == -1 ? 0 : next[index].occurrenceCount;
    final updatedEntry = FrequentItemStat(
      itemName: cleanedName,
      category: canonicalCategory,
      occurrenceCount: currentCount + 1,
      lastAddedAt: timestamp,
      isFavorite: index == -1 ? false : next[index].isFavorite,
    );

    if (index == -1) {
      next.add(updatedEntry);
    } else {
      next[index] = updatedEntry;
    }

    return next;
  }

  List<FrequentItemStat> _pruneExpiredFrequentItemStats(
    List<FrequentItemStat> source, {
    DateTime? referenceTime,
  }) {
    final cutoff = (referenceTime ?? DateTime.now().toUtc()).subtract(
      _frequentItemRetention,
    );

    return source
        .where(
          (entry) =>
              entry.isFavorite || !entry.lastAddedAt.toUtc().isBefore(cutoff),
        )
        .toList();
  }

  String? _findCategoryInList(
    List<String> list,
    String candidate, {
    String? excludingCategory,
  }) {
    final normalized = normalizeLatinText(candidate);
    final excludedNormalized = excludingCategory == null
        ? null
        : normalizeLatinText(excludingCategory);
    if (normalized.isEmpty) {
      return null;
    }

    for (final existing in list) {
      final existingNormalized = normalizeLatinText(existing);
      if (excludedNormalized != null && existingNormalized == excludedNormalized) {
        continue;
      }
      if (existingNormalized == normalized) {
        return existing;
      }
    }

    return null;
  }

  Future<void> _persist() async {
    await _store.save(_data);
  }
}
