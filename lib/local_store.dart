import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'models.dart';
import 'predefined_items.dart';

class LocalStore {
  static const String _storageKey = 'shopmaps_data_v1';
  static const String _legacyStorageKey = 'shopping_guide_data_v1';
  static const String _backupStorageKey = 'shopmaps_data_backup_v1';

  Future<AppData> load({
    String localeLanguageCode = 'en',
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey) ?? preferences.getString(_legacyStorageKey);
    final localizedDefaultCategories = AppLocalizations.defaultCategoriesForLanguageCode(
      localeLanguageCode,
    );

    if (raw == null || raw.isEmpty) {
      final initialData = AppData.empty(
        categories: localizedDefaultCategories,
        itemCategoryMemory: predefinedItemMemoryForLanguageCode(localeLanguageCode),
        predefinedItemsSeedVersion: predefinedItemSeedVersion,
      );
      await save(initialData);
      return initialData;
    }

    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map) {
        final loadedData = AppData.fromJson(
          Map<String, dynamic>.from(parsed),
          fallbackCategories: localizedDefaultCategories,
        );
        final migratedCategoryData = _migrateLegacyDefaultCategories(
          loadedData,
          localizedDefaultCategories: localizedDefaultCategories,
        );
        final migratedData = _migratePredefinedItems(
          migratedCategoryData,
          localeLanguageCode: localeLanguageCode,
        );
        if (jsonEncode(loadedData.toJson()) != jsonEncode(migratedData.toJson())) {
          await save(migratedData);
        }
        return migratedData;
      }

      return _resetToDefaultData(
        preferences,
        raw: raw,
        localeLanguageCode: localeLanguageCode,
        localizedDefaultCategories: localizedDefaultCategories,
      );
    } catch (_) {
      return _resetToDefaultData(
        preferences,
        raw: raw,
        localeLanguageCode: localeLanguageCode,
        localizedDefaultCategories: localizedDefaultCategories,
      );
    }
  }

  Future<void> save(AppData data) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = jsonEncode(data.toJson());
    await preferences.setString(_storageKey, raw);
    if (preferences.containsKey(_legacyStorageKey)) {
      await preferences.remove(_legacyStorageKey);
    }
  }

  Future<AppData> _resetToDefaultData(
    SharedPreferences preferences, {
    required String raw,
    required String localeLanguageCode,
    required List<String> localizedDefaultCategories,
  }) async {
    await _backupRawPayload(preferences, raw);
    final initialData = AppData.empty(
      categories: localizedDefaultCategories,
      itemCategoryMemory: predefinedItemMemoryForLanguageCode(localeLanguageCode),
      predefinedItemsSeedVersion: predefinedItemSeedVersion,
    );
    await save(initialData);
    return initialData;
  }

  Future<void> _backupRawPayload(
    SharedPreferences preferences,
    String raw,
  ) async {
    if (raw.isEmpty) {
      return;
    }
    await preferences.setString(_backupStorageKey, raw);
  }

  AppData _migrateLegacyDefaultCategories(
    AppData data, {
    required List<String> localizedDefaultCategories,
  }) {
    assert(
      localizedDefaultCategories.length == defaultCategories.length,
      'Localized default categories must match the default category count.',
    );
    if (localizedDefaultCategories.length != defaultCategories.length) {
      return data;
    }
    if (_sameCategories(localizedDefaultCategories, defaultCategories)) {
      return data;
    }
    if (!_sameCategories(data.categories, defaultCategories)) {
      return data;
    }

    final categoryMap = <String, String>{
      for (var index = 0; index < defaultCategories.length; index++)
        normalizeLatinText(defaultCategories[index]): localizedDefaultCategories[index],
    };

    String mapCategory(String category) {
      return categoryMap[normalizeLatinText(category)] ?? category;
    }

    return data.copyWith(
      categories: localizedDefaultCategories,
      marketLayouts: data.marketLayouts
          .map(
            (layout) => layout.copyWith(
              categoryOrder: layout.categoryOrder.map(mapCategory).toList(),
            ),
          )
          .toList(),
      groceryLists: data.groceryLists
          .map(
            (list) => list.copyWith(
              items: list.items
                  .map(
                    (item) => GroceryItem(
                      id: item.id,
                      name: item.name,
                      category: mapCategory(item.category),
                      quantity: item.quantity,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
      itemCategoryMemory: data.itemCategoryMemory
          .map(
            (entry) => RememberedItemCategory(
              itemName: entry.itemName,
              category: mapCategory(entry.category),
            ),
          )
          .toList(),
      frequentItemStats: data.frequentItemStats
          .map(
            (entry) => FrequentItemStat(
              itemName: entry.itemName,
              category: mapCategory(entry.category),
              occurrenceCount: entry.occurrenceCount,
              lastAddedAt: entry.lastAddedAt,
              isFavorite: entry.isFavorite,
            ),
          )
          .toList(),
    );
  }

  AppData _migratePredefinedItems(
    AppData data, {
    required String localeLanguageCode,
  }) {
    final seededMemory = predefinedItemMemoryForLanguageCode(
      localeLanguageCode,
      availableCategories: data.categories,
    );
    if (seededMemory.isEmpty) {
      return data;
    }

    final mergedMemory = _mergeRememberedItemCategories(
      seeded: seededMemory,
      existing: data.itemCategoryMemory,
    );
    final didInstallMissingItems = mergedMemory.length != data.itemCategoryMemory.length;
    final needsVersionBump =
        data.predefinedItemsSeedVersion < predefinedItemSeedVersion;

    if (!didInstallMissingItems && !needsVersionBump) {
      return data;
    }

    return data.copyWith(
      itemCategoryMemory: mergedMemory,
      predefinedItemsSeedVersion: predefinedItemSeedVersion,
    );
  }

  List<RememberedItemCategory> _mergeRememberedItemCategories({
    required List<RememberedItemCategory> seeded,
    required List<RememberedItemCategory> existing,
  }) {
    final byItem = <String, RememberedItemCategory>{};

    for (final entry in seeded) {
      final key = normalizeLatinText(entry.itemName);
      if (key.isEmpty) {
        continue;
      }
      byItem[key] = entry;
    }

    for (final entry in existing) {
      final key = normalizeLatinText(entry.itemName);
      if (key.isEmpty) {
        continue;
      }
      byItem[key] = entry;
    }

    return byItem.values.toList();
  }

  bool _sameCategories(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index++) {
      if (!sameNormalizedText(left[index], right[index])) {
        return false;
      }
    }

    return true;
  }
}
