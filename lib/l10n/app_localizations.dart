import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(localizations != null, 'AppLocalizations not found in context');
    return localizations!;
  }

  static const supportedLocales = [
    Locale('en'),
    Locale('pl'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Shopping Planner',
      'market': 'Market',
      'groceryList': 'Grocery list',
      'goShopping': 'Go shopping',
      'add': 'Add',
      'addCategory': 'Add category',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'rename': 'Rename',
      'edit': 'Edit',
      'addMarketLayout': 'Add market layout',
      'editMarketLayout': 'Edit market layout',
      'marketLayoutName': 'Market name',
      'categoriesInOrder': 'Categories in order (entrance to exit)',
      'emptyMarketLayouts': 'No market layouts yet.',
      'tapToOpen': 'Tap to open',
      'addCategoryToLayout': 'Add category to layout',
      'addNewCategory': 'Add new category',
      'newCategoryName': 'Category name',
      'category': 'Category',
      'chooseCategory': 'Choose category',
      'noCategoriesInLayout': 'No categories in this market layout yet.',
      'addGroceryList': 'Add grocery list',
      'groceryListName': 'List name',
      'emptyGroceryLists': 'No grocery lists yet.',
      'items': 'items',
      'addItem': 'Add item',
      'editItem': 'Edit item',
      'itemName': 'Item name',
      'quantity': 'Quantity',
      'itemHint': 'Hint from history',
      'noHints': 'No similar item found in history.',
      'selectedCategory': 'Selected category',
      'noCategorySelected': 'No category selected',
      'pickCategory': 'Pick category',
      'goShoppingFlow': 'Shopping route',
      'finishShopping': 'Finish shopping',
      'undo': 'Undo',
      'step1': '1. Choose grocery list',
      'step2': '2. Choose market layout',
      'shoppingResult': 'Shopping list in market order',
      'missingInLayout': 'Category not present in selected market layout',
      'nothingToShow': 'Nothing to show yet.',
      'language': 'Language',
      'systemLanguage': 'System default',
      'english': 'English',
      'polish': 'Polish',
      'createCategoryFirst': 'No categories yet. Add one first.',
      'nameCannotBeEmpty': 'Name cannot be empty.',
      'selectCategoryFirst': 'Select category first.',
      'selectListAndMarket': 'Create at least one grocery list and one market layout.',
      'deleteItem': 'Delete item',
      'deleteLayout': 'Delete market layout',
      'deleteList': 'Delete grocery list',
      'categoryDrinks': 'Drinks',
      'categorySweets': 'Sweets',
      'categoryFruits': 'Fruits',
      'categoryVegetables': 'Vegetables',
      'categoryAlcohol': 'Alcohol',
      'categoryDairy': 'Dairy',
      'categoryBakery': 'Bakery',
      'categoryMeat': 'Meat',
      'categoryFrozen': 'Frozen',
      'categoryHousehold': 'Household',
    },
    'pl': {
      'appTitle': 'Shopping Planner',
      'market': 'Sklep',
      'groceryList': 'Lista zakupów',
      'goShopping': 'Idź na zakupy',
      'add': 'Dodaj',
      'addCategory': 'Dodaj kategorię',
      'save': 'Zapisz',
      'cancel': 'Anuluj',
      'delete': 'Usuń',
      'rename': 'Zmień nazwę',
      'edit': 'Edytuj',
      'addMarketLayout': 'Dodaj układ sklepu',
      'editMarketLayout': 'Edytuj układ sklepu',
      'marketLayoutName': 'Nazwa sklepu',
      'categoriesInOrder': 'Kategorie w kolejności (od wejścia do wyjścia)',
      'emptyMarketLayouts': 'Brak układów sklepów.',
      'tapToOpen': 'Kliknij, aby otworzyć',
      'addCategoryToLayout': 'Dodaj kategorię do układu',
      'addNewCategory': 'Dodaj nową kategorię',
      'newCategoryName': 'Nazwa kategorii',
      'category': 'Kategoria',
      'chooseCategory': 'Wybierz kategorię',
      'noCategoriesInLayout': 'Brak kategorii w tym układzie sklepu.',
      'addGroceryList': 'Dodaj listę zakupów',
      'groceryListName': 'Nazwa listy',
      'emptyGroceryLists': 'Brak list zakupów.',
      'items': 'pozycji',
      'addItem': 'Dodaj produkt',
      'editItem': 'Edytuj produkt',
      'itemName': 'Nazwa produktu',
      'quantity': 'Ilość',
      'itemHint': 'Podpowiedź z historii',
      'noHints': 'Brak podobnych produktów w historii.',
      'selectedCategory': 'Wybrana kategoria',
      'noCategorySelected': 'Brak wybranej kategorii',
      'pickCategory': 'Wybierz kategorię',
      'goShoppingFlow': 'Trasa zakupów',
      'finishShopping': 'Zakończ zakupy',
      'undo': 'Cofnij',
      'step1': '1. Wybierz listę zakupów',
      'step2': '2. Wybierz układ sklepu',
      'shoppingResult': 'Lista zakupów w kolejności sklepu',
      'missingInLayout': 'Kategoria nie występuje w wybranym układzie sklepu',
      'nothingToShow': 'Na razie brak danych.',
      'language': 'Język',
      'systemLanguage': 'Domyślny systemowy',
      'english': 'Angielski',
      'polish': 'Polski',
      'createCategoryFirst': 'Brak kategorii. Najpierw dodaj kategorię.',
      'nameCannotBeEmpty': 'Nazwa nie może być pusta.',
      'selectCategoryFirst': 'Najpierw wybierz kategorię.',
      'selectListAndMarket': 'Utwórz przynajmniej jedną listę i jeden układ sklepu.',
      'deleteItem': 'Usuń produkt',
      'deleteLayout': 'Usuń układ sklepu',
      'deleteList': 'Usuń listę zakupów',
      'categoryDrinks': 'Napoje',
      'categorySweets': 'Słodycze',
      'categoryFruits': 'Owoce',
      'categoryVegetables': 'Warzywa',
      'categoryAlcohol': 'Alkohol',
      'categoryDairy': 'Nabiał',
      'categoryBakery': 'Piekarnia',
      'categoryMeat': 'Mięso',
      'categoryFrozen': 'Mrożonki',
      'categoryHousehold': 'Chemia domowa',
    },
  };

  static const Map<String, String> _defaultCategoryKeyByValue = {
    'drinks': 'categoryDrinks',
    'napoje': 'categoryDrinks',
    'sweets': 'categorySweets',
    'slodycze': 'categorySweets',
    'słodycze': 'categorySweets',
    'fruits': 'categoryFruits',
    'owoce': 'categoryFruits',
    'vegetables': 'categoryVegetables',
    'warzywa': 'categoryVegetables',
    'alcohol': 'categoryAlcohol',
    'alkohol': 'categoryAlcohol',
    'dairy': 'categoryDairy',
    'nabiał': 'categoryDairy',
    'nabial': 'categoryDairy',
    'bakery': 'categoryBakery',
    'piekarnia': 'categoryBakery',
    'meat': 'categoryMeat',
    'mięso': 'categoryMeat',
    'mieso': 'categoryMeat',
    'frozen': 'categoryFrozen',
    'mrożonki': 'categoryFrozen',
    'mrozonki': 'categoryFrozen',
    'household': 'categoryHousehold',
    'chemia domowa': 'categoryHousehold',
  };

  String _t(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key]!;
  }

  String get appTitle => _t('appTitle');
  String get market => _t('market');
  String get groceryList => _t('groceryList');
  String get goShopping => _t('goShopping');
  String get add => _t('add');
  String get addCategory => _t('addCategory');
  String get save => _t('save');
  String get cancel => _t('cancel');
  String get delete => _t('delete');
  String get rename => _t('rename');
  String get edit => _t('edit');
  String get addMarketLayout => _t('addMarketLayout');
  String get editMarketLayout => _t('editMarketLayout');
  String get marketLayoutName => _t('marketLayoutName');
  String get categoriesInOrder => _t('categoriesInOrder');
  String get emptyMarketLayouts => _t('emptyMarketLayouts');
  String get tapToOpen => _t('tapToOpen');
  String get addCategoryToLayout => _t('addCategoryToLayout');
  String get addNewCategory => _t('addNewCategory');
  String get newCategoryName => _t('newCategoryName');
  String get category => _t('category');
  String get chooseCategory => _t('chooseCategory');
  String get noCategoriesInLayout => _t('noCategoriesInLayout');
  String get addGroceryList => _t('addGroceryList');
  String get groceryListName => _t('groceryListName');
  String get emptyGroceryLists => _t('emptyGroceryLists');
  String get items => _t('items');
  String get addItem => _t('addItem');
  String get editItem => _t('editItem');
  String get itemName => _t('itemName');
  String get quantity => _t('quantity');
  String get itemHint => _t('itemHint');
  String get noHints => _t('noHints');
  String get selectedCategory => _t('selectedCategory');
  String get noCategorySelected => _t('noCategorySelected');
  String get pickCategory => _t('pickCategory');
  String get goShoppingFlow => _t('goShoppingFlow');
  String get finishShopping => _t('finishShopping');
  String get undo => _t('undo');
  String get step1 => _t('step1');
  String get step2 => _t('step2');
  String get shoppingResult => _t('shoppingResult');
  String get missingInLayout => _t('missingInLayout');
  String get nothingToShow => _t('nothingToShow');
  String get language => _t('language');
  String get systemLanguage => _t('systemLanguage');
  String get english => _t('english');
  String get polish => _t('polish');
  String get createCategoryFirst => _t('createCategoryFirst');
  String get nameCannotBeEmpty => _t('nameCannotBeEmpty');
  String get selectCategoryFirst => _t('selectCategoryFirst');
  String get selectListAndMarket => _t('selectListAndMarket');
  String get deleteItem => _t('deleteItem');
  String get deleteLayout => _t('deleteLayout');
  String get deleteList => _t('deleteList');

  String itemsCount(int count) {
    return '$count ${_t('items')}';
  }

  String categoryLabel(String category) {
    final key = _defaultCategoryKeyByValue[category.trim().toLowerCase()];
    if (key == null) {
      return category;
    }
    return _t(key);
  }

  String hintLabel(String itemName, String category) {
    return '$itemName -> ${categoryLabel(category)}';
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((supported) => supported.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
