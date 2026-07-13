import 'dart:convert';
import 'dart:io';

const _knownDevelopmentSupabaseUrls = {
  'https://kkytxouitzsmzghzznva.supabase.co',
};
const _knownDevelopmentFirebaseProjects = {'shopmaps-a446c'};
const _confirmation = 'I_UNDERSTAND_THIS_BUILD_USES_PRODUCTION_SERVICES';

const _requiredKeys = {
  'APP_ENV',
  'SUPABASE_URL',
  'SUPABASE_PUBLISHABLE_KEY',
  'GOOGLE_WEB_CLIENT_ID',
  'GOOGLE_IOS_CLIENT_ID',
  'FACEBOOK_SSO_ENABLED',
  'PUSH_NOTIFICATIONS_ENABLED',
  'FIREBASE_PROJECT_ID',
  'PRIVACY_POLICY_URL',
  'TERMS_OF_SERVICE_URL',
  'ACCOUNT_DELETION_URL',
  'SUPPORT_EMAIL',
  'PRODUCTION_CONFIRMATION',
};

void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.length > 2) {
    _fail(
      'Usage: dart run tool/validate_production_config.dart '
      '<config.json> [--example]',
    );
  }
  final exampleMode = arguments.contains('--example');
  final path = arguments.firstWhere((argument) => argument != '--example');
  final file = File(path);
  if (!file.existsSync()) {
    _fail('Production configuration file does not exist: $path');
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException catch (error) {
    _fail('Invalid JSON in $path: ${error.message}');
  }
  if (decoded is! Map<String, dynamic>) {
    _fail('Production configuration must be a JSON object.');
  }
  final config = decoded;
  final missing = _requiredKeys.difference(config.keys.toSet()).toList()
    ..sort();
  if (missing.isNotEmpty) {
    _fail('Missing production configuration keys: ${missing.join(', ')}');
  }

  final forbiddenKeys = config.keys.where((key) {
    final normalized = key.toUpperCase();
    return normalized.contains('SERVICE_ROLE') ||
        normalized.contains('SUPABASE_SECRET') ||
        normalized.contains('FIREBASE_SERVICE_ACCOUNT') ||
        normalized.contains('GEOAPIFY_API_KEY') ||
        normalized.contains('DATABASE_PASSWORD');
  }).toList();
  if (forbiddenKeys.isNotEmpty) {
    _fail(
      'Secrets must not be bundled into the application: '
      '${forbiddenKeys.join(', ')}',
    );
  }

  if (config['APP_ENV'] != 'production') {
    _fail('APP_ENV must equal "production".');
  }
  for (final key in ['FACEBOOK_SSO_ENABLED', 'PUSH_NOTIFICATIONS_ENABLED']) {
    if (config[key] is! bool) {
      _fail('$key must be a boolean.');
    }
  }
  if (config['PUSH_NOTIFICATIONS_ENABLED'] != true) {
    _fail('PUSH_NOTIFICATIONS_ENABLED must be true for production.');
  }

  if (exampleMode) {
    stdout.writeln('Production configuration example has the required schema.');
    return;
  }

  final placeholderKeys = _requiredKeys.where((key) {
    final value = config[key];
    if (value is! String) {
      return false;
    }
    final normalized = value.toUpperCase();
    return normalized.contains('REPLACE_ME') ||
        normalized.contains('YOUR_') ||
        normalized.contains('CHANGE_ME');
  }).toList();
  if (placeholderKeys.isNotEmpty) {
    _fail('Replace placeholders in: ${placeholderKeys.join(', ')}');
  }

  final supabaseUrl = _string(config, 'SUPABASE_URL');
  if (!_isHttpsUrl(supabaseUrl) || !supabaseUrl.endsWith('.supabase.co')) {
    _fail('SUPABASE_URL must be a valid HTTPS Supabase project URL.');
  }
  if (_knownDevelopmentSupabaseUrls.contains(supabaseUrl)) {
    _fail('SUPABASE_URL points to the known development project.');
  }

  final publishableKey = _string(config, 'SUPABASE_PUBLISHABLE_KEY');
  if (!publishableKey.startsWith('sb_publishable_')) {
    _fail('Use a Supabase publishable key in the production application.');
  }

  for (final key in ['GOOGLE_WEB_CLIENT_ID', 'GOOGLE_IOS_CLIENT_ID']) {
    if (!_string(config, key).endsWith('.apps.googleusercontent.com')) {
      _fail('$key must be a Google OAuth client ID.');
    }
  }

  final firebaseProjectId = _string(config, 'FIREBASE_PROJECT_ID');
  if (_knownDevelopmentFirebaseProjects.contains(firebaseProjectId)) {
    _fail('FIREBASE_PROJECT_ID points to the known development project.');
  }
  _validateFirebaseProject(firebaseProjectId);

  for (final key in [
    'PRIVACY_POLICY_URL',
    'TERMS_OF_SERVICE_URL',
    'ACCOUNT_DELETION_URL',
  ]) {
    if (!_isHttpsUrl(_string(config, key))) {
      _fail('$key must be a public HTTPS URL.');
    }
  }
  if (!RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  ).hasMatch(_string(config, 'SUPPORT_EMAIL'))) {
    _fail('SUPPORT_EMAIL must be a valid email address.');
  }
  if (config['PRODUCTION_CONFIRMATION'] != _confirmation) {
    _fail('PRODUCTION_CONFIRMATION has an invalid value.');
  }

  stdout.writeln('Production configuration is valid.');
}

void _validateFirebaseProject(String expectedProjectId) {
  final firebaseJson = File('firebase.json');
  final optionsFile = File('lib/firebase_options.dart');
  if (!firebaseJson.existsSync() || !optionsFile.existsSync()) {
    _fail('Run flutterfire configure for the production Firebase project.');
  }

  final firebaseConfig = jsonDecode(firebaseJson.readAsStringSync());
  final serializedFirebaseConfig = jsonEncode(firebaseConfig);
  if (!serializedFirebaseConfig.contains('"projectId":"$expectedProjectId"')) {
    _fail('firebase.json does not point to FIREBASE_PROJECT_ID.');
  }
  if (!optionsFile.readAsStringSync().contains(
    "projectId: '$expectedProjectId'",
  )) {
    _fail('lib/firebase_options.dart does not point to FIREBASE_PROJECT_ID.');
  }
}

String _string(Map<String, dynamic> config, String key) {
  final value = config[key];
  if (value is! String || value.trim().isEmpty) {
    _fail('$key must be a non-empty string.');
  }
  return value.trim();
}

bool _isHttpsUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

Never _fail(String message) {
  stderr.writeln('Production release check failed: $message');
  exit(1);
}
