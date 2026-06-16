# Supabase setup for ShopMaps

ShopMaps works without Supabase. Accounts, groups, shared grocery lists, shared
deposit codes, and public store maps are enabled only in builds that receive a
Supabase URL and publishable key.

## Development ShopMaps project

- Project reference: `kkytxouitzsmzghzznva`
- Region: `eu-central-1`
- API URL: `https://kkytxouitzsmzghzznva.supabase.co`

## Database migrations

All versioned files in `supabase/migrations/` must be applied in order.

The migration creates:

- public profiles with handles such as `Endriu#1337`,
- groups, memberships, and invitations,
- shared grocery lists and deposit vouchers,
- canonical store locations and public store maps,
- database-enforced filtering for user-created online text,
- Realtime replication for shared grocery lists, items, and deposit vouchers,
- Realtime replication for pending group invitations,
- RPC functions used by the Flutter app,
- Row Level Security policies.

Database filter tests use pgTAP and are stored under
`supabase/tests/database/`. With the local Supabase stack running, execute:

```bash
supabase test db
```

## Shared-list push notifications

Push notifications use Firebase Cloud Messaging (FCM) and the authenticated
Supabase Edge Function:

```text
supabase/functions/notify-shared-list-additions/index.ts
```

The Flutter integration is optional. Without Firebase configuration or without
`PUSH_NOTIFICATIONS_ENABLED`, the application continues to work without push
notifications.

Configure push notifications:

1. Create a Firebase project and register the Android application
   `com.dawidogly.shopMaps` and the iOS application `com.dawidogly.shopMaps`.
2. Run `flutterfire configure` for the Firebase project. This creates the native
   Firebase configuration required by `Firebase.initializeApp()`.
3. In Xcode, verify that the Runner target has Push Notifications and Background
   Modes > Remote notifications enabled. Upload an APNs authentication key in
   Firebase Console > Project settings > Cloud Messaging.
4. Enable the Firebase Cloud Messaging API and generate a service-account JSON
   key in Firebase Console > Project settings > Service accounts > Generate new
   private key. The JSON must belong to the same Firebase project used by the
   app and include `project_id`, `private_key_id`, `private_key`,
   `client_email`, and `token_uri`.
5. Add the complete service-account JSON as the Supabase Edge Function secret
   `FIREBASE_SERVICE_ACCOUNT_JSON`. Never add it to the Flutter application or
   commit it to Git.
   Do not paste `google-services.json` or `GoogleService-Info.plist`; neither is
   a service-account key. After replacing the secret, it is available to the
   function immediately without redeployment.
   The function prefers the current `SUPABASE_PUBLISHABLE_KEYS` and
   `SUPABASE_SECRET_KEYS` environment variables and retains compatibility with
   legacy Supabase keys.
6. Apply `20260612083000_shared_list_push_notifications.sql` and deploy
   `notify-shared-list-additions` with JWT verification enabled.
7. Enable push registration in the ignored `config/supabase.dev.json`:

```json
{
  "PUSH_NOTIFICATIONS_ENABLED": true
}
```

After a signed-in user adds at least one product to a shared list, ShopMaps
sends one notification to the other group members only when the editor is
closed. Removing or editing products without adding anything does not send a
notification. The backend also prevents repeated notifications for the same
additions and removes FCM tokens reported as invalid.

The database security advisor reports no schema issues. The Auth advisor warns
that leaked-password protection is disabled.

## Configure authentication

Enable Apple, Google, and Facebook in Supabase Authentication providers.

Add this redirect URL to the Supabase Auth redirect allow list:

```text
shopmaps://login-callback
```

## Native Google Sign-In

ShopMaps uses native Google Sign-In on iOS and Android. Add the OAuth client IDs
to the ignored `config/supabase.dev.json` file:

```json
{
  "GOOGLE_WEB_CLIENT_ID": "<web-oauth-client-id>.apps.googleusercontent.com",
  "GOOGLE_IOS_CLIENT_ID": "<ios-oauth-client-id>.apps.googleusercontent.com"
}
```

The web client ID is required on both platforms. The iOS client ID is required
on iOS.

In the Supabase Google provider configuration, add both client IDs to the
Client IDs field, separated by a comma, with the web client ID first:

```text
<web-oauth-client-id>.apps.googleusercontent.com,<ios-oauth-client-id>.apps.googleusercontent.com
```

Keep `Skip nonce check` disabled. ShopMaps generates a nonce for native Google
Sign-In and passes the matching raw value to Supabase for verification.

