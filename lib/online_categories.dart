import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class OnlineCategory {
  const OnlineCategory({
    required this.id,
    required this.labels,
    this.aliases = const [],
    this.active = true,
  });

  final String id;
  final Map<String, String> labels;
  final List<String> aliases;
  final bool active;

  String label(String languageCode) {
    return labels[languageCode] ?? labels['en'] ?? id;
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'labels': labels, 'aliases': aliases, 'active': active};
  }

  static OnlineCategory? tryFromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final json = Map<String, dynamic>.from(value);
    final id = json['id']?.toString().trim() ?? '';
    final rawLabels = json['labels'];
    final rawAliases = json['aliases'];
    if (id.isEmpty || rawLabels is! Map || rawAliases is! List) {
      return null;
    }

    final labels = <String, String>{};
    for (final entry in rawLabels.entries) {
      final languageCode = entry.key.toString().trim().toLowerCase();
      final label = entry.value?.toString().trim() ?? '';
      if (languageCode.isEmpty || label.isEmpty) {
        return null;
      }
      labels[languageCode] = label;
    }

    final aliases = <String>[];
    for (final alias in rawAliases) {
      final cleanedAlias = alias?.toString().trim() ?? '';
      if (cleanedAlias.isEmpty) {
        return null;
      }
      aliases.add(cleanedAlias);
    }

    return OnlineCategory(
      id: id,
      labels: Map.unmodifiable(labels),
      aliases: List.unmodifiable(aliases),
      active: json['active'] != false,
    );
  }
}

class OnlineCategories extends ChangeNotifier {
  OnlineCategories() {
    _replaceCategories(fallback, notify: false);
  }

  static const String otherId = 'other';
  static const String _cacheKey = 'shopmaps_online_categories_v1';
  static final RegExp _categoryIdPattern = RegExp(r'^[a-z][a-z0-9_]*$');

