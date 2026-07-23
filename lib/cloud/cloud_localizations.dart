import 'package:flutter/widgets.dart';

import 'cloud_controller.dart';
import 'supabase_config.dart';

class CloudLocalizations {
  CloudLocalizations(this.languageCode);

  factory CloudLocalizations.of(BuildContext context) {
    return CloudLocalizations(Localizations.localeOf(context).languageCode);
  }

  final String languageCode;

  static const _values = <String, Map<String, String>>{
    'en': {
      'account': 'Account',
      'localMode': 'Local mode',
      'localModeDescription':
          'Sign in only when you want to create groups and share lists or deposit codes.',
      'notConfigured': 'Supabase is not configured in this build.',
      'signIn': 'Sign in',
      'signInApple': 'Continue with Apple',
      'signInGoogle': 'Continue with Google',
      'signInFacebook': 'Continue with Facebook',
      'completeProfile': 'Enter your username',
      'completeProfileDescription': 'Your username is used to join groups.',
      'displayName': 'Public name',
      'storeCountry': 'Store country',
      'chooseStoreCountry': 'Choose store country',
      'changeStoreCountry': 'Change country',
      'saveStoreCountry': 'Save country',
      'storeCountryUpdated': 'Store country updated.',
      'createProfile': 'Create profile',
      'signedInAs': 'Signed in as',
      'signOut': 'Sign out',
      'deleteAccount': 'Delete account',
      'deleteAccountDescription':
          'Permanently deletes your profile, memberships, invitations, and data you shared in groups. Local data on this device and data shared by other members will remain.',
      'accountDeleted': 'Account deleted. Local data remains on this device.',
      'groups': 'Groups',
      'createGroup': 'Create group',
      'groupName': 'Group name',
      'emptyGroups': 'You do not belong to any groups yet.',
      'invitations': 'Invitations',
      'invitedBy': 'Invited by',
      'accept': 'Accept',
      'decline': 'Decline',
      'inviteMember': 'Invite member',
      'memberHandle': 'Name#1234',
      'sendInvite': 'Send invitation',
      'invitationSent': 'Invitation sent.',
      'members': 'Members',
      'emptyMembers': 'No group members.',
      'leaveGroup': 'Leave group',
      'leaveGroupDescription':
          'You will lose access to the data shared in this group. If you are the owner, ownership will be transferred to another member. A group with no other members will be deleted.',
      'sharedLists': 'Shared grocery lists',
      'sharedDeposits': 'Shared deposit codes',
      'shareLocalList': 'Share local list',
      'shareListExplanation':
          'The list will be moved to the group and removed from private lists on this device.',
      'sharedToGroup': 'List shared with the group.',
      'stopSharing': 'Stop sharing',
      'stopSharingExplanation':
          'The list will become private on this device and will no longer be available to anyone in the group.',
      'stoppedSharing': 'The list is private again.',
      'copyLocalList': 'Copy local list',
      'moveLocalDeposit': 'Move local deposit code',
      'copyListExplanation':
          'A separate copy will be created in the group. Your local list will remain unchanged.',
      'moveDepositExplanation':
          'The deposit code will be moved to the group after you select its store from the catalog.',
      'selectCanonicalStore': 'Select store',
      'selectCanonicalStoreDescription':
          'Find the address and select the matching store from the catalog.',
      'canonicalStoreRequired':
          'Select a store from the verified store catalog.',
      'storeCountryMismatch':
          'Select a store from the country set in your profile.',
      'genericOnlineError': 'Something went wrong. Try again.',
      'emptySharedLists': 'No shared grocery lists yet.',
      'emptySharedDeposits': 'No shared deposit codes yet.',
      'copiedToGroup': 'List copied to the group.',
      'movedToGroup': 'Deposit code moved to the group.',
      'membersCanEdit': 'All group members can access this data.',
      'myStoreMaps': 'My maps',
      'publicStoreMaps': 'Search',
      'share': 'Share',
      'shareStoreMap': 'Share store map',
      'selectStoreMapToShare': 'Select map to share',
      'updateSharedStoreMap': 'Update shared map',
      'unshareStoreMap': 'Stop sharing',
      'storeName': 'Store name',
      'storeNameFallbackHint':
          'Select a nearby store or enter its name manually.',
      'storeAddress': 'Store address',
      'addressHint': 'Start typing and select an address from the list.',
      'addressNoResults': 'No matching addresses.',
      'addressTooShort': 'Enter at least 3 characters.',
      'nearbyStores': 'Stores nearest to this address',
      'nearbyStoresNoResults':
          'No nearby stores found. Try a different address.',
      'publishStoreMap': 'Publish map',
      'matchStoreMapCategories': 'Match categories',
      'matchStoreMapCategoriesDescription':
          'Choose the public category that matches each local category before publishing.',
      'selectOnlineCategory': 'Public category',
      'categoryMappingRequired': 'Match all map categories before publishing.',
      'storeMapPublished': 'Store map published.',
      'storeMapAlreadyExists':
          'An identical layout for this store is already shared.',
      'storeMapUnpublished': 'Store map is no longer shared.',
      'emptyPublicStoreMaps': 'No shared store maps yet.',
      'signInToBrowseStoreMaps': 'Sign in to browse and share store maps.',
      'completeProfileToBrowseStoreMaps':
          'Complete your profile to browse and share store maps.',
      'copyStoreMap': 'Add to my stores',
      'storeMapCopied': 'Store map added to your maps.',
      'storeMapAlreadyAdded': 'Already in my stores',
      'reportStoreMap': 'Report map',
      'hideUserMaps': 'Hide maps from this user',
      'hideUserMapsConfirmation':
          'You will no longer see maps shared by {user}.',
      'hideUserMapsAction': 'Hide maps',
      'userMapsHidden': 'Maps from this user are now hidden.',
      'reportReasonIncorrect': 'Incorrect or outdated information',
      'reportReasonInappropriate': 'Inappropriate content',
      'reportReasonOther': 'Other issue',
      'reportSubmitted': 'The map was reported.',
      'contentRejected':
          'The content contains prohibited or offensive words. Change it and try again.',
      'sharedBy': 'Shared by',
      'findNearMe': 'Find near me',
      'clearLocation': 'Clear location',
      'locationServicesDisabled':
          'Location services are disabled. Enable them to find nearby stores.',
      'locationPermissionDenied':
          'Location permission is required to find nearby stores.',
      'locationPermissionDeniedForever':
          'Allow location access in settings to find nearby stores.',
      'locationUnavailable':
          'Your current location could not be determined. Try again.',
      'openSettings': 'Settings',
      'legalInformation': 'Legal information',
      'privacyPolicy': 'Privacy policy',
      'termsOfService': 'Terms of service',
      'accountDeletionPage': 'Account deletion',
      'support': 'Support',
      'searchSharedStores': 'Search stores or addresses',
      'poweredByGeoapify': 'Geoapify, © OpenStreetMap contributors',
      'mapsCountLabel': 'Maps',
      'downloadsCountLabel': 'Downloads',
      'back': 'Back',
    },
    'pl': {
      'account': 'Konto',
      'localMode': 'Tryb lokalny',
      'localModeDescription':
          'Zaloguj się tylko wtedy, gdy chcesz tworzyć grupy i udostępniać listy lub kody kaucji.',
      'notConfigured':
          'Supabase nie jest skonfigurowany w tej wersji aplikacji.',
      'signIn': 'Logowanie',
      'signInApple': 'Kontynuuj z Apple',
      'signInGoogle': 'Kontynuuj z Google',
      'signInFacebook': 'Kontynuuj z Facebookiem',
      'completeProfile': 'Podaj swoją nazwę użytkownika',
      'completeProfileDescription':
          'Nazwa użytkownika jest używana do dołączania do grup.',
      'displayName': 'Publiczna nazwa',
      'storeCountry': 'Kraj sklepów',
      'chooseStoreCountry': 'Wybierz kraj sklepów',
      'changeStoreCountry': 'Zmień kraj',
      'saveStoreCountry': 'Zapisz kraj',
      'storeCountryUpdated': 'Kraj sklepów został zaktualizowany.',
      'createProfile': 'Utwórz profil',
      'signedInAs': 'Zalogowano jako',
      'signOut': 'Wyloguj się',
      'deleteAccount': 'Usuń konto',
      'deleteAccountDescription':
          'Trwale usuwa Twój profil, członkostwa, zaproszenia oraz dane udostępnione przez Ciebie w grupach. Lokalne dane na tym urządzeniu i dane innych członków pozostaną.',
      'accountDeleted':
          'Konto zostało usunięte. Lokalne dane pozostały na tym urządzeniu.',
      'groups': 'Grupy',
      'createGroup': 'Utwórz grupę',
      'groupName': 'Nazwa grupy',
      'emptyGroups': 'Nie należysz jeszcze do żadnej grupy.',
      'invitations': 'Zaproszenia',
      'invitedBy': 'Zaprasza',
      'accept': 'Akceptuj',
      'decline': 'Odrzuć',
      'inviteMember': 'Zaproś osobę',
      'memberHandle': 'Nazwa#1234',
      'sendInvite': 'Wyślij zaproszenie',
      'invitationSent': 'Zaproszenie wysłane.',
      'members': 'Członkowie',
      'emptyMembers': 'Brak członków grupy.',
      'leaveGroup': 'Opuść grupę',
      'leaveGroupDescription':
          'Utracisz dostęp do danych udostępnionych w tej grupie. Jeśli jesteś właścicielem, własność zostanie przekazana innemu członkowi. Grupa bez innych członków zostanie usunięta.',
      'sharedLists': 'Współdzielone listy zakupów',
      'sharedDeposits': 'Współdzielone kody kaucji',
      'shareLocalList': 'Udostępnij lokalną listę',
      'shareListExplanation':
          'Lista zostanie przeniesiona do grupy i usunięta z prywatnych list na tym urządzeniu.',
      'sharedToGroup': 'Lista została udostępniona grupie.',
      'stopSharing': 'Przestań udostępniać',
      'stopSharingExplanation':
          'Lista ponownie stanie się prywatna na tym urządzeniu i przestanie być dostępna dla wszystkich członków grupy.',
      'stoppedSharing': 'Lista ponownie jest prywatna.',
      'copyLocalList': 'Kopiuj lokalną listę',
      'moveLocalDeposit': 'Przenieś lokalny kod kaucji',
      'copyListExplanation':
          'W grupie powstanie osobna kopia. Twoja lokalna lista pozostanie bez zmian.',
      'moveDepositExplanation':
          'Kod kaucji zostanie przeniesiony do grupy po wybraniu sklepu z katalogu.',
      'selectCanonicalStore': 'Wybierz sklep',
      'selectCanonicalStoreDescription':
          'Znajdź adres i wybierz właściwy sklep z katalogu.',
      'canonicalStoreRequired':
          'Wybierz sklep ze zweryfikowanego katalogu sklepów.',
      'storeCountryMismatch': 'Wybierz sklep z kraju ustawionego w profilu.',
      'genericOnlineError': 'Coś poszło nie tak. Spróbuj ponownie.',
      'emptySharedLists': 'Brak współdzielonych list zakupów.',
      'emptySharedDeposits': 'Brak współdzielonych kodów kaucji.',
      'copiedToGroup': 'Lista została skopiowana do grupy.',
      'movedToGroup': 'Kod kaucji został przeniesiony do grupy.',
      'membersCanEdit': 'Wszyscy członkowie grupy mają dostęp do tych danych.',
      'myStoreMaps': 'Moje mapy',
      'publicStoreMaps': 'Szukaj',
      'share': 'Udostępnij',
      'shareStoreMap': 'Udostępnij mapę sklepu',
      'selectStoreMapToShare': 'Wybierz mapę do udostępnienia',
      'updateSharedStoreMap': 'Aktualizuj udostępnioną mapę',
      'unshareStoreMap': 'Przestań udostępniać',
      'storeName': 'Nazwa sklepu',
      'storeNameFallbackHint':
          'Wybierz pobliski sklep lub wpisz jego nazwę ręcznie.',
      'storeAddress': 'Adres sklepu',
      'addressHint': 'Zacznij pisać i wybierz adres z listy.',
      'addressNoResults': 'Brak pasujących adresów.',
      'addressTooShort': 'Wpisz przynajmniej 3 znaki.',
      'nearbyStores': 'Sklepy najbliżej tego adresu',
      'nearbyStoresNoResults':
          'Nie znaleziono pobliskich sklepów. Spróbuj podać inny adres.',
      'publishStoreMap': 'Opublikuj mapę',
      'matchStoreMapCategories': 'Dopasuj kategorie',
      'matchStoreMapCategoriesDescription':
          'Przed publikacją wybierz publiczną kategorię pasującą do każdej lokalnej kategorii.',
      'selectOnlineCategory': 'Publiczna kategoria',
      'categoryMappingRequired':
          'Dopasuj wszystkie kategorie mapy przed publikacją.',
      'storeMapPublished': 'Mapa sklepu została udostępniona.',
      'storeMapAlreadyExists': 'Taki układ tego sklepu jest już udostępniony.',
      'storeMapUnpublished': 'Mapa sklepu nie jest już udostępniona.',
      'emptyPublicStoreMaps': 'Brak udostępnionych map sklepów.',
      'signInToBrowseStoreMaps':
          'Zaloguj się, aby przeglądać i udostępniać mapy sklepów.',
      'completeProfileToBrowseStoreMaps':
          'Uzupełnij profil, aby przeglądać i udostępniać mapy sklepów.',
      'copyStoreMap': 'Dodaj do moich sklepów',
      'storeMapCopied': 'Mapa sklepu została dodana do Twoich map.',
      'storeMapAlreadyAdded': 'Już w moich sklepach',
      'reportStoreMap': 'Zgłoś mapę',
      'hideUserMaps': 'Ukryj mapy tego użytkownika',
      'hideUserMapsConfirmation':
          'Nie będziesz już widzieć map udostępnionych przez użytkownika {user}.',
      'hideUserMapsAction': 'Ukryj mapy',
      'userMapsHidden': 'Mapy tego użytkownika zostały ukryte.',
      'reportReasonIncorrect': 'Nieprawidłowe lub nieaktualne informacje',
      'reportReasonInappropriate': 'Nieodpowiednia treść',
      'reportReasonOther': 'Inny problem',
      'reportSubmitted': 'Mapa została zgłoszona.',
      'contentRejected':
          'Treść zawiera niedozwolone lub obraźliwe słowa. Zmień ją i spróbuj ponownie.',
      'sharedBy': 'Udostępnił',
      'findNearMe': 'Znajdź blisko mnie',
      'clearLocation': 'Wyczyść lokalizację',
      'locationServicesDisabled':
          'Usługi lokalizacji są wyłączone. Włącz je, aby znaleźć pobliskie sklepy.',
      'locationPermissionDenied':
          'Dostęp do lokalizacji jest potrzebny, aby znaleźć pobliskie sklepy.',
      'locationPermissionDeniedForever':
          'Zezwól na dostęp do lokalizacji w ustawieniach, aby znaleźć pobliskie sklepy.',
      'locationUnavailable':
          'Nie udało się ustalić bieżącej lokalizacji. Spróbuj ponownie.',
      'openSettings': 'Ustawienia',
      'legalInformation': 'Informacje prawne',
      'privacyPolicy': 'Polityka prywatności',
      'termsOfService': 'Regulamin',
      'accountDeletionPage': 'Usuwanie konta',
      'support': 'Pomoc i kontakt',
      'searchSharedStores': 'Szukaj sklepów lub adresów',
      'poweredByGeoapify': 'Geoapify, © OpenStreetMap contributors',
      'mapsCountLabel': 'Mapy',
      'downloadsCountLabel': 'Pobrania',
      'back': 'Wróć',
    },
    'de': {
      'account': 'Konto',
      'localMode': 'Lokaler Modus',
      'localModeDescription':
          'Melde dich nur an, wenn du Gruppen erstellen und Listen oder Pfandcodes teilen möchtest.',
      'notConfigured': 'Supabase ist in diesem Build nicht konfiguriert.',
      'contentRejected':
          'Der Inhalt enthält unzulässige oder beleidigende Wörter. Ändere ihn und versuche es erneut.',
      'genericOnlineError': 'Etwas ist schiefgelaufen. Versuche es erneut.',
      'signIn': 'Anmeldung',
      'signInApple': 'Mit Apple fortfahren',
      'signInGoogle': 'Mit Google fortfahren',
      'signInFacebook': 'Mit Facebook fortfahren',
      'completeProfile': 'Gib deinen Benutzernamen ein',
      'completeProfileDescription':
          'Dein Benutzername wird zum Beitritt zu Gruppen verwendet.',
      'displayName': 'Öffentlicher Name',
      'createProfile': 'Profil erstellen',
      'signedInAs': 'Angemeldet als',
      'signOut': 'Abmelden',
      'deleteAccount': 'Konto löschen',
      'deleteAccountDescription':
          'Löscht dauerhaft dein Profil, Mitgliedschaften, Einladungen und von dir in Gruppen geteilte Daten. Lokale Daten auf diesem Gerät und Daten anderer Mitglieder bleiben erhalten.',
      'accountDeleted':
          'Konto gelöscht. Lokale Daten bleiben auf diesem Gerät.',
      'groups': 'Gruppen',
      'createGroup': 'Gruppe erstellen',
      'groupName': 'Gruppenname',
      'emptyGroups': 'Du gehörst noch keiner Gruppe an.',
      'invitations': 'Einladungen',
      'invitedBy': 'Eingeladen von',
      'accept': 'Annehmen',
      'decline': 'Ablehnen',
      'inviteMember': 'Mitglied einladen',
      'memberHandle': 'Name#1234',
      'sendInvite': 'Einladung senden',
      'invitationSent': 'Einladung gesendet.',
      'sharedLists': 'Geteilte Einkaufslisten',
      'sharedDeposits': 'Geteilte Pfandcodes',
      'copyLocalList': 'Lokale Liste kopieren',
      'moveLocalDeposit': 'Lokalen Pfandcode verschieben',
      'copyListExplanation':
          'In der Gruppe wird eine separate Kopie erstellt. Deine lokale Liste bleibt unverändert.',
      'moveDepositExplanation':
          'Der Pfandcode wird in die Gruppe verschoben und von diesem Gerät entfernt.',
      'emptySharedLists': 'Noch keine geteilten Einkaufslisten.',
      'emptySharedDeposits': 'Noch keine geteilten Pfandcodes.',
      'copiedToGroup': 'Liste in die Gruppe kopiert.',
      'movedToGroup': 'Pfandcode in die Gruppe verschoben.',
      'membersCanEdit': 'Alle Gruppenmitglieder haben Zugriff auf diese Daten.',
      'share': 'Teilen',
      'selectStoreMapToShare': 'Karte zum Teilen auswählen',
      'hideUserMaps': 'Karten dieses Nutzers ausblenden',
      'hideUserMapsConfirmation':
          'Du siehst keine von {user} geteilten Karten mehr.',
      'hideUserMapsAction': 'Karten ausblenden',
      'userMapsHidden': 'Die Karten dieses Nutzers wurden ausgeblendet.',
    },
    'nl': {
      'account': 'Account',
      'localMode': 'Lokale modus',
      'localModeDescription':
          'Log alleen in als je groepen wilt maken en lijsten of statiegeldcodes wilt delen.',
      'notConfigured': 'Supabase is niet geconfigureerd in deze build.',
      'contentRejected':
          'De inhoud bevat verboden of beledigende woorden. Pas deze aan en probeer het opnieuw.',
      'genericOnlineError': 'Er is iets misgegaan. Probeer het opnieuw.',
      'signIn': 'Inloggen',
      'signInApple': 'Doorgaan met Apple',
      'signInGoogle': 'Doorgaan met Google',
      'signInFacebook': 'Doorgaan met Facebook',
      'completeProfile': 'Voer je gebruikersnaam in',
      'completeProfileDescription':
          'Je gebruikersnaam wordt gebruikt om lid te worden van groepen.',
      'displayName': 'Openbare naam',
      'createProfile': 'Profiel maken',
      'signedInAs': 'Ingelogd als',
      'signOut': 'Uitloggen',
      'deleteAccount': 'Account verwijderen',
      'deleteAccountDescription':
          'Verwijdert permanent je profiel, lidmaatschappen, uitnodigingen en gegevens die je in groepen hebt gedeeld. Lokale gegevens en gegevens van andere leden blijven behouden.',
      'accountDeleted':
          'Account verwijderd. Lokale gegevens blijven op dit apparaat.',
      'groups': 'Groepen',
      'createGroup': 'Groep maken',
      'groupName': 'Groepsnaam',
      'emptyGroups': 'Je bent nog geen lid van een groep.',
      'invitations': 'Uitnodigingen',
      'invitedBy': 'Uitgenodigd door',
      'accept': 'Accepteren',
      'decline': 'Weigeren',
      'inviteMember': 'Lid uitnodigen',
      'memberHandle': 'Naam#1234',
      'sendInvite': 'Uitnodiging sturen',
      'invitationSent': 'Uitnodiging verstuurd.',
      'sharedLists': 'Gedeelde boodschappenlijsten',
      'sharedDeposits': 'Gedeelde statiegeldcodes',
      'copyLocalList': 'Lokale lijst kopiëren',
      'moveLocalDeposit': 'Lokale statiegeldcode verplaatsen',
      'copyListExplanation':
          'Er wordt een aparte kopie in de groep gemaakt. Je lokale lijst blijft ongewijzigd.',
      'moveDepositExplanation':
          'De statiegeldcode wordt naar de groep verplaatst en van dit apparaat verwijderd.',
      'emptySharedLists': 'Nog geen gedeelde boodschappenlijsten.',
      'emptySharedDeposits': 'Nog geen gedeelde statiegeldcodes.',
      'copiedToGroup': 'Lijst naar de groep gekopieerd.',
      'movedToGroup': 'Statiegeldcode naar de groep verplaatst.',
      'membersCanEdit': 'Alle groepsleden hebben toegang tot deze gegevens.',
      'share': 'Delen',
      'selectStoreMapToShare': 'Kaart kiezen om te delen',
      'hideUserMaps': 'Kaarten van deze gebruiker verbergen',
      'hideUserMapsConfirmation':
          'Je ziet geen kaarten meer die door {user} zijn gedeeld.',
      'hideUserMapsAction': 'Kaarten verbergen',
      'userMapsHidden': 'De kaarten van deze gebruiker zijn verborgen.',
    },
    'es': {
      'account': 'Cuenta',
      'localMode': 'Modo local',
      'localModeDescription':
          'Inicia sesión solo cuando quieras crear grupos y compartir listas o códigos de depósito.',
      'notConfigured': 'Supabase no está configurado en esta versión.',
      'contentRejected':
          'El contenido contiene palabras prohibidas u ofensivas. Cámbialo e inténtalo de nuevo.',
      'genericOnlineError': 'Algo salió mal. Inténtalo de nuevo.',
      'signIn': 'Iniciar sesión',
      'signInApple': 'Continuar con Apple',
      'signInGoogle': 'Continuar con Google',
      'signInFacebook': 'Continuar con Facebook',
      'completeProfile': 'Introduce tu nombre de usuario',
      'completeProfileDescription':
          'Tu nombre de usuario se utiliza para unirte a grupos.',
      'displayName': 'Nombre público',
      'createProfile': 'Crear perfil',
      'signedInAs': 'Sesión iniciada como',
      'signOut': 'Cerrar sesión',
      'deleteAccount': 'Eliminar cuenta',
      'deleteAccountDescription':
          'Elimina permanentemente tu perfil, membresías, invitaciones y los datos que compartiste en grupos. Los datos locales y los datos de otros miembros permanecerán.',
      'accountDeleted':
          'Cuenta eliminada. Los datos locales permanecen en este dispositivo.',
      'groups': 'Grupos',
      'createGroup': 'Crear grupo',
      'groupName': 'Nombre del grupo',
      'emptyGroups': 'Aún no perteneces a ningún grupo.',
      'invitations': 'Invitaciones',
      'invitedBy': 'Invitado por',
      'accept': 'Aceptar',
      'decline': 'Rechazar',
      'inviteMember': 'Invitar miembro',
      'memberHandle': 'Nombre#1234',
      'sendInvite': 'Enviar invitación',
      'invitationSent': 'Invitación enviada.',
      'sharedLists': 'Listas de compras compartidas',
      'sharedDeposits': 'Códigos de depósito compartidos',
      'copyLocalList': 'Copiar lista local',
      'moveLocalDeposit': 'Mover código de depósito local',
      'copyListExplanation':
          'Se creará una copia separada en el grupo. Tu lista local no cambiará.',
      'moveDepositExplanation':
          'El código de depósito se moverá al grupo y se eliminará de este dispositivo.',
      'emptySharedLists': 'Aún no hay listas compartidas.',
      'emptySharedDeposits': 'Aún no hay códigos compartidos.',
      'copiedToGroup': 'Lista copiada al grupo.',
      'movedToGroup': 'Código de depósito movido al grupo.',
      'membersCanEdit':
          'Todos los miembros del grupo tienen acceso a estos datos.',
      'share': 'Compartir',
      'selectStoreMapToShare': 'Seleccionar mapa para compartir',
      'hideUserMaps': 'Ocultar mapas de este usuario',
      'hideUserMapsConfirmation':
          'Ya no verás los mapas compartidos por {user}.',
      'hideUserMapsAction': 'Ocultar mapas',
      'userMapsHidden': 'Los mapas de este usuario se han ocultado.',
    },
    'fr': {
      'account': 'Compte',
      'localMode': 'Mode local',
      'localModeDescription':
          'Connectez-vous uniquement pour créer des groupes et partager des listes ou des codes de consigne.',
      'notConfigured': "Supabase n'est pas configuré dans cette version.",
      'contentRejected':
          'Le contenu contient des mots interdits ou offensants. Modifiez-le et réessayez.',
      'genericOnlineError': 'Une erreur est survenue. Réessayez.',
      'signIn': 'Connexion',
      'signInApple': 'Continuer avec Apple',
      'signInGoogle': 'Continuer avec Google',
      'signInFacebook': 'Continuer avec Facebook',
      'completeProfile': "Saisissez votre nom d'utilisateur",
      'completeProfileDescription':
          "Votre nom d'utilisateur est utilisé pour rejoindre des groupes.",
      'displayName': 'Nom public',
      'createProfile': 'Créer le profil',
      'signedInAs': 'Connecté en tant que',
      'signOut': 'Se déconnecter',
      'deleteAccount': 'Supprimer le compte',
      'deleteAccountDescription':
          'Supprime définitivement votre profil, vos appartenances, invitations et données partagées dans les groupes. Les données locales et celles des autres membres restent.',
      'accountDeleted':
          'Compte supprimé. Les données locales restent sur cet appareil.',
      'groups': 'Groupes',
      'createGroup': 'Créer un groupe',
      'groupName': 'Nom du groupe',
      'emptyGroups': "Vous n'appartenez encore à aucun groupe.",
      'invitations': 'Invitations',
      'invitedBy': 'Invité par',
      'accept': 'Accepter',
      'decline': 'Refuser',
      'inviteMember': 'Inviter un membre',
      'memberHandle': 'Nom#1234',
      'sendInvite': "Envoyer l'invitation",
      'invitationSent': 'Invitation envoyée.',
      'sharedLists': 'Listes de courses partagées',
      'sharedDeposits': 'Codes de consigne partagés',
      'copyLocalList': 'Copier une liste locale',
      'moveLocalDeposit': 'Déplacer un code de consigne local',
      'copyListExplanation':
          'Une copie distincte sera créée dans le groupe. Votre liste locale restera inchangée.',
      'moveDepositExplanation':
          'Le code de consigne sera déplacé dans le groupe et supprimé de cet appareil.',
      'emptySharedLists': 'Aucune liste partagée pour le moment.',
      'emptySharedDeposits': 'Aucun code partagé pour le moment.',
      'copiedToGroup': 'Liste copiée dans le groupe.',
      'movedToGroup': 'Code de consigne déplacé dans le groupe.',
      'membersCanEdit': 'Tous les membres du groupe ont accès à ces données.',
      'share': 'Partager',
      'selectStoreMapToShare': 'Sélectionner la carte à partager',
      'hideUserMaps': 'Masquer les cartes de cet utilisateur',
      'hideUserMapsConfirmation':
          'Vous ne verrez plus les cartes partagées par {user}.',
      'hideUserMapsAction': 'Masquer les cartes',
      'userMapsHidden': 'Les cartes de cet utilisateur sont masquées.',
    },
    'uk': {
      'account': 'Обліковий запис',
      'localMode': 'Локальний режим',
      'localModeDescription':
          'Увійдіть лише для створення груп і спільного доступу до списків або кодів застави.',
      'notConfigured': 'Supabase не налаштовано в цій збірці.',
      'contentRejected':
          'Вміст містить заборонені або образливі слова. Змініть його та спробуйте ще раз.',
      'genericOnlineError': 'Щось пішло не так. Спробуйте ще раз.',
      'signIn': 'Вхід',
      'signInApple': 'Продовжити з Apple',
      'signInGoogle': 'Продовжити з Google',
      'signInFacebook': 'Продовжити з Facebook',
      'completeProfile': 'Введіть ім’я користувача',
      'completeProfileDescription':
          'Ім’я користувача використовується для приєднання до груп.',
      'displayName': 'Публічне ім’я',
      'createProfile': 'Створити профіль',
      'signedInAs': 'Ви увійшли як',
      'signOut': 'Вийти',
      'deleteAccount': 'Видалити обліковий запис',
      'deleteAccountDescription':
          'Назавжди видаляє ваш профіль, членство, запрошення та дані, якими ви поділилися в групах. Локальні дані та дані інших учасників залишаться.',
      'accountDeleted':
          'Обліковий запис видалено. Локальні дані залишилися на цьому пристрої.',
      'groups': 'Групи',
      'createGroup': 'Створити групу',
      'groupName': 'Назва групи',
      'emptyGroups': 'Ви ще не належите до жодної групи.',
      'invitations': 'Запрошення',
      'invitedBy': 'Запросив',
      'accept': 'Прийняти',
      'decline': 'Відхилити',
      'inviteMember': 'Запросити учасника',
      'memberHandle': 'Ім’я#1234',
      'sendInvite': 'Надіслати запрошення',
      'invitationSent': 'Запрошення надіслано.',
      'sharedLists': 'Спільні списки покупок',
      'sharedDeposits': 'Спільні коди застави',
      'copyLocalList': 'Копіювати локальний список',
      'moveLocalDeposit': 'Перемістити локальний код застави',
      'copyListExplanation':
          'У групі буде створено окрему копію. Ваш локальний список не зміниться.',
      'moveDepositExplanation':
          'Код застави буде переміщено до групи та видалено з цього пристрою.',
      'emptySharedLists': 'Спільних списків ще немає.',
      'emptySharedDeposits': 'Спільних кодів ще немає.',
      'copiedToGroup': 'Список скопійовано до групи.',
      'movedToGroup': 'Код застави переміщено до групи.',
      'membersCanEdit': 'Усі учасники групи мають доступ до цих даних.',
      'share': 'Поділитися',
      'selectStoreMapToShare': 'Виберіть мапу для поширення',
      'hideUserMaps': 'Приховати мапи цього користувача',
      'hideUserMapsConfirmation':
          'Ви більше не бачитимете мапи, якими поділився користувач {user}.',
      'hideUserMapsAction': 'Приховати мапи',
      'userMapsHidden': 'Мапи цього користувача приховано.',
    },
    'it': {
      'account': 'Account',
      'localMode': 'Modalità locale',
      'localModeDescription':
          'Accedi solo quando vuoi creare gruppi e condividere liste o codici cauzione.',
      'notConfigured': 'Supabase non è configurato in questa build.',
      'contentRejected':
          'Il contenuto contiene parole vietate o offensive. Modificalo e riprova.',
      'genericOnlineError': 'Qualcosa è andato storto. Riprova.',
      'signIn': 'Accesso',
      'signInApple': 'Continua con Apple',
      'signInGoogle': 'Continua con Google',
      'signInFacebook': 'Continua con Facebook',
      'completeProfile': 'Inserisci il tuo nome utente',
      'completeProfileDescription':
          'Il nome utente viene utilizzato per unirsi ai gruppi.',
      'displayName': 'Nome pubblico',
      'createProfile': 'Crea profilo',
      'signedInAs': 'Accesso effettuato come',
      'signOut': 'Esci',
      'deleteAccount': 'Elimina account',
      'deleteAccountDescription':
          'Elimina definitivamente profilo, iscrizioni, inviti e dati condivisi da te nei gruppi. I dati locali e quelli degli altri membri rimarranno.',
      'accountDeleted':
          'Account eliminato. I dati locali rimangono su questo dispositivo.',
      'groups': 'Gruppi',
      'createGroup': 'Crea gruppo',
      'groupName': 'Nome del gruppo',
      'emptyGroups': 'Non appartieni ancora a nessun gruppo.',
      'invitations': 'Inviti',
      'invitedBy': 'Invitato da',
      'accept': 'Accetta',
      'decline': 'Rifiuta',
      'inviteMember': 'Invita membro',
      'memberHandle': 'Nome#1234',
      'sendInvite': 'Invia invito',
      'invitationSent': 'Invito inviato.',
      'sharedLists': 'Liste della spesa condivise',
      'sharedDeposits': 'Codici cauzione condivisi',
      'copyLocalList': 'Copia lista locale',
      'moveLocalDeposit': 'Sposta codice cauzione locale',
      'copyListExplanation':
          'Nel gruppo verrà creata una copia separata. La lista locale rimarrà invariata.',
      'moveDepositExplanation':
          'Il codice cauzione verrà spostato nel gruppo e rimosso da questo dispositivo.',
      'emptySharedLists': 'Nessuna lista condivisa.',
      'emptySharedDeposits': 'Nessun codice condiviso.',
      'copiedToGroup': 'Lista copiata nel gruppo.',
      'movedToGroup': 'Codice cauzione spostato nel gruppo.',
      'membersCanEdit':
          'Tutti i membri del gruppo hanno accesso a questi dati.',
      'share': 'Condividi',
      'selectStoreMapToShare': 'Seleziona mappa da condividere',
      'hideUserMaps': 'Nascondi le mappe di questo utente',
      'hideUserMapsConfirmation':
          'Non vedrai più le mappe condivise da {user}.',
      'hideUserMapsAction': 'Nascondi mappe',
      'userMapsHidden': 'Le mappe di questo utente sono state nascoste.',
    },
    'pt': {
      'account': 'Conta',
      'localMode': 'Modo local',
      'localModeDescription':
          'Inicie sessão apenas quando quiser criar grupos e partilhar listas ou códigos de caução.',
      'notConfigured': 'O Supabase não está configurado nesta versão.',
      'contentRejected':
          'O conteúdo contém palavras proibidas ou ofensivas. Altere-o e tente novamente.',
      'genericOnlineError': 'Algo correu mal. Tente novamente.',
      'signIn': 'Iniciar sessão',
      'signInApple': 'Continuar com Apple',
      'signInGoogle': 'Continuar com Google',
      'signInFacebook': 'Continuar com Facebook',
      'completeProfile': 'Introduza o seu nome de utilizador',
      'completeProfileDescription':
          'O nome de utilizador é usado para aderir a grupos.',
      'displayName': 'Nome público',
      'createProfile': 'Criar perfil',
      'signedInAs': 'Sessão iniciada como',
      'signOut': 'Terminar sessão',
      'deleteAccount': 'Excluir conta',
      'deleteAccountDescription':
          'Exclui permanentemente o seu perfil, associações, convites e dados partilhados por si nos grupos. Os dados locais e os dados de outros membros permanecerão.',
      'accountDeleted':
          'Conta excluída. Os dados locais permanecem neste dispositivo.',
      'groups': 'Grupos',
      'createGroup': 'Criar grupo',
      'groupName': 'Nome do grupo',
      'emptyGroups': 'Ainda não pertence a nenhum grupo.',
      'invitations': 'Convites',
      'invitedBy': 'Convidado por',
      'accept': 'Aceitar',
      'decline': 'Recusar',
      'inviteMember': 'Convidar membro',
      'memberHandle': 'Nome#1234',
      'sendInvite': 'Enviar convite',
      'invitationSent': 'Convite enviado.',
      'sharedLists': 'Listas de compras partilhadas',
      'sharedDeposits': 'Códigos de caução partilhados',
      'copyLocalList': 'Copiar lista local',
      'moveLocalDeposit': 'Mover código de caução local',
      'copyListExplanation':
          'Será criada uma cópia separada no grupo. A lista local permanecerá inalterada.',
      'moveDepositExplanation':
          'O código de caução será movido para o grupo e removido deste dispositivo.',
      'emptySharedLists': 'Ainda não há listas partilhadas.',
      'emptySharedDeposits': 'Ainda não há códigos partilhados.',
      'copiedToGroup': 'Lista copiada para o grupo.',
      'movedToGroup': 'Código de caução movido para o grupo.',
      'membersCanEdit': 'Todos os membros do grupo têm acesso a estes dados.',
      'share': 'Partilhar',
      'selectStoreMapToShare': 'Selecionar mapa para partilhar',
      'hideUserMaps': 'Ocultar mapas deste utilizador',
      'hideUserMapsConfirmation':
          'Deixará de ver os mapas partilhados por {user}.',
      'hideUserMapsAction': 'Ocultar mapas',
      'userMapsHidden': 'Os mapas deste utilizador foram ocultados.',
    },
  };