For iOS, copy `ios/Flutter/Secrets.xcconfig.example` to the ignored
`ios/Flutter/Secrets.xcconfig` and set the reversed iOS client ID there.
For example, for:

```text
123-example.apps.googleusercontent.com
```

set:

```text
GOOGLE_REVERSED_CLIENT_ID=com.googleusercontent.apps.123-example
```

`ios/Runner/Info.plist` references this local build setting. Keep `shopmaps` as
a separate URL scheme because it is still used by other Supabase OAuth
providers.

The iOS and Android projects already register this deep link.

Provider-specific credentials still need to be configured in Apple Developer,
Google Cloud, and the Supabase dashboard.

## Facebook Sign-In

1. Create a Facebook app at <https://developers.facebook.com>.
2. Add the Facebook Login product and configure the `email` and
   `public_profile` permissions.
3. Add the Supabase callback URL shown under Authentication > Providers >
   Facebook as a valid Facebook OAuth redirect URI. It has the format:

   ```text
   https://<project-ref>.supabase.co/auth/v1/callback
   ```

4. Enable Facebook in Supabase Authentication > Providers and enter the
   Facebook App ID and App Secret there. Never add the App Secret to the
   Flutter application.
5. Keep `shopmaps://login-callback` in the Supabase redirect allow list.

Facebook apps in development mode only allow administrators, developers, and
testers to sign in. Complete Meta's required app information and switch the app
live before public release.

## Run a configured development build

Use the project's publishable key. Never put a secret key or `service_role` key
inside the Flutter application.

```bash
flutter run --dart-define-from-file=config/supabase.dev.json
```

The local `config/supabase.dev.json` file is ignored by Git.
Without these defines, ShopMaps starts in its existing local-only mode.

## Geoapify address search

Public store maps use Geoapify autocomplete so users select a canonical address
instead of publishing arbitrary address text. After an address is selected, the
same Edge Function uses Geoapify Places API to show named grocery stores,
convenience stores, food shops, discount stores, and marketplaces within
4 kilometers, ordered by distance. Restricting the categories prevents stores
inside shopping malls from pushing nearby supermarkets out of the result
limit. These results are registered in the canonical `store_locations` catalog
by the Edge Function. Public maps and new shared deposit codes reference a
catalog record instead of trusting a user-entered store name.

Create a Geoapify API key and add it as the `GEOAPIFY_API_KEY` secret for the
Supabase Edge Function environment. The key must not be added to
`config/supabase.dev.json` or bundled into the Flutter application.

Deploy the authenticated Edge Function from:

```text
supabase/functions/geoapify-address-search/index.ts
```

## Sharing rules

- Signing in is optional.
- Sharing a grocery list moves it from private local lists into the selected
  group, so it is shown only once as a shared list.
- Stopping sharing restores the latest group version as a private local list on
  the current device and deletes the shared list and its items for the group.
- Shared grocery lists and deposit codes appear in the main grocery-list and
  deposit tabs. Group members receive changes through Supabase Realtime.
- Other group members receive one push notification after a user leaves a
  shared list in which they added products. Deletions alone do not notify.
- Adding, editing, renaming, or deleting shared-list data updates the group
  record. Purchased items are deleted from the shared list when shopping is
  finished or the shopping screen is closed.
- Moving a deposit code writes it to the group first and removes the local copy
  only after the remote operation succeeds.
- Any group member can delete a shared deposit code; the deletion is propagated
  to the other group members.
- A public store map is a published copy. The author's local map remains on
  their device.
- Store locations are deduplicated by Geoapify place ID and normalized store
  name. Public maps and newly shared deposit codes must use a store registered
  from Geoapify; local-only deposit codes may keep any store name.
- Signed-in users can browse public store maps and copy them into their local
  maps. Only the author can update or stop sharing a published map.
- Users are invited only through their complete `Name#1234` handle.
- Profiles cannot be browsed through the client API.
- Deleting an account removes its profile, memberships, invitations, and data
  shared by that user. Local device data and cloud data shared by other members
  remain.

## Before production

- Follow [`production-release.md`](production-release.md).
- Use a separate production Supabase project and Firebase project.
- Configure Apple and Google provider credentials.
- Enable leaked-password protection if password sign-in is added.
- Verify RLS with at least two test users.
- Add a privacy policy.
- Verify push delivery on physical Android and iOS devices.
- Decide whether group deposit codes need a redemption audit view.
- Add rate limiting for repeated invitation attempts if abuse becomes possible.
