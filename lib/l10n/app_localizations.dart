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
    Locale('de'),
    Locale('nl'),
    Locale('es'),
    Locale('fr'),
    Locale('uk'),
    Locale('it'),
    Locale('pt'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'ShopMaps',
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
      'emptyGroceryListItems': 'The list is empty.',
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
      'shoppingDoneIn': "Nice! You've done your shopping in:",
      'undo': 'Undo',
      'step1': '1. Choose grocery list',
      'step2': '2. Choose market layout',
      'shoppingResult': 'Shopping list in market order',
      'emptyShoppingList': 'The list is empty!',
      'missingInLayout': 'Category not present in selected market layout',
      'nothingToShow': 'Nothing to show yet.',
      'language': 'Language',
      'systemLanguage': 'System default',
      'english': 'English',
      'polish': 'Polish',
      'createCategoryFirst': 'No categories yet. Add one first.',
      'nameCannotBeEmpty': 'Name cannot be empty.',
      'selectCategoryFirst': 'Select category first.',
      'maxCategoriesReached': 'Maximum categories limit reached ({max}).',
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
      'appTitle': 'ShopMaps',
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
      'emptyGroceryListItems': 'Lista jest pusta.',
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
      'shoppingDoneIn': 'Super! Zrobiono zakupy w:',
      'undo': 'Cofnij',
      'step1': '1. Wybierz listę zakupów',
      'step2': '2. Wybierz układ sklepu',
      'shoppingResult': 'Lista zakupów w kolejności sklepu',
      'emptyShoppingList': 'Lista jest pusta!',
      'missingInLayout': 'Kategoria nie występuje w wybranym układzie sklepu',
      'nothingToShow': 'Na razie brak danych.',
      'language': 'Język',
      'systemLanguage': 'Domyślny systemowy',
      'english': 'Angielski',
      'polish': 'Polski',
      'createCategoryFirst': 'Brak kategorii. Najpierw dodaj kategorię.',
      'nameCannotBeEmpty': 'Nazwa nie może być pusta.',
      'selectCategoryFirst': 'Najpierw wybierz kategorię.',
      'maxCategoriesReached': 'Osiągnięto limit kategorii ({max}).',
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
    'de': {
      'appTitle': 'ShopMaps',
      'market': 'Markt',
      'groceryList': 'Einkaufsliste',
      'goShopping': 'Einkaufen gehen',
      'add': 'Hinzufügen',
      'addCategory': 'Kategorie hinzufügen',
      'save': 'Speichern',
      'cancel': 'Abbrechen',
      'delete': 'Löschen',
      'rename': 'Umbenennen',
      'edit': 'Bearbeiten',
      'addMarketLayout': 'Marktlayout hinzufügen',
      'editMarketLayout': 'Marktlayout bearbeiten',
      'marketLayoutName': 'Marktname',
      'categoriesInOrder': 'Kategorien in Reihenfolge (Eingang bis Ausgang)',
      'emptyMarketLayouts': 'Noch keine Marktlayouts.',
      'tapToOpen': 'Tippen zum Öffnen',
      'addCategoryToLayout': 'Kategorie zum Layout hinzufügen',
      'addNewCategory': 'Neue Kategorie hinzufügen',
      'newCategoryName': 'Kategoriename',
      'category': 'Kategorie',
      'chooseCategory': 'Kategorie wählen',
      'noCategoriesInLayout': 'Noch keine Kategorien in diesem Marktlayout.',
      'addGroceryList': 'Einkaufsliste hinzufügen',
      'groceryListName': 'Listenname',
      'emptyGroceryLists': 'Noch keine Einkaufslisten.',
      'emptyGroceryListItems': 'Die Liste ist leer.',
      'items': 'Artikel',
      'addItem': 'Artikel hinzufügen',
      'editItem': 'Artikel bearbeiten',
      'itemName': 'Artikelname',
      'quantity': 'Menge',
      'itemHint': 'Hinweis aus Verlauf',
      'noHints': 'Kein ähnlicher Artikel im Verlauf gefunden.',
      'selectedCategory': 'Ausgewählte Kategorie',
      'noCategorySelected': 'Keine Kategorie ausgewählt',
      'pickCategory': 'Kategorie auswählen',
      'goShoppingFlow': 'Einkaufsroute',
      'finishShopping': 'Einkauf beenden',
      'shoppingDoneIn': 'Super! Du hast deinen Einkauf geschafft in:',
      'undo': 'Rückgängig',
      'step1': '1. Einkaufsliste wählen',
      'step2': '2. Marktlayout wählen',
      'shoppingResult': 'Einkaufsliste in Markt-Reihenfolge',
      'emptyShoppingList': 'Die Liste ist leer!',
      'missingInLayout': 'Kategorie ist im ausgewählten Marktlayout nicht vorhanden',
      'nothingToShow': 'Noch nichts anzuzeigen.',
      'language': 'Sprache',
      'systemLanguage': 'Systemstandard',
      'english': 'Englisch',
      'polish': 'Polnisch',
      'createCategoryFirst': 'Noch keine Kategorien. Füge zuerst eine hinzu.',
      'nameCannotBeEmpty': 'Name darf nicht leer sein.',
      'selectCategoryFirst': 'Wähle zuerst eine Kategorie aus.',
      'maxCategoriesReached': 'Maximale Anzahl an Kategorien erreicht ({max}).',
      'selectListAndMarket':
          'Erstelle mindestens eine Einkaufsliste und ein Marktlayout.',
      'deleteItem': 'Artikel löschen',
      'deleteLayout': 'Marktlayout löschen',
      'deleteList': 'Einkaufsliste löschen',
      'categoryDrinks': 'Getränke',
      'categorySweets': 'Süßigkeiten',
      'categoryFruits': 'Obst',
      'categoryVegetables': 'Gemüse',
      'categoryAlcohol': 'Alkohol',
      'categoryDairy': 'Molkereiprodukte',
      'categoryBakery': 'Bäckerei',
      'categoryMeat': 'Fleisch',
      'categoryFrozen': 'Tiefkühlkost',
      'categoryHousehold': 'Haushalt',
    },
    'nl': {
      'appTitle': 'ShopMaps',
      'market': 'Winkel',
      'groceryList': 'Boodschappenlijst',
      'goShopping': 'Boodschappen doen',
      'add': 'Toevoegen',
      'addCategory': 'Categorie toevoegen',
      'save': 'Opslaan',
      'cancel': 'Annuleren',
      'delete': 'Verwijderen',
      'rename': 'Hernoemen',
      'edit': 'Bewerken',
      'addMarketLayout': 'Winkelindeling toevoegen',
      'editMarketLayout': 'Winkelindeling bewerken',
      'marketLayoutName': 'Winkelnaam',
      'categoriesInOrder': 'Categorieën op volgorde (ingang tot uitgang)',
      'emptyMarketLayouts': 'Nog geen winkelindelingen.',
      'tapToOpen': 'Tik om te openen',
      'addCategoryToLayout': 'Categorie aan indeling toevoegen',
      'addNewCategory': 'Nieuwe categorie toevoegen',
      'newCategoryName': 'Categorienaam',
      'category': 'Categorie',
      'chooseCategory': 'Kies categorie',
      'noCategoriesInLayout': 'Nog geen categorieën in deze winkelindeling.',
      'addGroceryList': 'Boodschappenlijst toevoegen',
      'groceryListName': 'Lijstnaam',
      'emptyGroceryLists': 'Nog geen boodschappenlijsten.',
      'emptyGroceryListItems': 'De lijst is leeg.',
      'items': 'items',
      'addItem': 'Item toevoegen',
      'editItem': 'Item bewerken',
      'itemName': 'Itemnaam',
      'quantity': 'Aantal',
      'itemHint': 'Hint uit geschiedenis',
      'noHints': 'Geen vergelijkbaar item gevonden in de geschiedenis.',
      'selectedCategory': 'Geselecteerde categorie',
      'noCategorySelected': 'Geen categorie geselecteerd',
      'pickCategory': 'Categorie kiezen',
      'goShoppingFlow': 'Winkelroute',
      'finishShopping': 'Boodschappen afronden',
      'shoppingDoneIn': 'Mooi! Je bent klaar met winkelen in:',
      'undo': 'Ongedaan maken',
      'step1': '1. Kies boodschappenlijst',
      'step2': '2. Kies winkelindeling',
      'shoppingResult': 'Boodschappenlijst in winkelvolgorde',
      'emptyShoppingList': 'De lijst is leeg!',
      'missingInLayout': 'Categorie staat niet in de gekozen winkelindeling',
      'nothingToShow': 'Nog niets om te tonen.',
      'language': 'Taal',
      'systemLanguage': 'Systeemstandaard',
      'english': 'Engels',
      'polish': 'Pools',
      'createCategoryFirst': 'Nog geen categorieën. Voeg er eerst één toe.',
      'nameCannotBeEmpty': 'Naam mag niet leeg zijn.',
      'selectCategoryFirst': 'Selecteer eerst een categorie.',
      'maxCategoriesReached': 'Maximaal aantal categorieën bereikt ({max}).',
      'selectListAndMarket':
          'Maak minimaal één boodschappenlijst en één winkelindeling aan.',
      'deleteItem': 'Item verwijderen',
      'deleteLayout': 'Winkelindeling verwijderen',
      'deleteList': 'Boodschappenlijst verwijderen',
      'categoryDrinks': 'Dranken',
      'categorySweets': 'Snoep',
      'categoryFruits': 'Fruit',
      'categoryVegetables': 'Groenten',
      'categoryAlcohol': 'Alcohol',
      'categoryDairy': 'Zuivel',
      'categoryBakery': 'Bakkerij',
      'categoryMeat': 'Vlees',
      'categoryFrozen': 'Diepvries',
      'categoryHousehold': 'Huishouden',
    },
    'es': {
      'appTitle': 'ShopMaps',
      'market': 'Tienda',
      'groceryList': 'Lista de compras',
      'goShopping': 'Ir de compras',
      'add': 'Añadir',
      'addCategory': 'Añadir categoría',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'delete': 'Eliminar',
      'rename': 'Renombrar',
      'edit': 'Editar',
      'addMarketLayout': 'Añadir diseño de tienda',
      'editMarketLayout': 'Editar diseño de tienda',
      'marketLayoutName': 'Nombre de la tienda',
      'categoriesInOrder': 'Categorías en orden (de entrada a salida)',
      'emptyMarketLayouts': 'Aún no hay diseños de tienda.',
      'tapToOpen': 'Toca para abrir',
      'addCategoryToLayout': 'Añadir categoría al diseño',
      'addNewCategory': 'Añadir nueva categoría',
      'newCategoryName': 'Nombre de la categoría',
      'category': 'Categoría',
      'chooseCategory': 'Elegir categoría',
      'noCategoriesInLayout': 'Aún no hay categorías en este diseño de tienda.',
      'addGroceryList': 'Añadir lista de compras',
      'groceryListName': 'Nombre de la lista',
      'emptyGroceryLists': 'Aún no hay listas de compras.',
      'emptyGroceryListItems': 'La lista está vacía.',
      'items': 'elementos',
      'addItem': 'Añadir producto',
      'editItem': 'Editar producto',
      'itemName': 'Nombre del producto',
      'quantity': 'Cantidad',
      'itemHint': 'Sugerencia del historial',
      'noHints': 'No se encontró un producto similar en el historial.',
      'selectedCategory': 'Categoría seleccionada',
      'noCategorySelected': 'No hay categoría seleccionada',
      'pickCategory': 'Elegir categoría',
      'goShoppingFlow': 'Ruta de compras',
      'finishShopping': 'Terminar compra',
      'shoppingDoneIn': '¡Bien! Has terminado tus compras en:',
      'undo': 'Deshacer',
      'step1': '1. Elige la lista de compras',
      'step2': '2. Elige el diseño de tienda',
      'shoppingResult': 'Lista de compras en orden de tienda',
      'emptyShoppingList': '¡La lista está vacía!',
      'missingInLayout': 'La categoría no está en el diseño de tienda seleccionado',
      'nothingToShow': 'Nada que mostrar todavía.',
      'language': 'Idioma',
      'systemLanguage': 'Predeterminado del sistema',
      'english': 'Inglés',
      'polish': 'Polaco',
      'createCategoryFirst': 'Aún no hay categorías. Añade una primero.',
      'nameCannotBeEmpty': 'El nombre no puede estar vacío.',
      'selectCategoryFirst': 'Selecciona una categoría primero.',
      'maxCategoriesReached': 'Se alcanzó el límite máximo de categorías ({max}).',
      'selectListAndMarket':
          'Crea al menos una lista de compras y un diseño de tienda.',
      'deleteItem': 'Eliminar producto',
      'deleteLayout': 'Eliminar diseño de tienda',
      'deleteList': 'Eliminar lista de compras',
      'categoryDrinks': 'Bebidas',
      'categorySweets': 'Dulces',
      'categoryFruits': 'Frutas',
      'categoryVegetables': 'Verduras',
      'categoryAlcohol': 'Alcohol',
      'categoryDairy': 'Lácteos',
      'categoryBakery': 'Panadería',
      'categoryMeat': 'Carne',
      'categoryFrozen': 'Congelados',
      'categoryHousehold': 'Hogar',
    },
    'fr': {
      'appTitle': 'ShopMaps',
      'market': 'Magasin',
      'groceryList': 'Liste de courses',
      'goShopping': 'Faire les courses',
      'add': 'Ajouter',
      'addCategory': 'Ajouter une catégorie',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'rename': 'Renommer',
      'edit': 'Modifier',
      'addMarketLayout': 'Ajouter un plan de magasin',
      'editMarketLayout': 'Modifier le plan du magasin',
      'marketLayoutName': 'Nom du magasin',
      'categoriesInOrder': "Catégories dans l'ordre (de l'entrée à la sortie)",
      'emptyMarketLayouts': "Aucun plan de magasin pour l'instant.",
      'tapToOpen': 'Touchez pour ouvrir',
      'addCategoryToLayout': 'Ajouter une catégorie au plan',
      'addNewCategory': 'Ajouter une nouvelle catégorie',
      'newCategoryName': 'Nom de la catégorie',
      'category': 'Catégorie',
      'chooseCategory': 'Choisir une catégorie',
      'noCategoriesInLayout': "Aucune catégorie dans ce plan de magasin.",
      'addGroceryList': 'Ajouter une liste de courses',
      'groceryListName': 'Nom de la liste',
      'emptyGroceryLists': "Aucune liste de courses pour l'instant.",
      'emptyGroceryListItems': 'La liste est vide.',
      'items': 'articles',
      'addItem': 'Ajouter un article',
      'editItem': "Modifier l'article",
      'itemName': "Nom de l'article",
      'quantity': 'Quantité',
      'itemHint': "Suggestion de l'historique",
      'noHints': "Aucun article similaire trouvé dans l'historique.",
      'selectedCategory': 'Catégorie sélectionnée',
      'noCategorySelected': 'Aucune catégorie sélectionnée',
      'pickCategory': 'Choisir une catégorie',
      'goShoppingFlow': 'Parcours des courses',
      'finishShopping': 'Terminer les courses',
      'shoppingDoneIn': 'Bravo ! Vous avez terminé vos courses en :',
      'undo': 'Annuler',
      'step1': '1. Choisissez la liste de courses',
      'step2': '2. Choisissez le plan du magasin',
      'shoppingResult': 'Liste de courses selon l’ordre du magasin',
      'emptyShoppingList': 'La liste est vide !',
      'missingInLayout': 'Catégorie absente du plan de magasin sélectionné',
      'nothingToShow': 'Rien à afficher pour le moment.',
      'language': 'Langue',
      'systemLanguage': 'Langue du système',
      'english': 'Anglais',
      'polish': 'Polonais',
      'createCategoryFirst': "Aucune catégorie. Ajoutez-en une d'abord.",
      'nameCannotBeEmpty': 'Le nom ne peut pas être vide.',
      'selectCategoryFirst': 'Sélectionnez d’abord une catégorie.',
      'maxCategoriesReached': 'Limite maximale de catégories atteinte ({max}).',
      'selectListAndMarket':
          'Créez au moins une liste de courses et un plan de magasin.',
      'deleteItem': "Supprimer l'article",
      'deleteLayout': 'Supprimer le plan du magasin',
      'deleteList': 'Supprimer la liste de courses',
      'categoryDrinks': 'Boissons',
      'categorySweets': 'Confiseries',
      'categoryFruits': 'Fruits',
      'categoryVegetables': 'Légumes',
      'categoryAlcohol': 'Alcool',
      'categoryDairy': 'Produits laitiers',
      'categoryBakery': 'Boulangerie',
      'categoryMeat': 'Viande',
      'categoryFrozen': 'Surgelés',
      'categoryHousehold': 'Maison',
    },
    'uk': {
      'appTitle': 'ShopMaps',
      'market': 'Магазин',
      'groceryList': 'Список покупок',
      'goShopping': 'Йти за покупками',
      'add': 'Додати',
      'addCategory': 'Додати категорію',
      'save': 'Зберегти',
      'cancel': 'Скасувати',
      'delete': 'Видалити',
      'rename': 'Перейменувати',
      'edit': 'Редагувати',
      'addMarketLayout': 'Додати план магазину',
      'editMarketLayout': 'Редагувати план магазину',
      'marketLayoutName': 'Назва магазину',
      'categoriesInOrder': 'Категорії у порядку (від входу до виходу)',
      'emptyMarketLayouts': 'Ще немає планів магазину.',
      'tapToOpen': 'Натисніть, щоб відкрити',
      'addCategoryToLayout': 'Додати категорію до плану',
      'addNewCategory': 'Додати нову категорію',
      'newCategoryName': 'Назва категорії',
      'category': 'Категорія',
      'chooseCategory': 'Вибрати категорію',
      'noCategoriesInLayout': 'У цьому плані магазину ще немає категорій.',
      'addGroceryList': 'Додати список покупок',
      'groceryListName': 'Назва списку',
      'emptyGroceryLists': 'Ще немає списків покупок.',
      'emptyGroceryListItems': 'Список порожній.',
      'items': 'позицій',
      'addItem': 'Додати товар',
      'editItem': 'Редагувати товар',
      'itemName': 'Назва товару',
      'quantity': 'Кількість',
      'itemHint': 'Підказка з історії',
      'noHints': 'У історії не знайдено схожого товару.',
      'selectedCategory': 'Вибрана категорія',
      'noCategorySelected': 'Категорію не вибрано',
      'pickCategory': 'Вибрати категорію',
      'goShoppingFlow': 'Маршрут покупок',
      'finishShopping': 'Завершити покупки',
      'shoppingDoneIn': 'Чудово! Ви зробили покупки за:',
      'undo': 'Скасувати',
      'step1': '1. Виберіть список покупок',
      'step2': '2. Виберіть план магазину',
      'shoppingResult': 'Список покупок у порядку магазину',
      'emptyShoppingList': 'Список порожній!',
      'missingInLayout': 'Категорія відсутня у вибраному плані магазину',
      'nothingToShow': 'Поки нічого показувати.',
      'language': 'Мова',
      'systemLanguage': 'Системна за замовчуванням',
      'english': 'Англійська',
      'polish': 'Польська',
      'createCategoryFirst': 'Ще немає категорій. Спочатку додайте одну.',
      'nameCannotBeEmpty': 'Назва не може бути порожньою.',
      'selectCategoryFirst': 'Спочатку виберіть категорію.',
      'maxCategoriesReached': 'Досягнуто максимального ліміту категорій ({max}).',
      'selectListAndMarket':
          'Створіть принаймні один список покупок і один план магазину.',
      'deleteItem': 'Видалити товар',
      'deleteLayout': 'Видалити план магазину',
      'deleteList': 'Видалити список покупок',
      'categoryDrinks': 'Напої',
      'categorySweets': 'Солодощі',
      'categoryFruits': 'Фрукти',
      'categoryVegetables': 'Овочі',
      'categoryAlcohol': 'Алкоголь',
      'categoryDairy': 'Молочні продукти',
      'categoryBakery': 'Випічка',
      'categoryMeat': "М'ясо",
      'categoryFrozen': 'Заморожені продукти',
      'categoryHousehold': 'Побутова хімія',
    },
    'it': {
      'appTitle': 'ShopMaps',
      'market': 'Negozio',
      'groceryList': 'Lista della spesa',
      'goShopping': 'Vai a fare la spesa',
      'add': 'Aggiungi',
      'addCategory': 'Aggiungi categoria',
      'save': 'Salva',
      'cancel': 'Annulla',
      'delete': 'Elimina',
      'rename': 'Rinomina',
      'edit': 'Modifica',
      'addMarketLayout': 'Aggiungi layout del negozio',
      'editMarketLayout': 'Modifica layout del negozio',
      'marketLayoutName': 'Nome del negozio',
      'categoriesInOrder': 'Categorie in ordine (dall’ingresso all’uscita)',
      'emptyMarketLayouts': 'Nessun layout negozio ancora.',
      'tapToOpen': 'Tocca per aprire',
      'addCategoryToLayout': 'Aggiungi categoria al layout',
      'addNewCategory': 'Aggiungi nuova categoria',
      'newCategoryName': 'Nome categoria',
      'category': 'Categoria',
      'chooseCategory': 'Scegli categoria',
      'noCategoriesInLayout': 'Nessuna categoria in questo layout negozio.',
      'addGroceryList': 'Aggiungi lista della spesa',
      'groceryListName': 'Nome lista',
      'emptyGroceryLists': 'Nessuna lista della spesa ancora.',
      'emptyGroceryListItems': 'La lista è vuota.',
      'items': 'elementi',
      'addItem': 'Aggiungi articolo',
      'editItem': 'Modifica articolo',
      'itemName': 'Nome articolo',
      'quantity': 'Quantità',
      'itemHint': 'Suggerimento dalla cronologia',
      'noHints': 'Nessun articolo simile trovato nella cronologia.',
      'selectedCategory': 'Categoria selezionata',
      'noCategorySelected': 'Nessuna categoria selezionata',
      'pickCategory': 'Scegli categoria',
      'goShoppingFlow': 'Percorso spesa',
      'finishShopping': 'Termina spesa',
      'shoppingDoneIn': 'Ottimo! Hai finito la spesa in:',
      'undo': 'Annulla',
      'step1': '1. Scegli la lista della spesa',
      'step2': '2. Scegli il layout del negozio',
      'shoppingResult': 'Lista della spesa in ordine del negozio',
      'emptyShoppingList': 'La lista è vuota!',
      'missingInLayout': 'Categoria non presente nel layout negozio selezionato',
      'nothingToShow': 'Niente da mostrare per ora.',
      'language': 'Lingua',
      'systemLanguage': 'Predefinita di sistema',
      'english': 'Inglese',
      'polish': 'Polacco',
      'createCategoryFirst': 'Nessuna categoria ancora. Aggiungine prima una.',
      'nameCannotBeEmpty': 'Il nome non può essere vuoto.',
      'selectCategoryFirst': 'Seleziona prima una categoria.',
      'maxCategoriesReached': 'Raggiunto il limite massimo di categorie ({max}).',
      'selectListAndMarket':
          'Crea almeno una lista della spesa e un layout del negozio.',
      'deleteItem': 'Elimina articolo',
      'deleteLayout': 'Elimina layout del negozio',
      'deleteList': 'Elimina lista della spesa',
      'categoryDrinks': 'Bevande',
      'categorySweets': 'Dolci',
      'categoryFruits': 'Frutta',
      'categoryVegetables': 'Verdure',
      'categoryAlcohol': 'Alcolici',
      'categoryDairy': 'Latticini',
      'categoryBakery': 'Panetteria',
      'categoryMeat': 'Carne',
      'categoryFrozen': 'Surgelati',
      'categoryHousehold': 'Casa',
    },
    'pt': {
      'appTitle': 'ShopMaps',
      'market': 'Loja',
      'groceryList': 'Lista de compras',
      'goShopping': 'Ir às compras',
      'add': 'Adicionar',
      'addCategory': 'Adicionar categoria',
      'save': 'Salvar',
      'cancel': 'Cancelar',
      'delete': 'Excluir',
      'rename': 'Renomear',
      'edit': 'Editar',
      'addMarketLayout': 'Adicionar layout da loja',
      'editMarketLayout': 'Editar layout da loja',
      'marketLayoutName': 'Nome da loja',
      'categoriesInOrder': 'Categorias em ordem (da entrada à saída)',
      'emptyMarketLayouts': 'Ainda não há layouts de loja.',
      'tapToOpen': 'Toque para abrir',
      'addCategoryToLayout': 'Adicionar categoria ao layout',
      'addNewCategory': 'Adicionar nova categoria',
      'newCategoryName': 'Nome da categoria',
      'category': 'Categoria',
      'chooseCategory': 'Escolher categoria',
      'noCategoriesInLayout': 'Ainda não há categorias neste layout de loja.',
      'addGroceryList': 'Adicionar lista de compras',
      'groceryListName': 'Nome da lista',
      'emptyGroceryLists': 'Ainda não há listas de compras.',
      'emptyGroceryListItems': 'A lista está vazia.',
      'items': 'itens',
      'addItem': 'Adicionar item',
      'editItem': 'Editar item',
      'itemName': 'Nome do item',
      'quantity': 'Quantidade',
      'itemHint': 'Dica do histórico',
      'noHints': 'Nenhum item semelhante encontrado no histórico.',
      'selectedCategory': 'Categoria selecionada',
      'noCategorySelected': 'Nenhuma categoria selecionada',
      'pickCategory': 'Escolher categoria',
      'goShoppingFlow': 'Rota de compras',
      'finishShopping': 'Finalizar compras',
      'shoppingDoneIn': 'Ótimo! Você terminou suas compras em:',
      'undo': 'Desfazer',
      'step1': '1. Escolha a lista de compras',
      'step2': '2. Escolha o layout da loja',
      'shoppingResult': 'Lista de compras na ordem da loja',
      'emptyShoppingList': 'A lista está vazia!',
      'missingInLayout': 'Categoria não presente no layout da loja selecionado',
      'nothingToShow': 'Nada para mostrar ainda.',
      'language': 'Idioma',
      'systemLanguage': 'Padrão do sistema',
      'english': 'Inglês',
      'polish': 'Polonês',
      'createCategoryFirst': 'Ainda não há categorias. Adicione uma primeiro.',
      'nameCannotBeEmpty': 'O nome não pode estar vazio.',
      'selectCategoryFirst': 'Selecione uma categoria primeiro.',
      'maxCategoriesReached': 'Limite máximo de categorias atingido ({max}).',
      'selectListAndMarket':
          'Crie pelo menos uma lista de compras e um layout de loja.',
      'deleteItem': 'Excluir item',
      'deleteLayout': 'Excluir layout da loja',
      'deleteList': 'Excluir lista de compras',
      'categoryDrinks': 'Bebidas',
      'categorySweets': 'Doces',
      'categoryFruits': 'Frutas',
      'categoryVegetables': 'Vegetais',
      'categoryAlcohol': 'Álcool',
      'categoryDairy': 'Laticínios',
      'categoryBakery': 'Padaria',
      'categoryMeat': 'Carne',
      'categoryFrozen': 'Congelados',
      'categoryHousehold': 'Casa',
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
  String get emptyGroceryListItems => _t('emptyGroceryListItems');
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
  String get shoppingDoneIn => _t('shoppingDoneIn');
  String get undo => _t('undo');
  String get step1 => _t('step1');
  String get step2 => _t('step2');
  String get shoppingResult => _t('shoppingResult');
  String get emptyShoppingList => _t('emptyShoppingList');
  String get missingInLayout => _t('missingInLayout');
  String get nothingToShow => _t('nothingToShow');
  String get language => _t('language');
  String get systemLanguage => _t('systemLanguage');
  String get english => _t('english');
  String get polish => _t('polish');
  String get createCategoryFirst => _t('createCategoryFirst');
  String get nameCannotBeEmpty => _t('nameCannotBeEmpty');
  String get selectCategoryFirst => _t('selectCategoryFirst');
  String maxCategoriesReached(int max) => _t('maxCategoriesReached').replaceAll('{max}', '$max');
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

  String shoppingDoneMessage(int minutes, int seconds) {
    return '🎆🎆🎆 ${_t('shoppingDoneIn')} ${shoppingDurationLabel(minutes, seconds)}!';
  }

  String shoppingDurationLabel(int minutes, int seconds) {
    switch (locale.languageCode) {
      case 'pl':
        return '$minutes ${_polishMinuteLabel(minutes)} i $seconds ${_polishSecondLabel(seconds)}';
      case 'de':
        return '$minutes ${minutes == 1 ? 'Minute' : 'Minuten'} und '
            '$seconds ${seconds == 1 ? 'Sekunde' : 'Sekunden'}';
      case 'nl':
        return '$minutes ${minutes == 1 ? 'minuut' : 'minuten'} en '
            '$seconds ${seconds == 1 ? 'seconde' : 'seconden'}';
      case 'es':
        return '$minutes ${minutes == 1 ? 'minuto' : 'minutos'} y '
            '$seconds ${seconds == 1 ? 'segundo' : 'segundos'}';
      case 'fr':
        return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} et '
            '$seconds ${seconds == 1 ? 'seconde' : 'secondes'}';
      case 'uk':
        return '$minutes ${_ukrainianMinuteLabel(minutes)} і '
            '$seconds ${_ukrainianSecondLabel(seconds)}';
      case 'it':
        return '$minutes ${minutes == 1 ? 'minuto' : 'minuti'} e '
            '$seconds ${seconds == 1 ? 'secondo' : 'secondi'}';
      case 'pt':
        return '$minutes ${minutes == 1 ? 'minuto' : 'minutos'} e '
            '$seconds ${seconds == 1 ? 'segundo' : 'segundos'}';
      default:
        final minuteLabel = minutes == 1 ? 'minute' : 'minutes';
        final secondLabel = seconds == 1 ? 'second' : 'seconds';
        return '$minutes $minuteLabel and $seconds $secondLabel';
    }
  }

  String _polishMinuteLabel(int value) {
    if (_isPolishOne(value)) {
      return 'minuta';
    }
    if (_isPolishFew(value)) {
      return 'minuty';
    }
    return 'minut';
  }

  String _polishSecondLabel(int value) {
    if (_isPolishOne(value)) {
      return 'sekunda';
    }
    if (_isPolishFew(value)) {
      return 'sekundy';
    }
    return 'sekund';
  }

  String _ukrainianMinuteLabel(int value) {
    if (_isSlavicOne(value)) {
      return 'хвилина';
    }
    if (_isSlavicFew(value)) {
      return 'хвилини';
    }
    return 'хвилин';
  }

  String _ukrainianSecondLabel(int value) {
    if (_isSlavicOne(value)) {
      return 'секунда';
    }
    if (_isSlavicFew(value)) {
      return 'секунди';
    }
    return 'секунд';
  }

  bool _isPolishOne(int value) {
    return _isSlavicOne(value);
  }

  bool _isPolishFew(int value) {
    return _isSlavicFew(value);
  }

  bool _isSlavicOne(int value) {
    final mod10 = value % 10;
    final mod100 = value % 100;
    return mod10 == 1 && mod100 != 11;
  }

  bool _isSlavicFew(int value) {
    final mod10 = value % 10;
    final mod100 = value % 100;
    return mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14);
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
