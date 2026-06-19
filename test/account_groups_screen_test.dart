import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopmaps/app_controller.dart';
import 'package:shopmaps/cloud/cloud_controller.dart';
import 'package:shopmaps/cloud/cloud_localizations.dart';
import 'package:shopmaps/cloud/cloud_models.dart';
import 'package:shopmaps/l10n/app_localizations.dart';
import 'package:shopmaps/local_store.dart';
import 'package:shopmaps/models.dart';
import 'package:shopmaps/screens/account_groups_screen.dart';

class _NotifyingCloudController extends CloudController {
  _NotifyingCloudController() : super(null);

  @override
  Future<void> refreshSharedData() async {
    notifyListeners();
  }
}

class _GroupMembersCloudController extends CloudController {
  _GroupMembersCloudController() : super(null);

  bool leaveRequested = false;

  @override
  Future<List<CloudGroupMember>> loadGroupMembers(String groupId) async {
    return const [
      CloudGroupMember(userId: 'anna-id', displayName: 'Anna', role: 'owner'),
      CloudGroupMember(userId: 'jan-id', displayName: 'Jan', role: 'member'),
    ];
  }

  @override
  Future<void> refreshSharedData() async {}

  @override
  Future<bool> leaveGroup(String groupId) async {
    leaveRequested = true;
    return true;
  }
}

class _SynchronousRefreshCloudController extends CloudController {
  _SynchronousRefreshCloudController() : super(null);

  @override
  Future<void> refresh() async {
    notifyListeners();
  }
}

class _LoadingProfileCloudController extends CloudController {
  _LoadingProfileCloudController() : super(null);

  @override
  bool get isConfigured => true;

  @override
  bool get isSignedIn => true;

  @override
  bool get isProfileLoading => true;
}

class _ProfileSetupCloudController extends CloudController {
  _ProfileSetupCloudController({this.currentProfile}) : super(null);

  CloudProfile? currentProfile;
  String? completedDisplayName;
  String? completedCountryCode;
  String? updatedCountryCode;

  @override
  bool get isConfigured => true;

  @override
  bool get isSignedIn => true;

  @override
  bool get isProfileLoading => false;

  @override
  bool get needsProfile =>
      currentProfile == null || !currentProfile!.hasStoreCountry;

  @override
  CloudProfile? get profile => currentProfile;

  @override
  Future<bool> completeProfile({
    required String displayName,
    required String countryCode,
  }) async {
    completedDisplayName = displayName;
    completedCountryCode = countryCode;
    currentProfile = CloudProfile(
      id: 'user-id',
      displayName: displayName,
      discriminator: 7,
      countryCode: countryCode,
    );
    notifyListeners();
    return true;
  }

  @override
  Future<bool> updateProfileCountry(String countryCode) async {
    updatedCountryCode = countryCode;
    final profile = currentProfile;
    if (profile != null) {
      currentProfile = CloudProfile(
        id: profile.id,
        displayName: profile.displayName,
        discriminator: profile.discriminator,
        countryCode: countryCode,
      );
    }
    notifyListeners();
    return true;
  }
}

class _SignedOutCloudController extends CloudController {
  _SignedOutCloudController() : super(null);

  bool facebookSignInRequested = false;

  @override
  bool get isConfigured => true;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> signInWithFacebook() async {
    facebookSignInRequested = true;
  }
}

class _DeletableCloudController extends CloudController {
  _DeletableCloudController() : super(null);

  bool deleteRequested = false;

  @override
  bool get isConfigured => true;

  @override
  bool get isSignedIn => true;

  @override
  bool get isProfileLoading => false;

  @override
  bool get needsProfile => false;

  @override
  CloudProfile get profile => const CloudProfile(
    id: 'user-id',
    displayName: 'Endriu',
    discriminator: 42,
    countryCode: 'pl',
  );

  @override
  Future<bool> deleteAccount() async {
    deleteRequested = true;
    return true;
  }
}

class _InvitedCloudController extends CloudController {
  _InvitedCloudController() : super(null);

  bool? acceptedInvite;
  List<CloudGroupInvite> pendingInvites = const [
    CloudGroupInvite(
      id: 'invite-id',
      spaceId: 'group-id',
      groupName: 'Dom',
      inviterHandle: 'Endriu#0042',
    ),
  ];

