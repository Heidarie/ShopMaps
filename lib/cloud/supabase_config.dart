class SsoProviderSettings {
  const SsoProviderSettings({required this.isEnabled});

  final bool isEnabled;
}

class SupabaseConfig {
  const SupabaseConfig._();

  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  static const facebookSso = SsoProviderSettings(
    isEnabled: bool.fromEnvironment('FACEBOOK_SSO_ENABLED'),
  );
  static const pushNotificationsEnabled = bool.fromEnvironment(
    'PUSH_NOTIFICATIONS_ENABLED',
  );
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const privacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');
  static const termsOfServiceUrl = String.fromEnvironment(
    'TERMS_OF_SERVICE_URL',
  );
  static const accountDeletionUrl = String.fromEnvironment(
    'ACCOUNT_DELETION_URL',
  );
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
  static const productionConfirmation = String.fromEnvironment(
    'PRODUCTION_CONFIRMATION',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
  static bool get isProduction => environment == 'production';

  static void validateRuntimeConfiguration() {
    if (!isProduction) {
      return;
    }

    final missing = <String>[
      if (url.isEmpty) 'SUPABASE_URL',
      if (publishableKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
      if (googleWebClientId.isEmpty) 'GOOGLE_WEB_CLIENT_ID',
      if (googleIosClientId.isEmpty) 'GOOGLE_IOS_CLIENT_ID',
      if (firebaseProjectId.isEmpty) 'FIREBASE_PROJECT_ID',
      if (privacyPolicyUrl.isEmpty) 'PRIVACY_POLICY_URL',
      if (termsOfServiceUrl.isEmpty) 'TERMS_OF_SERVICE_URL',
      if (accountDeletionUrl.isEmpty) 'ACCOUNT_DELETION_URL',
      if (supportEmail.isEmpty) 'SUPPORT_EMAIL',
    ];
    if (missing.isNotEmpty) {
      throw StateError(
        'Production configuration is incomplete: ${missing.join(', ')}',
      );
    }

    final invalidUrls = <String>[
      if (!_isHttpsUrl(url)) 'SUPABASE_URL',
      if (!_isHttpsUrl(privacyPolicyUrl)) 'PRIVACY_POLICY_URL',
      if (!_isHttpsUrl(termsOfServiceUrl)) 'TERMS_OF_SERVICE_URL',
      if (!_isHttpsUrl(accountDeletionUrl)) 'ACCOUNT_DELETION_URL',
    ];
    if (invalidUrls.isNotEmpty) {
      throw StateError(
        'Production URLs must use HTTPS: ${invalidUrls.join(', ')}',
      );
    }
    if (!publishableKey.startsWith('sb_publishable_')) {
      throw StateError(
        'Production must use a Supabase publishable key, not a secret key.',
      );
    }
    if (!pushNotificationsEnabled) {
      throw StateError('Production push notifications must be enabled.');
    }
    if (productionConfirmation !=
        'I_UNDERSTAND_THIS_BUILD_USES_PRODUCTION_SERVICES') {
      throw StateError('Production configuration was not confirmed.');
    }
  }

  static bool _isHttpsUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }
}
