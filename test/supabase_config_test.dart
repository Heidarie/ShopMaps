import 'package:flutter_test/flutter_test.dart';
import 'package:shopmaps/cloud/supabase_config.dart';

void main() {
  test('legal settings point to sections of the shared legal document', () {
    final privacyUri = Uri.parse(SupabaseConfig.privacyPolicyUrl);
    final rulesUri = Uri.parse(SupabaseConfig.termsOfServiceUrl);
    final accountDeletionUri = Uri.parse(SupabaseConfig.accountDeletionUrl);

    expect(
      {
        '${privacyUri.origin}${privacyUri.path}',
        '${rulesUri.origin}${rulesUri.path}',
        '${accountDeletionUri.origin}${accountDeletionUri.path}',
      },
      {'https://heidarie.github.io/ShopMaps/'},
    );
    expect(privacyUri.fragment, 'privacy');
    expect(rulesUri.fragment, 'rules');
    expect(accountDeletionUri.fragment, 'account-deletion');
  });
}