  @override
  bool get isConfigured => true;

  @override
  bool get isSignedIn => true;

  @override
  bool get isProfileLoading => false;

  @override
  bool get needsProfile => false;

  @override
  CloudProfile get profile => const CloudProfile(
    id: 'user-id',
    displayName: 'Tester',
    discriminator: 8533,
    countryCode: 'pl',
  );

  @override
  List<CloudGroupInvite> get invites => pendingInvites;

  @override
  Future<void> refresh() async {}

  @override
  Future<bool> respondToInvite({
    required String inviteId,
    required bool accept,
  }) async {
    acceptedInvite = accept;
    pendingInvites = const [];
    notifyListeners();
    return true;
  }
}

class _SharingCloudController extends CloudController {
  _SharingCloudController({this.sharedList}) : super(null);

  SharedGroceryList? sharedList;
  bool shareRequested = false;
  bool stopSharingRequested = false;

  @override
  List<SharedGroceryList> get sharedLists => [?sharedList];

  @override
  Future<void> refreshSharedData() async {}

  @override
  Future<bool> shareListWithGroup({
    required String groupId,
    required GroceryListModel list,
  }) async {
    shareRequested = true;
    sharedList = SharedGroceryList(
      id: 'shared-list-id',
      spaceId: groupId,
      groupName: 'Dom',
      name: list.name,
      items: list.items,
      sourceLocalId: list.id,
    );
    notifyListeners();
    return true;
  }

  @override
  Future<SharedGroceryList?> fetchSharedList(String listId) async => sharedList;

