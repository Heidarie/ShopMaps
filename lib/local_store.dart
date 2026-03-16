import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'models.dart';

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
      final initialData = AppData.empty(categories: localizedDefaultCategories);
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
        final migratedData = _migrateLegacyDefaultCategories(
          loadedData,
          localizedDefaultCategories: localizedDefaultCategories,
        );
        if (!_sameCategories(loadedData.categories, migratedData.categories)) {
          await save(migratedData);
        }
        return migratedData;
      }

      return _resetToDefaultData(
        preferences,
        raw: raw,
        localizedDefaultCategories: localizedDefaultCategories,
      );
    } catch (_) {
      return _resetToDefaultData(
        preferences,
        raw: raw,
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
    required List<String> localizedDefaultCategories,
  }) async {
    await _backupRawPayload(preferences, raw);
    final initialData = AppData.empty(categories: localizedDefaultCategories);
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
        defaultCategories[index]: localizedDefaultCategories[index],
    };

    String mapCategory(String category) => categoryMap[category] ?? category;

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
