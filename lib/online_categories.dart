import 'models.dart';

class OnlineCategory {
  const OnlineCategory({
    required this.id,
    required this.labels,
    this.aliases = const [],
  });

  final String id;
  final Map<String, String> labels;
  final List<String> aliases;

  String label(String languageCode) {
    return labels[languageCode] ?? labels['en'] ?? id;
  }
}

class OnlineCategories {
  const OnlineCategories._();

  static const String otherId = 'other';

  static const List<OnlineCategory> all = [
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
      aliases: ['coffee', 'tea', 'kawa', 'herbata', 'cafe', 'kaffee', 'tee'],
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
      aliases: ['pasta', 'rice', 'flour', 'makaron', 'ryz', 'maka'],
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
      aliases: ['oil', 'sauce', 'oleje', 'sosy', 'olive oil'],
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

  static final Map<String, OnlineCategory> _byId = {
    for (final category in all) category.id: category,
  };

  static final Set<String> ids = _byId.keys.toSet();

  static bool isId(String value) => ids.contains(value.trim());

  static String label(String id, String languageCode) {
    return _byId[id]?.label(languageCode) ??
        _byId[otherId]!.label(languageCode);
  }

  static String? idForLabelOrAlias(String value, {String? languageCode}) {
    final key = normalizeLatinText(value);
    if (key.isEmpty) {
      return null;
    }
    if (ids.contains(value.trim())) {
      return value.trim();
    }

    for (final category in all) {
      final preferredLabel = languageCode == null
          ? null
          : category.labels[languageCode];
      final candidates = <String>[
        category.id,
        ?preferredLabel,
        ...category.labels.values,
        ...category.aliases,
      ];
      if (candidates.any((candidate) => normalizeLatinText(candidate) == key)) {
        return category.id;
      }
    }
    return null;
  }

  static List<String> canonicalizeOrder(Iterable<String> ids) {
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
}