  @override
  Future<bool> deleteSharedList(String listId) async {
    stopSharingRequested = true;
    sharedList = null;
    notifyListeners();
    return true;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('signed-out page has the Polish Logowanie title', () {
    expect(CloudLocalizations('pl').text('signIn'), 'Logowanie');
  });

  testWidgets('Android login shows Facebook and Google but hides Apple', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final cloudController = _SignedOutCloudController();
    final appController = AppController(LocalStore());

    await tester.pumpWidget(
      _localizedApp(
        AccountGroupsScreen(
          cloudController: cloudController,
          appController: appController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kontynuuj z Facebookiem'), findsOneWidget);
    expect(find.text('Kontynuuj z Google'), findsOneWidget);
    expect(find.text('Kontynuuj z Apple'), findsNothing);

    await tester.tap(find.text('Kontynuuj z Facebookiem'));
    expect(cloudController.facebookSignInRequested, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('iOS login shows Facebook, Google, and Apple', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final cloudController = _SignedOutCloudController();
    final appController = AppController(LocalStore());

    await tester.pumpWidget(
      _localizedApp(
        AccountGroupsScreen(
          cloudController: cloudController,
          appController: appController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kontynuuj z Facebookiem'), findsOneWidget);
    expect(find.text('Kontynuuj z Google'), findsOneWidget);
    expect(find.text('Kontynuuj z Apple'), findsOneWidget);
    final appleButton = find.widgetWithText(FilledButton, 'Kontynuuj z Apple');
    final googleButton = find.widgetWithText(
      OutlinedButton,
      'Kontynuuj z Google',
    );
    final facebookButton = find.widgetWithText(
      OutlinedButton,
      'Kontynuuj z Facebookiem',
    );
    expect(
      tester.getSize(appleButton).height,
      tester.getSize(googleButton).height,
    );
    expect(
      tester.getSize(googleButton).height,
      tester.getSize(facebookButton).height,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('shows only a loader while the signed-in profile is loading', (
    tester,
  ) async {
    final cloudController = _LoadingProfileCloudController();
    final appController = AppController(LocalStore());

    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: AccountGroupsScreen(
          cloudController: cloudController,
          appController: appController,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Enter your username'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('new profile setup asks for username and store country', (
    tester,
  ) async {
    final cloudController = _ProfileSetupCloudController();
    final appController = AppController(LocalStore());

    await tester.pumpWidget(
      _localizedApp(
        AccountGroupsScreen(
          cloudController: cloudController,
          appController: appController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Podaj swoją nazwę użytkownika'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Publiczna nazwa'), findsOneWidget);
    expect(find.text('Kraj sklepów'), findsOneWidget);
    expect(find.text('Polska'), findsOneWidget);
    final nameCard = tester.element(
      find
          .ancestor(
            of: find.text('Podaj swoją nazwę użytkownika'),
            matching: find.byType(Card),
          )
          .first,
    );
    final countryCard = tester.element(
      find
          .ancestor(of: find.text('Kraj sklepów'), matching: find.byType(Card))
          .first,
    );
    expect(nameCard, isNot(countryCard));

    await tester.enterText(
      find.widgetWithText(TextField, 'Publiczna nazwa'),
      'Endriu',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Utwórz profil'));
    await tester.pumpAndSettle();

    expect(cloudController.completedDisplayName, 'Endriu');
    expect(cloudController.completedCountryCode, 'pl');

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('legacy profile without a country asks only for store country', (
    tester,
  ) async {
    final cloudController = _ProfileSetupCloudController(
      currentProfile: const CloudProfile(
        id: 'user-id',
        displayName: 'Legacy',
        discriminator: 7,
      ),
    );
    final appController = AppController(LocalStore());

    await tester.pumpWidget(
      _localizedApp(
        AccountGroupsScreen(
          cloudController: cloudController,
          appController: appController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Legacy#0007'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Polska'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Zapisz kraj'));
    await tester.pumpAndSettle();

    expect(cloudController.updatedCountryCode, 'pl');

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('opening groups does not notify listeners during build', (
    tester,
  ) async {
    final cloudController = _SynchronousRefreshCloudController();
    final appController = AppController(LocalStore());

    await tester.pumpWidget(
      _localizedApp(
        AccountGroupsScreen(
          cloudController: cloudController,
          appController: appController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('profile country can be changed later', (tester) async {
    final cloudController = _ProfileSetupCloudController(
      currentProfile: const CloudProfile(
        id: 'user-id',
        displayName: 'Endriu',
        discriminator: 42,
        countryCode: 'pl',
      ),
    );
    final appController = AppController(LocalStore());

    await tester.pumpWidget(
      _localizedApp(
        AccountGroupsScreen(
          cloudController: cloudController,
          appController: appController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Zmień kraj'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Polska').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Niemcy').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Zapisz kraj'));
    await tester.pumpAndSettle();

    expect(cloudController.updatedCountryCode, 'de');
    expect(find.text('Kraj sklepów został zaktualizowany.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('account deletion keeps local grocery lists', (tester) async {
    final cloudController = _DeletableCloudController();
    final appController = AppController(LocalStore());
    await appController.load();
    await appController.createGroceryList('Local list');

    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: AccountGroupsScreen(
          cloudController: cloudController,
          appController: appController,
        ),
      ),
    );

    final deleteButton = find.widgetWithText(OutlinedButton, 'Delete account');
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete account'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    expect(cloudController.deleteRequested, isTrue);
    expect(appController.groceryLists.single.name, 'Local list');

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('signed-in label is displayed above the user handle', (
    tester,
  ) async {
    final cloudController = _DeletableCloudController();
    final appController = AppController(LocalStore());

    await tester.pumpWidget(
      _localizedApp(
        AccountGroupsScreen(
          cloudController: cloudController,
          appController: appController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final signedInLabel = find.text('Zalogowano jako');
    final handle = find.text('Endriu#0042');
    expect(signedInLabel, findsOneWidget);
    expect(handle, findsOneWidget);
    expect(
      tester.getTopLeft(signedInLabel).dy,
      lessThan(tester.getTopLeft(handle).dy),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('pending group invitation can be accepted or declined', (
    tester,
  ) async {
    final cloudController = _InvitedCloudController();
    final appController = AppController(LocalStore());

    await tester.pumpWidget(
      _localizedApp(
        AccountGroupsScreen(
          cloudController: cloudController,
          appController: appController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Zaproszenia'), findsOneWidget);
    expect(find.text('Dom'), findsOneWidget);
    expect(find.text('Zaprasza: Endriu#0042'), findsOneWidget);
    expect(find.text('Odrzuć'), findsOneWidget);
    expect(find.text('Akceptuj'), findsOneWidget);

    await tester.tap(find.text('Akceptuj'));
    await tester.pumpAndSettle();

    expect(cloudController.acceptedInvite, isTrue);
    expect(find.text('Zaproszenia'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('group details can notify listeners while loading after mount', (
    tester,
  ) async {
    final cloudController = _NotifyingCloudController();
    final appController = AppController(LocalStore());
    const group = CloudGroup(id: 'group-id', name: 'Group', role: 'member');

    await tester.pumpWidget(
      MaterialApp(
        home: ListenableBuilder(
          listenable: cloudController,
          builder: (context, _) => GroupDetailsScreen(
            group: group,
            cloudController: cloudController,
            appController: appController,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('group details show member nicknames without tags', (
    tester,
  ) async {
    final cloudController = _GroupMembersCloudController();
    final appController = AppController(LocalStore());

    await tester.pumpWidget(
      _localizedApp(
        GroupDetailsScreen(
          group: const CloudGroup(id: 'group-id', name: 'Dom', role: 'member'),
          cloudController: cloudController,
          appController: appController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Członkowie'), findsOneWidget);
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('Jan'), findsOneWidget);
    expect(find.textContaining('#'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('group details allow the user to leave after confirmation', (
    tester,
  ) async {
    final cloudController = _GroupMembersCloudController();
    final appController = AppController(LocalStore());

    await tester.pumpWidget(
      _localizedApp(
        GroupDetailsScreen(
          group: const CloudGroup(id: 'group-id', name: 'Dom', role: 'member'),
          cloudController: cloudController,
          appController: appController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'Opuść grupę'),
      300,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Opuść grupę'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Utracisz dostęp'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Opuść grupę'));
    await tester.pumpAndSettle();

    expect(cloudController.leaveRequested, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets('sharing moves a local list into the group without a duplicate', (
    tester,
  ) async {
    final cloudController = _SharingCloudController();
    final appController = AppController(LocalStore());
    await appController.load(localeLanguageCode: 'pl');
    await appController.upsertGroceryList(
      const GroceryListModel(id: 'local-id', name: 'Lista X', items: []),
    );

    await tester.pumpWidget(
      _localizedApp(
        GroupDetailsScreen(
          group: const CloudGroup(id: 'group-id', name: 'Dom', role: 'member'),
          cloudController: cloudController,
          appController: appController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Udostępnij lokalną listę'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lista X (0)'));
    await tester.pumpAndSettle();

    expect(cloudController.shareRequested, isTrue);
    expect(appController.groceryLists, isEmpty);
    expect(find.text('Lista X'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    cloudController.dispose();
    appController.dispose();
  });

  testWidgets(
    'stopping sharing restores the private list and removes group data',
    (tester) async {
      final cloudController = _SharingCloudController(
        sharedList: const SharedGroceryList(
          id: 'shared-list-id',
          spaceId: 'group-id',
          groupName: 'Dom',
          name: 'Lista X',
          sourceLocalId: 'local-id',
          items: [
            GroceryItem(
              id: 'item-id',
              name: 'Mleko',
              category: 'Nabiał',
              quantity: 1,
            ),
          ],
        ),
      );
      final appController = AppController(LocalStore());
      await appController.load(localeLanguageCode: 'pl');

      await tester.pumpWidget(
        _localizedApp(
          GroupDetailsScreen(
            group: const CloudGroup(
              id: 'group-id',
              name: 'Dom',
              role: 'member',
            ),
            cloudController: cloudController,
            appController: appController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Przestań udostępniać'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Przestań udostępniać'),
      );
      await tester.pumpAndSettle();

      expect(cloudController.stopSharingRequested, isTrue);
      expect(cloudController.sharedLists, isEmpty);
      expect(appController.groceryLists.single.id, 'local-id');
      expect(appController.groceryLists.single.items.single.name, 'Mleko');

      await tester.pumpWidget(const SizedBox.shrink());
      cloudController.dispose();
      appController.dispose();
    },
  );
}

Widget _localizedApp(Widget home) {
  return MaterialApp(
    locale: const Locale('pl'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}
