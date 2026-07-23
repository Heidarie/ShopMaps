# Wydanie produkcyjne ShopMaps

Repozytorium zawiera bramki, które celowo blokują produkcyjny build, dopóki
konfiguracja, dokumenty prawne i podpisywanie nie będą kompletne.

## Co jest już przygotowane

- konfiguracja produkcyjna jest oddzielona od `config/supabase.dev.json`;
- aplikacja sprawdza konfigurację przy `APP_ENV=production`;
- walidator odrzuca znany projekt developerski Supabase i Firebase;
- Android release wymaga prywatnego upload keystore;
- iOS używa APNs `development` dla Debug/Profile i `production` dla Release;
- ustawienia aplikacji pokazują skonfigurowane linki prawne i kontakt;
- konfiguracje Firebase dev/prod można zapisywać i przełączać lokalnie;
- Edge Functions mają jawnie włączone `verify_jwt`;
- CI sprawdza schemat przykładowej konfiguracji produkcyjnej.

## 1. Ustal dane wydawcy

Przed konfiguracją usług ustal:

1. nazwę wydawcy lub firmy;
2. adres administratora danych;
3. publiczny adres e-mail wsparcia;
4. domenę albo adres GitHub Pages dla dokumentów;
5. docelowe identyfikatory aplikacji:
   - iOS: `com.dawidogly.shopMaps`;
   - Android: `com.dawidogly.shopMaps`.

Nie zmieniaj identyfikatorów po utworzeniu aplikacji w sklepach.

## 2. Dokończ dokumenty prawne

1. Poddaj sekcję regulaminu w `docs/index.html` weryfikacji prawnej.
2. Opublikuj `docs/index.html` pod publicznym adresem HTTPS.
3. Upewnij się, że dokument działa bez logowania, a odnośniki do sekcji
   `#privacy`, `#rules` i `#account-deletion` przewijają do właściwej treści.
4. Wpisz adres jednego dokumentu z odpowiednimi kotwicami do
   `config/supabase.prod.json`, na przykład:

   ```json
   {
     "PRIVACY_POLICY_URL": "https://heidarie.github.io/ShopMaps/#privacy",
     "TERMS_OF_SERVICE_URL": "https://heidarie.github.io/ShopMaps/#rules",
     "ACCOUNT_DELETION_URL": "https://heidarie.github.io/ShopMaps/#account-deletion"
   }
   ```

## 3. Utwórz produkcyjny Supabase

Nie używaj projektu developerskiego `kkytxouitzsmzghzznva` jako produkcji.

1. Utwórz nowy projekt Supabase w regionie UE.
2. Zapisz bezpiecznie hasło bazy i skonfiguruj backupy oraz alerty.
3. Zainstaluj Supabase CLI i zaloguj się:

   ```bash
   supabase login
   supabase link --project-ref <PRODUCTION_PROJECT_REF>
   ```

4. Sprawdź i zastosuj migracje:

   ```bash
   supabase migration list
   supabase db push
   ```

5. Ustaw sekrety Edge Functions. Pliku z sekretami nie dodawaj do Git:

   ```bash
   cp supabase/functions/.env.example supabase/functions/.env.prod
   # Uzupełnij GEOAPIFY_API_KEY i FIREBASE_SERVICE_ACCOUNT_JSON
   supabase secrets set --project-ref <PRODUCTION_PROJECT_REF> \
     --env-file supabase/functions/.env.prod
   ```

6. Wdróż funkcje:

   ```bash
   supabase functions deploy geoapify-address-search \
     --project-ref <PRODUCTION_PROJECT_REF>
   supabase functions deploy notify-shared-list-additions \
     --project-ref <PRODUCTION_PROJECT_REF>
   ```

7. W Supabase Auth włącz Google, Apple i Facebook.
8. Dodaj redirect URL `shopmaps://login-callback`.
9. W Google provider wpisz produkcyjny web client ID oraz iOS client ID.
10. Pozostaw sprawdzanie nonce włączone.
11. Uruchom Security Advisor i napraw problemy bezpieczeństwa.
12. Przetestuj RLS co najmniej dwoma kontami: członkiem grupy i osobą spoza
    grupy.
13. Ustal harmonogram obsługi zgłoszeń zgodnie z
    [`moderation.md`](moderation.md).

Dokumentacja:

- <https://supabase.com/docs/guides/integrations/supabase-for-platforms>
- <https://supabase.com/docs/guides/functions/deploy>
- <https://supabase.com/docs/guides/functions/secrets>

## 4. Utwórz produkcyjny Firebase

1. Zapisz obecną konfigurację developerską:

   ```bash
   scripts/save-firebase-environment.sh dev
   ```

2. Utwórz osobny projekt Firebase dla produkcji.
3. Dodaj aplikacje Android i iOS `com.dawidogly.shopMaps`.
4. Uruchom FlutterFire CLI dla projektu produkcyjnego:

   ```bash
   flutterfire configure
   ```

5. Sprawdź aktualizację `google-services.json`, `GoogleService-Info.plist`,
   `ios/Flutter/Secrets.xcconfig` oraz `firebase.json`. Te pliki pozostają
   lokalne i nie mogą trafić do Git.
