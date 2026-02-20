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

class AppController extends ChangeNotifier {
  AppController(this._store);

  final LocalStore _store;

  AppData _data = AppData.empty();
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  List<String> get categories => _data.categories;
  List<MarketLayout> get marketLayouts => _data.marketLayouts;
  List<GroceryListModel> get groceryLists => _data.groceryLists;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _data = await _store.load();

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

  Future<String?> addCategory(String rawName) async {
    final cleaned = rawName.trim();
    if (cleaned.isEmpty) {
      return null;
    }

    final existing = _resolveCategory(cleaned);
    if (existing != null) {
      return existing;
    }

    final updated = [..._data.categories, cleaned];
    _data = _data.copyWith(categories: updated);
    notifyListeners();
    await _persist();

    return cleaned;
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

  Future<void> addItemToList({
    required String listId,
    required String itemName,
    required String category,
  }) async {
    final cleanedName = itemName.trim();
    if (cleanedName.isEmpty) {
      return;
    }

    final canonicalCategory = _resolveCategory(category) ?? category.trim();
    if (canonicalCategory.isEmpty) {
      return;
    }

    if (_resolveCategory(canonicalCategory) == null) {
      await addCategory(canonicalCategory);
    }

    final next = [..._data.groceryLists];
    final index = next.indexWhere((list) => list.id == listId);
    if (index == -1) {
      return;
    }

    final list = next[index];
    final updatedItems = [
      ...list.items,
      GroceryItem(id: createId(), name: cleanedName, category: canonicalCategory),
    ];
    final updatedMemory = _upsertItemCategoryMemory(
      source: _data.itemCategoryMemory,
      itemName: cleanedName,
      category: canonicalCategory,
    );

    next[index] = list.copyWith(items: updatedItems);
    _data = _data.copyWith(
      groceryLists: next,
      itemCategoryMemory: updatedMemory,
    );
    notifyListeners();
    await _persist();
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
      if (normalizedName.contains(normalizedQuery)) {
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
        if (normalizedName.contains(normalizedQuery) &&
            !byName.containsKey(normalizedName)) {
          byName[normalizedName] = ItemHint(
            itemName: item.name,
            category: _resolveCategory(item.category) ?? item.category,
          );
        }
      }
    }

    final hints = byName.values.toList();
    hints.sort((a, b) {
      final aName = a.itemName.toLowerCase();
      final bName = b.itemName.toLowerCase();
      final aStartsWith = aName.startsWith(normalizedQuery);
      final bStartsWith = bName.startsWith(normalizedQuery);

      if (aStartsWith && !bStartsWith) {
        return -1;
      }
      if (!aStartsWith && bStartsWith) {
        return 1;
      }
      return aName.compareTo(bName);
    });

    return hints.take(8).toList();
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
      final key = category.toLowerCase();
      categoryByKey.putIfAbsent(key, () => category);
      grouped.putIfAbsent(key, () => []).add(item);
    }

    for (final items in grouped.values) {
      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    final result = <ShoppingSection>[];
    final used = <String>{};

    for (final category in _canonicalCategoryList(marketLayout.categoryOrder)) {
      final key = category.toLowerCase();
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

      final key = canonical.toLowerCase();
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

  String? _findCategoryInList(List<String> list, String candidate) {
    final normalized = candidate.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    for (final existing in list) {
      if (existing.toLowerCase() == normalized) {
        return existing;
      }
    }

    return null;
  }

  Future<void> _persist() async {
    await _store.save(_data);
  }
}