  static const List<OnlineCategory> fallback = [
    OnlineCategory(
      id: 'drinks',
      labels: {
        'en': 'Drinks',
        'pl': 'Napoje',
        'de': 'Getränke',
        'nl': 'Dranken',
        'es': 'Bebidas',
        'fr': 'Boissons',
        'uk': 'Напої',
        'it': 'Bevande',
        'pt': 'Bebidas',
      },
      aliases: ['drink', 'napoj', 'wasser', 'water', 'sok', 'juice'],
    ),
    OnlineCategory(
      id: 'coffee_tea',
      labels: {
        'en': 'Coffee & tea',
        'pl': 'Kawa i herbata',
        'de': 'Kaffee und Tee',
        'nl': 'Koffie en thee',
        'es': 'Café y té',
        'fr': 'Café et thé',
        'uk': 'Кава і чай',
        'it': 'Caffè e tè',
        'pt': 'Café e chá',
      },
      aliases: ['coffee and tea', 'kawa herbata'],
    ),
    OnlineCategory(
      id: 'alcohol',
      labels: {
        'en': 'Alcohol',
        'pl': 'Alkohol',
        'de': 'Alkohol',
        'nl': 'Alcohol',
        'es': 'Alcohol',
        'fr': 'Alcool',
        'uk': 'Алкоголь',
        'it': 'Alcol',
        'pt': 'Álcool',
      },
      aliases: ['beer', 'wine', 'piwo', 'wino', 'spirits'],
    ),
    OnlineCategory(
      id: 'sweets',
      labels: {
        'en': 'Sweets',
        'pl': 'Słodycze',
        'de': 'Süßigkeiten',
        'nl': 'Snoep',
        'es': 'Dulces',
        'fr': 'Confiseries',
        'uk': 'Солодощі',
        'it': 'Dolci',
        'pt': 'Doces',
      },
      aliases: ['sweet', 'candy', 'chocolate', 'slodycze', 'czekolada'],
    ),
    OnlineCategory(
      id: 'snacks',
      labels: {
        'en': 'Snacks',
        'pl': 'Przekąski',
        'de': 'Snacks',
        'nl': 'Snacks',
        'es': 'Aperitivos',
        'fr': 'Snacks',
        'uk': 'Снеки',
        'it': 'Snack',
        'pt': 'Snacks',
      },
      aliases: ['snack', 'przekaski', 'chips', 'crisps'],
    ),
    OnlineCategory(
      id: 'fruit',
      labels: {
        'en': 'Fruit',
        'pl': 'Owoce',
        'de': 'Obst',
        'nl': 'Fruit',
        'es': 'Fruta',
        'fr': 'Fruits',
        'uk': 'Фрукти',
        'it': 'Frutta',
        'pt': 'Fruta',
      },
      aliases: ['fruits', 'owoce', 'apples', 'jablka'],
    ),
    OnlineCategory(
      id: 'vegetables',
      labels: {
        'en': 'Vegetables',
        'pl': 'Warzywa',
        'de': 'Gemüse',
        'nl': 'Groenten',
        'es': 'Verduras',
        'fr': 'Légumes',
        'uk': 'Овочі',
        'it': 'Verdure',
        'pt': 'Legumes',
      },
      aliases: ['vegetable', 'veggies', 'warzywa', 'gemuse'],
    ),
    OnlineCategory(
      id: 'dairy_eggs',
      labels: {
        'en': 'Dairy & eggs',
        'pl': 'Nabiał i jajka',
        'de': 'Milchprodukte und Eier',
        'nl': 'Zuivel en eieren',
        'es': 'Lácteos y huevos',
        'fr': 'Produits laitiers et œufs',
        'uk': 'Молочні продукти та яйця',
        'it': 'Latticini e uova',
        'pt': 'Laticínios e ovos',
      },
      aliases: ['dairy', 'eggs', 'nabial', 'jajka', 'milk', 'mleko'],
    ),
    OnlineCategory(
      id: 'bakery',
      labels: {
        'en': 'Bakery',
        'pl': 'Piekarnia',
        'de': 'Bäckerei',
        'nl': 'Bakkerij',
        'es': 'Panadería',
        'fr': 'Boulangerie',
        'uk': 'Випічка',
        'it': 'Panetteria',
        'pt': 'Padaria',
      },
      aliases: ['bread', 'pieczywo', 'chleb', 'baked goods'],
    ),
    OnlineCategory(
      id: 'meat',
      labels: {
        'en': 'Meat',
        'pl': 'Mięso',
        'de': 'Fleisch',
        'nl': 'Vlees',
        'es': 'Carne',
        'fr': 'Viande',
        'uk': 'Мʼясо',
        'it': 'Carne',
        'pt': 'Carne',
      },
      aliases: ['mieso', 'butcher'],
    ),
    OnlineCategory(
      id: 'fish_seafood',
      labels: {
        'en': 'Fish & seafood',
        'pl': 'Ryby i owoce morza',
        'de': 'Fisch und Meeresfrüchte',
        'nl': 'Vis en zeevruchten',
        'es': 'Pescado y marisco',
        'fr': 'Poisson et fruits de mer',
        'uk': 'Риба та морепродукти',
        'it': 'Pesce e frutti di mare',
        'pt': 'Peixe e marisco',
      },
      aliases: ['fish', 'seafood', 'ryby', 'owoce morza'],
    ),
    OnlineCategory(
      id: 'frozen',
      labels: {
        'en': 'Frozen',
        'pl': 'Mrożonki',
        'de': 'Tiefkühlkost',
        'nl': 'Diepvries',
        'es': 'Congelados',
        'fr': 'Surgelés',
        'uk': 'Заморожені продукти',
        'it': 'Surgelati',
        'pt': 'Congelados',
      },
      aliases: ['frozen food', 'mrozonki', 'freezer'],
    ),
    OnlineCategory(
      id: 'dry_goods',
      labels: {
        'en': 'Pasta, rice & flour',
        'pl': 'Makaron, ryż i mąka',
        'de': 'Nudeln, Reis und Mehl',
        'nl': 'Pasta, rijst en bloem',
        'es': 'Pasta, arroz y harina',
        'fr': 'Pâtes, riz et farine',
        'uk': 'Макарони, рис і борошно',
        'it': 'Pasta, riso e farina',
        'pt': 'Massa, arroz e farinha',
      },
      aliases: ['flour', 'maka'],
    ),
    OnlineCategory(
      id: 'canned_jars',
      labels: {
        'en': 'Cans & jars',
        'pl': 'Konserwy i słoiki',
        'de': 'Konserven und Gläser',
        'nl': 'Blikken en potten',
        'es': 'Conservas y tarros',
        'fr': 'Conserves et bocaux',
        'uk': 'Консерви та банки',
        'it': 'Scatolette e barattoli',
        'pt': 'Conservas e frascos',
      },
      aliases: ['cans', 'jars', 'konserwy', 'sloiki', 'preserves'],
    ),
    OnlineCategory(
      id: 'spices_condiments',
      labels: {
        'en': 'Spices & condiments',
        'pl': 'Przyprawy',
        'de': 'Gewürze',
        'nl': 'Kruiden en specerijen',
        'es': 'Especias y condimentos',
        'fr': 'Épices et condiments',
        'uk': 'Спеції та приправи',
        'it': 'Spezie e condimenti',
        'pt': 'Especiarias e condimentos',
      },
      aliases: ['spices', 'condiments', 'przyprawy', 'herbs'],
    ),
    OnlineCategory(
      id: 'oils_sauces',
      labels: {
        'en': 'Oils & sauces',
        'pl': 'Oleje i sosy',
        'de': 'Öle und Soßen',
        'nl': 'Oliën en sauzen',
        'es': 'Aceites y salsas',
        'fr': 'Huiles et sauces',
        'uk': 'Олії та соуси',
        'it': 'Oli e salse',
        'pt': 'Óleos e molhos',
      },
      aliases: ['oil', 'oleje', 'olive oil'],
    ),
    OnlineCategory(
      id: 'ready_meals',
      labels: {
        'en': 'Ready meals',
        'pl': 'Dania gotowe',
        'de': 'Fertiggerichte',
        'nl': 'Kant-en-klaarmaaltijden',
        'es': 'Platos preparados',
        'fr': 'Plats préparés',
        'uk': 'Готові страви',
        'it': 'Piatti pronti',
        'pt': 'Refeições prontas',
      },
      aliases: ['ready meal', 'dania gotowe', 'meal kits'],
    ),
    OnlineCategory(
      id: 'household_cleaning',
      labels: {
        'en': 'Household cleaning',
        'pl': 'Chemia domowa',
        'de': 'Haushaltsreinigung',
        'nl': 'Huishoudelijke schoonmaak',
        'es': 'Limpieza del hogar',
        'fr': 'Entretien de la maison',
        'uk': 'Побутова хімія',
        'it': 'Pulizia della casa',
        'pt': 'Limpeza doméstica',
      },
      aliases: ['household', 'cleaning', 'chemia', 'detergents'],
    ),
    OnlineCategory(
      id: 'paper_hygiene',
      labels: {
        'en': 'Paper & hygiene',
        'pl': 'Papier i higiena',
        'de': 'Papier und Hygiene',
        'nl': 'Papier en hygiëne',
        'es': 'Papel e higiene',
        'fr': 'Papier et hygiène',
        'uk': 'Папір та гігієна',
        'it': 'Carta e igiene',
        'pt': 'Papel e higiene',
      },
      aliases: ['paper', 'hygiene', 'papier', 'toilet paper'],
    ),
    OnlineCategory(
      id: 'personal_care',
      labels: {
        'en': 'Personal care',
        'pl': 'Higiena osobista',
        'de': 'Körperpflege',
        'nl': 'Persoonlijke verzorging',
        'es': 'Cuidado personal',
        'fr': 'Soins personnels',
        'uk': 'Особиста гігієна',
        'it': 'Cura personale',
        'pt': 'Cuidados pessoais',
      },
      aliases: ['cosmetics', 'kosmetyki', 'body care', 'higiena osobista'],
    ),
    OnlineCategory(
      id: 'nuts_seeds',
      labels: {
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
      aliases: ['nuts', 'seeds', 'orzechy', 'pestki'],
    ),
    OnlineCategory(
      id: 'vegetarian_vegan',
      labels: {
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
      aliases: ['vegetarian', 'vegan', 'plant based', 'wegetarianskie'],
    ),
    OnlineCategory(
      id: 'cheese',
      labels: {
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
      aliases: ['cheeses', 'ser', 'queso', 'fromage'],
    ),
    OnlineCategory(
      id: 'ham',
      labels: {
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
      aliases: ['hams', 'szynka', 'prosciutto', 'jamon'],
    ),
    OnlineCategory(
      id: 'world_cuisines',
      labels: {
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
      aliases: ['international food', 'international cuisine', 'world food'],
    ),
    OnlineCategory(
      id: 'organic',
      labels: {
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
      aliases: ['eco', 'ecological', 'ekologiczne', 'organic food'],
    ),
    OnlineCategory(
      id: 'pasta',
      labels: {
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
      aliases: ['makaron', 'noodles'],
    ),
    OnlineCategory(
      id: 'rice',
      labels: {
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
      aliases: ['ryz'],
    ),
    OnlineCategory(
      id: 'sauces',
      labels: {
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
      aliases: ['sauce', 'sos'],
    ),
    OnlineCategory(
      id: 'coffee',
      labels: {
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
      aliases: ['kawa', 'cafe'],
    ),
    OnlineCategory(
      id: 'tea',
      labels: {
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
      aliases: ['herbata'],
    ),
    OnlineCategory(
      id: otherId,
      labels: {
        'en': 'Other',
        'pl': 'Inne',
        'de': 'Andere',
        'nl': 'Overig',
        'es': 'Otros',
        'fr': 'Autre',
        'uk': 'Інше',
        'it': 'Altro',
        'pt': 'Outros',
      },
      aliases: ['misc', 'miscellaneous', 'inne', 'other category'],
    ),
  ];

  late List<OnlineCategory> _categories;
  late List<OnlineCategory> _activeCategories;
  late Map<String, OnlineCategory> _byId;
  late Set<String> _ids;
  bool _initialized = false;

  List<OnlineCategory> get all => _activeCategories;
  Set<String> get ids => _ids;

  bool isId(String value) => _ids.contains(value.trim());

  String label(String id, String languageCode) {
    return _byId[id]?.label(languageCode) ??
        _byId[otherId]!.label(languageCode);
  }

  String? idForLabelOrAlias(String value, {String? languageCode}) {
    final key = normalizeLatinText(value);
    if (key.isEmpty) {
      return null;
    }
    if (_ids.contains(value.trim())) {
      return value.trim();
    }

    for (final category in _categories) {
      final preferredLabel = languageCode == null
          ? null
          : category.labels[languageCode];
      final candidates = <String>[
        category.id,
        ?preferredLabel,
        ...category.labels.values,
      ];
      if (candidates.any((candidate) => normalizeLatinText(candidate) == key)) {
        return category.id;
      }
    }

    for (final category in _categories) {
      if (category.aliases.any(
        (candidate) => normalizeLatinText(candidate) == key,
      )) {
        return category.id;
      }
    }

    return null;
  }

  List<String> canonicalizeOrder(Iterable<String> ids) {
    final result = <String>[];
    final seen = <String>{};
    for (final id in ids) {
      final cleaned = id.trim();
      if (isId(cleaned) && seen.add(cleaned)) {
        result.add(cleaned);
      }
    }
    return result;
  }

  Future<bool> restoreCached() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_cacheKey);
    if (raw == null || raw.isEmpty) {
      return false;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        await preferences.remove(_cacheKey);
        return false;
      }
      final cachedCategories = <OnlineCategory>[];
      for (final entry in decoded) {
        final category = OnlineCategory.tryFromJson(entry);
        if (category == null) {
          await preferences.remove(_cacheKey);
          return false;
        }
        cachedCategories.add(category);
      }
      if (!_isValidCatalog(cachedCategories)) {
        await preferences.remove(_cacheKey);
        return false;
      }
      _replaceCategories(cachedCategories);
      return true;
    } catch (error) {
      debugPrint('Ignoring invalid cached online category catalog: $error');
      await preferences.remove(_cacheKey);
      return false;
    }
  }

  Future<bool> replaceFromRemoteRows(List<dynamic> rows) async {
    final parsedRows = <({int sortOrder, OnlineCategory category})>[];
    final sortOrders = <int>{};

    for (final row in rows) {
      if (row is! Map) {
        return false;
      }
      final json = Map<String, dynamic>.from(row);
      final sortOrder = switch (json['sort_order']) {
        int value => value,
        num value => value.toInt(),
        _ => -1,
      };
      final category = OnlineCategory.tryFromJson({
        'id': json['category_id'],
        'labels': json['labels'],
        'aliases': json['aliases'],
        'active': json['active'],
      });
      if (sortOrder <= 0 || !sortOrders.add(sortOrder) || category == null) {
        return false;
      }
      parsedRows.add((sortOrder: sortOrder, category: category));
    }

    parsedRows.sort((left, right) {
      final orderComparison = left.sortOrder.compareTo(right.sortOrder);
      if (orderComparison != 0) {
        return orderComparison;
      }
      return left.category.id.compareTo(right.category.id);
    });
    final remoteCategories = parsedRows
        .map((row) => row.category)
        .toList(growable: false);
    if (!_isValidCatalog(remoteCategories)) {
      return false;
    }

    _replaceCategories(remoteCategories);
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _cacheKey,
        jsonEncode(_categories.map((category) => category.toJson()).toList()),
      );
    } catch (error) {
      debugPrint('Failed to cache online category catalog: $error');
    }
    return true;
  }

  void resetToFallback() {
    _replaceCategories(fallback);
  }

  bool _isValidCatalog(List<OnlineCategory> categories) {
    if (categories.isEmpty || categories.length > 500) {
      return false;
    }

    final categoryIds = <String>{};
    for (final category in categories) {
      if (!_categoryIdPattern.hasMatch(category.id) ||
          !categoryIds.add(category.id) ||
          (category.labels['en']?.trim().isEmpty ?? true)) {
        return false;
      }
    }

    for (final category in categories) {
      if (category.id == otherId) {
        return category.active;
      }
    }
    return false;
  }

  void _replaceCategories(
    List<OnlineCategory> categories, {
    bool notify = true,
  }) {
    final nextCategories = List<OnlineCategory>.unmodifiable(categories);
    final nextJson = jsonEncode(
      nextCategories.map((category) => category.toJson()).toList(),
    );
    final currentJson = _initialized
        ? jsonEncode(_categories.map((category) => category.toJson()).toList())
        : null;

    _categories = nextCategories;
    _activeCategories = List<OnlineCategory>.unmodifiable(
      nextCategories.where((category) => category.active),
    );
    _byId = Map<String, OnlineCategory>.unmodifiable({
      for (final category in nextCategories) category.id: category,
    });
    _ids = Set<String>.unmodifiable(_byId.keys);
    _initialized = true;

    if (notify && currentJson != nextJson) {
      notifyListeners();
    }
  }
}
