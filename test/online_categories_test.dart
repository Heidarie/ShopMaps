import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopmaps/online_categories.dart';

void main() {
  late OnlineCategories categories;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    categories = OnlineCategories();
  });

  tearDown(() {
    categories.dispose();
  });

  const expectedLabels = <String, Map<String, String>>{
    'nuts_seeds': {
      'en': 'Nuts & seeds',
      'pl': 'Orzechy i pestki',
      'de': 'Nüsse und Samen',
      'nl': 'Noten en zaden',
      'es': 'Frutos secos y semillas',
      'fr': 'Noix et graines',
      'uk': 'Горіхи та насіння',
      'it': 'Frutta secca e semi',
      'pt': 'Frutos secos e sementes',
    },
    'vegetarian_vegan': {
      'en': 'Vegetarian & vegan',
      'pl': 'Wege',
      'de': 'Vegetarisch & vegan',
      'nl': 'Vegetarisch en veganistisch',
      'es': 'Vegetariano y vegano',
      'fr': 'Végétarien et végan',
      'uk': 'Вегетаріанські та веганські продукти',
      'it': 'Vegetariano e vegano',
      'pt': 'Vegetariano e vegano',
    },
    'cheese': {
      'en': 'Cheese',
      'pl': 'Sery',
      'de': 'Käse',
      'nl': 'Kaas',
      'es': 'Quesos',
      'fr': 'Fromages',
      'uk': 'Сири',
      'it': 'Formaggi',
      'pt': 'Queijos',
    },
    'ham': {
      'en': 'Ham',
      'pl': 'Szynki',
      'de': 'Schinken',
      'nl': 'Ham',
      'es': 'Jamones',
      'fr': 'Jambons',
      'uk': 'Шинки',
      'it': 'Prosciutti',
      'pt': 'Presuntos',
    },
    'world_cuisines': {
      'en': 'World cuisines',
      'pl': 'Kuchnie świata',
      'de': 'Internationale Küche',
      'nl': 'Wereldkeuken',
      'es': 'Cocinas del mundo',
      'fr': 'Cuisines du monde',
      'uk': 'Кухні світу',
      'it': 'Cucine dal mondo',
      'pt': 'Cozinhas do mundo',
    },
    'organic': {
      'en': 'Organic',
      'pl': 'Bio',
      'de': 'Bio',
      'nl': 'Biologisch',
      'es': 'Ecológico',
      'fr': 'Bio',
      'uk': 'Органічні продукти',
      'it': 'Biologico',
      'pt': 'Biológico',
    },
    'pasta': {
      'en': 'Pasta',
      'pl': 'Makarony',
      'de': 'Nudeln',
      'nl': 'Pasta',
      'es': 'Pastas',
      'fr': 'Pâtes',
      'uk': 'Макаронні вироби',
      'it': 'Pasta',
      'pt': 'Massas',
    },
    'rice': {
      'en': 'Rice',
      'pl': 'Ryże',
      'de': 'Reis',
      'nl': 'Rijst',
      'es': 'Arroces',
      'fr': 'Riz',
      'uk': 'Рис',
      'it': 'Riso',
      'pt': 'Arroz',
    },
    'sauces': {
      'en': 'Sauces',
      'pl': 'Sosy',
      'de': 'Soßen',
      'nl': 'Sauzen',
      'es': 'Salsas',
      'fr': 'Sauces',
      'uk': 'Соуси',
      'it': 'Salse',
      'pt': 'Molhos',
    },
    'coffee': {
      'en': 'Coffee',
      'pl': 'Kawy',
      'de': 'Kaffee',
      'nl': 'Koffie',
      'es': 'Cafés',
      'fr': 'Cafés',
      'uk': 'Кава',
      'it': 'Caffè',
      'pt': 'Cafés',
    },
    'tea': {
      'en': 'Tea',
      'pl': 'Herbaty',
      'de': 'Tee',
      'nl': 'Thee',
      'es': 'Tés',
      'fr': 'Thés',
      'uk': 'Чай',
      'it': 'Tè',
      'pt': 'Chás',
    },
  };

  test('contains the new online categories before Other', () {
    expect(categories.all, hasLength(32));
    expect(
      categories.all
          .skip(20)
          .take(expectedLabels.length)
          .map((category) => category.id),
      expectedLabels.keys,
    );
    expect(categories.all.last.id, OnlineCategories.otherId);
  });

  test('provides all supported translations for new categories', () {
    for (final category in expectedLabels.entries) {
      for (final label in category.value.entries) {
        expect(
          categories.label(category.key, label.key),
          label.value,
          reason: '${category.key}/${label.key}',
        );
      }
    }
  });

  test('maps localized labels to their specific category ids', () {
    const polishLabels = {
      'Orzechy i pestki': 'nuts_seeds',
      'Wege': 'vegetarian_vegan',
      'Sery': 'cheese',
      'Szynki': 'ham',
      'Kuchnie świata': 'world_cuisines',
      'Bio': 'organic',
      'Makarony': 'pasta',
      'Ryże': 'rice',
      'Sosy': 'sauces',
      'Kawy': 'coffee',
      'Herbaty': 'tea',
    };

    for (final mapping in polishLabels.entries) {
      expect(
        categories.idForLabelOrAlias(mapping.key, languageCode: 'pl'),
        mapping.value,
      );
    }

    const specificAliases = {
      'kawa': 'coffee',
      'herbata': 'tea',
      'makaron': 'pasta',
      'ryż': 'rice',
      'sos': 'sauces',
    };

    for (final mapping in specificAliases.entries) {
      expect(categories.idForLabelOrAlias(mapping.key), mapping.value);
    }
  });

  test('applies a valid remote catalog and hides inactive choices', () async {
    final remoteRows = [
      ..._remoteRows(
        labelOverrides: const {
          'coffee': {'en': 'Fresh coffee', 'pl': 'Świeże kawy'},
        },
        inactiveIds: const {'drinks'},
        sortOrderOverrides: const {OnlineCategories.otherId: 34},
      ),
      {
        'category_id': 'breakfast',
        'sort_order': 33,
        'active': true,
        'labels': {'en': 'Breakfast', 'pl': 'Śniadania'},
        'aliases': ['morning food'],
      },
    ];

    expect(await categories.replaceFromRemoteRows(remoteRows), isTrue);
    expect(categories.label('coffee', 'pl'), 'Świeże kawy');
    expect(categories.label('breakfast', 'pl'), 'Śniadania');
    expect(categories.idForLabelOrAlias('morning food'), 'breakfast');
    expect(
      categories.all.map((category) => category.id),
      isNot(contains('drinks')),
    );
    expect(categories.isId('drinks'), isTrue);
    expect(categories.label('drinks', 'pl'), 'Napoje');
  });

  test('restores the last valid remote catalog from cache', () async {
    final remoteRows = _remoteRows(
      labelOverrides: const {
        'tea': {'en': 'Specialty tea', 'pl': 'Herbaty specialty'},
      },
    );
    expect(await categories.replaceFromRemoteRows(remoteRows), isTrue);

    final restored = OnlineCategories();
    addTearDown(restored.dispose);

    expect(await restored.restoreCached(), isTrue);
    expect(restored.label('tea', 'en'), 'Specialty tea');
    expect(restored.label('tea', 'pl'), 'Herbaty specialty');
  });

  test('rejects an incomplete remote catalog and keeps fallback', () async {
    final remoteRows = _remoteRows()
        .where((row) => row['category_id'] != OnlineCategories.otherId)
        .toList();

    expect(await categories.replaceFromRemoteRows(remoteRows), isFalse);
    expect(categories.all, hasLength(32));
    expect(categories.label(OnlineCategories.otherId, 'pl'), 'Inne');
  });
}

List<Map<String, dynamic>> _remoteRows({
  Map<String, Map<String, String>> labelOverrides = const {},
  Set<String> inactiveIds = const {},
  Map<String, int> sortOrderOverrides = const {},
}) {
  return [
    for (final entry in OnlineCategories.fallback.indexed)
      {
        'category_id': entry.$2.id,
        'sort_order': sortOrderOverrides[entry.$2.id] ?? entry.$1 + 1,
        'active': !inactiveIds.contains(entry.$2.id),
        'labels': {...entry.$2.labels, ...?labelOverrides[entry.$2.id]},
        'aliases': entry.$2.aliases,
      },
  ];
}