6. Zapisz konfigurację produkcyjną:

   ```bash
   scripts/save-firebase-environment.sh prod
   scripts/use-firebase-environment.sh dev
   ```

7. W Firebase włącz Cloud Messaging API i dodaj klucz APNs.
8. Utwórz konto serwisowe FCM i ustaw jego JSON wyłącznie jako sekret
   `FIREBASE_SERVICE_ACCOUNT_JSON` w produkcyjnym Supabase.

## 5. Skonfiguruj logowanie

### Google

1. Utwórz produkcyjny web OAuth client.
2. Utwórz produkcyjny iOS OAuth client dla `com.dawidogly.shopMaps`.
3. Jeżeli iOS client ID różni się od obecnego, dodaj jego odwrócony
   identyfikator do `CFBundleURLSchemes` w `ios/Runner/Info.plist`.
4. Wpisz oba client ID do Supabase Auth i `config/supabase.prod.json`.

### Apple

1. Dołącz do Apple Developer Program.
2. Włącz Sign in with Apple i Push Notifications dla App ID.
3. W Xcode upewnij się, że Runner ma capability `Sign in with Apple`.
4. W Supabase Auth skonfiguruj Apple provider i dodaj natywny Bundle ID
   `com.dawidogly.shopMaps`.
5. Jeżeli używasz także web/OAuth fallbacku, skonfiguruj Services ID i callback
   `https://<PRODUCTION_PROJECT_REF>.supabase.co/auth/v1/callback`.
6. Przetestuj pierwsze logowanie, ponowne logowanie i usuwanie konta.

### Facebook

1. Utwórz aplikację na Meta for Developers i dodaj Facebook Login.
2. Włącz uprawnienia `email` oraz `public_profile`.
3. Dodaj callback Supabase
   `https://<PRODUCTION_PROJECT_REF>.supabase.co/auth/v1/callback` jako
   poprawny OAuth redirect URI.
4. W Supabase Auth skonfiguruj App ID i App Secret Facebooka. App Secret nie
   może trafić do aplikacji ani Git.
5. Zostaw `"FACEBOOK_SSO_ENABLED": false` w `config/supabase.prod.json`, dopóki
   provider nie jest gotowy do publicznego użycia. Po włączeniu ustaw `true`.
6. Uzupełnij wymagane dane, politykę prywatności i przełącz aplikację Meta z
   trybu development na live.

## 6. Skonfiguruj podpisywanie Androida

1. Utwórz prywatny upload keystore:

   ```bash
   mkdir -p android/keystores
   keytool -genkeypair -v \
     -keystore android/keystores/shopmaps-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias shopmaps-upload
   ```

2. Skopiuj i uzupełnij konfigurację:

   ```bash
   cp android/key.properties.example android/key.properties
   ```

3. Zrób zaszyfrowaną kopię keystore i haseł poza repozytorium.
4. Włącz Play App Signing podczas tworzenia aplikacji w Google Play Console.

## 7. Przygotuj panele sklepów

### App Store Connect

1. Utwórz aplikację z bundle ID `com.dawidogly.shopMaps`.
2. Uzupełnij opis, kategorię, słowa kluczowe i adres wsparcia.
3. Dodaj URL polityki prywatności i wypełnij App Privacy.
4. Przygotuj zrzuty ekranów oraz informacje dla App Review.

### Google Play Console

1. Utwórz aplikację z application ID `com.dawidogly.shopMaps`.
2. Uzupełnij Data Safety.
3. Dodaj URL polityki prywatności i publiczny URL usuwania konta.
4. Skonfiguruj Play App Signing i najpierw użyj Internal Testing.

## 8. Utwórz konfigurację produkcyjną

```bash
cp config/supabase.prod.example.json config/supabase.prod.json
```

Uzupełnij wszystkie wartości. Nie dodawaj tego pliku do Git.

Sprawdź konfigurację:

```bash
scripts/use-firebase-environment.sh prod
scripts/check-secrets.sh
dart run tool/validate_production_config.dart config/supabase.prod.json
```

Walidator odrzuci projekt developerski, placeholdery, sekrety umieszczone w
aplikacji, brak HTTPS i niespójną konfigurację FlutterFire.

## 9. Testy przed wysłaniem

Przetestuj na fizycznym iPhonie i Androidzie:

1. logowanie Google i Apple;
2. tworzenie i usuwanie konta;
3. zaproszenia oraz opuszczanie grupy;
4. realtime współdzielonych list i kodów kaucji;
5. powiadomienia push;
6. publikowanie, wyszukiwanie i pobieranie map sklepów;
7. „Znajdź blisko mnie” oraz odmowę uprawnienia lokalizacji;
8. linki prawne w Ustawieniach;
9. tryb lokalny bez logowania i bez Internetu.

## 10. Zbuduj artefakty

Najpierw zwiększ `version` w `pubspec.yaml`, np. `1.3.0+7`.

```bash
scripts/build-production-ios.sh
scripts/build-production-android.sh
```

Skrypty aktywują Firebase `prod`, sprawdzają konfigurację, dokumenty,
podpisywanie i APNs, uruchamiają analizę oraz testy, a następnie budują IPA/AAB.

Po testach wyślij IPA do TestFlight, a AAB do Google Play Internal Testing.