  static const _countryNames = <String, Map<String, String>>{
    'en': {
      'gb': 'United Kingdom',
      'pl': 'Poland',
      'de': 'Germany',
      'nl': 'Netherlands',
      'es': 'Spain',
      'fr': 'France',
      'ua': 'Ukraine',
      'it': 'Italy',
      'pt': 'Portugal',
    },
    'pl': {
      'gb': 'Wielka Brytania',
      'pl': 'Polska',
      'de': 'Niemcy',
      'nl': 'Holandia',
      'es': 'Hiszpania',
      'fr': 'Francja',
      'ua': 'Ukraina',
      'it': 'Włochy',
      'pt': 'Portugalia',
    },
    'de': {
      'gb': 'Vereinigtes Königreich',
      'pl': 'Polen',
      'de': 'Deutschland',
      'nl': 'Niederlande',
      'es': 'Spanien',
      'fr': 'Frankreich',
      'ua': 'Ukraine',
      'it': 'Italien',
      'pt': 'Portugal',
    },
    'nl': {
      'gb': 'Verenigd Koninkrijk',
      'pl': 'Polen',
      'de': 'Duitsland',
      'nl': 'Nederland',
      'es': 'Spanje',
      'fr': 'Frankrijk',
      'ua': 'Oekraïne',
      'it': 'Italië',
      'pt': 'Portugal',
    },
    'es': {
      'gb': 'Reino Unido',
      'pl': 'Polonia',
      'de': 'Alemania',
      'nl': 'Países Bajos',
      'es': 'España',
      'fr': 'Francia',
      'ua': 'Ucrania',
      'it': 'Italia',
      'pt': 'Portugal',
    },
    'fr': {
      'gb': 'Royaume-Uni',
      'pl': 'Pologne',
      'de': 'Allemagne',
      'nl': 'Pays-Bas',
      'es': 'Espagne',
      'fr': 'France',
      'ua': 'Ukraine',
      'it': 'Italie',
      'pt': 'Portugal',
    },
    'uk': {
      'gb': 'Велика Британія',
      'pl': 'Польща',
      'de': 'Німеччина',
      'nl': 'Нідерланди',
      'es': 'Іспанія',
      'fr': 'Франція',
      'ua': 'Україна',
      'it': 'Італія',
      'pt': 'Португалія',
    },
    'it': {
      'gb': 'Regno Unito',
      'pl': 'Polonia',
      'de': 'Germania',
      'nl': 'Paesi Bassi',
      'es': 'Spagna',
      'fr': 'Francia',
      'ua': 'Ucraina',
      'it': 'Italia',
      'pt': 'Portogallo',
    },
    'pt': {
      'gb': 'Reino Unido',
      'pl': 'Polónia',
      'de': 'Alemanha',
      'nl': 'Países Baixos',
      'es': 'Espanha',
      'fr': 'França',
      'ua': 'Ucrânia',
      'it': 'Itália',
      'pt': 'Portugal',
    },
  };

  String text(String key) {
    return _values[languageCode]?[key] ?? _values['en']![key] ?? key;
  }

  String countryName(String countryCode) {
    return _countryNames[languageCode]?[countryCode] ??
        _countryNames['en']![countryCode] ??
        countryCode.toUpperCase();
  }

  String? errorMessage(CloudController controller, {bool? showRawDetails}) {
    if (controller.errorKind == CloudErrorKind.contentRejected) {
      return text('contentRejected');
    }
    if (controller.errorKind == CloudErrorKind.canonicalStoreRequired) {
      return text('canonicalStoreRequired');
    }
    if (controller.errorKind == CloudErrorKind.storeCountryMismatch) {
      return text('storeCountryMismatch');
    }
    final rawMessage = controller.errorMessage;
    if (rawMessage == null) {
      return null;
    }
    if (showRawDetails ?? !SupabaseConfig.isProduction) {
      return rawMessage;
    }
    return text('genericOnlineError');
  }
}
